///|
fn[A] die(message : String) -> A {
  @miniio.stderr.write_text("error: \{message}\n") catch {
    _ => ()
  }
  @miniio.exit(1)
  panic()
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
fn dirname(path : String) -> String {
  @path.Path(path).normalize().dirname().to_string()
}

///|
fn dir_basename(path : String) -> String {
  @path.Path(path).normalize().basename().to_owned()
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
    "\{name}_"
  } else {
    name
  }
}

///|
fn fixture_type_name(input : String) -> String {
  let name = safe_identifier(dir_basename(input))
  fixture_type_name_for_name(name)
}

///|
fn fixture_type_name_for_name(name : String) -> String {
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
priv struct BundleDir {
  path : String
  entries : Array[BundleEntry]
}

///|
priv enum BundleEntry {
  EntryFile(String, EmbeddedContent)
  EntryDir(String, BundleDir)
}

///|
priv enum InputBundle {
  SingleFile(EmbeddedContent)
  Directory(BundleDir)
}

///|
priv struct FixtureDir {
  type_name : String
  fields : Array[FixtureField]
}

///|
priv enum FixtureField {
  FixtureFile(String, String, EmbeddedContent)
  FixtureDirField(String, FixtureDir)
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
    candidate = "\{base}_\{suffix}"
    suffix += 1
  }
  names.push(candidate)
  candidate
}

///|
fn unique_type_name(base : String, names : Array[String]) -> String {
  let mut candidate = base
  let mut suffix = 2
  while contains_name(names, candidate) {
    candidate = "\{base}\{suffix}"
    suffix += 1
  }
  names.push(candidate)
  candidate
}

///|
fn normalize_prune_paths(paths : Array[String]) -> Array[String] {
  let normalized : Array[String] = []
  for path in paths {
    let value = normalize_path(path)
    if value != "" && value != "." {
      normalized.push(value)
    }
  }
  normalized
}

///|
fn should_prune_path(
  relative_path : String,
  prune_paths : Array[String],
) -> Bool {
  let path = normalize_path(relative_path)
  for prune_path in prune_paths {
    if path == prune_path {
      return true
    }
  }
  false
}

///|
fn path_exists(path : String) -> Bool raise {
  @miniio.exists(path) catch {
    Noent | Notdir => false
    err => raise err
  }
}

///|
fn ensure_dir(path : String) -> Unit raise {
  let normalized = normalize_path(path)
  if normalized == "" || normalized == "." {
    return
  }
  if path_exists(normalized) {
    guard @miniio.is_dir(normalized) else { raise @miniio.Errno::Notdir }
    return
  }
  let parent = dirname(normalized)
  if parent != normalized {
    ensure_dir(parent)
  }
  @miniio.mkdir(normalized) catch {
    Exist => {
      guard @miniio.is_dir(normalized) else { raise @miniio.Errno::Notdir }
    }
    err => raise err
  }
}

///|
fn ensure_output_parent_dir(output_path : String) -> Unit raise {
  ensure_dir(dirname(output_path))
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
fn collect_dir(
  dir : String,
  output_path : String,
  prune_paths : Array[String],
  relative_dir : String,
) -> BundleDir raise {
  let normalized_output = normalize_path(output_path)
  let entries : Array[BundleEntry] = []
  for name in @miniio.readdir(dir, include_hidden=true, sort=true) {
    let child = path_join(dir, name)
    let relative_child = if relative_dir == "" {
      name
    } else {
      path_join(relative_dir, name)
    }
    if normalize_path(child) != normalized_output &&
      !should_prune_path(relative_child, prune_paths) {
      if @miniio.is_dir(child) {
        entries.push(
          EntryDir(
            name,
            collect_dir(child, output_path, prune_paths, relative_child),
          ),
        )
      } else {
        let content = read_embedded_content(child)
        entries.push(EntryFile(name, content))
      }
    }
  }
  { path: dir, entries }
}

///|
fn read_input_bundle(
  input : String,
  output_path : String,
  prune_paths : Array[String],
) -> InputBundle raise {
  if @miniio.is_dir(input) {
    Directory(collect_dir(normalize_path(input), output_path, prune_paths, ""))
  } else {
    SingleFile(read_embedded_content(input))
  }
}

///|
fn write_literal_lines(
  buf : StringBuilder,
  content : String,
  indent : String,
) -> Unit {
  for line in content.split("\n") {
    buf <+ "\{indent}#|"
    buf.write_view(line)
    buf <+ "\n"
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
    buf <+ "\{indent}([] : Bytes)\n"
    return
  }
  buf <+ "\{indent}([\n"
  for i in 0..<values.length() {
    if i % 12 == 0 {
      buf <+ "\{indent}  "
    }
    buf <+ "0x\{values[i].to_hex().to_upper()}"
    if i == values.length() - 1 {
      buf <+ ",\n"
    } else if i % 12 == 11 {
      buf <+ ",\n"
    } else {
      buf <+ ", "
    }
  }
  buf <+ "\{indent}] : Bytes)\n"
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
  let const_name = "_embed_\{name}"
  let buf = StringBuilder()
  buf <+
    $|// Generated by moonbit-community/embed from \{input}.
    $|
    $|
  write_content_constant(buf, const_name, content)
  buf <+
    $|///|
    $|pub let \{name} : \{content_type_name(content)} = \{const_name}
    $|
  buf.to_string()
}

///|
fn prepare_fixture_dir(
  dir : BundleDir,
  type_names : Array[String],
  const_names : Array[String],
) -> FixtureDir {
  let field_names : Array[String] = []
  let fields : Array[FixtureField] = []
  for entry in dir.entries {
    match entry {
      EntryFile(name, content) => {
        let field_name = unique_name(safe_identifier(name), field_names)
        let const_name = unique_name(
          "_embed_\{safe_identifier(name)}",
          const_names,
        )
        fields.push(FixtureFile(field_name, const_name, content))
      }
      EntryDir(name, child) => {
        let field_name = unique_name(safe_identifier(name), field_names)
        fields.push(
          FixtureDirField(
            field_name,
            prepare_fixture_dir(child, type_names, const_names),
          ),
        )
      }
    }
  }
  {
    type_name: unique_type_name(fixture_type_name(dir.path), type_names),
    fields,
  }
}

///|
fn write_content_constant(
  buf : StringBuilder,
  name : String,
  content : EmbeddedContent,
) -> Unit {
  buf <+
    $|///|
    $|let \{name} : \{content_type_name(content)} =
    $|
  write_content_literal(buf, content, "  ")
  buf <+ "\n"
}

///|
fn write_fixture_constants(buf : StringBuilder, fixture : FixtureDir) -> Unit {
  for field in fixture.fields {
    match field {
      FixtureFile(_, const_name, content) =>
        write_content_constant(buf, const_name, content)
      FixtureDirField(_, child) => write_fixture_constants(buf, child)
    }
  }
}

///|
fn write_fixture_structs(buf : StringBuilder, fixture : FixtureDir) -> Unit {
  buf <+
    $|///|
    $|pub struct \{fixture.type_name} {
    $|
  for field in fixture.fields {
    match field {
      FixtureFile(name, _, content) =>
        buf <+ "  \{name} : \{content_type_name(content)}\n"
      FixtureDirField(name, child) => buf <+ "  \{name} : \{child.type_name}\n"
    }
  }
  buf <+
    $|}
    $|
    $|
  for field in fixture.fields {
    match field {
      FixtureDirField(_, child) => write_fixture_structs(buf, child)
      _ => ()
    }
  }
}

///|
fn write_fixture_value(
  buf : StringBuilder,
  fixture : FixtureDir,
  indent : String,
) -> Unit {
  let field_indent = "\{indent}  "
  buf <+ "{\n"
  for field in fixture.fields {
    match field {
      FixtureFile(name, const_name, _) =>
        buf <+ "\{field_indent}\{name}: \{const_name},\n"
      FixtureDirField(name, child) => {
        buf <+ "\{field_indent}\{name}: "
        write_fixture_value(buf, child, field_indent)
        buf <+ ",\n"
      }
    }
  }
  buf <+ "\{indent}}"
}

///|
fn render_dir_bundle(dir : BundleDir) -> String {
  let value_name = safe_identifier(dir_basename(dir.path))
  let fixture = prepare_fixture_dir(dir, [], [])
  let buf = StringBuilder()
  buf <+
    $|// Generated by moonbit-community/embed from \{dir.path}.
    $|
    $|
  write_fixture_constants(buf, fixture)
  write_fixture_structs(buf, fixture)
  buf <+
    $|///|
    $|pub let \{value_name} : \{fixture.type_name} =
  buf <+ " "
  write_fixture_value(buf, fixture, "")
  buf <+ "\n"
  buf.to_string()
}

///|
fn render_bundle(input : String, bundle : InputBundle) -> String {
  match bundle {
    SingleFile(content) => render_file_bundle(input, content)
    Directory(dir) => render_dir_bundle(dir)
  }
}

///|
fn count_label(count : Int) -> String {
  if count == 1 {
    "1 file"
  } else {
    "\{count} files"
  }
}

///|
fn count_dir_files(dir : BundleDir) -> Int {
  let mut count = 0
  for entry in dir.entries {
    match entry {
      EntryFile(_, _) => count += 1
      EntryDir(_, child) => count += count_dir_files(child)
    }
  }
  count
}

///|
fn count_bundle_files(bundle : InputBundle) -> Int {
  match bundle {
    SingleFile(_) => 1
    Directory(dir) => count_dir_files(dir)
  }
}

///|
fn run(
  input : String,
  output_path : String,
  prune_paths : Array[String],
) -> Unit {
  let normalized_prune_paths = normalize_prune_paths(prune_paths)
  let bundle = read_input_bundle(input, output_path, normalized_prune_paths) catch {
    err => die("failed to read input \{input}: \{err}")
  }
  let content = render_bundle(input, bundle)
  ensure_output_parent_dir(output_path) catch {
    err => die("failed to create output directory for \{output_path}: \{err}")
  }
  @miniio.write_text_file(
    output_path,
    content,
    create_mode=@miniio.CreateMode::CreateOrTruncate,
  ) catch {
    err => die("failed to write output \{output_path}: \{err}")
  }
  @miniio.stdout.write_text(
    "wrote \{output_path} with \{count_label(count_bundle_files(bundle))}\n",
  ) catch {
    err => die("failed to write stdout: \{err}")
  }
}

///|
fn main {
  try {
    let cli = @argparse.Command(
      "embed",
      about="Embed a file or all files under a directory into a MoonBit source file.",
      options=[
        @argparse.OptionArg(
          "output",
          short='o',
          about="Output MoonBit source path.",
          required=true,
        ),
        @argparse.OptionArg(
          "prune",
          short='p',
          about="Relative file or directory path to skip. May be repeated.",
          action=Append,
        ),
      ],
      positionals=[
        @argparse.PositionArg(
          "path",
          about="File or directory to embed.",
          num_args=@argparse.ValueRange::single(),
        ),
      ],
    )
    let matches = cli.parse()
    let input = matches.values["path"][0]
    let output_path = matches.values["output"][0]
    let prune_paths = match matches.values.get("prune") {
      Some(paths) => paths
      None => []
    }
    run(input, output_path, prune_paths)
  } catch {
    err => {
      println(err.to_string())
      @miniio.exit(2)
    }
  }
}
