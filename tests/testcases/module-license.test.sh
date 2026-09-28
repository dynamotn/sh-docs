# shellcheck shell=bash
# @file tests/testcases/module-license.test.sh
# @brief Testcase for the @license tag.
# @description The license is rendered as the last section of the document.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @license MIT
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview

## 📄 License

- MIT
MD

tests::assert
