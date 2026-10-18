# shellcheck shell=bash
# @file tests/testcases/anchor-collision.test.sh
# @brief Testcase for a function whose anchor is already taken.
# @description A function named like a section of the document, such as
#   `usage`, would share its anchor, and every link to the function would land
#   on the section. So would the second of two functions whose names slug
#   alike. Such a function gets an anchor of its own, `fn-<slug>`, and every
#   link to it, `@see` included, points there. Any other function keeps the
#   anchor GitHub gives its heading.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file cli.sh
# @usage cli.sh
# @tip Run it.

# @description Print usage.
# @see reference
usage() {
  :
}

# @description Print the reference.
# @see usage
reference() {
  :
}

# @description Trim, namespaced.
str::trim() {
  :
}

# @description Trim, flat.
strtrim() {
  :
}
SH

tests::put expected << 'MD'
# cli.sh

> 🧭 Source: [src/cli.sh](../src/cli.sh)
>
> Jump to: [Overview](#overview) · [Usage](#usage) · [Tips](#tips) · [Reference](#reference)

<a id="overview"></a>

## ✨ Overview

### 🚀 Highlights

- [`usage`](#fn-usage) — Print usage.
- [`reference`](#fn-reference) — Print the reference.
- [`str::trim`](#strtrim) — Trim, namespaced.
- [`strtrim`](#fn-strtrim) — Trim, flat.

<a id="usage"></a>

## 🚀 Usage

cli.sh

<a id="tips"></a>

## 💡 Tips

- Run it.

<a id="reference"></a>

## 📚 Reference

<a id="fn-usage"></a>

### `usage`

Print usage.

**🔗 See also**

- [reference](#fn-reference)

---

<a id="fn-reference"></a>

### `reference`

Print the reference.

**🔗 See also**

- [usage](#fn-usage)

---

### `str::trim`

Trim, namespaced.

---

<a id="fn-strtrim"></a>

### `strtrim`

Trim, flat.
MD

tests::assert
