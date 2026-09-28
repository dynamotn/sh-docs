# shellcheck shell=bash
# @file tests/testcases/example.test.sh
# @brief Testcase for the @example tag.
# @description One @example renders a single code fence; several are numbered.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Trim surrounding whitespace.
# @example
#   strings::trim "  padded  "
strings::trim() {
  :
}

# @description Fold to lower case.
# @example
#   strings::lower "ABC"
# @example
#   printf '%s' "ABC" | strings::lower
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

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.
- [`strings::lower`](#stringslower) — Fold to lower case.

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.

**🧪 Example**

```bash
strings::trim "  padded  "
```


---

### `strings::lower`

Fold to lower case.

**🧪 Examples**

```bash
strings::lower "ABC"
```

```bash
printf '%s' "ABC" | strings::lower
```
MD

tests::assert
