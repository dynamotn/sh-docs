# shellcheck shell=bash
# @file tests/testcases/since.test.sh
# @brief Testcase for the @since tag.
# @description `@since` names the version a module or a function first
#   appeared in. The module's is printed under the brief, a function's under
#   its heading.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @brief Helpers for text manipulation.
# @since 1.0.0

# @description Trim surrounding whitespace.
# @since 1.2.0
strings::trim() {
  :
}
SH

tests::put expected << 'MD'
# strings.sh

Helpers for text manipulation.

_Since: 1.0.0_

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Reference](#reference)

<a id="overview"></a>

## ✨ Overview

### 🚀 Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.

<a id="reference"></a>

## 📚 Reference

### `strings::trim`

_Since: 1.2.0_

Trim surrounding whitespace.
MD

tests::assert
tests::run --strict
tests::assert_exitcode 0
