# shellcheck shell=bash
# @file tests/testcases/module-deprecated.test.sh
# @brief Testcase for @deprecated in a file header.
# @description A deprecated module carries a callout under its title.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file legacy.sh
# @brief Superseded helpers.
# @deprecated Use `strings.sh` instead; this module goes away in 2.0.
SH

tests::put expected << 'MD'
# legacy.sh

Superseded helpers.

> 🧭 Source: [src/legacy.sh](../src/legacy.sh)
>
> Jump to: [Overview](#overview)

> ⚠️ **Deprecated module**
>
> Use `strings.sh` instead; this module goes away in 2.0.

<a id="overview"></a>
## ✨ Overview
MD

tests::assert
