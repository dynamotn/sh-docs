# shellcheck shell=bash
# @file tests/testcases/header-cli.test.sh
# @brief Testcase for the command-line tags of an entrypoint script.
# @description A script that is run rather than sourced documents its own
#   command line in the header: `@option`, `@arg`, the streams and `@exitcode`
#   are printed in a "Command line" section. A tag the header does not know
#   ends the one before it instead of being appended to it.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file greet
# @brief Greet someone.
# @usage greet [-l] NAME
# @option -l | --loud Shout the greeting.
# @arg $1 string The name to greet.
# @stdin Nothing is read.
# @stdout The greeting.
# @see greet.md
# @unknown This is not appended to the @see entry.
# @exitcode 0 The greeting was written.
# @exitcode 1 No name was given,
#   or the name was empty.

printf 'Hello %s\n' "$1"
SH

tests::put expected << 'MD'
# greet

Greet someone.

> 🧭 Source: [src/greet](../src/greet)
>
> Jump to: [Overview](#overview) · [Usage](#usage) · [Command line](#command-line) · [See also](#see-also)

<a id="overview"></a>

## ✨ Overview

<a id="usage"></a>

## 🚀 Usage

greet [-l] NAME

<a id="command-line"></a>

## 🖥️ Command line

**🎛️ Options**

| Option | Description |
| --- | --- |
| **-l \| --loud** | Shout the greeting. |

**🧾 Arguments**

| Name | Type | Description |
| --- | --- | --- |
| `$1` | string | The name to greet. |

**📥 Input on stdin**

- Nothing is read.

**📤 Output on stdout**

- The greeting.

**🚦 Exit codes**

- `0`: The greeting was written.
- `1`: No name was given, or the name was empty.

<a id="see-also"></a>

## 🔗 See also

- [greet.md](#greetmd)
MD

tests::assert
