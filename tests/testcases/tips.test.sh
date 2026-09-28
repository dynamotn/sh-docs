# shellcheck shell=bash
# @file tests/testcases/tips.test.sh
# @brief Testcase for the @tip tag.
# @description Module tips and function tips are collected into one Tips section.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @tip Source the module once; it is not idempotent.

# @description Trim surrounding whitespace.
# @tip Prefer this over a subshell with `sed`.
strings::trim() {
  :
}
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Tips](#tips) · [Reference](#reference)

<a id="overview"></a>
## ✨ Overview

### 🚀 Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.

<a id="tips"></a>
## 💡 Tips

- Source the module once; it is not idempotent.

### `strings::trim`

- Prefer this over a subshell with `sed`.

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.
MD

tests::assert
