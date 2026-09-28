# shellcheck shell=bash
# @file tests/testcases/module-see.test.sh
# @brief Testcase for @see in a file header.
# @description Each @see entry is resolved as a path, a Markdown link or an anchor.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @see
#   - src/arrays.sh
#   - docs/arrays.md
#   - example/trim.sh
#   - [shdoc](https://github.com/reconquest/shdoc)
#   - strings::trim
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

- [src/arrays.sh](../src/arrays.sh)
- [docs/arrays.md](arrays.md)
- [example/trim.sh](../example/trim.sh)
- [shdoc](https://github.com/reconquest/shdoc)
- [strings::trim](#stringstrim)
MD

tests::assert
