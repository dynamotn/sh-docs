# shellcheck shell=bash
# @file tests/testcases/layout-options.test.sh
# @brief Testcase for --src-dir and --root-files.
# @description The source link follows --src-dir, and --root-files names the modules that
#   sit at the repository root instead of inside it.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file bootstrap.sh
# @see lib/strings.sh
SH

tests::put expected << 'MD'
# bootstrap.sh

> 🧭 Source: [bootstrap.sh](../bootstrap.sh)
>
> Jump to: [Overview](#overview) · [See also](#see-also)

<a id="overview"></a>
## ✨ Overview

<a id="see-also"></a>
## 🔗 See also

- [lib/strings.sh](../lib/strings.sh)
MD

tests::assert --src-dir lib --root-files bootstrap.sh
