# shellcheck shell=bash
# @file tests/testcases/no-file-tag.test.sh
# @brief Testcase for a document generated without @file.
# @description Without @file there is no title and no source path to link to, so neither
#   is invented.

tests::put input << 'SH'
#!/usr/bin/env bash
# @brief Helpers for text manipulation.
SH

tests::put expected << 'MD'
Helpers for text manipulation.

> Jump to: [Overview](#overview)

<a id="overview"></a>
## ✨ Overview
MD

tests::assert
