# shellcheck shell=bash
# @file tests/testcases/linter-directives.test.sh
# @brief Testcase for linter directives inside doc comments.
# @description A `shellcheck` or `dyshellint` directive is addressed to a tool,
#   not to the reader, so it is dropped wherever it appears: in the file
#   header, in a function block, and in the middle of a description.

tests::put input << 'SH'
# shellcheck shell=bash
# @file strings.sh
# @namespace strings
# @brief Helpers for text manipulation.
# @description Trimming and folding.
# dyshellint disable=BSG020 the header is the fixture here
#   Second paragraph.

# @description Trim surrounding whitespace.
# shellcheck disable=SC2034
function strings::trim {
  :
}
SH

tests::put expected << 'MD'
# strings.sh

Helpers for text manipulation.

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Reference](#reference)

<a id="overview"></a>
## ✨ Overview

Trimming and folding.
Second paragraph.

### 🚀 Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.
MD

tests::assert
