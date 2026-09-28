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
		parse_header()
	}
	if ($0 ~ /^[[:space:]]*#/) {
		pending_lines[++pending_count] = $0
		next
	}
	if (match($0, /^[[:blank:]]*(function[[:blank:]]+)?([a-zA-Z0-9_\-:\.]+)[[:blank:]]*(\([[:blank:]]*\))?[[:blank:]]*\{/, m)) {
		parse_function_block(m[2])
		pending_count = 0
		delete pending_lines
		function_declaration = ""
		next
	}
	if (match($0, /^[[:blank:]]*(function[[:blank:]]+)?([a-zA-Z0-9_\-:\.]+)[[:blank:]]*(\([[:blank:]]*\))?[[:blank:]]*$/, m)) {
		function_declaration = $0
		next
	}
	if ($0 ~ /^[[:blank:]]*\{/ && function_declaration != "") {
		match(function_declaration, /^[[:blank:]]*(function[[:blank:]]+)?([a-zA-Z0-9_\-:\.]+)[[:blank:]]*(\([[:blank:]]*\))?[[:blank:]]*$/, m)
		parse_function_block(m[2])
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
	render_module()
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

function render_source_link(path)
{
	# Modules live in `src_dir`; the files named by `root_files` sit at the
	# repository root instead.
	if (source_path != "") {
		path = source_path
	} else if (module_file in is_root_file || src_dir == "") {
		path = module_file
	} else {
		path = src_dir "/" module_file
	}
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

function parse_function_block(name, i, line, mode, key, rest, parts, argline)
{
	scan_pending_meta()
	if (pending_internal) {
		pending_section = ""
		return
	}
	fn_count++
	fn_name[fn_count] = name
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
			} else {
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
		if (line ~ /^@file[[:space:]]+/) {
			module_file = trim(substr(line, 7))
			mode = ""
			continue
		}
		if (line ~ /^@brief[[:space:]]+/) {
			module_brief = trim(substr(line, 8))
			mode = ""
			continue
		}
		if (line ~ /^@(name|file)[[:space:]]+/) {
			module_file = trim(substr(line, index(line, " ") + 1))
			mode = ""
			continue
		}
		if (line ~ /^@description/) {
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
			push_item("module_tip", 0, rest)
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
		}
	}
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

function print_arg_table(kind, idx, i, key, text, m)
{
	print "| Name | Type | Description |"
	print "| --- | --- | --- |"
	for (i = 1; i <= counts[kind, idx]; i++) {
		key = kind SUBSEP idx SUBSEP i
		text = items[key]
		if (match(text, /^(\$[^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$/, m)) {
			print_table_row("`" m[1] "`", m[2], m[3], 1)
		} else {
			print_table_row(text, "", "", 1)
		}
	}
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

function print_env_table(kind, idx, i, key, text, m)
{
	print "| Variable | Type | Description |"
	print "| --- | --- | --- |"
	for (i = 1; i <= counts[kind, idx]; i++) {
		key = kind SUBSEP idx SUBSEP i
		text = items[key]
		if (match(text, /^([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$/, m)) {
			print_table_row("**`" m[1] "`**", m[2], m[3], 1)
		} else {
			print_table_row(text, "", "", 1)
		}
	}
}

function decorate_block_title(title)
{
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

function print_function(idx, fn_desc_key, fn_heading_level, starts_new_section)
{
	starts_new_section = (fn_section[idx] != "" && fn_section[idx] != last_printed_section)
	if (printed_reference_count > 0 && !starts_new_section) {
		print "---"
		print ""
	}
	if (fn_section[idx] != "" && fn_section[idx] != last_printed_section) {
		print_anchor(github_anchor(fn_section[idx]))
		print "### 🧩 " fn_section[idx]
		print ""
		last_printed_section = fn_section[idx]
	}
	fn_heading_level = (fn_section[idx] != "" ? "####" : "###")
	print fn_heading_level " `" fn_name[idx] "`"
	print ""
	if (counts["fn_deprecated", idx] > 0) {
		print "> ⚠️ **Deprecated**"
		print ">"
		for (i = 1; i <= counts["fn_deprecated", idx]; i++) {
			print "> " items["fn_deprecated", idx, i]
		}
		print ""
	}
	fn_desc_key = "fn_desc" SUBSEP idx
	if (fn_desc_key in texts) {
		print_multiline(dedent_doc(texts[fn_desc_key] ""))
		print ""
	}
	if (counts["fn_example", idx] > 0) {
		if (counts["fn_example", idx] == 1) {
			print "**🧪 Example**"
		} else {
			print "**🧪 Examples**"
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
			if (index(content, fn_name[i]) > 0) {
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
	print "## 🧪 Related examples"
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
	print "## 💡 Tips"
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
		print "### `" fn_name[i] "`"
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
			print "> 🧭 Source: " render_source_link()
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
	print_quick_links()
	if (counts["module_deprecated", 0] > 0) {
		print "> ⚠️ **Deprecated module**"
		print ">"
		for (i = 1; i <= counts["module_deprecated", 0]; i++) {
			print "> " items["module_deprecated", 0, i]
		}
		print ""
	}
	print_anchor("overview")
	print "## ✨ Overview"
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
		print "### 🧰 Module variables"
		print ""
		for (i = 1; i <= counts["module_globals", 0]; i++) {
			print "- " items["module_globals", 0, i]
		}
		print ""
	}
	if (counts["module_env", 0] > 0) {
		print "### 🌍 Environment"
		print ""
		print_env_table("module_env", 0)
		print ""
	}
	if (fn_count > 0) {
		print "### 🚀 Highlights"
		print ""
		for (i = 1; i <= fn_count; i++) {
			print "- " render_function_link(fn_name[i]) " \342\200\224 " summary(texts["fn_desc", i])
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
		print "## 🚀 Usage"
		print ""
		print_multiline(dedent_doc(usage))
		print ""
	}
	if (counts["module_see", 0] > 0) {
		print_anchor("see-also")
		print "## 🔗 See also"
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
		print "## 📚 Reference"
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
		print "## 📄 License"
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
