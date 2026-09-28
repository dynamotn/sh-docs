# shellcheck shell=bash
# @file tests/testcases/stdin-stdout-stderr.test.sh
# @brief Testcase for the @stdin, @stdout and @stderr tags.
# @description The three streams are documented in their own blocks.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Fold stdin to lower case.
# @stdin The text to fold.
# @stdout The folded text.
# @stderr A diagnostic when the input is not valid UTF-8.
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

- [`strings::lower`](#stringslower) — Fold stdin to lower case.

<a id="reference"></a>
## 📚 Reference

### `strings::lower`

Fold stdin to lower case.

**📥 Input on stdin**

- The text to fold.

**📤 Output on stdout**

- The folded text.

**📤 Output on stderr**

- A diagnostic when the input is not valid UTF-8.
MD

tests::assert
