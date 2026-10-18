#!/usr/bin/env bash
# @file contrib/github-action.sh
# @brief Run sh-docs with the inputs of the GitHub Action.
# @description `action.yml` hands its inputs over as environment variables;
#   this turns them into a sh-docs command line and runs it. `files` holds
#   paths or globs separated by whitespace, `**` included, so a path with a
#   space in it cannot be given. `args` is split on whitespace too, and comes
#   last, so an option in it overrides the input of the same name.
# @env SH_DOCS_FILES string The sources to document, as paths or globs.
# @env SH_DOCS_OUTPUT_DIR string [default: docs] Where the documents go.
# @env SH_DOCS_CHECK string [default: true] `true` to compare instead of write.
# @env SH_DOCS_STRICT string [default: false] `true` to add `--strict`.
# @env SH_DOCS_INDEX string [default: false] `true` to add `--index`.
# @env SH_DOCS_FORMAT string [default: markdown] `markdown` or `man`.
# @env SH_DOCS_ARGS string? Further sh-docs options.
# @env SH_DOCS_BIN string? The sh-docs to run, when it is not the one in this
#   checkout.
# @exitcode 0 The documents were generated, and nothing was found
# @exitcode 1 A document is missing or stale, or --strict reported a problem
# @exitcode 2 An input is invalid, or sh-docs could not run
# @see action.yml
# @license MIT

set -euo pipefail

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
  printf 'sh-docs: bash 4.4 or newer is required, found %s\n' "${BASH_VERSION}" >&2
  exit 2
fi
shopt -s inherit_errexit globstar

readonly SH_DOCS_BIN="${SH_DOCS_BIN:-${BASH_SOURCE[0]%/*}/../sh-docs}"

# @description Report an invalid input and stop.
# @arg $1 string The message
# @stderr The message, as a GitHub Actions error annotation
# @exitcode 2 Always
function _die {
  printf '::error title=sh-docs::%s\n' "$1" >&2
  printf 'sh-docs: %s\n' "$1" >&2
  exit 2
}

# @description Stop unless a boolean input reads `true` or `false`.
# @arg $1 string The name of the input
# @arg $2 string Its value
# @exitcode 0 The value is `true` or `false`
# @exitcode 2 The value is neither
function _need_bool {
  [[ $2 == true || $2 == false ]] || _die "$1 must be true or false, not $2"
}

# @description Build the sh-docs command line from the inputs and run it.
# @noargs
# @exitcode 0 sh-docs found nothing
# @exitcode 1 sh-docs found a stale document or a --strict problem
# @exitcode 2 An input is invalid, or sh-docs failed
function _main {
  local _pattern _match
  local _check="${SH_DOCS_CHECK:-true}" _strict="${SH_DOCS_STRICT:-false}"
  local _index="${SH_DOCS_INDEX:-false}"
  local -a _patterns=() _matches=() _sources=() _extra=() _args=()

  read -ra _patterns <<< "${SH_DOCS_FILES-}"
  ((${#_patterns[@]})) || _die 'the files input is empty'
  for _pattern in "${_patterns[@]}"; do
    mapfile -t _matches < <(compgen -G "${_pattern}" || true)
    ((${#_matches[@]})) || _die "${_pattern} matches no file"
    for _match in "${_matches[@]}"; do
      _sources+=("${_match}")
    done
  done

  _need_bool check "${_check}"
  _need_bool strict "${_strict}"
  _need_bool index "${_index}"
  [[ ${_check} == false ]] || _args+=(--check)
  [[ ${_strict} == false ]] || _args+=(--strict)
  [[ ${_index} == false ]] || _args+=(--index)
  _args+=(--format "${SH_DOCS_FORMAT:-markdown}")
  _args+=(--output-dir "${SH_DOCS_OUTPUT_DIR:-docs}")
  read -ra _extra <<< "${SH_DOCS_ARGS-}"
  _args+=("${_extra[@]}")

  exec "${SH_DOCS_BIN}" "${_args[@]}" -- "${_sources[@]}"
}

_main "$@"
