# Testing

The `tests/` directory contains an E2E test suite for the AI Rolling Demo UI. Those tests are also used by our nightly CI run (`.github/workflows/nightly.yml`) which verifies that the deployed RHDH instances work and behave as expected.

## Prerequisites

- `python` version greater than `3.11`.
- [uv](https://docs.astral.sh/uv/) installed (`pip install uv` or via the official installer).
- A running RHDH instance (e.g. deployed via `make install`).

## Set up the test environment

```bash
cd tests
uv sync
uv run playwright install chromium
```

## Running tests locally

Assuming you have followed the [SETUP_GUIDE](SETUP_GUIDE.md), you should have already set the following variables in your `private-env`:

- `ARGOCD_APP_NAME`
- `RHDH_NAMESPACE`
- `RHDH_CLUSTER_ROUTER_BASE`
- `KEYCLOAK_CLIENT_ID`
- `KEYCLOAK_CLIENT_SECRET`

Add the required variables to `scripts/private-env`:

```bash
# RHDH_BASE_URL can be derived from already exported variables in private-env
export RHDH_BASE_URL="https://${ARGOCD_APP_NAME}-backstage-${RHDH_NAMESPACE}.${RHDH_CLUSTER_ROUTER_BASE}"
# Default is production unless otherwise set in app-config
export RHDH_ENVIRONMENT="production"
# A test user that your client can impersonate to authenticate in RHDH
export ROLLING_DEMO_TEST_USERNAME="demo-user"
# Optional: set to "false" to run tests with a visible browser window (default: "true")
export PLAYWRIGHT_HEADLESS="false"
```

Then run:

```bash
make tests
```

**NOTE**: It will exit with an error if `tests/.venv` does not exist or if `uv`/`pytest` is not available after activating the `.venv`.
