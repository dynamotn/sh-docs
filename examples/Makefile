SH_DOCS = ../sh-docs
OBJECTS = $(patsubst %.sh, %.md, $(wildcard *.sh))

all: $(OBJECTS)

%.md: %.sh
	$(SH_DOCS) < $^ > $@

.PHONY: all
