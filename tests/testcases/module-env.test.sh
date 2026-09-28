# shellcheck shell=bash
# @file tests/testcases/module-env.test.sh
# @brief Testcase for @env in a file header.
# @description Environment variables the module reads are rendered as a table.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @env STRINGS_LOCALE string Locale used when folding case.
# @env STRINGS_DEBUG bool Print the intermediate state of each helper.
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview

### 🌍 Environment

| Variable | Type | Description |
| --- | --- | --- |
| **`STRINGS_LOCALE`** | string | Locale used when folding case. |
| **`STRINGS_DEBUG`** | bool | Print the intermediate state of each helper. |
MD

tests::assert
