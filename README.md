# embed-files

Embed a file or all files under a directory into one MoonBit source file.

```sh
moon runwasm moonbit-community/embed-files ./fixtures -o fixtures_bundle.mbt
```

The `-o <output.mbt>` option is required.

For a directory input like `./fixtures`, files become fields on a generated
fixture record. UTF-8 text files become `String` fields, and binary files become
`Bytes` fields:

```moonbit
pub struct FixturesFixture {
  readme_md : String
  image_png : Bytes
}

pub let fixtures : FixturesFixture = {
  readme_md: (
    #|...
  ),
  image_png: (
    ([
      0xFF, 0xAA,
    ] : Bytes)
  ),
}
```

For a single file input like `./fixtures/readme.md`, the generated output has
one top-level constant:

```moonbit
pub let readme_md : String =
  #|...
```

For a single binary file input, the generated constant has type `Bytes`:

```moonbit
pub let image_png : Bytes =
  ([
    0xFF, 0xAA,
  ] : Bytes)
```
