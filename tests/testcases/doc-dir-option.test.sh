# shellcheck shell=bash
# @file tests/testcases/doc-dir-option.test.sh
# @brief Testcase for --doc-dir.
# @description --doc-dir moves the directory the document is assumed to live in. A
#   reference into that directory is resolved relative to the document; one
#   into any other known directory -- including the default "docs", which
#   stays in --link-dirs -- has to climb out of it first.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @see
#   - doc/arrays.md
#   - src/arrays.sh
#   - docs/arrays.md
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [See also](#see-also)

<a id="overview"></a>
## ✨ Overview

<a id="see-also"></a>
## 🔗 See also

- [doc/arrays.md](arrays.md)
- [src/arrays.sh](../src/arrays.sh)
- [docs/arrays.md](../docs/arrays.md)
MD

tests::assert --doc-dir doc
