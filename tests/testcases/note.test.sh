# shellcheck shell=bash
# @file tests/testcases/note.test.sh
# @brief Testcase for the @note tag.
# @description Notes stay with the function they document.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Print a greeting.
# @note Not safe to call from a trap handler.
# @note Writes nothing when the name is empty.
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

**📝 Notes**

- Not safe to call from a trap handler.
- Writes nothing when the name is empty.
MD

tests::assert
