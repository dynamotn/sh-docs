# shellcheck shell=bash
# @file greeting.sh
# @brief A library that greets people.
# @namespace greeting
# @description The module is the worked example used in the README. It shows
#   the tags a typical module uses:
#
#   * a header that names and describes the module
#   * functions grouped into sections
#   * arguments, options, exit codes, and streams
#
#   ## Loading
#
#   The module is self-contained and safe to source more than once.
#
# @usage
#   ```bash
#   . src/greeting.sh
#   greeting::say "World"
#   ```
#
# @env GREETING_WORD string Word used instead of `Hello`.
#
# @tip Source the module before setting `GREETING_WORD`; it is read on every
#   call, not at load time.
#
# @see
#   - src/strings.sh
#   - [sh-docs](https://github.com/dynamotn/sh-docs)
#
# @license MIT

# @section Greeting
# @description Greet a person by name.
#
#   The greeting is written to stdout; nothing else is.
# @example
#   greeting::say "World"
#   greeting::say --loud "World"
# @option -l | --loud Shout the greeting.
# @option --word=<word> Use the given word instead of `Hello`.
# @arg $1 string The name to greet.
# @env GREETING_WORD string Word used instead of `Hello`.
# @stdout The greeting, followed by a newline.
# @stderr A diagnostic when no name was given.
# @exitcode 0 The greeting was written.
# @exitcode 1 No name was given.
# @note The greeting is not localized.
# @see greeting::reply
function greeting::say {
  local name="${1-}"

  if [[ -z ${name} ]]; then
    printf 'greeting: no name given\n' >&2
    return 1
  fi

  printf '%s %s\n' "${GREETING_WORD:-Hello}" "${name}"
}

# @section Greeting
# @description Read a name from stdin and greet whoever it names.
# @noargs
# @stdin The name to greet.
# @set REPLY string The greeting that was written.
# @exitcode 0 The greeting was written.
function greeting::reply {
  local name
  read -r name
  REPLY="$(greeting::say "${name}")"
  printf '%s\n' "${REPLY}"
}

# @section Compatibility
# @description Greet a person by name.
# @deprecated Use `greeting::say` instead; this one goes away in 2.0.
# @arg $1 string The name to greet.
function greeting::hello {
  greeting::say "$@"
}

# @internal
# @description Never appears in the generated document.
# @noargs
function __greeting_reset {
  unset -v REPLY
}
