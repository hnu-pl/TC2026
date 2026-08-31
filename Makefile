# Top-level makefile

.PHONY: all all-clean build build-clean update-files-json

TYPFILE = main.typ
BUILD_DIR = _build
DIRTY_SRCS = $(shell typst eval 'query(<meta:dirty-file>).map(it => it.value.file)' --in $(TYPFILE) | jq -r '.[]' | tr '\n' ' ' | sed 's/[[:space:]]*$$//')
TYPST_COMPILE = \
	typst compile $(TYPFILE) && \
	echo "" >> main.typ && \
	sleep 0.1 && \
	sed -i '$d' main.typ

all: build 

refresh: build
	touch $(TYPFILE)

build: | $(BUILD_DIR)/Makefile
	@if [ -n "$(strip $(DIRTY_SRCS))" ]; then \
		$(MAKE) -C $(BUILD_DIR) DIRTY_SRCS='$(DIRTY_SRCS)'; \
	else \
		echo "No dirty files; skipping _build sub-make."; \
	fi
	$(MAKE) update-files-json
	$(TYPST_COMPILE)

all-clean:
	# rm -f $(TYPFILE:.typ=.pdf)
	rm -rf $(BUILD_DIR)
	$(MAKE) update-files-json
	$(TYPST_COMPILE)

build-clean: | $(BUILD_DIR)/Makefile
	$(MAKE) -C $(BUILD_DIR) clean
	$(MAKE) update-files-json
	$(TYPST_COMPILE)

update-files-json:
	if [ -d "$(BUILD_DIR)" ] && [ -n "$$(find $(BUILD_DIR) -maxdepth 1 -type f ! -name 'files.json' -print -quit)" ]; then \
		find $(BUILD_DIR) -maxdepth 1 -type f ! -name 'files.json' | sort | while IFS= read -r file; do \
			rel=$$(basename "$$file"); \
			size=$$(stat -c '%s' "$$file"); \
			mtime=$$(stat -c '%y' "$$file"); \
			sha256=$$(sha256sum "$$file" | cut -d' ' -f1); \
			jq -n --arg file "$$rel" --arg modified_at "$$mtime" --arg sha256 "$$sha256" --argjson size "$$size" --rawfile content "$$file" '{file: $$file, size: $$size, modified_at: $$modified_at, content: $$content, sha256: $$sha256}'; \
		done | jq -s . > files.json; \
	else \
		echo '[]' > files.json; \
	fi

$(BUILD_DIR)/Makefile: $(TYPFILE)
	mkdir -p $(BUILD_DIR) && typst eval 'query(<meta:make-file>).map(it=>it.value.code)' --in $< | jq -r '.[]' > $@
