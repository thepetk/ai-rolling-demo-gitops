.PHONY: install install-no-gpu tests

install:
	bash setup.sh

install-no-gpu:
	SKIP_GPU_DEPS=true SKIP_RHOAI_SETUP=true bash setup.sh

tests:
	bash scripts/run-tests.sh
