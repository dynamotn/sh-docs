SH_DOCS = ../sh-docs
OBJECTS = $(patsubst %.sh, %.md, $(wildcard *.sh))

all: $(OBJECTS)

%.md: %.sh
	$(SH_DOCS) < $^ > $@

# Compare each committed document with what its source generates, without
# writing anything.
check:
	@status=0; for src in $(wildcard *.sh); do \
		$(SH_DOCS) --check --output "$${src%.sh}.md" "$$src" || status=1; \
	done; exit $$status

.PHONY: all check
