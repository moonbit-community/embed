# embed

Embed a file or all files under a directory into one MoonBit source file.

```sh
moonx moonbit-community/embed@latest ./fixtures -o fixtures_bundle.mbt
```

The `-o <output.mbt>` option is required. Missing parent directories for the
output path are created recursively.
Directory traversal includes hidden files. The output file itself is skipped when
it is inside the input directory.

Use `--prune <path>` or `-p <path>` to skip files or directories relative to
the input directory. The option can be repeated:

```sh
moonx moonbit-community/embed@latest ./fixtures -o fixtures_bundle.mbt --prune _build --prune cache/tmp.bin
```

For a directory input like `./fixtures`, files become fields on a generated
fixture record, and subdirectories become nested fixture records. UTF-8 text
files become `String` fields, and binary files become `Bytes` fields. File
contents are emitted as private top-level bindings so the final fixture value
stays short:

```moonbit
let _embed_readme_md : String =
  #|...

let _embed_image_png : Bytes =
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
  readme_md: _embed_readme_md,
  nested: {
    image_png: _embed_image_png,
  },
}
```

For a single file input like `./fixtures/readme.md`, the generated output has
one public top-level binding:

```moonbit
let _embed_readme_md : String =
  #|...

pub let readme_md : String = _embed_readme_md
```

For a single binary file input, the generated binding has type `Bytes`:

```moonbit
let _embed_image_png : Bytes =
  ([
    0xFF, 0xAA,
  ] : Bytes)

pub let image_png : Bytes = _embed_image_png
```

Names are derived from file and directory names: letters are lowercased,
punctuation becomes `_`, and names starting with digits get a `v_` prefix.
Colliding fields within a directory receive numeric suffixes. Generate each
independent bundle in its own package if its file names overlap another bundle;
private top-level bindings also share the package namespace.

Text must be valid UTF-8 without NUL bytes; other files are embedded as `Bytes`.
Use `moonx moonbit-community/embed@0.1.6` to pin this release instead of resolving
`@latest` on each invocation. Run `moonx moonbit-community/embed@latest --help`
for the full CLI usage.

## Development

Use the latest stable MoonBit toolchain and Python 3.10 or newer:

```sh
moon update
moon fmt
moon info --target wasm
moon check --target wasm --warn-list +73+79 --deny-warn
moon check --target native --warn-list +73+79 --deny-warn
moon test --target wasm -j 1
moon test --target native -j 1
python3 tests/test_cli.py
```

The CLI test generates single-file and directory bundles, then compiles and tests
their contents on Wasm and native. To run the local CLI directly:

```sh
moon run --target wasm . -- ./fixtures -o fixtures_bundle.mbt
```
