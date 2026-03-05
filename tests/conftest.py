import base64
import hashlib
import hmac
import json
import os
import time
import warnings

import pytest
import requests
from playwright.sync_api import sync_playwright, Browser, BrowserContext, Page

# suppress urllib3 warnings for self-signed certificates
warnings.filterwarnings("ignore", message="Unverified HTTPS request")


def _require_env(name: "str") -> "str":
    """
    requires an environment variable to be set and returns
    its value. If the variable is not set, it raises an
    EnvironmentError with a message indicating which variable
    is missing and how to set it.
    """
    value = os.environ.get(name)
    if not value:
        raise EnvironmentError(
            f"Required environment variable '{name}' is not set. "
            "Set it before running the tests:\n"
            f"  export {name}=<value>"
        )
    return value


def _get_keycloak_token(
    keycloak_base_url: "str",
    realm: "str",
    client_id: "str",
    client_secret: "str",
    username: "str",
    password: "str",
) -> "dict[str, str]":
    """
    obtains tokens from Keycloak using the Resource Owner Password
    Credentials grant. No browser, no RH SSO redirect, no OTP.
    """
    resp = requests.post(
        f"{keycloak_base_url}/realms/{realm}/protocol/openid-connect/token",
        data={
            "grant_type": "password",
            "client_id": client_id,
            "client_secret": client_secret,
            "username": username,
            "password": password,
            "scope": "openid profile email",
        },
        verify=False,
    )
    resp.raise_for_status()
    return resp.json()


def _decode_jwt_claims(token: "str") -> "dict":
    """
    decodes the payload of a JWT without signature verification.
    """
    payload = token.split(".")[1]
    payload += "=" * (4 - len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))


def _b64url_encode(data: "bytes") -> "str":
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _forge_backstage_token(
    backend_secret: "str",
    username: "str",
) -> "str":
    """
    forges a Backstage user identity JWT signed with the BACKEND_SECRET (HS256).

    Backstage stores backend.auth.keys[].secret as a base64url-encoded value;
    the actual signing key bytes are obtained by decoding it.  The token type
    'vnd.backstage.user.v1+jwt' is required by Backstage 1.28+ (RHDH 1.9).
    """
    # backend.auth.keys[].secret is base64url-encoded per Backstage convention
    padded = backend_secret + "=" * (4 - len(backend_secret) % 4)
    key_bytes = base64.urlsafe_b64decode(padded)

    # 'vnd.backstage.user.v1+jwt' is required by Backstage 1.28+ / RHDH 1.9
    header = {"alg": "HS256", "typ": "vnd.backstage.user.v1+jwt"}
    now = int(time.time())
    payload = {
        "sub": f"user:default/{username}",
        "ent": [f"user:default/{username}"],
        "iat": now,
        "exp": now + 3600,
    }

    header_b64 = _b64url_encode(json.dumps(header, separators=(",", ":")).encode())
    payload_b64 = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode())
    signing_input = f"{header_b64}.{payload_b64}"

    sig = hmac.new(key_bytes, signing_input.encode(), hashlib.sha256).digest()
    return f"{signing_input}.{_b64url_encode(sig)}"


@pytest.fixture(scope="session")
def base_url() -> "str":
    """
    returns the base url of RHDH instance we are testing
    """
    return _require_env("BASE_URL").rstrip("/")


@pytest.fixture(scope="session")
def authenticated_page(base_url: "str") -> "Page":
    """
    returns a session-scoped authenticated Playwright Page.

    authentication flow:
      1. ROPC grant against Keycloak — local user, no browser, no RH SSO
      2. extract preferred_username from the Keycloak access token claims
      3. forge a Backstage user identity JWT signed with BACKEND_SECRET
      4. inject the token into Playwright's sessionStorage so RHDH
         treats the browser as already authenticated
    """
    keycloak_data = _get_keycloak_token(
        keycloak_base_url=_require_env("KEYCLOAK_BASE_URL"),
        realm=_require_env("KEYCLOAK_REALM"),
        client_id=_require_env("KEYCLOAK_CLIENT_ID"),
        client_secret=_require_env("KEYCLOAK_CLIENT_SECRET"),
        username=_require_env("KEYCLOAK_USERNAME"),
        password=_require_env("KEYCLOAK_PASSWORD"),
    )

    access_claims = _decode_jwt_claims(keycloak_data["access_token"])
    username = access_claims.get("preferred_username") or access_claims["sub"]

    backstage_token = _forge_backstage_token(
        backend_secret=_require_env("BACKEND_SECRET"),
        username=username,
    )

    with sync_playwright() as playwright:
        browser: Browser = playwright.chromium.launch(headless=False)
        context: BrowserContext = browser.new_context(ignore_https_errors=True)
        page: Page = context.new_page()

        # navigate to the origin so sessionStorage writes are valid
        page.goto(base_url, wait_until="domcontentloaded")

        # inject the forged Backstage identity token into the key RHDH reads on boot
        page.evaluate(
            "token => window.sessionStorage.setItem("
            "'@backstage/core:SignInPage:token', token)",
            backstage_token,
        )

        # reload so RHDH picks up the token and renders authenticated
        page.goto(base_url, wait_until="networkidle")

        # --- diagnostic: dump sessionStorage and check auth state ---
        storage = page.evaluate(
            "() => JSON.stringify(Object.fromEntries(Object.entries(sessionStorage)))"
        )
        on_login_page = page.locator("button:text('Sign in')").is_visible()
        print(f"\n[conftest] on_login_page={on_login_page}")
        print(f"[conftest] sessionStorage={storage}")
        print(f"[conftest] current_url={page.url}")
        # --- end diagnostic ---

        # close the quickstart guide if it is present
        try:
            hide_btn = page.locator("button:text-is('Hide')")
            hide_btn.wait_for(state="visible", timeout=5000)
            hide_btn.click()
        except Exception:
            pass

        yield page

        context.close()
        browser.close()
