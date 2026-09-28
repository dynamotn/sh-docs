# shellcheck shell=bash
# @file tests/testcases/related-examples.test.sh
# @brief Testcase for --example-dir.
# @description --example-dir lists the example scripts that mention a documented
#   function, in a stable order, skipping the ones @see already links to.

mkdir -p example
cat > example/trim.sh << 'SH'
strings::trim "  padded  "
SH
cat > example/lower.sh << 'SH'
strings::lower "ABC"
SH
cat > example/unrelated.sh << 'SH'
printf 'nothing to do with the module\n'
SH

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @see example/lower.sh

# @description Trim surrounding whitespace.
strings::trim() {
  :
}
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [See also](#see-also) · [Reference](#reference)

<a id="overview"></a>
## ✨ Overview

### 🚀 Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.

<a id="see-also"></a>
## 🔗 See also

- [example/lower.sh](../example/lower.sh)

<a id="reference"></a>
## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.

## 🧪 Related examples

- [example/trim.sh](../example/trim.sh)
MD

tests::assert --example-dir example
