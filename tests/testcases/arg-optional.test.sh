# shellcheck shell=bash
# @file tests/testcases/arg-optional.test.sh
# @brief Testcase for optional arguments and defaults.
# @description A type ending in `?` marks an argument or a variable optional,
#   and `[default: value]` after the type gives its default, which makes it
#   optional too. A table gains its Required and Default columns only when one
#   of its rows uses them, so a table that does not looks as it always did.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @env STRINGS_FILL string [default: space] Character used for padding.
# @env STRINGS_LOCALE string Locale used when folding case.

# @description Repeat a string.
# @arg $1 string The string to repeat.
# @arg $2 number [default: 1] How many times to repeat it.
# @arg $3 string? Separator put between the copies.
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

### 🌍 Environment

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| **`STRINGS_FILL`** | string | no | `space` | Character used for padding. |
| **`STRINGS_LOCALE`** | string | yes |  | Locale used when folding case. |

### 🚀 Highlights

- [`strings::repeat`](#stringsrepeat) — Repeat a string.

<a id="reference"></a>

## 📚 Reference

### `strings::repeat`

Repeat a string.

**🧾 Arguments**

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `$1` | string | yes |  | The string to repeat. |
| `$2` | number | no | `1` | How many times to repeat it. |
| `$3` | string | no |  | Separator put between the copies. |
MD

tests::assert
