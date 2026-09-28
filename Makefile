SHELL = /bin/bash

SHELL_FILES = sh-docs tests/run_tests tests/lib.sh $(wildcard tests/testcases/*.test.sh) examples/readme-example.sh

# The formatting the style guide implies, the same set dyshellint checks with.
SHFMT_FLAGS = --language-dialect bash --indent 2 --case-indent --binary-next-line --space-redirects

INSTALL ?= install
PREFIX ?= /usr/local
DESTDIR ?=
DST ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share/sh-docs
MANDIR ?= $(PREFIX)/share/man/man1
MANPAGE = contrib/sh-docs.1

.PHONY: all test examples check-examples lint fmt install uninstall

all: test

test:
	./tests/run_tests

examples:
	$(MAKE) -C examples/ -B

# The generated example is committed, so it can fall behind the source it is
# generated from. The testcase of the same name checks it in the suite too.
check-examples: examples
	git diff --exit-code -- examples/

# dyshellint drives ShellCheck and shfmt itself, so it is the whole shell pass.
lint:
	dyshellint $(SHELL_FILES)
	gawk -f sh-docs.awk /dev/null > /dev/null

fmt:
	shfmt $(SHFMT_FLAGS) -w $(SHELL_FILES)

install:
	$(INSTALL) -d "$(DESTDIR)$(DST)" "$(DESTDIR)$(DATADIR)" "$(DESTDIR)$(MANDIR)"
	$(INSTALL) -m 0644 sh-docs.awk "$(DESTDIR)$(DATADIR)/sh-docs.awk"
	# The wrapper looks for the awk program next to itself, which is only true
	# in a checkout; point it at the installed copy instead.
	sed 's|$${SELF_DIR}/sh-docs.awk|$(DATADIR)/sh-docs.awk|' sh-docs \
		> "$(DESTDIR)$(DST)/sh-docs"
	chmod 0755 "$(DESTDIR)$(DST)/sh-docs"
	$(INSTALL) -m 0644 $(MANPAGE) "$(DESTDIR)$(MANDIR)/sh-docs.1"

uninstall:
	rm -f "$(DESTDIR)$(DST)/sh-docs" \
		"$(DESTDIR)$(DATADIR)/sh-docs.awk" \
		"$(DESTDIR)$(MANDIR)/sh-docs.1"
	-rmdir "$(DESTDIR)$(DATADIR)"
