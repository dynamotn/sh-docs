# shellcheck shell=bash
# @file tests/testcases/option.test.sh
# @brief Testcase for the @option tag.
# @description Options are rendered as a table, with the angle brackets escaped.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @description Print a greeting.
# @option -h Show help.
# @option --help Show help.
# @option -h | --help Show help either way.
# @option -v<value> Set a value, joined to the letter.
# @option --value=<value> Set a value with an equals sign.
# @option --value <value> Set a value separated by a space.
# @option -v <value> | --value=<value> Set a value, both spellings.
# @option not an option at all
say::hello() {
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

- [`say::hello`](#sayhello) — Print a greeting.

<a id="reference"></a>
## 📚 Reference

### `say::hello`

Print a greeting.

**🎛️ Options**

| Option | Description |
| --- | --- |
| **-h** | Show help. |
| **--help** | Show help. |
| **-h \| --help** | Show help either way. |
| **-v\<value\>** | Set a value, joined to the letter. |
| **--value=\<value\>** | Set a value with an equals sign. |
| **--value \<value\>** | Set a value separated by a space. |
| **-v \<value\> \| --value=\<value\>** | Set a value, both spellings. |
| not an option at all |  |
MD

tests::assert
