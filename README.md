# quick-bundle

Bundle all UTF-8 files under a directory into one MoonBit source file.

```sh
moon runwasm moonbit-community/quick-bundle ./fixtures
```

For `./fixtures`, the generated file is `fixtures_bundle.mbt`. Each bundled
file becomes a top-level constant:

```moonbit
let fixtures_readme_md : String =
  #|...
```
