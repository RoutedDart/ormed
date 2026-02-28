#!/usr/bin/env python3
"""Check docs/README dependency snippets against current package versions.

Default behavior is non-blocking (exit 0), so it can be used as an advisory
check locally and in CI. Use --fail-on-drift to make it blocking.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Iterable

PUBSPEC_NAME_RE = re.compile(r"^name:\s*([A-Za-z0-9_]+)\s*$")
PUBSPEC_VERSION_RE = re.compile(
    r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.\-]+)?)\s*$"
)
SEMVER_RE = re.compile(r"([0-9]+)\.([0-9]+)\.([0-9]+)")
DEP_LINE_RE = re.compile(r"^\s*([A-Za-z0-9_]+)\s*:\s*([^\s#]+)")

DEFAULT_MANIFEST_GLOBS = ("packages/*/pubspec.yaml",)
DEFAULT_TARGET_GLOBS = (
    "README.md",
    "packages/*/README.md",
    ".site/docs/**/*.mdx",
    ".site/docs/**/*.md",
    ".site/examples/**/*.yaml",
    ".site/examples/**/*.yml",
)


def _iter_target_files(root: Path, globs: Iterable[str]) -> list[Path]:
    seen: set[Path] = set()
    files: list[Path] = []
    for pattern in globs:
        for path in root.glob(pattern):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            files.append(resolved)
    return sorted(files)


def _load_package_versions(
    root: Path, manifest_globs: Iterable[str], package_name_regex: str
) -> dict[str, tuple[int, int, int]]:
    versions: dict[str, tuple[int, int, int]] = {}
    name_pattern = re.compile(package_name_regex)
    manifests = _iter_target_files(root, manifest_globs)
    for pubspec in manifests:
        name: str | None = None
        version: str | None = None
        for line in pubspec.read_text(encoding="utf-8").splitlines():
            if name is None:
                match = PUBSPEC_NAME_RE.match(line.strip())
                if match:
                    name = match.group(1)
            if version is None:
                match = PUBSPEC_VERSION_RE.match(line.strip())
                if match:
                    version = match.group(1)
            if name and version:
                break
        if not (name and version):
            continue
        if not name_pattern.search(name):
            continue
        semver_match = SEMVER_RE.search(version)
        if not semver_match:
            continue
        versions[name] = tuple(int(semver_match.group(i)) for i in (1, 2, 3))
    return versions


def _scan_outdated_snippets(
    root: Path,
    package_versions: dict[str, tuple[int, int, int]],
    target_globs: Iterable[str],
) -> list[str]:
    outdated: list[str] = []
    for target in _iter_target_files(root, target_globs):
        display_target: str
        try:
            display_target = str(target.relative_to(root))
        except ValueError:
            display_target = str(target)
        for lineno, line in enumerate(
            target.read_text(encoding="utf-8").splitlines(), start=1
        ):
            match = DEP_LINE_RE.match(line)
            if not match:
                continue
            package = match.group(1)
            if package not in package_versions:
                continue
            raw_constraint = match.group(2).strip("'\"")
            semver_match = SEMVER_RE.search(raw_constraint)
            if not semver_match:
                continue
            found = tuple(int(semver_match.group(i)) for i in (1, 2, 3))
            expected = package_versions[package]
            if found < expected:
                outdated.append(
                    f"{display_target}:{lineno} -> {package}: {raw_constraint} "
                    f"(current: {expected[0]}.{expected[1]}.{expected[2]})"
                )
    return outdated


def _write_report(report_file: Path, outdated: list[str], report_title: str) -> None:
    if outdated:
        lines = [f"### {report_title}", ""]
        limit = 200
        for item in outdated[:limit]:
            lines.append(f"- `{item}`")
        if len(outdated) > limit:
            lines.append(f"- ... and {len(outdated) - limit} more")
        content = "\n".join(lines) + "\n"
    else:
        content = f"### {report_title}\n\n- None.\n"
    report_file.write_text(content, encoding="utf-8")


def _write_github_output(status: str, outdated_count: int, report_file: Path) -> None:
    output_path = os.getenv("GITHUB_OUTPUT")
    if not output_path:
        return
    with open(output_path, "a", encoding="utf-8") as output:
        output.write(f"status={status}\n")
        output.write(f"outdated_count={outdated_count}\n")
        output.write(f"report_file={report_file}\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check snippet dependency versions against package versions."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Repository root to scan (default: .)",
    )
    parser.add_argument(
        "--manifest-glob",
        action="append",
        default=[],
        help=(
            "Glob pattern for package manifests containing `name:` and `version:` "
            "(repeatable). Default: packages/*/pubspec.yaml"
        ),
    )
    parser.add_argument(
        "--target-glob",
        action="append",
        default=[],
        help=(
            "Glob pattern for snippet-bearing files to scan (repeatable). "
            "Defaults include root README, package READMEs, and .site docs/examples."
        ),
    )
    parser.add_argument(
        "--package-name-regex",
        default="^ormed",
        help=(
            "Regex for package names to include from manifests "
            "(default: ^ormed)."
        ),
    )
    parser.add_argument(
        "--report-file",
        default="snippet-version-report.md",
        help="Markdown report output path (default: snippet-version-report.md)",
    )
    parser.add_argument(
        "--report-title",
        default="Outdated snippet references",
        help="Report heading text (default: Outdated snippet references)",
    )
    parser.add_argument(
        "--fail-on-drift",
        action="store_true",
        help="Exit with code 1 when outdated snippets are found.",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    manifest_globs = args.manifest_glob or list(DEFAULT_MANIFEST_GLOBS)
    target_globs = args.target_glob or list(DEFAULT_TARGET_GLOBS)
    package_versions = _load_package_versions(
        root,
        manifest_globs=manifest_globs,
        package_name_regex=args.package_name_regex,
    )
    outdated = _scan_outdated_snippets(
        root,
        package_versions=package_versions,
        target_globs=target_globs,
    )

    report_file = (root / args.report_file).resolve()
    report_file.parent.mkdir(parents=True, exist_ok=True)
    _write_report(report_file, outdated, report_title=args.report_title)

    status = "outdated" if outdated else "clean"
    _write_github_output(
        status=status, outdated_count=len(outdated), report_file=report_file
    )

    if outdated:
        print(f"Found {len(outdated)} outdated package version snippet(s).")
        print(f"Report written to: {report_file}")
    else:
        print("No outdated package versions found in snippets.")
        print(f"Report written to: {report_file}")

    if args.fail_on_drift and outdated:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
