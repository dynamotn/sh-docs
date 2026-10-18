# shellcheck shell=bash
# @file tests/testcases/warning.test.sh
# @brief Testcase for the @warning tag.
# @description `@warning`, as in shdoc, prints a callout after the description.
#   Several warnings are listed in one callout.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file fs.sh

# @description Remove a directory.
# @warning Nothing is asked before deleting.
# @arg $1 string The directory.
fs::remove() {
  :
}

# @description Move a file.
# @warning The destination is overwritten,
#   without a backup.
# @warning Not atomic across filesystems.
fs::move() {
  :
}
SH

tests::put expected << 'MD'
# fs.sh

> 🧭 Source: [src/fs.sh](../src/fs.sh)
>
> Jump to: [Overview](#overview) · [Reference](#reference)

<a id="overview"></a>

## ✨ Overview

### 🚀 Highlights

- [`fs::remove`](#fsremove) — Remove a directory.
- [`fs::move`](#fsmove) — Move a file.

<a id="reference"></a>

## 📚 Reference

### `fs::remove`

Remove a directory.

> ⚠️ **Warning**
>
> Nothing is asked before deleting.

**🧾 Arguments**

| Name | Type | Description |
| --- | --- | --- |
| `$1` | string | The directory. |

---

### `fs::move`

Move a file.

> ⚠️ **Warning**
>
> - The destination is overwritten, without a backup.
> - Not atomic across filesystems.
MD

tests::assert
tests::run --strict
tests::assert_exitcode 0
