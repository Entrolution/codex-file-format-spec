# Makefile for Codex Pandoc Writer

PANDOC := pandoc
WRITER := codex.lua
JQ := jq

# Test input files
TEST_INPUTS := $(wildcard tests/inputs/*.md)
TEST_OUTPUTS := $(patsubst tests/inputs/%.md,tests/outputs/%.json,$(TEST_INPUTS))
TEST_CDX := $(patsubst tests/inputs/%.md,tests/outputs/%.cdx,$(TEST_INPUTS))

.PHONY: all test clean test-json test-cdx help check-deps

all: test

help:
	@echo "Codex Pandoc Writer"
	@echo ""
	@echo "Targets:"
	@echo "  test        Run all tests (JSON output)"
	@echo "  test-cdx    Run full pipeline tests (creates .cdx files)"
	@echo "  clean       Remove generated files"
	@echo "  check-deps  Check for required dependencies"
	@echo ""
	@echo "Examples:"
	@echo "  make test"
	@echo "  make test-cdx"
	@echo "  $(PANDOC) input.md -t $(WRITER) -o output.json"

check-deps:
	@command -v $(PANDOC) >/dev/null 2>&1 || { echo "Error: pandoc not found"; exit 1; }
	@command -v $(JQ) >/dev/null 2>&1 || { echo "Error: jq not found"; exit 1; }
	@echo "All dependencies found."

# Create outputs directory
tests/outputs:
	mkdir -p tests/outputs

# Test JSON output from writer
test-json: check-deps tests/outputs $(TEST_OUTPUTS)
	@echo "JSON tests complete."

tests/outputs/%.json: tests/inputs/%.md $(WRITER) lib/*.lua
	@echo "Converting $< -> $@"
	@$(PANDOC) $< -t $(WRITER) -o $@
	@$(JQ) '.content.blocks | length' $@ > /dev/null && echo "  Valid JSON with $$($(JQ) '.content.blocks | length' $@) blocks"

# Test full pipeline
test-cdx: check-deps tests/outputs $(TEST_CDX)
	@echo "CDX pipeline tests complete."

tests/outputs/%.cdx: tests/inputs/%.md $(WRITER) lib/*.lua scripts/pandoc-to-cdx.sh
	@echo "Creating CDX: $< -> $@"
	@./scripts/pandoc-to-cdx.sh $< $@

# Run all tests
test: test-json
	@echo ""
	@echo "All tests passed!"

# Validate JSON structure
validate: test-json
	@echo "Validating JSON structure..."
	@for f in tests/outputs/*.json; do \
		echo "Checking $$f..."; \
		$(JQ) -e '.manifest and .content and .dublin_core' $$f > /dev/null || { echo "FAIL: $$f missing required sections"; exit 1; }; \
		$(JQ) -e '.content.version and .content.blocks' $$f > /dev/null || { echo "FAIL: $$f invalid content structure"; exit 1; }; \
		$(JQ) -e '.dublin_core.version and .dublin_core.terms' $$f > /dev/null || { echo "FAIL: $$f invalid dublin_core structure"; exit 1; }; \
		echo "  OK"; \
	done
	@echo "Validation complete."

# Clean generated files
clean:
	rm -rf tests/outputs
	rm -f tests/expected/*.json

# Development: watch for changes and run tests
watch:
	@echo "Watching for changes... (Ctrl+C to stop)"
	@while true; do \
		$(MAKE) test-json 2>&1 || true; \
		sleep 2; \
	done

# Print a sample conversion
sample:
	@echo "Sample conversion of tests/inputs/basic.md:"
	@echo ""
	@$(PANDOC) tests/inputs/basic.md -t $(WRITER) | $(JQ) '.'
