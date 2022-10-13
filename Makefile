SHELL := /bin/bash
MKFILE_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: setup-test install-std-regular install-std-rapid install-ap-regular install-ap-rapid cleanup
# ## Self help
# help:
# 	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

source: ## Sources envars from the source.sh file
	source source.sh

test: ##Creates four projects and configures directories to test each variation.
	./test.sh

cleanup: ## Delete projects created by setup test
	./project-remove.sh