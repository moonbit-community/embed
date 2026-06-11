# embed-files

Embed a file or all files under a directory into one MoonBit source file.

```sh
moon runwasm moonbit-community/embed-files ./fixtures -o fixtures_bundle.mbt
```

The `-o <output.mbt>` option is required.
The output directory must already exist.
Use `--prune <path>` or `-p <path>` to skip files or directories relative to
the input directory. The option can be repeated:

```sh
moon runwasm moonbit-community/embed-files ./fixtures -o fixtures_bundle.mbt --prune _build --prune cache/tmp.bin
```

For a directory input like `./fixtures`, files become fields on a generated
fixture record, and subdirectories become nested fixture records. UTF-8 text
files become `String` fields, and binary files become `Bytes` fields. File
contents are emitted as private top-level constants so the final fixture value
stays short:

```moonbit
let _embed_files_readme_md : String =
  #|...

let _embed_files_image_png : Bytes =
  ([
    0xFF, 0xAA,
  ] : Bytes)

pub struct FixturesFixture {
  readme_md : String
  nested : NestedFixture
}

pub struct NestedFixture {
  image_png : Bytes
}

pub let fixtures : FixturesFixture = {
  readme_md: _embed_files_readme_md,
  nested: {
    image_png: _embed_files_image_png,
  },
}
```

For a single file input like `./fixtures/readme.md`, the generated output has
one top-level constant:

```moonbit
let _embed_files_readme_md : String =
  #|...

pub let readme_md : String = _embed_files_readme_md
```

For a single binary file input, the generated constant has type `Bytes`:

```moonbit
let _embed_files_image_png : Bytes =
  ([
    0xFF, 0xAA,
  ] : Bytes)

pub let image_png : Bytes = _embed_files_image_png
```
