# shellcheck shell=bash
# @file tests/testcases/no-emoji.test.sh
# @brief Testcase for --no-emoji.
# @description --no-emoji drops the emoji from every heading, label and
#   callout, and changes nothing else: the anchors stay where they were. The
#   module sections and the function sections are checked one input each.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh
# @usage strings.sh
# @env STRINGS_LOCALE string Locale.
# @exitcode 0 Always.
# @deprecated Use text.sh.
# @see text.sh
# @license MIT
SH

tests::put expected << 'MD'
# strings.sh

> Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Usage](#usage) · [Command line](#command-line) · [See also](#see-also)

> **Deprecated module**
>
> Use text.sh.

<a id="overview"></a>

## Overview

### Environment

| Variable | Type | Description |
| --- | --- | --- |
| **`STRINGS_LOCALE`** | string | Locale. |

<a id="usage"></a>

## Usage

strings.sh

<a id="command-line"></a>

## Command line

**Exit codes**

- `0`: Always.

<a id="see-also"></a>

## See also

- [text.sh](#textsh)

## License

- MIT
MD

tests::assert --no-emoji

tests::put input << 'SH'
#!/usr/bin/env bash
# @file strings.sh

# @section Trimming
# @description Trim surrounding whitespace.
# @example
#   strings::trim " a "
# @arg $1 string The text.
# @option -a Trim all.
# @env STRINGS_TRIM string What to trim.
# @set TRIMMED string The result.
# @note A note.
# @stdin Nothing.
# @stdout The text.
# @stderr Nothing.
# @exitcode 0 Always.
# @see strings::lower
# @deprecated Use text::trim.
# @warning Slow.
# @tip Trim once.
strings::trim() {
  :
}
SH

tests::put expected << 'MD'
# strings.sh

> Source: [src/strings.sh](../src/strings.sh)
>
> Jump to: [Overview](#overview) · [Tips](#tips) · [Reference](#reference)
>
> Reference sections: [Trimming](#trimming)

<a id="overview"></a>

## Overview

### Highlights

- [`strings::trim`](#stringstrim) — Trim surrounding whitespace.

<a id="tips"></a>

## Tips

**[`strings::trim`](#stringstrim)**

- Trim once.

<a id="reference"></a>

## Reference

<a id="trimming"></a>

### Trimming

#### `strings::trim`

> **Deprecated**
>
> Use text::trim.

Trim surrounding whitespace.

> **Warning**
>
> Slow.

**Example**

```bash
strings::trim " a "
```

**Options**

| Option | Description |
| --- | --- |
| **-a** | Trim all. |

**Arguments**

| Name | Type | Description |
| --- | --- | --- |
| `$1` | string | The text. |

**Environment variables**

| Variable | Type | Description |
| --- | --- | --- |
| **`STRINGS_TRIM`** | string | What to trim. |

**Variable sets**

- **`TRIMMED`** (string): The result.

**Notes**

- A note.

**Input on stdin**

- Nothing.

**Output on stdout**

- The text.

**Output on stderr**

- Nothing.

**Exit codes**

- `0`: Always.

**See also**

- [strings::lower](#stringslower)
MD

tests::assert --no-emoji
