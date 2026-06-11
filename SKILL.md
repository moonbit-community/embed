---
name: embed-files
description: "Embed files into a generated MoonBit source file."
---

# embed-files

Use this skill when a MoonBit project needs small fixture files, examples,
templates, or other static assets checked in as generated MoonBit source.

## Workflow

1. Choose the exact file or directory to embed. Do not embed build outputs,
   dependency caches, secrets, or large generated trees unless the user
   explicitly asks for them.
2. Choose an output `.mbt` path in the package that should own the embedded
   data. The output path is required; missing parent directories are created.
3. Run the tool:

```sh
moon runwasm moonbit-community/embed-files <path> -o <output.mbt> [--prune <path> ...]
```

Use repeated `--prune <path>` / `-p <path>` options for paths relative to the
input directory:

```sh
moon runwasm moonbit-community/embed-files ./fixtures -o test/fixtures_bundle.mbt --prune _build --prune .mooncakes
```

4. Inspect the generated file before handoff. Check that the public names are
   usable for the surrounding code and that no unintended files were embedded.
5. Run the package or module checks that cover the output file, normally
   `moon check` and the relevant `moon test`.

## Guidance

- Prefer embedding stable, small inputs used by tests, examples, or code
  generation. Keep large assets as external files unless embedding is
  intentional.
- Prune common project noise such as `_build`, `.mooncakes`, `tmp`,
  `node_modules`, coverage output, downloaded dependencies, and editor caches.
- Binary files are supported, but inspect the generated size before committing.
- Directory inputs are recursive and keep their nested structure in the
  generated MoonBit API.
- If generated names collide or are awkward, rename the source files or choose a
  narrower input directory, then regenerate.
