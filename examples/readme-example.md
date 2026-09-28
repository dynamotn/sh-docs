# greeting.sh

A library that greets people.

> 🧭 Source: [src/greeting.sh](../src/greeting.sh)
>
> Jump to: [Overview](#overview) · [Usage](#usage) · [See also](#see-also) · [Tips](#tips) · [Reference](#reference)
>
> Reference sections: [Greeting](#greeting) · [Compatibility](#compatibility)

<a id="overview"></a>
## ✨ Overview

The module is the worked example used in the README. It shows
the tags a typical module uses:

* a header that names and describes the module
* functions grouped into sections
* arguments, options, exit codes, and streams

### 🌍 Environment

| Variable | Type | Description |
| --- | --- | --- |
| **`GREETING_WORD`** | string | Word used instead of `Hello`. |

### 🚀 Highlights

- [`greeting::say`](#greetingsay) — Greet a person by name. The greeting is written to stdout; nothing else is.
- [`greeting::reply`](#greetingreply) — Read a name from stdin and greet whoever it names.
- [`greeting::hello`](#greetinghello) — Greet a person by name.

## Loading

The module is self-contained and safe to source more than once.

<a id="usage"></a>
## 🚀 Usage

```bash
. src/greeting.sh
greeting::say "World"
```

<a id="see-also"></a>
## 🔗 See also

- [src/strings.sh](../src/strings.sh)
- [sh-docs](https://github.com/dynamotn/sh-docs)

<a id="tips"></a>
## 💡 Tips

- Source the module before setting `GREETING_WORD`; it is read on every call, not at load time.

<a id="reference"></a>
## 📚 Reference

<a id="greeting"></a>
### 🧩 Greeting

#### `greeting::say`

Greet a person by name.

The greeting is written to stdout; nothing else is.

**🧪 Example**

```bash
greeting::say "World"
greeting::say --loud "World"
```

**🎛️ Options**

| Option | Description |
| --- | --- |
| **-l \| --loud** | Shout the greeting. |
| **--word=\<word\>** | Use the given word instead of `Hello`. |

**🧾 Arguments**

| Name | Type | Description |
| --- | --- | --- |
| `$1` | string | The name to greet. |

**🌍 Environment variables**

| Variable | Type | Description |
| --- | --- | --- |
| **`GREETING_WORD`** | string | Word used instead of `Hello`. |

**📝 Notes**

- The greeting is not localized.

**📤 Output on stdout**

- The greeting, followed by a newline.

**📤 Output on stderr**

- A diagnostic when no name was given.

**🚦 Exit codes**

- `0`: The greeting was written.
- `1`: No name was given.

**🔗 See also**

- [greeting::reply](#greetingreply)


---

#### `greeting::reply`

Read a name from stdin and greet whoever it names.

_Function has no arguments._

**🧩 Variable sets**

- **`REPLY`** (string): The greeting that was written.

**📥 Input on stdin**

- The name to greet.

**🚦 Exit codes**

- `0`: The greeting was written.


<a id="compatibility"></a>
### 🧩 Compatibility

#### `greeting::hello`

> ⚠️ **Deprecated**
>
> Use `greeting::say` instead; this one goes away in 2.0.

Greet a person by name.

**🧾 Arguments**

| Name | Type | Description |
| --- | --- | --- |
| `$1` | string | The name to greet. |

## 📄 License

- MIT
