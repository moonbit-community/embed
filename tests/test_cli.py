"""Generate fixtures with the CLI and test their values in a fresh module."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def run(*args, cwd=ROOT):
    subprocess.run(args, cwd=cwd, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", help="Test a published moonx package instead of local source")
    args = parser.parse_args()
    cli = ["moonx", args.package] if args.package else ["moon", "run", "--target", "wasm", ".", "--"]
    (ROOT / "_build").mkdir(exist_ok=True)
    temp = Path(tempfile.mkdtemp(prefix="embed-cli-", dir=ROOT / "_build"))
    try:
        fixtures = temp / "fixtures"
        (fixtures / "nested").mkdir(parents=True)
        (fixtures / "cache").mkdir()
        (fixtures / "readme.md").write_bytes("Hello, MoonBit!\n你好\n".encode("utf-8"))
        (fixtures / ".hidden").write_text("included", encoding="utf-8")
        (fixtures / "nested" / "data.bin").write_bytes(bytes([255, 0, 170]))
        (fixtures / "cache" / "ignore.txt").write_text("skip", encoding="utf-8")
        (fixtures / "skip.txt").write_text("skip", encoding="utf-8")
        consumer = temp / "consumer"
        # Output inside the input directory must not embed itself on regeneration.
        bundle = fixtures / "bundle.mbt"
        for _ in range(2):
            run(*cli, str(fixtures), "-o", str(bundle), "--prune", "cache", "-p", "skip.txt")
        generated = bundle.read_text(encoding="utf-8")
        assert "ignore_txt" not in generated and "skip_txt" not in generated
        assert "bundle_mbt" not in generated
        consumer.mkdir()
        shutil.copyfile(bundle, consumer / "bundle.mbt")
        (consumer / "moon.mod").write_text('name = "test/embed_consumer"\n', encoding="utf-8")
        (consumer / "moon.pkg").write_text('', encoding="utf-8")
        run(*cli, str(fixtures / "readme.md"), "-o", str(consumer / "single" / "data.mbt"))
        (consumer / "single" / "moon.pkg").write_text("", encoding="utf-8")
        run(*cli, str(fixtures / "nested" / "data.bin"), "-o", str(consumer / "binary" / "data.mbt"))
        (consumer / "binary" / "moon.pkg").write_text("", encoding="utf-8")
        (consumer / "single" / "values_wbtest.mbt").write_text('test { assert_eq(readme_md, "Hello, MoonBit!\\n你好\\n") }\n', encoding="utf-8")
        (consumer / "binary" / "values_wbtest.mbt").write_text('test { assert_eq(data_bin, ([0xFF, 0x00, 0xAA] : Bytes)) }\n', encoding="utf-8")
        (consumer / "values_wbtest.mbt").write_text('''///|
test "embedded values survive code generation" {
  assert_eq(fixtures.readme_md, "Hello, MoonBit!\\n你好\\n")
  assert_eq(fixtures.hidden, "included")
  assert_eq(fixtures.nested.data_bin, ([0xFF, 0x00, 0xAA] : Bytes))
}
''', encoding="utf-8")
        run("moon", "test", "--target", "wasm", "--deny-warn", cwd=consumer)
        run("moon", "test", "--target", "native", "--release", "--deny-warn", cwd=consumer)
    finally:
        shutil.rmtree(temp)


if __name__ == "__main__":
    main()
