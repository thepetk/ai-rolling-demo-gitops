import os
import pytest
from playwright.sync_api import sync_playwright, Browser, BrowserContext, Page


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


@pytest.fixture(scope="session")
def base_url() -> "str":
    """
    returns the base url of RHDH isntance we are testing
    """
    return _require_env("BASE_URL").rstrip("/")


@pytest.fixture(scope="session")
def authenticated_page(base_url: "str") -> "Page":
    """
    returns a session-scoped fixture that performs
    Red Hat SSO (Keycloak) login once and yields the
    authenticated Playwright Page for reuse across all tests.
    """
    username = _require_env("RH_USERNAME")
    password = _require_env("RH_PASSWORD")

    with sync_playwright() as playwright:
        browser: Browser = playwright.chromium.launch(headless=True)
        context: BrowserContext = browser.new_context(
            ignore_https_errors=True,
        )
        page: Page = context.new_page()

        # navigate to the app and get a redirect to the SSO login page
        page.goto(base_url, wait_until="networkidle")

        # fill in SSO credentials
        page.fill("input#username", username)
        page.fill("input#password", password)
        page.click("input[type='submit']")

        # wait for the RHDH home page to load after redirect
        page.wait_for_url(f"{base_url}/**", wait_until="networkidle")

        yield page

        context.close()
        browser.close()
