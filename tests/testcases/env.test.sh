# shellcheck shell=bash
# @file tests/testcases/env.test.sh
# @brief Testcase for the @env tag on a function.
# @description Environment variables a function reads are rendered as a table.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Print a greeting.
# @env GREETING string Word used instead of "Hello".
# @env GREETING_UPPER bool Whether to shout.
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

**🌍 Environment variables**

| Variable | Type | Description |
| --- | --- | --- |
| **`GREETING`** | string | Word used instead of "Hello". |
| **`GREETING_UPPER`** | bool | Whether to shout. |
MD

tests::assert
