///|
test "sanitize identifier" {
  assert_eq(sanitize_identifier("demo/a-b.mbt"), "demo_a_b_mbt")
  assert_eq(sanitize_identifier("123-data.json"), "v_123_data_json")
  assert_eq(sanitize_identifier("..."), "bundle")
}

///|
test "render bundle constants" {
  let files = [("a.txt", "one\ntwo"), ("a-txt", "three")]
  let rendered = render_bundle("sample-dir", files)
  assert_true(rendered.contains("let sample_dir_a_txt : String ="))
  assert_true(rendered.contains("let sample_dir_a_txt_2 : String ="))
  assert_true(rendered.contains("  #|one\n  #|two\n"))
}
