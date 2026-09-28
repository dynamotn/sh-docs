# shellcheck shell=bash
# @file tests/testcases/function-declaration-forms.test.sh
# @brief Testcase for the four function declaration forms.
# @description All four declaration forms are documented alike.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file forms.sh

# @description Posix form.
posix::form() {
  :
}

# @description Keyword form.
function keyword::form {
  :
}

# @description Keyword form with parentheses.
function both::form() {
  :
}

# @description Opening brace on the next line.
next::line()
{
  :
}
SH

tests::put expected << 'MD'
# forms.sh

> 🧭 Source: [src/forms.sh](../src/forms.sh)
>
> Jump to: [Overview](#overview) · [Reference](#reference)

<a id="overview"></a>
## ✨ Overview

### 🚀 Highlights

- [`posix::form`](#posixform) — Posix form.
- [`keyword::form`](#keywordform) — Keyword form.
- [`both::form`](#bothform) — Keyword form with parentheses.
- [`next::line`](#nextline) — Opening brace on the next line.

<a id="reference"></a>
## 📚 Reference

### `posix::form`

Posix form.


---

### `keyword::form`

Keyword form.


---

### `both::form`

Keyword form with parentheses.


---

### `next::line`

Opening brace on the next line.
MD

tests::assert
