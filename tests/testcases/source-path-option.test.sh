# shellcheck shell=bash
# @file tests/testcases/source-path-option.test.sh
# @brief Testcase for --source-path.
# @description --source-path overrides the path derived from --src-dir and --root-files.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [modules/text/strings.sh](../modules/text/strings.sh)
>
> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview
MD

tests::assert --source-path=modules/text/strings.sh
