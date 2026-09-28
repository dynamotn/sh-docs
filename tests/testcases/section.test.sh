# shellcheck shell=bash
# @file tests/testcases/section.test.sh
# @brief Testcase for the @section tag.
# @description Functions are grouped under their section, and the groups are listed in
#   the navigation block.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @section Trimming
# @description Remove leading whitespace.
strings::ltrim() {
  :
}

# @section Trimming
# @description Remove trailing whitespace.
strings::rtrim() {
  :
}

# @section Casing
# @description Fold to lower case.
strings::lower() {
  :
}
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Reference](#reference)
>
> Reference sections: [Trimming](#trimming) · [Casing](#casing)

<a id="overview"></a>
## ✨ Overview

### 🚀 Highlights

- [`strings::ltrim`](#stringsltrim) — Remove leading whitespace.
- [`strings::rtrim`](#stringsrtrim) — Remove trailing whitespace.
- [`strings::lower`](#stringslower) — Fold to lower case.

<a id="reference"></a>
## 📚 Reference

<a id="trimming"></a>
### 🧩 Trimming

#### `strings::ltrim`

Remove leading whitespace.


---

#### `strings::rtrim`

Remove trailing whitespace.


<a id="casing"></a>
### 🧩 Casing

#### `strings::lower`

Fold to lower case.
MD

tests::assert
