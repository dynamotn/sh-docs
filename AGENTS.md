# AGENTS.md

sh-docs is a GNU awk program with a thin bash wrapper. The awk program is the
product; the README, the example and the tests are fixtures that describe the
public annotation language.

* `sh-docs.awk` — the parser and the renderer.
* `sh-docs` — argument handling only: it maps command-line options onto awk
  variables, reads a file or stdin, and writes stdout or `--output`.
* `examples/readme-example.sh` / `.md` — the worked example, regenerated with
  `make examples`.
* `tests/` — a dependency-free bash harness.

## Architecture

The parser is an ordered set of awk pattern/action rules over one input stream.
Rule order is part of the design: moving a rule changes whether a line is
consumed as a header line, an annotation, a function declaration, a
continuation, or plain source.

State is global and describes the block being collected. `header_lines` holds
the file header until the first blank line after `@file`; `pending_lines` holds
the comment block collected since the last statement, and is flushed into a
function when a declaration follows it and discarded when plain source does.
`counts`/`items` hold repeated tag entries keyed by `kind SUBSEP index`, and
`texts` holds the free-form ones (`@description`, `@usage`).

Recognition and rendering live in the same file but are separate concerns.
`parse_header`, `parse_module_block` and `parse_function_block` only collect;
`render_module` and everything it calls only print. Keep them apart when
reviewing a diff.

Function detection supports `name()`, `function name`, `function name()`, and a
declaration whose `{` sits on the next line. Preserve all four when touching
those rules.

## Layout configuration

Nothing about the documented repository is hardcoded. `init_layout` reads
`src_dir`, `doc_dir`, `root_files`, `source_path`, `link_dirs`, `example_dir`
and `example_prefix` from `-v` assignments and falls back to the defaults
documented at the top of the file. Every path decision — the "Source" link, a
relative `@see` target, the example scan — goes through those variables. A new
path rule belongs there, not inline.

## Rendering contracts

* Every section prints its own trailing blank line. A section that adds another
  one before the next heading is a bug, and the tests pin the spacing.
* Descriptions are dedented with `dedent_doc`, which handles both the indented
  paragraph under a bare `@description` and the first line written on the tag
  itself.
* A comment that is a linter directive (`shellcheck …=`, `dyshellint …=`) is
  dropped by `is_directive` wherever it appears, so it never reaches the
  document.
* `render_link` resolves `@see` entries in a fixed order: Markdown link, known
  directory prefix, explicit relative path, absolute URL, anchor. Anchors follow
  GitHub's rules in `github_anchor`.
* Output must be deterministic. Anything that iterates an awk array for output
  sets `PROCINFO["sorted_in"]`; committed documents are compared byte for byte
  by the projects that use sh-docs.
* `@section` is not sticky by design: each documented function carries its own.
  Do not change that without updating the README and the testcases that rely on
  it.

## Style

The shell sources are held to the Dynamo shell style guide, enforced by
`dyshellint` (which runs ShellCheck and shfmt itself) through `make lint`:

* `function name {`, never `name()`; private functions of an entrypoint are
  `_prefixed`, and a library's are `namespace::name` or `__namespace_name`.
* Every file opens with an shdoc header carrying `@file`, `@brief` and
  `@description`, and every function carries at least `@description`.
* A sourced file has no shebang and stays non-executable; it declares its
  namespace with `@namespace` and its shell with `# shellcheck shell=bash`.
* Formatting is `shfmt --indent 2 --case-indent --binary-next-line
  --space-redirects`, which `make fmt` applies.
* A finding that cannot be fixed is silenced with
  `# dyshellint disable=CODE <reason>` and never without the reason. There are
  two: `BSG051` in `sh-docs` and `BSG011` in `tests/run_tests`.

Never write `dybatpho::` in a shell source here, not even in a comment:
`dyshellint` reads it as "this file sources dybatpho" and turns on a set of
rules the project cannot satisfy.

## Tests

```sh
make test              # everything
tests/run_tests option # only the testcases whose name contains "option"
```

Each file under `tests/testcases/` runs in its own temporary directory with
`tests/lib.sh` sourced. The common shape is an `input` heredoc, an `expected`
heredoc, and `tests::assert`; quote both heredoc delimiters so nothing in the
fixture is expanded. A failing run keeps its working directories and prints the
path.

When changing parser or renderer behavior, add a testcase that shows the exact
annotation input and the full Markdown output, and regenerate the example with
`make examples` — `make check-examples` and the `examples-up-to-date` testcase
both fail otherwise.

## Change guidance

Keep sh-docs to gawk and bash. Do not add a build step, a second runtime, or a
dependency for the test harness.
