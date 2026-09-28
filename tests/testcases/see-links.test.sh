# shellcheck shell=bash
# @file tests/testcases/see-links.test.sh
# @brief Testcase for @see on a function.
# @description Each @see entry of a function is resolved the same way as a module one.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Trim surrounding whitespace.
# @see strings::lower
# @see src/arrays.sh
# @see docs/arrays.md
# @see ./CONTRIBUTING.md
# @see [shdoc](https://github.com/reconquest/shdoc)
strings::trim() {
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

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.

**🔗 See also**

- [strings::lower](#stringslower)
- [src/arrays.sh](../src/arrays.sh)
- [docs/arrays.md](arrays.md)
- [./CONTRIBUTING.md](./CONTRIBUTING.md)
- [shdoc](https://github.com/reconquest/shdoc)
MD

tests::assert
