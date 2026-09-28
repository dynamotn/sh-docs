# shellcheck shell=bash
# @file tests/testcases/exitcode.test.sh
# @brief Testcase for the @exitcode tag.
# @description Exit codes are rendered as a bullet list of code and condition.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Print a greeting.
# @exitcode 0 The greeting was printed.
# @exitcode 1 No name was given.
say::hello() {
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

- [`say::hello`](#sayhello) — Print a greeting.

<a id="reference"></a>
## 📚 Reference

### `say::hello`

Print a greeting.

**🚦 Exit codes**

- `0`: The greeting was printed.
- `1`: No name was given.
MD

tests::assert
