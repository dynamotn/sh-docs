# shellcheck shell=bash
# @file tests/testcases/internal.test.sh
# @brief Testcase for the @internal tag.
# @description An @internal function is left out of the document entirely.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @internal
# @description Not part of the public interface.
__strings_helper() {
  :
}

# @description Trim surrounding whitespace.
strings::trim() {
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

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.
MD

tests::assert
