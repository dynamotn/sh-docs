# shellcheck shell=bash
# @file tests/testcases/arg.test.sh
# @brief Testcase for the @arg tag.
# @description Positional arguments are rendered as a table of name, type and
#   description.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Repeat a string.
# @arg $1 string The string to repeat.
# @arg $2 number How many times to repeat it.
# @arg $@ any Extra separators, joined with a pipe | character.
strings::repeat() {
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

- [`strings::repeat`](#stringsrepeat) — Repeat a string.

<a id="reference"></a>
## 📚 Reference

### `strings::repeat`

Repeat a string.

**🧾 Arguments**

| Name | Type | Description |
| --- | --- | --- |
| `$1` | string | The string to repeat. |
| `$2` | number | How many times to repeat it. |
| `$@` | any | Extra separators, joined with a pipe \| character. |
MD

tests::assert
