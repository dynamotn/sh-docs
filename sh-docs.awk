#!/usr/bin/env gawk -f
#
# sh-docs -- generate GitHub-flavored Markdown from shell doc comments.
#
# Layout of the documented repository is configured through `-v` variables; the
# defaults describe a repository whose modules live in `src/` and whose
# generated documents live in `docs/`:
#
#   src_dir        directory holding the documented sources     (default "src")
#   doc_dir        directory the generated document is written to (default "docs")
#   root_files     comma-separated modules that sit at the repository root
#                  instead of inside `src_dir`                  (default "init.sh")
#   source_path    explicit path of the documented source, relative to the
#                  repository root; overrides `src_dir`/`root_files`
#   link_dirs      comma-separated path prefixes that `@see` entries are
#                  resolved as paths rather than as anchors
#                  (default "docs,example,src,scripts")
#   example_dir    filesystem directory scanned for related examples; scanning
#                  is off when empty                            (default "")
#   example_prefix prefix the scanned examples are linked under (default "example")
#   strict         when 1, report unknown tags, public functions without
#                  `@description` and positional arguments without `@arg`
#                  on stderr, and exit 3 once the document is written
#                                                               (default 0)
#   line_links     when 1, link each function to its line in the source
#                                                               (default 0)
#   no_emoji       when 1, print headings and labels without emoji (default 0)
#   emit           "summary" prints the module name and brief, separated by a
#                  tab, instead of the document; the wrapper builds the
#                  index from it                                (default "")

BEGIN {
	module_file = ""
	module_brief = ""
	header_done = 0
	header_count = 0
	header_seen_file = 0
	pending_count = 0
	fn_count = 0
	function_declaration = ""
	pending_section = ""
	# A declaration with its body opened on the same line, and one whose body
	# opens on the next line.
	FN_OPEN = "^[[:blank:]]*(function[[:blank:]]+)?([a-zA-Z0-9_\\-:\\.]+)[[:blank:]]*(\\([[:blank:]]*\\))?[[:blank:]]*(\\{|\\(([^)]|$))"
	FN_DECL = "^[[:blank:]]*(function[[:blank:]]+)?([a-zA-Z0-9_\\-:\\.]+)[[:blank:]]*(\\([[:blank:]]*\\))?[[:blank:]]*$"
	# The tags each kind of block understands. `--strict` reports any other.
	split("file name brief description usage see tip env license deprecated namespace" \
		" since arg option exitcode stdin stdout stderr", parts, " ")
	for (i in parts) {
		is_header_tag[parts[i]] = 1
	}
	split("description example arg option env stdin stdout stderr exitcode set see" \
		" tip deprecated note noargs section internal warning since", parts, " ")
	for (i in parts) {
		is_function_tag[parts[i]] = 1
	}
	delete parts
	warned = 0
	body_fn = 0
	init_layout()
}

function init_layout(i, n, parts)
{
	if (src_dir == "") {
		src_dir = "src"
	}
	if (doc_dir == "") {
		doc_dir = "docs"
	}
	if (example_prefix == "") {
		example_prefix = "example"
	}
	if (link_dirs == "") {
		link_dirs = "docs,example,src,scripts"
	}
	if (root_files == "") {
		root_files = "init.sh"
	}
	sub(/\/+$/, "", src_dir)
	sub(/\/+$/, "", doc_dir)
	sub(/\/+$/, "", example_prefix)
	sub(/\/+$/, "", example_dir)
	n = split(link_dirs, parts, /[[:space:]]*,[[:space:]]*/)
	for (i = 1; i <= n; i++) {
		if (parts[i] != "") {
			is_link_dir[parts[i]] = 1
		}
	}
	# The document itself lives in `doc_dir`, so a reference into it is
	# resolved relative to the document, and one into any other configured
	# directory has to climb out of it first.
	is_link_dir[doc_dir] = 1
	is_link_dir[example_prefix] = 1
	is_link_dir[src_dir] = 1
	n = split(root_files, parts, /[[:space:]]*,[[:space:]]*/)
	for (i = 1; i <= n; i++) {
		if (parts[i] != "") {
			is_root_file[parts[i]] = 1
		}
	}
}

function path_prefix(text, slash)
{
	slash = index(text, "/")
	if (slash == 0) {
		return ""
	}
	return substr(text, 1, slash - 1)
}

{
	if (! header_done) {
		# The file header ends at the first blank line that follows it. Without
		# this, a file whose first statement sits far below the header, such as
		# `init.sh`, would absorb unrelated comment blocks into the last module
		# tag it saw.
		if ($0 ~ /^[[:space:]]*$/ && header_seen_file) {
			header_done = 1
			parse_header()
			next
		}
		if ($0 ~ /^#!/ || $0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) {
			header_lines[++header_count] = $0
			if ($0 ~ /^[[:space:]]*#[[:space:]]*@(file|name)[[:space:]]+/) {
				header_seen_file = 1
			}
			next
		}
		header_done = 1
		if (starts_function($0)) {
			release_header_tail()
		}
		parse_header()
	}
	if (body_fn) {
		scan_body_line($0)
	}
	if ($0 ~ /^[[:space:]]*#/) {
		pending_lines[++pending_count] = $0
		pending_nr[pending_count] = NR
		next
	}
	# The body of a function is a `{ ... }` group or a `( ... )` subshell. A
	# `()` right after the name is the empty parameter list, never a body.
	if (match($0, FN_OPEN, m) && is_declaration(m)) {
		parse_function_block(m[2], NR)
		start_body($0, substr($0, RSTART + RLENGTH))
		pending_count = 0
		delete pending_lines
		function_declaration = ""
		next
	}
	if (match($0, FN_DECL, m) && is_declaration(m)) {
		function_declaration = m[2]
		function_declaration_nr = NR
		function_declaration_line = $0
		next
	}
	if ($0 ~ /^[[:blank:]]*[{(]/ && function_declaration != "") {
		parse_function_block(function_declaration, function_declaration_nr)
		start_body(function_declaration_line, substr($0, index($0, substr(trim($0), 1, 1)) + 1))
		pending_count = 0
		delete pending_lines
		function_declaration = ""
		next
	}
	if ($0 ~ /^[[:blank:]]*$/ && function_declaration != "") {
		next
	}
	if ($0 !~ /^[[:space:]]*$/) {
		parse_module_block()
		pending_count = 0
		delete pending_lines
		function_declaration = ""
	}
}

END {
	if (! header_done) {
		parse_header()
	}
	if (body_fn) {
		close_body()
	}
	if (emit == "summary") {
		print module_file "\t" module_brief
		exit
	}
	render_module()
	# The document is complete either way; the status tells the wrapper that
	# `--strict` found something to report.
	if (strict && warned) {
		exit 3
	}
}

# Report a problem with the documentation on stderr, when `--strict` asked for
# it. The line number is the one in the documented source.
function warn(nr, message, name)
{
	if (! strict) {
		return
	}
	name = (FILENAME == "" || FILENAME == "-" ? "<stdin>" : FILENAME)
	printf "sh-docs: %s:%d: %s\n", name, nr, message > "/dev/stderr"
	warned = 1
}

# A private function needs no documentation: its name, or the last `::` part
# of it, starts with `_`.
function is_public(name)
{
	sub(/^.*::/, "", name)
	return (name !~ /^_/)
}

# The body of the function just parsed starts. `declaration` is the line that
# named the function, which sets the indentation its closing `}` or `)` sits
# at; `rest` is whatever follows the opener on the same line.
function start_body(declaration, rest)
{
	if (! body_fn) {
		return
	}
	match(declaration, /^[[:blank:]]*/)
	body_indent = substr(declaration, 1, RLENGTH)
	scan_positional(rest, NR)
	if (trim(rest) ~ /[})]$/) {
		close_body()
	}
}

function scan_body_line(line)
{
	if (substr(line, 1, length(body_indent) + 1) ~ /[})]$/ \
		&& substr(line, 1, length(body_indent)) == body_indent) {
		close_body()
		return
	}
	if (line ~ /^[[:space:]]*#/) {
		return
	}
	scan_positional(line, NR)
}

# Record the positional parameters `text` reads. Escaped dollars and
# single-quoted text are not expansions, and a trailing comment is not code.
function scan_positional(text, nr, n)
{
	gsub(/\\\$/, "", text)
	gsub(/'[^']*'/, "", text)
	sub(/[[:space:]]#.*$/, "", text)
	while (match(text, /\$\{?[1-9]/)) {
		n = substr(text, RSTART + RLENGTH - 1, 1)
		if (! (n in body_uses)) {
			body_uses[n] = nr
		}
		text = substr(text, RSTART + RLENGTH)
	}
}

# The body has ended: report the positions it read that no `@arg` covers.
function close_body(i, token, covered, n, idx, name)
{
	idx = body_fn
	body_fn = 0
	name = fn_name[idx]
	if (is_public(name)) {
		for (i = 1; i <= counts["fn_arg", idx]; i++) {
			token = items["fn_arg", idx, i]
			sub(/[[:space:]].*$/, "", token)
			if (token == "$@" || token == "$*") {
				delete body_uses
				return
			}
			covered[token] = 1
		}
		PROCINFO["sorted_in"] = "@val_num_asc"
		for (n in body_uses) {
			if (! (("$" n) in covered)) {
				warn(body_uses[n], name " uses $" n " without @arg $" n)
			}
		}
		delete PROCINFO["sorted_in"]
	}
	delete body_uses
}

# An emoji and the space after it, or nothing under `--no-emoji`.
function ic(emoji)
{
	return (no_emoji ? "" : emoji " ")
}

# The tag a cleaned comment line opens, or "" when it opens none.
function tag_of(line, m)
{
	if (match(line, /^@([[:alnum:]_-]+)([[:space:]]|$)/, m)) {
		return m[1]
	}
	return ""
}

# Bash only reads a line as a function declaration when it carries the
# `function` keyword or the `()` after the name. Without that check a lone
# command such as `fi` or `cleanup`, followed by a `{ ... }` group, would be
# documented as a function, and the comment above a plain command would be
# handed to the next function instead of being discarded.
function is_declaration(m)
{
	return (m[1] != "" || m[3] != "")
}

function starts_function(line, m)
{
	return ((match(line, FN_OPEN, m) || match(line, FN_DECL, m)) && is_declaration(m))
}

# A header that ends at a statement, rather than at a blank line after `@file`,
# swallows every comment above that statement. The block after its last blank
# line is the documentation of the statement, unless it carries one of the tags
# that only the header knows.
function release_header_tail(i, last_blank, has_module_tag, line)
{
	last_blank = 0
	for (i = header_count; i >= 1; i--) {
		if (header_lines[i] ~ /^[[:space:]]*$/) {
			last_blank = i
			break
		}
	}
	if (last_blank == 0 || last_blank == header_count) {
		return
	}
	has_module_tag = 0
	for (i = last_blank + 1; i <= header_count; i++) {
		line = clean_comment(header_lines[i])
		if (line ~ /^@(file|name|brief)([[:space:]]+|$)/) {
			has_module_tag = 1
			break
		}
	}
	if (has_module_tag) {
		return
	}
	for (i = last_blank + 1; i <= header_count; i++) {
		pending_lines[++pending_count] = header_lines[i]
		pending_nr[pending_count] = i
		delete header_lines[i]
	}
	header_count = last_blank
}

function append_item(kind, idx, value, key)
{
	key = kind SUBSEP idx SUBSEP counts[kind, idx]
	if (items[key] == "") {
		items[key] = value
	} else {
		items[key] = items[key] " " trim(value)
	}
}

function append_text(kind, idx, value, key)
{
	key = kind SUBSEP idx
	if (value == "__BLANK__") {
		if (texts[key] == "") {
			return
		}
		if (texts[key] !~ /\n\n$/) {
			texts[key] = texts[key] "\n\n"
		}
		return
	}
	if (texts[key] == "") {
		texts[key] = value
	} else if (texts[key] ~ /\n\n$/) {
		# The paragraph break is already there. Joining with another newline
		# would turn every blank line in a description into two.
		texts[key] = texts[key] value
	} else {
		texts[key] = texts[key] "\n" value
	}
}

function clean_comment(line)
{
	sub(/^[[:space:]]*#[[:space:]]?/, "", line)
	sub(/[[:space:]]+$/, "", line)
	return line
}

function dedent(text, n, arr, i, line, indent, min_indent, out)
{
	n = split(text, arr, /\n/)
	min_indent = -1
	for (i = 1; i <= n; i++) {
		line = arr[i]
		if (trim(line) == "") {
			continue
		}
		match(line, /^[[:space:]]*/)
		indent = RLENGTH
		if (min_indent < 0 || indent < min_indent) {
			min_indent = indent
		}
	}
	if (min_indent < 0) {
		return text
	}
	out = ""
	for (i = 1; i <= n; i++) {
		line = arr[i]
		if (min_indent > 0) {
			line = substr(line, min_indent + 1)
		}
		out = out (i == 1 ? "" : "\n") line
	}
	return out
}

# Strip the indentation shared by every line but the first. A description
# written as `@description Short.` followed by indented continuation lines has
# a flush first line, which pins `dedent`'s common indent at zero and leaves
# the rest of the paragraph indented in the document.
function dedent_body(text, n, arr, i, line, indent, min_indent, out)
{
	n = split(text, arr, /\n/)
	if (n < 2) {
		return text
	}
	min_indent = -1
	for (i = 2; i <= n; i++) {
		line = arr[i]
		if (trim(line) == "") {
			continue
		}
		match(line, /^[[:space:]]*/)
		indent = RLENGTH
		if (min_indent < 0 || indent < min_indent) {
			min_indent = indent
		}
	}
	if (min_indent <= 0) {
		return text
	}
	out = arr[1]
	for (i = 2; i <= n; i++) {
		out = out "\n" substr(arr[i], min_indent + 1)
	}
	return out
}

# Descriptions come in both shapes: the whole paragraph indented under a bare
# `@description`, and a first line on the tag itself. `dedent` handles the
# first, `dedent_body` the second, and each is a no-op for the other's shape.
function dedent_doc(text)
{
	return dedent_body(dedent(text))
}

# A linter directive is addressed to a tool, not to the reader of the document.
# `shellcheck shell=bash`, `shellcheck disable=SC2034` and the `dyshellint`
# spellings of the same all belong to the source, never to the documentation.
function is_directive(line)
{
	return (line ~ /^(shellcheck|dyshellint)[[:space:]]+[a-z-]+=/)
}

function is_separator(line, stripped)
{
	stripped = trim(line)
	return (stripped != "" && stripped ~ /^#+$/)
}

function normalize_ref(text, out)
{
	out = trim(text)
	gsub(/^`+|`+$/, "", out)
	gsub(/^\[[^]]+\]\(/, "", out)
	gsub(/\)$/, "", out)
	return out
}

function github_anchor(text, out)
{
	out = normalize_ref(text)
	gsub(/[`*]/, "", out)
	out = tolower(out)
	gsub(/[^[:alnum:] _-]/, "", out)
	gsub(/[[:space:]]+/, "-", out)
	gsub(/-+/, "-", out)
	gsub(/^-+|-+$/, "", out)
	return out
}

function doc_link_target(text, out, prefix)
{
	out = normalize_ref(text)
	prefix = path_prefix(out)
	if (prefix == doc_dir) {
		out = substr(out, length(doc_dir) + 2)
	} else if (prefix in is_link_dir) {
		out = "../" out
	}
	return out
}

function render_link(text, url, raw)
{
	raw = trim(text)
	gsub(/^`+|`+$/, "", raw)
	# A reference that is already a Markdown link is passed through untouched.
	# Normalizing it first strips it down to the bare URL, which then gets
	# anchor-linked into the current document -- a link that goes nowhere.
	if (raw ~ /^\[[^]]+\]\([^)]+\)[[:punct:]]*$/) {
		return raw
	}
	text = normalize_ref(text)
	if (path_prefix(text) in is_link_dir) {
		url = doc_link_target(text)
		return "[" text "](" url ")"
	}
	if (text ~ /^\.{0,2}\//) {
		return "[" text "](" text ")"
	}
	if (text ~ /^[[:alpha:]][[:alnum:]+.-]*:\/\//) {
		return "[" text "](" text ")"
	}
	url = github_anchor(text)
	return "[" text "](#" url ")"
}

# The path of the documented source relative to the repository root, or ""
# when there is none: a document generated from stdin without `@file`.
function source_file(path)
{
	# Modules live in `src_dir`; the files named by `root_files` sit at the
	# repository root instead.
	if (source_path != "") {
		path = source_path
	} else if (module_file == "") {
		path = ""
	} else if (module_file in is_root_file || src_dir == "") {
		path = module_file
	} else {
		path = src_dir "/" module_file
	}
	return path
}

function render_source_link(path)
{
	path = source_file()
	return "[" path "](../" path ")"
}

function render_function_link(name)
{
	return "[`" name "`](#" github_anchor(name) ")"
}

function append_nav_link(nav, label, anchor)
{
	if (anchor == "") {
		return nav
	}
	return nav (nav == "" ? "" : " · ") "[" label "](#" github_anchor(anchor) ")"
}

function print_anchor(id)
{
	if (id == "") {
		return
	}
	print "<a id=\"" id "\"></a>"
}

function scan_pending_meta(i, line, rest)
{
	pending_internal = 0
	for (i = 1; i <= pending_count; i++) {
		line = pending_lines[i]
		if (line !~ /^[[:space:]]*#/) {
			continue
		}
		line = clean_comment(line)
		if (line ~ /^@internal([[:space:]]+|$)/) {
			pending_internal = 1
		} else if (line ~ /^@section[[:space:]]+/) {
			rest = trim(substr(line, 9))
			if (rest != "") {
				pending_section = rest
			}
		}
	}
}

function parse_module_block(i, line, mode, rest)
{
	mode = ""
	for (i = 1; i <= pending_count; i++) {
		line = pending_lines[i]
		if (line !~ /^[[:space:]]*#/) {
			continue
		}
		line = clean_comment(line)
		if (is_separator(line) || is_directive(line)) {
			continue
		}
		if (trim(line) == "") {
			continue
		}
		if (line ~ /^@env([[:space:]]+|$)/) {
			rest = trim(substr(line, 5))
			if (rest != "") {
				push_item("module_env", 0, rest)
			}
			mode = "env"
			continue
		}
		if (line ~ /^@license([[:space:]]+|$)/) {
			rest = trim(substr(line, 9))
			if (rest != "") {
				push_item("module_license", 0, rest)
			}
			mode = "license"
			continue
		}
		if (line ~ /^@deprecated([[:space:]]+|$)/) {
			rest = trim(substr(line, 12))
			if (rest != "") {
				push_item("module_deprecated", 0, rest)
			}
			mode = "deprecated"
			continue
		}
		if (line ~ /^@see([[:space:]]+|$)/) {
			rest = trim(substr(line, 5))
			if (rest != "") {
				push_item("module_see", 0, rest)
			}
			mode = "see"
			continue
		}
		if (line ~ /^@tip([[:space:]]+|$)/) {
			rest = trim(substr(line, 5))
			if (rest != "") {
				push_item("module_tip", 0, rest)
			}
			mode = "tip"
			continue
		}
		if (mode == "env" && counts["module_env", 0] > 0) {
			append_item("module_env", 0, line)
		} else if (mode == "license" && counts["module_license", 0] > 0) {
			append_item("module_license", 0, line)
		} else if (mode == "deprecated" && counts["module_deprecated", 0] > 0) {
			append_item("module_deprecated", 0, line)
		} else if (mode == "see" && trim(line) ~ /^-[[:space:]]+/) {
			rest = trim(line)
			push_item("module_see", 0, trim(substr(rest, 3)))
		} else if (mode == "see" && counts["module_see", 0] > 0) {
			append_item("module_see", 0, line)
		} else if (mode == "tip" && counts["module_tip", 0] > 0) {
			append_item("module_tip", 0, line)
		}
	}
}

function parse_function_block(name, nr, i, line, mode, key, rest, parts, argline)
{
	if (body_fn) {
		close_body()
	}
	scan_pending_meta()
	if (pending_internal) {
		pending_section = ""
		return
	}
	fn_count++
	fn_name[fn_count] = name
	fn_nr[fn_count] = nr
	public_names[fn_count] = name
	fn_section[fn_count] = pending_section
	pending_section = ""
	mode = ""
	for (i = 1; i <= pending_count; i++) {
		line = pending_lines[i]
		if (line !~ /^[[:space:]]*#/) {
			continue
		}
		line = clean_comment(line)
		if (is_separator(line) || is_directive(line)) {
			continue
		}
		if (trim(line) == "") {
			if (mode == "description") {
				append_text("fn_desc", fn_count, "__BLANK__")
			} else if (mode == "example" && counts["fn_example", fn_count] > 0) {
				key = "fn_example" SUBSEP fn_count SUBSEP counts["fn_example", fn_count]
				items[key] = items[key] "\n"
			}
			continue
		}
		if (line ~ /^@/) {
			split(substr(line, 2), parts, /[[:space:]]+/)
			key = parts[1]
			rest = trim(substr(line, 2 + length(key)))
			if (key == "description") {
				if (rest != "") {
					append_text("fn_desc", fn_count, rest)
				}
				mode = "description"
			} else if (key == "example") {
				push_item("fn_example", fn_count, rest)
				mode = "example"
			} else if (key == "arg") {
				push_item("fn_arg", fn_count, rest)
				mode = "arg"
			} else if (key == "option") {
				push_item("fn_option", fn_count, rest)
				mode = "option"
			} else if (key == "env") {
				push_item("fn_env", fn_count, rest)
				mode = "env"
			} else if (key == "stdin") {
				push_item("fn_stdin", fn_count, rest)
				mode = "stdin"
			} else if (key == "stdout") {
				push_item("fn_stdout", fn_count, rest)
				mode = "stdout"
			} else if (key == "stderr") {
				push_item("fn_stderr", fn_count, rest)
				mode = "stderr"
			} else if (key == "exitcode") {
				push_item("fn_exitcode", fn_count, rest)
				mode = "exitcode"
			} else if (key == "set") {
				push_item("fn_set", fn_count, rest)
				mode = "set"
			} else if (key == "see") {
				push_item("fn_see", fn_count, rest)
				mode = "see"
			} else if (key == "tip") {
				push_item("fn_tip", fn_count, rest)
				mode = "tip"
			} else if (key == "deprecated") {
				push_item("fn_deprecated", fn_count, rest)
				mode = "deprecated"
			} else if (key == "note") {
				push_item("fn_note", fn_count, rest)
				mode = "note"
			} else if (key == "noargs") {
				fn_noargs[fn_count] = 1
				mode = ""
			} else if (key == "warning") {
				push_item("fn_warning", fn_count, rest)
				mode = "warning"
			} else if (key == "since") {
				fn_since[fn_count] = rest
				mode = ""
			} else {
				if (! (key in is_function_tag)) {
					warn(pending_nr[i], "unknown tag @" key)
				}
				mode = ""
			}
			continue
		}
		if (mode == "description") {
			append_text("fn_desc", fn_count, line)
		} else if (mode == "example" && counts["fn_example", fn_count] > 0) {
			key = "fn_example" SUBSEP fn_count SUBSEP counts["fn_example", fn_count]
			if (items[key] == "") {
				items[key] = line
			} else {
				items[key] = items[key] "\n" line
			}
		} else if ((mode == "stdin" || mode == "stdout" || mode == "stderr") && counts["fn_" mode, fn_count] > 0) {
			key = "fn_" mode SUBSEP fn_count SUBSEP counts["fn_" mode, fn_count]
			if (items[key] == "") {
				items[key] = line
			} else {
				items[key] = items[key] "\n" line
			}
		} else if (mode == "env" && counts["fn_env", fn_count] > 0) {
			append_item("fn_env", fn_count, line)
		} else if (mode != "") {
			append_item("fn_" mode, fn_count, line)
		}
	}
	if (! (("fn_desc" SUBSEP fn_count) in texts) && is_public(name)) {
		warn(nr, name " has no @description")
	}
	body_fn = fn_count
}

function parse_header(i, line, mode, rest)
{
	mode = ""
	for (i = 1; i <= header_count; i++) {
		line = header_lines[i]
		if (line ~ /^#!/) {
			continue
		}
		if (line !~ /^[[:space:]]*#/) {
			continue
		}
		line = clean_comment(line)
		if (is_separator(line) || is_directive(line)) {
			continue
		}
		if (trim(line) == "") {
			if (mode == "description") {
				append_text("module_desc", 0, "__BLANK__")
			} else if (mode == "usage") {
				append_text("module_usage", 0, "__BLANK__")
			}
			continue
		}
		if (line ~ /^@brief[[:space:]]+/) {
			module_brief = trim(substr(line, 8))
			mode = ""
			continue
		}
		if (line ~ /^@since[[:space:]]+/) {
			module_since = trim(substr(line, 8))
			mode = ""
			continue
		}
		if (line ~ /^@(name|file)[[:space:]]+/) {
			# The value may follow a tab as well as a space.
			module_file = line
			sub(/^@(name|file)[[:space:]]+/, "", module_file)
			module_file = trim(module_file)
			mode = ""
			continue
		}
		if (line ~ /^@description([[:space:]]+|$)/) {
			rest = trim(substr(line, 13))
			if (rest != "") {
				append_text("module_desc", 0, rest)
			}
			mode = "description"
			continue
		}
		if (line ~ /^@usage([[:space:]]+|$)/) {
			rest = trim(substr(line, 7))
			if (rest != "") {
				append_text("module_usage", 0, rest)
			}
			mode = "usage"
			continue
		}
		if (line ~ /^@see([[:space:]]+|$)/) {
			rest = trim(substr(line, 5))
			if (rest != "") {
				push_item("module_see", 0, rest)
			}
			mode = "see"
			continue
		}
		if (line ~ /^@tip([[:space:]]+|$)/) {
			rest = trim(substr(line, 5))
			if (rest != "") {
				push_item("module_tip", 0, rest)
			}
			mode = "tip"
			continue
		}
		if (line ~ /^@env([[:space:]]+|$)/) {
			rest = trim(substr(line, 5))
			if (rest != "") {
				push_item("module_env", 0, rest)
			}
			mode = "env"
			continue
		}
		if (line ~ /^@license([[:space:]]+|$)/) {
			rest = trim(substr(line, 9))
			if (rest != "") {
				push_item("module_license", 0, rest)
			}
			mode = "license"
			continue
		}
		if (line ~ /^@deprecated([[:space:]]+|$)/) {
			rest = trim(substr(line, 12))
			if (rest != "") {
				push_item("module_deprecated", 0, rest)
			}
			mode = "deprecated"
			continue
		}
		# The command line of a script that is run rather than sourced.
		if (line ~ /^@(arg|option|exitcode|stdin|stdout|stderr)([[:space:]]+|$)/) {
			mode = tag_of(line)
			rest = trim(substr(line, length(mode) + 2))
			if (rest != "") {
				push_item("cli_" mode, 0, rest)
			}
			continue
		}
		# Any other tag ends the one before it. Otherwise its text would be
		# read as a continuation line, and land inside, say, a `@see` link.
		if (tag_of(line) != "") {
			if (! (tag_of(line) in is_header_tag)) {
				warn(i, "unknown tag @" tag_of(line))
			}
			mode = ""
			continue
		}
		if (line ~ /^\*\*.*\((string|bool|number)\):/) {
			push_item("module_globals", 0, line)
			continue
		}
		if (mode == "description") {
			append_text("module_desc", 0, line)
		} else if (mode == "usage") {
			append_text("module_usage", 0, line)
		} else if (mode == "see" && trim(line) ~ /^-[[:space:]]+/) {
			rest = trim(line)
			push_item("module_see", 0, trim(substr(rest, 3)))
		} else if (mode == "see" && counts["module_see", 0] > 0) {
			append_item("module_see", 0, line)
		} else if (mode == "tip" && counts["module_tip", 0] > 0) {
			append_item("module_tip", 0, line)
		} else if (mode == "env" && counts["module_env", 0] > 0) {
			append_item("module_env", 0, line)
		} else if (mode == "license" && counts["module_license", 0] > 0) {
			append_item("module_license", 0, line)
		} else if (mode == "deprecated" && counts["module_deprecated", 0] > 0) {
			append_item("module_deprecated", 0, line)
		} else if (("cli_" mode, 0) in counts && counts["cli_" mode, 0] > 0) {
			append_item("cli_" mode, 0, line)
		}
	}
}

function has_command_line()
{
	return (counts["cli_option", 0] + counts["cli_arg", 0] + counts["cli_stdin", 0] \
		+ counts["cli_stdout", 0] + counts["cli_stderr", 0] + counts["cli_exitcode", 0] > 0)
}

function print_command_line()
{
	if (! has_command_line()) {
		return
	}
	print_anchor("command-line")
	print "## " ic("\360\237\226\245\357\270\217") "Command line"
	print ""
	print_list("cli_option", 0, "Options", "option")
	print_list("cli_arg", 0, "Arguments", "arg")
	print_list("cli_stdin", 0, "Input on stdin", "bullet")
	print_list("cli_stdout", 0, "Output on stdout", "bullet")
	print_list("cli_stderr", 0, "Output on stderr", "bullet")
	print_list("cli_exitcode", 0, "Exit codes", "exit")
}

function md_escape(text)
{
	gsub(/\|/, "\\|", text)
	return text
}

function print_table_row(c1, c2, c3, has_three)
{
	c1 = md_escape(c1)
	c2 = md_escape(c2)
	c3 = md_escape(c3)
	if (has_three) {
		print "| " c1 " | " c2 " | " c3 " |"
	} else {
		print "| " c1 " | " c2 " |"
	}
}

# Split `name type [default: value] description` into `p`. A type ending in
# `?`, or a default, makes the parameter optional.
function parse_param(text, p, m)
{
	delete p
	if (! match(text, /^([^[:space:]]+)[[:space:]]+([^[:space:]]+)([[:space:]]+\[default:[[:space:]]*([^]]*)\])?[[:space:]]+(.*)$/, m)) {
		return 0
	}
	p["name"] = m[1]
	p["type"] = m[2]
	p["optional"] = (p["type"] ~ /\?$/ || m[3] != "")
	sub(/\?$/, "", p["type"])
	p["has_default"] = (m[3] != "")
	p["default"] = trim(m[4])
	p["desc"] = m[5]
	return 1
}

# The table of `@arg` or `@env` entries. The Required and Default columns are
# only added when a row uses them, so a table without optional entries reads
# as it always did.
function print_param_table(kind, idx, label, is_arg, i, text, p, extra, name, ok)
{
	extra = 0
	for (i = 1; i <= counts[kind, idx]; i++) {
		if (parse_param(items[kind, idx, i], p) && p["optional"] \
			&& (! is_arg || p["name"] ~ /^\$/)) {
			extra = 1
		}
	}
	if (extra) {
		print "| " label " | Type | Required | Default | Description |"
		print "| --- | --- | --- | --- | --- |"
	} else {
		print "| " label " | Type | Description |"
		print "| --- | --- | --- |"
	}
	for (i = 1; i <= counts[kind, idx]; i++) {
		text = items[kind, idx, i]
		ok = parse_param(text, p) && (! is_arg || p["name"] ~ /^\$/)
		if (! ok) {
			print_cells(text, "", extra ? "" : "\001", extra ? "" : "\001", "")
			continue
		}
		name = (is_arg ? "`" p["name"] "`" : "**`" p["name"] "`**")
		if (extra) {
			print_cells(name, p["type"], (p["optional"] ? "no" : "yes"), \
				(p["has_default"] ? "`" p["default"] "`" : ""), p["desc"])
		} else {
			print_cells(name, p["type"], "\001", "\001", p["desc"])
		}
	}
}

# Print a table row; a cell holding "\001" is left out, so the same call
# serves the three- and the five-column table.
function print_cells(c1, c2, c3, c4, c5, row)
{
	row = "| " md_escape(c1) " | " md_escape(c2)
	if (c3 != "\001") {
		row = row " | " md_escape(c3)
	}
	if (c4 != "\001") {
		row = row " | " md_escape(c4)
	}
	print row " | " md_escape(c5) " |"
}

function print_arg_table(kind, idx)
{
	print_param_table(kind, idx, "Name", 1)
}

function print_option_table(kind, idx, i, key, text, m, term, desc)
{
	print "| Option | Description |"
	print "| --- | --- |"
	for (i = 1; i <= counts[kind, idx]; i++) {
		key = kind SUBSEP idx SUBSEP i
		text = items[key]
		if (match(text, /^(((-[[:alnum:]]([[:blank:]]*<[^>]+>)?|--[[:alnum:]][[:alnum:]-]*((=|[[:blank:]]+)<[^>]+>)?)([[:blank:]]*\|?[[:blank:]]+))+)([^[:blank:]|<-].*)?$/, m)) {
			term = trim(m[1])
			desc = trim(m[8])
			gsub(/[[:blank:]]+\|[[:blank:]]+/, " | ", term)
			gsub(/</, "\\<", term)
			gsub(/>/, "\\>", term)
			print_table_row("**" term "**", desc, "", 0)
		} else {
			print_table_row(text, "", "", 0)
		}
	}
}

function print_env_table(kind, idx)
{
	print_param_table(kind, idx, "Variable", 0)
}

function decorate_block_title(title)
{
	if (no_emoji) return title
	if (title == "Arguments") return "🧾 Arguments"
	if (title == "Options") return "🎛️ Options"
	if (title == "Environment variables") return "🌍 Environment variables"
	if (title == "Exit codes") return "🚦 Exit codes"
	if (title == "Input on stdin") return "📥 Input on stdin"
	if (title == "Output on stdout") return "📤 Output on stdout"
	if (title == "Output on stderr") return "📤 Output on stderr"
	if (title == "See also") return "🔗 See also"
	if (title == "Notes") return "📝 Notes"
	if (title == "Variable sets") return "🧩 Variable sets"
	return title
}

function print_bullet_list(kind, idx, formatter, i, key, text, m)
{
	for (i = 1; i <= counts[kind, idx]; i++) {
		key = kind SUBSEP idx SUBSEP i
		text = items[key]
		if (formatter == "see") {
			print "- " render_link(text)
		} else if (formatter == "exit" && match(text, /^([^[:space:]]+)[[:space:]]+(.*)$/, m)) {
			print "- `" m[1] "`: " m[2]
		} else if (formatter == "set" && match(text, /^([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$/, m)) {
			# `@set NAME type description`, spelled like `@arg` and `@env`.
			print "- **`" m[1] "`** (" m[2] "): " m[3]
		} else if (formatter == "set" && match(text, /^([^[:space:]]+)[[:space:]]+(.*)$/, m)) {
			print "- **`" m[1] "`**: " m[2]
		} else {
			print "- " text
		}
	}
}

function print_function(idx, fn_desc_key, fn_heading_level, starts_new_section, i)
{
	starts_new_section = (fn_section[idx] != "" && fn_section[idx] != last_printed_section)
	if (printed_reference_count > 0 && !starts_new_section) {
		print "---"
		print ""
	}
	if (fn_section[idx] != "" && fn_section[idx] != last_printed_section) {
		print_anchor(github_anchor(fn_section[idx]))
		print "### " ic("🧩") fn_section[idx]
		print ""
		last_printed_section = fn_section[idx]
	}
	fn_heading_level = (fn_section[idx] != "" ? "####" : "###")
	print fn_heading_level " `" fn_name[idx] "`"
	print ""
	if (line_links && source_file() != "") {
		print "_Source: [" source_file() ":" fn_nr[idx] "](../" source_file() "#L" fn_nr[idx] ")_"
		print ""
	}
	if (counts["fn_deprecated", idx] > 0) {
		print "> " ic("⚠️") "**Deprecated**"
		print ">"
		for (i = 1; i <= counts["fn_deprecated", idx]; i++) {
			print "> " items["fn_deprecated", idx, i]
		}
		print ""
	}
	if (fn_since[idx] != "") {
		print "_Since: " fn_since[idx] "_"
		print ""
	}
	fn_desc_key = "fn_desc" SUBSEP idx
	if (fn_desc_key in texts) {
		print_multiline(dedent_doc(texts[fn_desc_key] ""))
		print ""
	}
	if (counts["fn_warning", idx] > 0) {
		print "> " ic("⚠️") "**Warning**"
		print ">"
		for (i = 1; i <= counts["fn_warning", idx]; i++) {
			print "> " (counts["fn_warning", idx] > 1 ? "- " : "") items["fn_warning", idx, i]
		}
		print ""
	}
	if (counts["fn_example", idx] > 0) {
		if (counts["fn_example", idx] == 1) {
			print "**" ic("🧪") "Example**"
		} else {
			print "**" ic("🧪") "Examples**"
		}
		print ""
		for (i = 1; i <= counts["fn_example", idx]; i++) {
			print "```bash"
			print dedent(items["fn_example", idx, i])
			print "```"
			print ""
		}
	}
	if (fn_noargs[idx]) {
		print "_Function has no arguments._"
		print ""
	}
	print_list("fn_option", idx, "Options", "option")
	print_list("fn_arg", idx, "Arguments", "arg")
	print_list("fn_env", idx, "Environment variables", "env")
	print_list("fn_set", idx, "Variable sets", "set")
	print_list("fn_note", idx, "Notes", "bullet")
	print_list("fn_stdin", idx, "Input on stdin", "bullet")
	print_list("fn_stdout", idx, "Output on stdout", "bullet")
	print_list("fn_stderr", idx, "Output on stderr", "bullet")
	print_list("fn_exitcode", idx, "Exit codes", "exit")
	print_list("fn_see", idx, "See also", "see")
	printed_reference_count++
}

function print_list(kind, idx, title, formatter, i, key, text)
{
	if (counts[kind, idx] == 0) {
		return
	}
	print "**" decorate_block_title(title) "**"
	print ""
	if (formatter == "arg") {
		print_arg_table(kind, idx)
	} else if (formatter == "option") {
		print_option_table(kind, idx)
	} else if (formatter == "env") {
		print_env_table(kind, idx)
	} else if (formatter == "set") {
		print_bullet_list(kind, idx, "set")
	} else if (formatter == "see") {
		print_bullet_list(kind, idx, "see")
	} else if (formatter == "exit") {
		print_bullet_list(kind, idx, "exit")
	} else {
		print_bullet_list(kind, idx, "")
	}
	print ""
}

function print_multiline(text, n, arr, i)
{
	n = split(text, arr, /\n/)
	for (i = 1; i <= n; i++) {
		print arr[i]
	}
}

function example_rel(path, rel)
{
	rel = path
	if (substr(rel, 1, length(example_dir) + 1) == example_dir "/") {
		rel = substr(rel, length(example_dir) + 2)
	} else {
		sub(/^.*\//, "", rel)
	}
	return example_prefix "/" rel
}

function print_related_examples(cmd, path, found, content, line, i, j, skip, rel_path)
{
	if (example_dir == "") {
		return
	}
	cmd = "find " shell_quote(example_dir) " -maxdepth 1 -type f -name '*.sh' | sort"
	found = 0
	while ((cmd | getline path) > 0) {
		content = ""
		while ((getline line < path) > 0) {
			content = content line "\n"
		}
		close(path)
		for (i = 1; i <= fn_count; i++) {
			if (mentions(content, fn_name[i])) {
				rel_path = example_rel(path)
				skip = 0
				for (j = 1; j <= counts["module_see", 0]; j++) {
					if (normalize_ref(items["module_see", 0, j]) == rel_path) {
						skip = 1
						break
					}
				}
				if (!skip) {
					related[rel_path] = 1
					found = 1
				}
				break
			}
		}
	}
	close(cmd)
	if (! found) {
		return
	}
	print "## " ic("🧪") "Related examples"
	print ""
	# Unordered array traversal would make the generated document depend on
	# awk's internal hashing, which is exactly the kind of spurious diff a
	# `--check` run reports as stale documentation.
	PROCINFO["sorted_in"] = "@ind_str_asc"
	for (rel_path in related) {
		print "- " render_link(rel_path)
	}
	delete PROCINFO["sorted_in"]
}

# Whether `content` uses `name` as a whole word. A plain substring test would
# relate an example calling `strings::trim_all` to `strings::trim` as well.
function mentions(content, name, pos, at, before, after)
{
	pos = 1
	while ((at = index(substr(content, pos), name)) > 0) {
		at += pos - 1
		before = (at == 1 ? "" : substr(content, at - 1, 1))
		after = substr(content, at + length(name), 1)
		if (before !~ /[[:alnum:]_:.-]/ && after !~ /[[:alnum:]_:.-]/) {
			return 1
		}
		pos = at + 1
	}
	return 0
}

function shell_quote(text)
{
	gsub(/'/, "'\\''", text)
	return "'" text "'"
}

function print_tips_section(i, j, has_tips)
{
	has_tips = counts["module_tip", 0] > 0
	if (! has_tips) {
		for (i = 1; i <= fn_count; i++) {
			if (counts["fn_tip", i] > 0) {
				has_tips = 1
				break
			}
		}
	}
	if (! has_tips) {
		return
	}
	print_anchor("tips")
	print "## " ic("💡") "Tips"
	print ""
	if (counts["module_tip", 0] > 0) {
		for (j = 1; j <= counts["module_tip", 0]; j++) {
			print "- " items["module_tip", 0, j]
		}
		print ""
	}
	for (i = 1; i <= fn_count; i++) {
		if (counts["fn_tip", i] == 0) {
			continue
		}
		# A heading here would claim the function's anchor before the reference
		# does, since GitHub numbers repeated headings in document order: every
		# link to the function would then land in the Tips section.
		print "**" render_function_link(fn_name[i]) "**"
		print ""
		for (j = 1; j <= counts["fn_tip", i]; j++) {
			print "- " items["fn_tip", i, j]
		}
		print ""
	}
}

function print_quick_links(i, nav, section_nav, section_name, has_tips)
{
	nav = ""
	has_tips = counts["module_tip", 0] > 0
	if (! has_tips) {
		for (i = 1; i <= fn_count; i++) {
			if (counts["fn_tip", i] > 0) {
				has_tips = 1
				break
			}
		}
	}
	nav = append_nav_link(nav, "Overview", "Overview")
	if (texts["module_usage", 0] != "") {
		nav = append_nav_link(nav, "Usage", "Usage")
	}
	if (has_command_line()) {
		nav = append_nav_link(nav, "Command line", "Command line")
	}
	if (counts["module_see", 0] > 0) {
		nav = append_nav_link(nav, "See also", "See also")
	}
	if (has_tips) {
		nav = append_nav_link(nav, "Tips", "Tips")
	}
	if (fn_count > 0) {
		nav = append_nav_link(nav, "Reference", "Reference")
	}
	if (nav != "") {
		# A document generated from stdin without `@file` has no source path
		# to point at, and a link to `src/` alone points at the wrong thing.
		if (module_file != "" || source_path != "") {
			print "> " ic("🧭") "Source: " render_source_link()
			print ">"
		}
		print "> Jump to: " nav
	}
	section_nav = ""
	for (i = 1; i <= fn_count; i++) {
		section_name = fn_section[i]
		if (section_name == "" || seen_sections[section_name]) {
			continue
		}
		seen_sections[section_name] = 1
		section_nav = append_nav_link(section_nav, section_name, section_name)
	}
	delete seen_sections
	if (section_nav != "") {
		print ">"
		print "> Reference sections: " section_nav
	}
	if (nav != "" || section_nav != "") {
		print ""
	}
}

function push_item(kind, idx, value, key)
{
	counts[kind, idx]++
	key = kind SUBSEP idx SUBSEP counts[kind, idx]
	items[key] = value
}

function render_module(i, desc, intro, usage, rest, n, j, line, in_rest)
{
	last_printed_section = ""
	printed_reference_count = 0
	if (module_file != "") {
		print "# " module_file
		print ""
	}
	if (module_brief != "") {
		print module_brief
		print ""
	}
	if (module_since != "") {
		print "_Since: " module_since "_"
		print ""
	}
	print_quick_links()
	if (counts["module_deprecated", 0] > 0) {
		print "> " ic("⚠️") "**Deprecated module**"
		print ">"
		for (i = 1; i <= counts["module_deprecated", 0]; i++) {
			print "> " items["module_deprecated", 0, i]
		}
		print ""
	}
	print_anchor("overview")
	print "## " ic("✨") "Overview"
	print ""
	desc = texts["module_desc", 0]
	if (desc != "") {
		desc = dedent_doc(desc)
		intro = ""
		rest = ""
		in_rest = 0
		n = split(desc, desc_lines, /\n/)
		for (j = 1; j <= n; j++) {
			line = desc_lines[j]
			if (! in_rest && (line ~ /^###[[:space:]]/ || line ~ /^##[[:space:]]/)) {
				in_rest = 1
			}
			if (in_rest) {
				rest = rest (rest == "" ? "" : "\n") line
			} else {
				intro = intro (intro == "" ? "" : "\n") line
			}
		}
		# The blank line that separated the intro from the first heading is
		# still attached to it; printing it as well as the separator below
		# would leave two blank lines in the document.
		sub(/\n+$/, "", intro)
		if (intro != "") {
			print_multiline(intro)
			print ""
		}
	}
	if (counts["module_globals", 0] > 0) {
		print "### " ic("🧰") "Module variables"
		print ""
		for (i = 1; i <= counts["module_globals", 0]; i++) {
			print "- " items["module_globals", 0, i]
		}
		print ""
	}
	if (counts["module_env", 0] > 0) {
		print "### " ic("🌍") "Environment"
		print ""
		print_env_table("module_env", 0)
		print ""
	}
	if (fn_count > 0) {
		print "### " ic("🚀") "Highlights"
		print ""
		for (i = 1; i <= fn_count; i++) {
			# Reading `texts` directly would create an empty description, which
			# the reference then prints as an extra blank line.
			line = (("fn_desc" SUBSEP i) in texts ? summary(texts["fn_desc", i]) : "")
			print "- " render_function_link(fn_name[i]) (line == "" ? "" : " \342\200\224 " line)
		}
		print ""
	}
	sub(/\n+$/, "", rest)
	if (rest != "") {
		print_multiline(rest)
		print ""
	}
	usage = texts["module_usage", 0]
	sub(/\n+$/, "", usage)
	if (usage != "") {
		print_anchor("usage")
		print "## " ic("🚀") "Usage"
		print ""
		print_multiline(dedent_doc(usage))
		print ""
	}
	print_command_line()
	if (counts["module_see", 0] > 0) {
		print_anchor("see-also")
		print "## " ic("🔗") "See also"
		print ""
		for (i = 1; i <= counts["module_see", 0]; i++) {
			line = items["module_see", 0, i]
			print "- " render_link(line)
		}
		print ""
	}
	print_tips_section()
	if (fn_count > 0) {
		print_anchor("reference")
		print "## " ic("📚") "Reference"
		print ""
		for (i = 1; i <= fn_count; i++) {
			print_function(i)
			if (i < fn_count) {
				print ""
			}
		}
	}
	# Every section above ends with a blank line of its own, so these two must
	# not add a second one.
	if (counts["module_license", 0] > 0) {
		print "## " ic("📄") "License"
		print ""
		for (i = 1; i <= counts["module_license", 0]; i++) {
			print "- " items["module_license", 0, i]
		}
	}
	print_related_examples()
}

function summary(text, out)
{
	out = text
	gsub(/\n+/, " ", out)
	gsub(/[[:space:]]+/, " ", out)
	return trim(out)
}

function trim(s)
{
	sub(/^[[:space:]]+/, "", s)
	sub(/[[:space:]]+$/, "", s)
	return s
}
