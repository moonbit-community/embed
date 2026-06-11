///|
test "sanitize identifier" {
  assert_eq(sanitize_identifier("demo/a-b.mbt"), "demo_a_b_mbt")
  assert_eq(sanitize_identifier("123-data.json"), "v_123_data_json")
  assert_eq(sanitize_identifier("..."), "bundle")
  assert_eq(safe_identifier("let"), "let_")
  assert_eq(fixture_type_name("sample-dir"), "SampleDirFixture")
}

///|
test "render single file bundle" {
  let rendered = render_bundle("data-file.txt", false, [
    ("data-file.txt", "one\ntwo"),
  ])
  assert_true(rendered.contains("pub let data_file_txt : String ="))
  assert_true(rendered.contains("  #|one\n  #|two\n"))
  assert_eq(rendered.contains("struct"), false)
}

///|
test "render directory fixture" {
  let files = [("a.txt", "one\ntwo"), ("a-txt", "three")]
  let rendered = render_bundle("sample-dir", true, files)
  assert_true(rendered.contains("pub struct SampleDirFixture {"))
  assert_true(rendered.contains("  a_txt : String\n"))
  assert_true(rendered.contains("  a_txt_2 : String\n"))
  assert_true(rendered.contains("pub let sample_dir : SampleDirFixture = {"))
  assert_true(rendered.contains("  a_txt: (\n    #|one\n    #|two\n  ),"))
}
