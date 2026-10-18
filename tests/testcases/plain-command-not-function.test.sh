# shellcheck shell=bash
# @file tests/testcases/plain-command-not-function.test.sh
# @brief Testcase for a bare command that looks like a declaration.
# @description A line holding a single word is a command, not a function
#   declaration: bash needs the `function` keyword or `()` for that. So `fi`
#   followed by a `{ ... }` group documents nothing, and the comment above a
#   plain command is discarded instead of reaching the next function.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

if true; then
  :
fi
{
  printf 'grouped\n'
} > /dev/null

# @description Run the cleanup first.
cleanup

# @description Trim surrounding whitespace.
strings::trim() {
  :
}

helper() {
  :
}
SH

tests::put expected << 'MD'
# strings.sh

> 🧭 Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Reference](#reference)

<a id="overview"></a>

## ✨ Overview

### 🚀 Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.
- [`helper`](#helper)

<a id="reference"></a>

## 📚 Reference

### `strings::trim`

Trim surrounding whitespace.

---

### `helper`
MD

tests::assert
