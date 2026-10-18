# shellcheck shell=bash
# @file tests/testcases/module-example.test.sh
# @brief Testcase for @example in the file header.
# @description A script documents how it is run with `@example` in its
#   header, as a function does in its own block. The examples are printed in
#   their own section after the command line, each in a code block of its own,
#   with blank lines and indentation kept.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file greet
# @brief Greet someone.
# @option -l | --loud Shout the greeting.
# @example
#   greet World
# @example
#   greet --loud World
#
#   NAME=World
#   greet "$NAME"

printf 'Hello %s\n' "$1"
SH

tests::put expected << 'MD'
# greet

Greet someone.

> 🧭 Source: [src/greet](../src/greet)
>
> Jump to: [Overview](#overview) · [Command line](#command-line) · [Examples](#examples)

<a id="overview"></a>

## ✨ Overview

<a id="command-line"></a>

## 🖥️ Command line

**🎛️ Options**

| Option | Description |
| --- | --- |
| **-l \| --loud** | Shout the greeting. |

<a id="examples"></a>

## 🧪 Examples

```bash
greet World
```

```bash
greet --loud World

NAME=World
greet "$NAME"
```
MD

tests::assert
tests::run --strict
tests::assert_exitcode 0

# A single example is labelled as one.
tests::put input << 'SH'
# @file greet
# @example greet World
SH

tests::put expected << 'MD'
# greet

> 🧭 Source: [src/greet](../src/greet)
>
> Jump to: [Overview](#overview) · [Example](#examples)

<a id="overview"></a>

## ✨ Overview

<a id="examples"></a>

## 🧪 Example

```bash
greet World
```
MD

tests::assert
