VARIANTS = open	blacklist	whitelist
GEN = $(addprefix gen-,$(VARIANTS))
BUILD = $(addprefix build-,$(VARIANTS))
IMAGE = wiltonsr/opentracker
.PHONY: all
all: build-all-variants

.PHONY: gen-all-variants
gen-all-variants: $(GEN)

.PHONY: $(GEN)
$(GEN):
	./update.sh $(@:gen-%=%)

.PHONY: $(BUILD)
$(BUILD):
	$(eval TAG = $(@:build-%=%))
	@echo Building tag $(TAG) from Dockerfile.$(TAG) file...
	docker build -t $(IMAGE):$(TAG) -f Dockerfile.$(TAG) .

.PHONY: tag-latest
tag-latest:
	@echo Tagging open image as latest
	docker image tag $(IMAGE):open $(IMAGE):latest

.PHONY: build-all-variants
build-all-variants: gen-all-variants $(BUILD) tag-latest

.PHONY: registry-push
registry-push:
	docker push -a $(IMAGE)