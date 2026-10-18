# shellcheck shell=bash
# @file tests/testcases/header-without-file.test.sh
# @brief Testcase for a header with no @file and a function below it.
# @description Without `@file` the header has no blank line to end at, so it
#   runs up to the first statement. The comment block directly above a function
#   still documents that function rather than the module.

tests::put input << 'SH'
#!/usr/bin/env bash
# @brief Helpers for text manipulation.

# @description Trim surrounding whitespace.
strings::trim() {
  :
}
SH

tests::put expected << 'MD'
Helpers for text manipulation.

> Jump to: [Overview](#overview) · [Reference](#reference)

<a id="overview"></a>
## ✨ Overview

### 🚀 Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.
MD

tests::assert

# A module description above a plain statement still belongs to the module.
tests::put input << 'SH'
#!/usr/bin/env bash
# Copyright notice.

# @description The module overview.
set -euo pipefail
SH

tests::put expected << 'MD'
> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview

The module overview.
MD

tests::assert
