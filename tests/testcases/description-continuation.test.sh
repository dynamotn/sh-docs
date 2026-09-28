# shellcheck shell=bash
# @file tests/testcases/description-continuation.test.sh
# @brief Testcase for the two shapes of @description.
# @description A description reads the same whether the first line sits on the tag or the
#   whole paragraph is indented under it.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Trim surrounding whitespace.
#
#   The value is returned on stdout, never in place.
strings::trim() {
  :
}

# @description
#   Fold to lower case.
#
#   The value is returned on stdout, never in place.
strings::lower() {
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

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace. The value is returned on stdout, never in place.
- [`strings::lower`](#stringslower) — Fold to lower case. The value is returned on stdout, never in place.

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.

The value is returned on stdout, never in place.


---

### `strings::lower`

Fold to lower case.

The value is returned on stdout, never in place.
MD

tests::assert
