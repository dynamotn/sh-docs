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
description. Like `@arg`, it can be [optional](#optional-arguments-and-defaults).

```bash
# @env STRINGS_LOCALE string Locale used when folding case.
# @env STRINGS_FILL string [default: space] Character used for padding.
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

#### `@option`, `@arg`, `@stdin`, `@stdout`, `@stderr`, `@exitcode`

The command line of a script that is run rather than sourced. They take the
same fields as the [function tags](#function-tags) of the same name, and are
printed in a "Command line" section after the usage.

```bash
#!/usr/bin/env bash
# @file greet
# @brief Greet someone.
# @usage greet [-l] NAME
# @option -l | --loud Shout the greeting.
# @arg $1 string The name to greet.
# @stdout The greeting.
# @exitcode 0 The greeting was written.
# @exitcode 1 No name was given.
```

#### `@since`

The version the module first appeared in, printed under the brief.

```bash
# @since 1.0.0
```

#### `@namespace`

The namespace a sourced library declares its functions in. It is read for the
benefit of linters and not printed.

### Function tags

These are read from the comment block directly above a function definition. All
four declaration forms are recognised, including an opening brace on its own
line, and the body may be a `( ... )` subshell as well as a `{ ... }` group:

```bash
name() { ... }
function name { ... }
function name() { ... }
name()
{ ... }
name() ( ... )
```

As in bash, a declaration needs the `function` keyword or the `()` after the
name: a line holding a lone command such as `cleanup` is never taken for one,
and the comment block above it is discarded.

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
table row. `$@` documents every argument at once.

```bash
# @arg $1 string The string to repeat.
# @arg $2 number How many times to repeat it.
```

##### Optional arguments and defaults

A type ending in `?` marks an `@arg` or `@env` entry optional, and
`[default: value]` after the type gives its default, which makes it optional
too. The table gains "Required" and "Default" columns only when one of its
rows uses them, so a table without optional entries looks as it always did.

```bash
# @arg $1 string The string to repeat.
# @arg $2 number [default: 1] How many times to repeat it.
# @arg $3 string? Separator put between the copies.
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

A practical note, collected into the document's "Tips" section under a link to
the function.

#### `@deprecated`

Marks the function as deprecated and prints the reason as a callout above its
description.

#### `@warning`

A danger the caller has to know about, printed as a callout after the
description. Several warnings are listed in one callout. The tag comes from
shdoc.

```bash
# @warning Nothing is asked before deleting.
```

#### `@since`

The version the function first appeared in, printed under its heading.

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

A function is linked by the anchor GitHub gives its heading, the slug of its
name, unless that anchor is already taken: by a section of the document
(`overview`, `usage`, `command-line`, `see-also`, `tips`, `reference`, or an
`@section`), or by an earlier function whose name slugs alike. Such a function
gets an explicit `fn-<slug>` anchor above its heading, and the highlights, the
tips and every `@see` naming it link there. Without it, a function called
`usage` could never be reached: a browser jumps to the first element with an
id, which is the Usage section.

Angle brackets in prose are left alone, so write `` `<value>` `` in a
description if you want them to survive Markdown rendering. Only the option
column escapes them for you.

## Usage

sh-docs reads a shell script from a file or from standard input and writes
Markdown to standard output.

```bash
sh-docs < your-shell-script.sh > docs/lib.md
sh-docs your-shell-script.sh --output docs/lib.md
cat your-shell-script.sh | sh-docs - > docs/lib.md
```

Committed documents fall behind their sources without anyone noticing. With
`--check`, sh-docs compares the document it would write with the `--output`
file, byte for byte, and writes nothing. A missing or stale document prints a
unified diff on stdout and fails with exit status 1, which makes it a CI step:

```bash
for src in src/*.sh; do
  sh-docs --check "$src" --output "docs/$(basename "${src%.sh}").md" || stale=1
done
exit "${stale:-0}"
```

A misspelt tag is otherwise dropped without a word, and a function nobody
described shows up in the reference with nothing under it. `--strict` reports
both on stderr, each with its line, and exits 1 once the document is written:

```console
$ sh-docs --strict src/strings.sh -o docs/strings.md
sh-docs: src/strings.sh:6: unknown tag @descripton
sh-docs: src/strings.sh:7: strings::trim has no @description
```

`--strict` also reads the body of each public function and reports a `$N` or
`${N...}` it uses without an `@arg $N`; `@arg $@` covers every position. It
skips comments, single-quoted text such as an awk program, and escaped dollars,
and takes the body to end at the `}` or `)` indented like the declaration,
which is how shfmt writes it.

A function is private, and needs no description, when its name or the last
`::` part of it starts with `_`; an `@internal` one is not documented at all.

### Several files at once

With `--output-dir`, sh-docs takes any number of sources and writes one
document each into that directory, named after the source with a `.sh`,
`.bash`, `.zsh` or `.ksh` extension dropped. `--index` adds an `index.md` that
lists the documents with their brief. `--check` and `--strict` cover every
file, and fail if any one does.

```bash
sh-docs --output-dir docs --index src/*.sh
sh-docs --check --output-dir docs --index src/*.sh
```

### Other output options

`--line-links` adds a link under each function heading to the line it is
declared on, such as `src/strings.sh#L12`. It is off by default: any edit above
a function moves its line, and a committed document would go stale with it.

`--no-emoji` prints every heading, label and callout without its emoji. The
anchors do not change.

### prek and pre-commit

The repository ships two hooks, for [prek](https://github.com/j178/prek) and
pre-commit: `sh-docs` regenerates the documents of the staged shell sources,
and `sh-docs-check` fails when one of them is missing or stale. Both write to
`docs/` by default; an `args` override must keep `--output-dir`. gawk has to be
on `PATH`.

```yaml
repos:
  - repo: https://github.com/dynamotn/sh-docs
    rev: <a tag or commit>
    hooks:
      - id: sh-docs-check
        args: [--output-dir, docs, --src-dir, lib]
        files: ^lib/
```

A newly generated document is untracked, so the `sh-docs` hook reports it as
passed; it fails once a committed document changes. `sh-docs-check` reports
both.

```
Usage: sh-docs [OPTION]... [FILE]
  or:  sh-docs --output-dir DIR [OPTION]... FILE...

Options:
  -o, --output FILE         write the document to FILE instead of stdout
      --output-dir DIR      write one document per FILE into DIR, named after
                            it without its shell extension
      --index               with --output-dir, also write DIR/index.md
      --check               compare the document with the one in --output
                            instead of writing it; print a diff when it is
                            missing or out of date
      --strict              report unknown tags, public functions without
                            @description and positional arguments without
                            @arg on stderr, after writing the document
      --line-links          link each function to its line in the source
      --no-emoji            print headings and labels without emoji
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

Exit status:
  0  the documents were generated, and nothing was found
  1  --check found a document missing or stale, or --strict reported a problem
  2  the invocation was invalid, an input was unreadable, or awk failed
```

The exit status follows `diff` and `grep`: 0 when the documents were generated
and nothing was found, 1 when `--check` found a document missing or stale or
`--strict` reported a problem, and 2 when sh-docs itself could not do its job:
an invalid invocation, an unreadable input, or a failing awk. A CI step can
therefore regenerate the documents on 1 and stop on 2.

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

sh-docs needs `gawk` and Bash 4.4 or newer. On macOS, whose `/bin/bash` is
3.2, install a newer one, for instance with Homebrew; sh-docs says so when it
finds an older one.

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
* `@usage`, `@tip`, `@note`, `@license`, `@since` and "Related examples" are
  additions, and the header documents a script's command line;
* optional arguments and defaults get their own table columns;
* `@section` is not sticky: each documented function carries its own;
* an index of functions is printed as a "Highlights" list, with the first
  sentence of each description;
* relative `@see` paths are rewritten for a document that lives in `docs/`.

## Development

```bash
make test       # run the testcases
make examples   # regenerate examples/*.md
make lint       # dyshellint the shell sources, and parse-check the awk program
make strict     # run sh-docs --strict over its own sources
make fmt        # shfmt the shell sources
```

`.pre-commit-config.yaml` runs the same targets from prek or pre-commit
(`prek install`), each only when a file it covers is staged.

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
