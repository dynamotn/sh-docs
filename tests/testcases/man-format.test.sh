# shellcheck shell=bash
# @file tests/testcases/man-format.test.sh
# @brief Testcase for --format man.
# @description --format man renders the same annotations as a roff man page:
#   the header fills NAME, SYNOPSIS, DESCRIPTION, OPTIONS, ARGUMENTS, the
#   streams, ENVIRONMENT, EXIT STATUS, EXAMPLES, NOTES, SEE ALSO and LICENSE,
#   and the functions of a library are listed under FUNCTIONS. Markdown in a
#   description becomes roff, a backslash is escaped, a line that starts with a
#   dot cannot be read as a request, and a hyphen in code is a minus sign. The
#   page carries no date unless --man-date gives one, so it is the same on
#   every run.

tests::put input << 'SH'
#!/usr/bin/env bash
# @file greet
# @brief Greet someone by name.
# @since 2.0.0
# @description Prints a greeting. Use `--loud` to **shout** it.
#
#   ## Locale
#
#   - The word comes from `GREET_WORD`.
#   - A path such as `C:\greet` is kept.
#   .dotted line stays text.
# @usage
#   ```bash
#   greet [-l] [-o <file>] NAME
#   ```
# @option -l | --loud Shout the greeting.
# @option -o <file> | --output=<file> Write to a file.
# @arg $1 string The name to greet.
# @arg $2 string [default: !] Punctuation.
# @env GREET_WORD string [default: Hello] Word used.
# @stdout The greeting.
# @exitcode 0 Written.
# @exitcode 1 No name.
# @example
#   greet -l World
# @see printf(1)
# @see [shdoc](https://github.com/reconquest/shdoc)
# @tip Pipe it into `cowsay`.
# @license MIT

printf 'Hello %s\n' "$1"
SH

tests::put expected << 'ROFF'
.TH GREET 1 "2026-10-19" "greet 2.0.0"
.SH NAME
greet \- Greet someone by name.
.SH SYNOPSIS
.RS
.nf
greet [\-l] [\-o <file>] NAME
.fi
.RE
.SH DESCRIPTION
Prints a greeting. Use \fB\-\-loud\fR to \fBshout\fR it.
.SS Locale
.IP \(bu 2
The word comes from \fBGREET_WORD\fR.
.IP \(bu 2
A path such as \fBC:\egreet\fR is kept.
\&.dotted line stays text.
.SH OPTIONS
.TP
\fB\-l\fR, \fB\-\-loud\fR
Shout the greeting.
.TP
\fB\-o\fR \fIfile\fR, \fB\-\-output\fR=\fIfile\fR
Write to a file.
.SH ARGUMENTS
.TP
\fI$1\fR (string)
The name to greet.
.TP
\fI$2\fR (string, optional, default: \fB!\fR)
Punctuation.
.SH STDOUT
The greeting.
.SH ENVIRONMENT
.TP
\fBGREET_WORD\fR (string, optional, default: \fBHello\fR)
Word used.
.SH EXIT STATUS
.TP
\fB0\fR
Written.
.TP
\fB1\fR
No name.
.SH EXAMPLES
.RS
.nf
greet \-l World
.fi
.RE
.SH NOTES
.IP \(bu 2
Pipe it into \fBcowsay\fR.
.SH SEE ALSO
\fBprintf\fR(1),
shdoc <https://github.com/reconquest/shdoc>
.SH LICENSE
MIT
ROFF

tests::assert --format man --man-date 2026-10-19

tests::put input << 'SH'
# shellcheck shell=bash
# @file strings.sh
# @brief String helpers.

# @description Repeat a string.
#
#   ### Notes
#
#   Uses `printf`.
# @deprecated Use `text::repeat`.
# @since 1.2.0
# @warning Slow for large counts.
# @example
#   strings::repeat ab 3
# @arg $1 string The string.
# @arg $2 number? How many times.
# @set REPLY string The result.
# @stdout The repeated string.
# @exitcode 0 Always.
# @see strings::trim
# @tip Cache the result.
strings::repeat() {
  :
}

# @description Trim.
# @noargs
strings::trim() {
  :
}
SH

tests::put expected << 'ROFF'
.TH STRINGS.SH 3 "" "strings.sh"
.SH NAME
strings.sh \- String helpers.
.SH SYNOPSIS
.B strings.sh
.SH FUNCTIONS
.SS strings::repeat
\fBDeprecated:\fR
Use \fBtext::repeat\fR.
.PP
Since 1.2.0.
.PP
Repeat a string.
.PP
\fBNotes\fR
.PP
Uses \fBprintf\fR.
.PP
\fBWarning:\fR Slow for large counts.
.PP
.RS
.nf
strings::repeat ab 3
.fi
.RE
.PP
\fBArguments\fR
.TP
\fI$1\fR (string)
The string.
.TP
\fI$2\fR (number, optional)
How many times.
.PP
\fBSets\fR
.TP
\fBREPLY\fR (string)
The result.
.PP
\fBStandard output\fR
.IP \(bu 2
The repeated string.
.PP
\fBExit status\fR
.TP
\fB0\fR
Always.
.PP
\fBSee also\fR
.PP
strings::trim
.SS strings::trim
Trim.
.PP
Takes no arguments.
.SH NOTES
.IP \(bu 2
\fBstrings::repeat\fR: Cache the result.
ROFF

tests::assert --format man --man-section 3

# Under --output-dir the section is the extension of each page.
cp input strings.sh
tests::run --format man --man-section 3 --output-dir man strings.sh
tests::assert_exitcode 0
tests::assert_no_diff expected man/strings.3

tests::run --format pdf
tests::assert_exitcode 2
tests::assert_stderr_contains 'unknown format: pdf'

tests::run --format man --man-section x
tests::assert_exitcode 2
tests::assert_stderr_contains 'invalid man section: x'

tests::run --format man --index --output-dir man strings.sh
tests::assert_exitcode 2
tests::assert_stderr_contains '--index lists Markdown documents'
