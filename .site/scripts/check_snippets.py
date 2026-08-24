#!/usr/bin/env python3
"""Validate code-region imports used by the Docusaurus documentation."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


FILE_PATTERN = re.compile(r"file=([^\s]+)")
REGION_START = re.compile(r"^\s*(?://|#|<!--)\s*#region\s+(.+?)\s*(?:-->)?\s*$")
REGION_END = re.compile(r"^\s*(?://|#|<!--)\s*#endregion(?:\s+.*?)?\s*(?:-->)?\s*$")


def extract_region(source: str, name: str) -> str:
    lines = source.splitlines()
    start = None
    for index, line in enumerate(lines):
        match = REGION_START.match(line)
        if match and match.group(1) == name:
            start = index + 1
            break
    if start is None:
        raise ValueError(f'region "{name}" not found')

    for index in range(start, len(lines)):
        if REGION_END.match(lines[index]):
            return "\n".join(lines[start:index])
    return "\n".join(lines[start:])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-lines", type=int, default=40)
    args = parser.parse_args()

    site_root = Path(__file__).resolve().parents[1]
    docs_root = site_root / "docs"
    references = 0
    missing: list[str] = []
    oversized: list[tuple[str, int]] = []
    max_size = 0

    for doc in sorted(docs_root.rglob("*.mdx")):
        for line_number, line in enumerate(doc.read_text().splitlines(), 1):
            match = FILE_PATTERN.search(line)
            if not match:
                continue
            references += 1
            reference = match.group(1)
            path, separator, region = reference.partition("#")
            source_path = (doc.parent / path).resolve()
            label = f"{doc.relative_to(site_root)}:{line_number} -> {reference}"
            if not source_path.is_file():
                missing.append(f"{label} (file not found)")
                continue
            try:
                source = source_path.read_text()
                snippet = extract_region(source, region) if separator else source
            except ValueError as error:
                missing.append(f"{label} ({error})")
                continue
            size = sum(bool(line.strip()) for line in snippet.splitlines())
            max_size = max(max_size, size)
            if size > args.max_lines:
                oversized.append((label, size))

    print(f"Snippet references: {references}")
    print(f"Missing references: {len(missing)}")
    print(f"Max snippet size (non-blank lines): {max_size}")
    print(f"Snippets over {args.max_lines} lines: {len(oversized)}")
    for issue in missing + [f"{label} ({size} lines)" for label, size in oversized]:
        print(f"- {issue}")

    return 1 if missing or oversized else 0


if __name__ == "__main__":
    sys.exit(main())
