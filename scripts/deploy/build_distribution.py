#!/usr/bin/env python3
"""
Build a distributable archive for kardenwort-mpv.

Default artifact format:
    YYYYMMDDHHMMSS-kardenwort-mpv.zip
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path
import shutil
import tempfile


ARTIFACT_SUFFIX = "kardenwort-mpv"
INCLUDE_PATHS = [
    "mpv.conf",
    "input.conf",
    "fonts.conf",
    "anki-mapping.ini",
    "scripts",
    "LICENSE",
    "README.md",
    "release-notes.md",
]


def current_zid() -> str:
    return datetime.now().strftime("%Y%m%d%H%M%S")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build kardenwort-mpv distribution zip")
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Project root path (defaults to repository root)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("dist"),
        help="Output directory for distribution archives",
    )
    parser.add_argument(
        "--artifact-name",
        type=str,
        default=None,
        help="Override artifact name (without extension)",
    )
    return parser.parse_args()


def copy_payload(project_root: Path, staging_root: Path, payload_dirname: str) -> None:
    payload_root = staging_root / payload_dirname
    payload_root.mkdir(parents=True, exist_ok=True)

    for rel_path in INCLUDE_PATHS:
        source = project_root / rel_path
        if not source.exists():
            raise FileNotFoundError(f"Missing required path: {source}")

        target = payload_root / rel_path
        if source.is_dir():
            shutil.copytree(source, target, dirs_exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)


def main() -> int:
    args = parse_args()
    project_root = args.project_root.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    zid = current_zid()
    artifact_stem = args.artifact_name or f"{zid}-{ARTIFACT_SUFFIX}"

    with tempfile.TemporaryDirectory(prefix="kardenwort-build-") as temp_dir:
        staging_root = Path(temp_dir)
        copy_payload(project_root, staging_root, artifact_stem)
        archive_base = output_dir / artifact_stem
        archive_path = shutil.make_archive(str(archive_base), "zip", root_dir=staging_root)

    print(archive_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
