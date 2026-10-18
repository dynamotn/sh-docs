# shellcheck shell=bash
# @file tests/testcases/tag-boundary.test.sh
# @brief Testcase for a word that merely starts with a tag name.
# @description A tag ends at whitespace or at the end of the line, so
#   `@descriptionless` is not `@description` followed by `less`.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @descriptionless text
# @description The real overview.
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview)

<a id="overview"></a>

## ✨ Overview

The real overview.
MD

tests::assert
