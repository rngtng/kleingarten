PROJECT     ?= rngtng/kleingarten
BUILD_TAG   ?= dev
REGISTRY_TAG = $(PROJECT):$(BUILD_TAG)

NPROCS = $(shell sysctl hw.ncpu  | grep -o '[0-9]\+')
MAKEFLAGS += -j$(NPROCS)

.PHONY: help # List all documented targets
help:
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 $(shell echo "\t") \2/' | sort | expand -t20

.PHONY: build # Build docker image with `dev` tag
build:
	docker build -t $(REGISTRY_TAG) .

.PHONY: test-gh-action # Test github actions locally with https://github.com/nektos/act
test-gh-action:
	echo '{ "inputs": { "tag": "0.1.0" } }' > /tmp/act.json
	act --artifact-server-path /tmp/artifacts workflow_dispatch -e /tmp/act.json

.PHONY: dev # Build docker image, run and ssh inside
dev:
	docker run --rm -it -v "$(shell pwd):/app" $(REGISTRY_TAG)

.PHONY: run #
run: build
	docker run --rm -it --entrypoint=ruby $(REGISTRY_TAG) ./inspect.rb > timeline.html


# https://ademcan.net/blog/2013/04/10/how-to-convert-pdf-to-png-from-the-command-line-on-a-mac/
files := $(wildcard files/old/*.pdf)
%.txt:
	@sips -s format png $(@:.txt=.pdf) --out $(@:.txt=.png)
	@tesseract -l deu $(@:.txt=.png) $(@:.txt=)
	@rm $(@:.txt=.png)

.PHONY: convert # Transform pdf to text
convert: $(files:.pdf=.txt)

clean:
	rm -rf files/old/*.txt
