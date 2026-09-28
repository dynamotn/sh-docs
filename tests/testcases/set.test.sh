# shellcheck shell=bash
# @file tests/testcases/set.test.sh
# @brief Testcase for the @set tag.
# @description A variable the function sets is rendered with its type.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Store the greeting in a variable.
# @set REPLY string The rendered greeting.
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

- [`say::hello`](#sayhello) — Store the greeting in a variable.

<a id="reference"></a>
## 📚 Reference

### `say::hello`

Store the greeting in a variable.

**🧩 Variable sets**

- **`REPLY`** (string): The rendered greeting.
MD

tests::assert
