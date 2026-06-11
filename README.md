# embed-files

Embed a UTF-8 file or all UTF-8 files under a directory into one MoonBit source
file.

```sh
moon runwasm moonbit-community/embed-files ./fixtures
```

For a directory input like `./fixtures`, the generated file is
`fixtures_bundle.mbt`. Files become fields on a generated fixture record:

```moonbit
pub struct FixturesFixture {
  readme_md : String
}

pub let fixtures : FixturesFixture = {
  readme_md: (
    #|...
  ),
}
```

For a single file input like `./fixtures/readme.md`, the generated file is
`./fixtures/readme_md_bundle.mbt` with one top-level constant:

```moonbit
pub let readme_md : String =
  #|...
```
