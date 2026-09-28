# shellcheck shell=bash
# @file tests/testcases/module-usage.test.sh
# @brief Testcase for the @usage tag.
# @description The usage block is rendered as a section of its own.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @usage
#   . src/strings.sh
#   strings::trim "  padded  "
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Usage](#usage)

<a id="overview"></a>
## ✨ Overview

<a id="usage"></a>
## 🚀 Usage

. src/strings.sh
strings::trim "  padded  "
MD

tests::assert
