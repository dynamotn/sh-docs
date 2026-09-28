# shellcheck shell=bash
# @file tests/testcases/noargs.test.sh
# @brief Testcase for the @noargs tag.
# @description A function that takes no arguments says so.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Print the current version.
# @noargs
say::version() {
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

- [`say::version`](#sayversion) — Print the current version.

<a id="reference"></a>
## 📚 Reference

### `say::version`

Print the current version.

_Function has no arguments._
MD

tests::assert
