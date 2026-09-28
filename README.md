# sh-docs

sh-docs generates Markdown API documentation for bash/zsh/sh libraries from the
comments already in the source.

It reads the annotations in a file header and above each function definition and
writes a GitHub-flavored Markdown document: a title and brief, a navigation
block, an overview, a highlight list of every public function, and a reference
section with tables for arguments, options, environment variables, exit codes
and streams.

sh-docs started as the documentation generator of
[dybatpho](https://github.com/dynamotn/dybatpho) and follows the annotation
language of [reconquest/shdoc](https://github.com/reconquest/shdoc), with a
richer default layout and a handful of tags of its own.

## Index

* [Example](#example)
* [Annotations](#annotations)
* [Usage](#usage)
* [Repository layout](#repository-layout)
* [Installation](#installation)
* [Differences from shdoc](#differences-from-shdoc)
* [Development](#development)
* [License](#license)

## Example

Generate documentation with:

```bash
sh-docs < src/greeting.sh > docs/greeting.md
```

_Source_: [examples/readme-example.sh](examples/readme-example.sh)<br>
_Output_: [examples/readme-example.md](examples/readme-example.md)

~~~bash
# shellcheck shell=bash
# @file greeting.sh
# @brief A library that greets people.
# @description The module is the worked example used in the README.
#
# @usage
#   ```bash
#   . src/greeting.sh
#   greeting::say "World"
#   ```
#
# @env GREETING_WORD string Word used instead of `Hello`.
# @license MIT

# @section Greeting
# @description Greet a person by name.
#
#   The greeting is written to stdout; nothing else is.
# @example
#   greeting::say "World"
# @option -l | --loud Shout the greeting.
# @arg $1 string The name to greet.
# @stdout The greeting, followed by a newline.
# @exitcode 0 The greeting was written.
# @exitcode 1 No name was given.
# @see greeting::reply
function greeting::say {
  printf '%s %s\n' "${GREETING_WORD:-Hello}" "$1"
}
~~~

produces, among the rest of the document:

~~~markdown
#### `greeting::say`

Greet a person by name.

The greeting is written to stdout; nothing else is.

**🧪 Example**

```bash
greeting::say "World"
```

**🎛️ Options**

| Option | Description |
| --- | --- |
| **-l \| --loud** | Shout the greeting. |

**🧾 Arguments**

| Name | Type | Description |
| --- | --- | --- |
| `$1` | string | The name to greet. |

**🚦 Exit codes**

- `0`: The greeting was written.
- `1`: No name was given.
~~~

## Annotations

An annotation is a `#` comment whose first word is a tag. Tags in the file
header describe the module; tags in the comment block directly above a function
definition describe that function. A comment block is consumed by the next
function definition it meets, so a block that documents nothing is discarded.

Continuation lines are indented under the tag and belong to it until the next
tag. The indentation shared by the continuation lines is stripped, so a
description reads the same whether its first line sits on the `@description`
line or the whole paragraph is indented beneath it.

### Module tags

These are read from the file header — the run of comments at the top of the
file, ending at the first blank line after `@file` or `@name`.

#### `@file`, `@name`

The name of the module, used as the document title and to build the link back
to the source. Two spellings of one tag.

```bash
# @file strings.sh
```

#### `@brief`

One line about the module, printed under the title.

```bash
# @brief Helpers for text manipulation.
```

#### `@description`

The module overview. Markdown is passed through, so lists and code fences work.
A `##` or `###` heading inside the description splits it: everything before the
first heading is printed as the overview intro, and everything from the heading
on is printed after the generated highlight list.

```bash
# @description
#   The module groups the string helpers used across the project.
#
#   ## Loading
#
#   Safe to source more than once.
```

#### `@usage`

A usage block, printed as its own section. The content is Markdown, so wrap
commands in a code fence if you want one.

~~~bash
# @usage
#   ```bash
#   . src/strings.sh
#   ```
~~~

#### `@env`

An environment variable the module reads. Three fields: name, type,
description.

```bash
# @env STRINGS_LOCALE string Locale used when folding case.
```

#### `@see`

A reference, printed in the "See also" section. One per tag, or a Markdown list
under a bare `@see`. See [Links](#links) for how each entry is resolved.

```bash
# @see
#   - src/arrays.sh
#   - [shdoc](https://github.com/reconquest/shdoc)
```

#### `@tip`

A practical note, collected into the "Tips" section together with the `@tip`
entries of every function.

```bash
# @tip Source the module once; it is not idempotent.
```

#### `@deprecated`

Marks the whole module as deprecated and prints the reason as a callout under
the title.

```bash
# @deprecated Use `strings.sh` instead; this module goes away in 2.0.
```

#### `@license`

The license of the module, printed as the last section.

```bash
# @license MIT
```

### Function tags

These are read from the comment block directly above a function definition. All
four declaration forms are recognised, including an opening brace on its own
line:

```bash
name() { ... }
function name { ... }
function name() { ... }
name()
{ ... }
```

#### `@description`

What the function does. The first sentence is reused as its entry in the
highlight list.

#### `@section`

Groups the function under a heading in the reference, and adds the group to the
navigation block. Each documented function carries its own `@section`; the tag
is not sticky, so a function without one is not grouped.

```bash
# @section Trimming
# @description Remove leading whitespace.
strings::ltrim() { ... }
```

#### `@example`

A usage example, rendered as a bash code fence. Repeat the tag for more than
one example; they are numbered in the document.

```bash
# @example
#   strings::trim "  padded  "
```

#### `@arg`

A positional argument. Three fields: name, type, description. Rendered as a
table row.

```bash
# @arg $1 string The string to repeat.
# @arg $2 number How many times to repeat it.
```

#### `@option`

An option the function accepts. An option argument is written between `<` and
`>`, and alternative spellings are separated by `|`. Anything that does not
parse as an option is printed as written.

```bash
# @option -h | --help Show help.
# @option -v<value> | --value=<value> Set a value.
```

#### `@env`

An environment variable the function reads. Same three fields as the module
tag.

#### `@set`

A variable the function sets. Three fields: name, type, description.

```bash
# @set REPLY string The rendered greeting.
```

#### `@exitcode`

An exit code and the condition that produces it. Repeat for each one.

```bash
# @exitcode 0 The greeting was written.
# @exitcode 1 No name was given.
```

#### `@stdin`, `@stdout`, `@stderr`

What the function reads from stdin and writes to stdout and stderr.

```bash
# @stdin The text to fold.
# @stdout The folded text.
# @stderr A diagnostic when the input is not valid UTF-8.
```

#### `@noargs`

States that the function takes no arguments.

#### `@note`

A caveat, printed in the function's own "Notes" block. Unlike `@tip`, it stays
with the function.

#### `@tip`

A practical note, collected into the document's "Tips" section under the
function's name.

#### `@deprecated`

Marks the function as deprecated and prints the reason as a callout above its
description.

#### `@see`

A reference for this function, printed in its "See also" block.

#### `@internal`

Skips the function entirely. Use it to keep the same comment style on private
helpers without publishing them.

```bash
# @internal
__strings_helper() { ... }
```

### Links

Every `@see` entry is resolved as one of:

* a Markdown link (`[text](url)`) — passed through untouched;
* an absolute URL — linked to itself;
* a path starting with `./` or `/` — linked to itself;
* a path under one of the known directories (`--link-dirs`, by default `docs`,
  `example`, `src`, `scripts`) — rewritten relative to the generated document,
  so `src/arrays.sh` becomes `../src/arrays.sh` and `docs/arrays.md` becomes
  `arrays.md`;
* anything else — a GitHub-style anchor into the current document, which is how
  a reference to another function in the same module is linked.

Angle brackets in prose are left alone, so write `` `<value>` `` in a
description if you want them to survive Markdown rendering. Only the option
column escapes them for you.

## Usage

sh-docs reads a shell script from a file or from standard input and writes
Markdown to standard output.

```bash
sh-docs < your-shell-script.sh > docs/lib.md
sh-docs your-shell-script.sh --output docs/lib.md
```

```
Usage: sh-docs [OPTION]... [FILE]

Options:
  -o, --output FILE         write the document to FILE instead of stdout
      --src-dir DIR         directory the documented sources live in
                            (default: src)
      --doc-dir DIR         directory the generated documents live in, used to
                            resolve relative links (default: docs)
      --root-files LIST     comma-separated sources that sit at the repository
                            root instead of inside --src-dir (default: init.sh)
      --source-path PATH    path of the documented source relative to the
                            repository root; overrides --src-dir/--root-files
      --link-dirs LIST      comma-separated path prefixes that @see entries are
                            resolved as paths rather than as anchors
                            (default: docs,example,src,scripts)
      --example-dir DIR     scan DIR for examples that mention a documented
                            function and list them under "Related examples"
      --example-prefix DIR  prefix the scanned examples are linked under
                            (default: example)
  -h, --help                show this help and exit
  -V, --version             show version information and exit
```

The awk program can also be run on its own, with the same settings passed as
awk variables:

```bash
gawk -v src_dir=lib -f sh-docs.awk lib/strings.sh > docs/strings.md
```

## Repository layout

The defaults describe a repository whose modules live in `src/` and whose
generated documents live in `docs/`:

```
.
├── src/strings.sh      # documented source
├── docs/strings.md     # generated document
└── example/trim.sh     # example scripts, optional
```

The "Source" link in the navigation block and every relative `@see` link is
built from that layout, which is what the options above adjust. A module that
sits at the repository root instead of inside `src/` is named with
`--root-files`; a layout that does not fit at all is pinned per file with
`--source-path`.

With `--example-dir`, sh-docs scans that directory for scripts mentioning a
documented function and lists them under "Related examples", skipping the ones
`@see` already links to.

## Installation

sh-docs needs `gawk` and `bash`.

```bash
git clone https://github.com/dynamotn/sh-docs
cd sh-docs
sudo make install
```

`make install` honours `PREFIX` (default `/usr/local`), `DESTDIR`, `DST` and
`MANDIR`.

To use it from a checkout without installing, run `./sh-docs`; it finds
`sh-docs.awk` next to itself, or wherever `SH_DOCS_AWK` points.

## Differences from shdoc

sh-docs is annotation-compatible with shdoc for the common tags, but the
generated document is not the same:

* the document opens with a navigation block that links to each section, to the
  reference groups, and back to the source file;
* arguments, options and environment variables are rendered as tables rather
  than definition lists, and section headings carry an emoji;
* `@usage`, `@tip`, `@note`, `@license` and "Related examples" are additions;
* `@section` is not sticky: each documented function carries its own;
* an index of functions is printed as a "Highlights" list, with the first
  sentence of each description;
* relative `@see` paths are rewritten for a document that lives in `docs/`.

## Development

```bash
make test       # run the testcases
make examples   # regenerate examples/*.md
make lint       # dyshellint the shell sources, and parse-check the awk program
make fmt        # shfmt the shell sources
```

The shell sources follow the Dynamo shell style guide and are checked with
[dyshellint](https://gitlab.com/dynamo-tools/dyshellint), which drives
ShellCheck and shfmt itself. Two findings are silenced in place, each with its
reason next to the directive: the hand-written option parser in `sh-docs`,
which cannot use the guide's spec helpers without taking on a dependency the
project does not want, and the global tally in `tests/run_tests`, which the
EXIT trap has to read after `_main` has returned.

The test suite is plain bash with no dependencies beyond `gawk` and `diff`.
Each file under `tests/testcases/` writes an `input`, the `expected` Markdown,
and calls `tests::assert`; see [tests/lib.sh](tests/lib.sh) for the helpers.
Run a subset by name:

```bash
tests/run_tests option see
```

## License

MIT
