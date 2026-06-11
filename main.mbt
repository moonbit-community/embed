///|
fn[A] die(message : String) -> A {
  @miniio.stderr.write_text("error: " + message + "\n") catch {
    _ => ()
  }
  @miniio.exit(1)
  panic()
}

///|
fn usage() -> String {
  let text =
    #|Usage: embed-files <path>
    #|
    #|Embed a file or all files under a directory into <path>_bundle.mbt.
    #|
  text
}

///|
fn path_join(base : String, child : String) -> String {
  @path.Path::join(base, child).to_string()
}

///|
fn normalize_path(path : String) -> String {
  @path.Path(path).normalize().to_string()
}

///|
fn dir_basename(path : String) -> String {
  @path.Path(path).normalize().basename().to_owned()
}

///|
fn output_path_for_input(input : String) -> String {
  let normalized = normalize_path(input)
  let parent = @path.Path(normalized).dirname().to_string()
  let name = safe_identifier(dir_basename(normalized)) + "_bundle.mbt"
  if parent == "" || parent == "." {
    name
  } else {
    path_join(parent, name)
  }
}

///|
fn is_identifier_char(ch : Char) -> Bool {
  ch.is_ascii_alphabetic() || ch.is_ascii_digit()
}

///|
fn sanitize_identifier(raw : String) -> String {
  let buf = StringBuilder()
  let mut wrote = false
  let mut last_was_separator = false
  for ch in raw.to_array() {
    if is_identifier_char(ch) {
      if !wrote && ch.is_ascii_digit() {
        buf.write_string("v_")
      }
      buf.write_char(ch.to_ascii_lowercase())
      wrote = true
      last_was_separator = false
    } else if wrote && !last_was_separator {
      buf.write_char('_')
      last_was_separator = true
    }
  }
  if !wrote {
    "bundle"
  } else {
    buf.to_string()
  }
}

///|
fn is_reserved_identifier(name : String) -> Bool {
  match name {
    "as"
    | "async"
    | "catch"
    | "const"
    | "derive"
    | "else"
    | "enum"
    | "false"
    | "fn"
    | "for"
    | "guard"
    | "if"
    | "impl"
    | "import"
    | "in"
    | "is"
    | "let"
    | "loop"
    | "match"
    | "mut"
    | "priv"
    | "pub"
    | "raise"
    | "return"
    | "struct"
    | "test"
    | "trait"
    | "true"
    | "try"
    | "type"
    | "while" => true
    _ => false
  }
}

///|
fn safe_identifier(raw : String) -> String {
  let name = sanitize_identifier(raw)
  if is_reserved_identifier(name) {
    name + "_"
  } else {
    name
  }
}

///|
fn fixture_type_name(input : String) -> String {
  let name = safe_identifier(dir_basename(input))
  let buf = StringBuilder()
  let mut next_upper = true
  for ch in name.to_array() {
    if ch == '_' {
      next_upper = true
    } else if next_upper {
      buf.write_char(ch.to_ascii_uppercase())
      next_upper = false
    } else {
      buf.write_char(ch)
    }
  }
  buf.write_string("Fixture")
  buf.to_string()
}

///|
priv enum EmbeddedContent {
  Text(String)
  Binary(Bytes)
}

///|
fn contains_name(names : Array[String], name : String) -> Bool {
  for existing in names {
    if existing == name {
      return true
    }
  }
  false
}

///|
fn unique_name(base : String, names : Array[String]) -> String {
  let mut candidate = base
  let mut suffix = 2
  while contains_name(names, candidate) {
    candidate = base + "_" + suffix.to_string()
    suffix += 1
  }
  names.push(candidate)
  candidate
}

///|
fn relative_path(root : String, file : String) -> String {
  @path.Path(file).relative(base=@path.Path(root)).to_string()
}

///|
fn bytes_has_nul(bytes : Bytes) -> Bool {
  for byte in bytes.to_array() {
    if byte == b'\x00' {
      return true
    }
  }
  false
}

///|
fn read_embedded_content(path : String) -> EmbeddedContent raise {
  let data = @miniio.read_file(path)
  let bytes = data.binary()
  if bytes_has_nul(bytes) {
    Binary(bytes)
  } else {
    Text(data.text()) catch {
      _ => Binary(bytes)
    }
  }
}

///|
fn collect_files(
  root : String,
  dir : String,
  output_path : String,
  files : Array[(String, EmbeddedContent)],
) -> Unit raise {
  let normalized_output = normalize_path(output_path)
  for name in @miniio.readdir(dir, include_hidden=true, sort=true) {
    let child = path_join(dir, name)
    if normalize_path(child) != normalized_output {
      if @miniio.is_dir(child) {
        collect_files(root, child, output_path, files)
      } else {
        let content = read_embedded_content(child)
        files.push((relative_path(root, child), content))
      }
    }
  }
}

///|
fn read_input_entries(
  input : String,
  output_path : String,
) -> (Bool, Array[(String, EmbeddedContent)]) raise {
  let entries : Array[(String, EmbeddedContent)] = []
  if @miniio.is_dir(input) {
    collect_files(
      normalize_path(input),
      normalize_path(input),
      output_path,
      entries,
    )
    (true, entries)
  } else {
    entries.push((dir_basename(input), read_embedded_content(input)))
    (false, entries)
  }
}

///|
fn write_literal_lines(
  buf : StringBuilder,
  content : String,
  indent : String,
) -> Unit {
  for line in content.split("\n") {
    buf.write_string(indent)
    buf.write_string("#|")
    buf.write_view(line)
    buf.write_string("\n")
  }
}

///|
fn content_type_name(content : EmbeddedContent) -> String {
  match content {
    Text(_) => "String"
    Binary(_) => "Bytes"
  }
}

///|
fn write_binary_literal(
  buf : StringBuilder,
  bytes : Bytes,
  indent : String,
) -> Unit {
  let values = bytes.to_array()
  if values.is_empty() {
    buf.write_string(indent)
    buf.write_string("([] : Bytes)\n")
    return
  }
  buf.write_string(indent)
  buf.write_string("([\n")
  for i in 0..<values.length() {
    if i % 12 == 0 {
      buf.write_string(indent)
      buf.write_string("  ")
    }
    buf.write_string("0x")
    buf.write_string(values[i].to_hex().to_upper())
    if i == values.length() - 1 {
      buf.write_string(",\n")
    } else if i % 12 == 11 {
      buf.write_string(",\n")
    } else {
      buf.write_string(", ")
    }
  }
  buf.write_string(indent)
  buf.write_string("] : Bytes)\n")
}

///|
fn write_content_literal(
  buf : StringBuilder,
  content : EmbeddedContent,
  indent : String,
) -> Unit {
  match content {
    Text(text) => write_literal_lines(buf, text, indent)
    Binary(bytes) => write_binary_literal(buf, bytes, indent)
  }
}

///|
fn render_file_bundle(input : String, content : EmbeddedContent) -> String {
  let name = safe_identifier(dir_basename(input))
  let buf = StringBuilder()
  buf.write_string("///| Generated by moonbit-community/embed-files from ")
  buf.write_string(input)
  buf.write_string(".\n\n")
  buf.write_string("///|\n")
  buf.write_string("pub let ")
  buf.write_string(name)
  buf.write_string(" : ")
  buf.write_string(content_type_name(content))
  buf.write_string(" =\n")
  write_content_literal(buf, content, "  ")
  buf.to_string()
}

///|
fn render_dir_bundle(
  dir : String,
  files : Array[(String, EmbeddedContent)],
) -> String {
  let value_name = safe_identifier(dir_basename(dir))
  let type_name = fixture_type_name(dir)
  let names : Array[String] = []
  let buf = StringBuilder()
  buf.write_string("///| Generated by moonbit-community/embed-files from ")
  buf.write_string(dir)
  buf.write_string(".\n\n")
  let fields = files.map(fn(entry) {
    unique_name(safe_identifier(entry.0), names)
  })
  buf.write_string("///|\n")
  buf.write_string("pub struct ")
  buf.write_string(type_name)
  buf.write_string(" {\n")
  for i in 0..<fields.length() {
    buf.write_string("  ")
    buf.write_string(fields[i])
    buf.write_string(" : ")
    buf.write_string(content_type_name(files[i].1))
    buf.write_string("\n")
  }
  buf.write_string("}\n\n")
  buf.write_string("///|\n")
  buf.write_string("pub let ")
  buf.write_string(value_name)
  buf.write_string(" : ")
  buf.write_string(type_name)
  buf.write_string(" = {\n")
  for i in 0..<files.length() {
    buf.write_string("  ")
    buf.write_string(fields[i])
    buf.write_string(": (\n")
    write_content_literal(buf, files[i].1, "    ")
    buf.write_string("  ),\n")
  }
  buf.write_string("}\n")
  buf.to_string()
}

///|
fn render_bundle(
  input : String,
  is_dir : Bool,
  files : Array[(String, EmbeddedContent)],
) -> String {
  if is_dir {
    render_dir_bundle(input, files)
  } else {
    guard files.length() == 1 else {
      die("single-file bundle expected one input file")
    }
    render_file_bundle(input, files[0].1)
  }
}

///|
fn count_label(count : Int) -> String {
  if count == 1 {
    "1 file"
  } else {
    count.to_string() + " files"
  }
}

///|
fn run(input : String) -> Unit raise {
  let output_path = output_path_for_input(input)
  let (is_dir, entries) = read_input_entries(input, output_path)
  let content = render_bundle(input, is_dir, entries)
  @miniio.write_text_file(
    output_path,
    content,
    create_mode=@miniio.CreateMode::CreateOrTruncate,
  )
  @miniio.stdout.write_text(
    "wrote " + output_path + " with " + count_label(entries.length()) + "\n",
  )
}

///|
fn main {
  try {
    let args = @miniio.args_get()
    if args.length() == 2 && (args[1] == "-h" || args[1] == "--help") {
      @miniio.stdout.write_text(usage())
      @miniio.exit(0)
    }
    if args.length() != 2 {
      @miniio.stderr.write_text(usage())
      @miniio.exit(2)
    }
    run(args[1])
  } catch {
    err => die(err.to_string())
  }
}
