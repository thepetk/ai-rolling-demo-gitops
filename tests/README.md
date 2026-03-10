# AI Rolling Demo Testing Suite

Testing Suite for E2E tests on UI of AI Rolling Demo. The current directory
is used by our nightly tests to verify that specific parts of our RHDH
instance (deployed by our gitops environment) works and behaves as expected.

## Prerequisites

- [uv](https://docs.astral.sh/uv/) installed (`pip install uv` or via the official installer)

## Setup

```bash
cd tests
uv sync
uv run playwright install chromium
```

## Required Environment Variables

| Variable                     | Description                                          | Example                              |
| ---------------------------- | ---------------------------------------------------- | ------------------------------------ |
| `BASE_URL`                   | Root URL of the RHDH instance (no trailing `/`)      | `https://rolling-demo-backstage-...` |
| `RHDH_ENVIRONMENT`           | Backstage auth environment name                      | `development`                        |
| `ROLLING_DEMO_TEST_USERNAME` | Username of the test user to impersonate in Keycloak | `demo-user`                          |
| `KEYCLOAK_CLIENT_ID`         | Client ID of the Keycloak service account            | `my-client`                          |
| `KEYCLOAK_CLIENT_SECRET`     | Client secret of the Keycloak service account        | `mys3cr3t`                           |

Export them before running tests:

```bash
export BASE_URL=https://rolling-demo-backstage-rolling-demo-ns.apps.example.com
export RHDH_ENVIRONMENT=development
export ROLLING_DEMO_TEST_USERNAME=demo-user
export KEYCLOAK_CLIENT_ID=my-client
export KEYCLOAK_CLIENT_SECRET=s3cr3t
```

## Running Tests

```bash
# All tests
uv run pytest -v

# Smoke tests only (no authentication required)
uv run pytest -m smoke -v

# Login page tests only
uv run pytest test_login.py -v
```
