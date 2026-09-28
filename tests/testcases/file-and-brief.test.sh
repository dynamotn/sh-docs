# shellcheck shell=bash
# @file tests/testcases/file-and-brief.test.sh
# @brief Testcase for the @file and @brief tags.
# @description The title and the line under it come from @file and @brief.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @brief Helpers for text manipulation.
SH

tests::put expected << 'MD'
# strings.sh

Helpers for text manipulation.

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview
MD

tests::assert
