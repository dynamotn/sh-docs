# shellcheck shell=bash
# @file tests/testcases/line-links.test.sh
# @brief Testcase for --line-links.
# @description --line-links links each function to the line it is declared on.
#   It is off by default: every edit above a function moves its line, and a
#   committed document would go stale with it. Without a source path there is
#   nothing to link to, so no link is printed.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Trim surrounding whitespace.
strings::trim() {
  :
}

# @description Fold to lower case.
strings::lower()
{
  :
}
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Reference](#reference)

<a id="overview"></a>

## ✨ Overview

### 🚀 Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.
- [`strings::lower`](#stringslower) — Fold to lower case.

<a id="reference"></a>

## 📚 Reference

### `strings::trim`

_Source: [src/strings.sh:5](../src/strings.sh#L5)_

Trim surrounding whitespace.

---

### `strings::lower`

_Source: [src/strings.sh:10](../src/strings.sh#L10)_

Fold to lower case.
MD

tests::assert --line-links

# The link follows --source-path.
tests::run --line-links --source-path lib/strings.sh
tests::assert_exitcode 0
tests::assert_stdout_contains '_Source: [lib/strings.sh:5](../lib/strings.sh#L5)_'

# No @file and no --source-path: no link.
tests::put input << 'SH'
# @description Trim surrounding whitespace.
strings::trim() {
  :
}
SH
tests::run --line-links
tests::assert_exitcode 0
if grep -qF '_Source:' stdout; then
  tests::fail 'a document without a source path has no line links'
fi
