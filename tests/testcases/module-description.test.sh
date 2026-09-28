# shellcheck shell=bash
# @file tests/testcases/module-description.test.sh
# @brief Testcase for @description in a file header.
# @description A heading inside the description splits it: the intro goes above the
#   highlight list, the rest below it.

tests::put input << 'SH'
#!/usr/bin/env bash
# @name strings.sh
# @brief Helpers for text manipulation.
# @description
#   The module groups the string helpers used across the project.
#
#   Every helper is safe to call in a subshell.
#
#   ## Design notes
#
#   The helpers never write to stdout unless documented.
SH

tests::put expected << 'MD'
# strings.sh

Helpers for text manipulation.

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview

The module groups the string helpers used across the project.

Every helper is safe to call in a subshell.

## Design notes

The helpers never write to stdout unless documented.
MD

tests::assert
