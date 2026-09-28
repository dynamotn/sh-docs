# shellcheck shell=bash
# @file tests/testcases/deprecated-function.test.sh
# @brief Testcase for @deprecated on a function.
# @description A deprecated function carries a callout above its description.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Trim surrounding whitespace.
# @deprecated Use `strings::trim` instead.
strings::strip() {
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

- [`strings::strip`](#stringsstrip) — Trim surrounding whitespace.

<a id="reference"></a>
## 📚 Reference

### `strings::strip`

> ⚠️ **Deprecated**
>
> Use `strings::trim` instead.

Trim surrounding whitespace.
MD

tests::assert
