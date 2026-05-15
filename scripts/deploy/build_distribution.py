#!/usr/bin/env python3
"""
Build a distributable archive for kardenwort-mpv.

Default artifact format:
    YYYYMMDDHHMMSS-kardenwort-mpv.zip
"""

from __future__ import annotations

import argparse
from datetime import datetime
import json
from pathlib import Path
import shutil
import tempfile


ARTIFACT_SUFFIX = "kardenwort-mpv"
DEFAULT_INCLUDE_MPV_DIST = False
DEFAULT_MPV_DISTRIBUTION_PATH = Path(r"C:\mpv\mpv-0.39.0-x86_64")
DEFAULT_CONFIG_PATH = Path(__file__).with_name("build_distribution.config.json")
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
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG_PATH,
        help="Optional JSON config path (default: scripts/deploy/build_distribution.config.json)",
    )
    parser.add_argument(
        "--with-mpv-dist",
        action="store_true",
        help="Include a bundled mpv distribution folder in the archive",
    )
    parser.add_argument(
        "--mpv-dist-path",
        type=Path,
        default=None,
        help=r"Path to mpv distribution root (example: C:\mpv\mpv-0.39.0-x86_64)",
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


def load_config(config_path: Path) -> dict:
    if not config_path.exists():
        return {}
    with config_path.open("r", encoding="utf-8") as file:
        data = json.load(file)
    if not isinstance(data, dict):
        raise ValueError(f"Config file must contain a JSON object: {config_path}")
    return data


def resolve_mpv_options(args: argparse.Namespace) -> tuple[bool, Path]:
    config = load_config(args.config.resolve())
    include_mpv = bool(config.get("with_mpv_distribution", DEFAULT_INCLUDE_MPV_DIST))
    if args.with_mpv_dist:
        include_mpv = True

    config_path = config.get("mpv_distribution_path")
    mpv_dist_path = Path(config_path) if config_path else DEFAULT_MPV_DISTRIBUTION_PATH
    if args.mpv_dist_path is not None:
        mpv_dist_path = args.mpv_dist_path

    return include_mpv, mpv_dist_path.resolve()


def copy_mpv_distribution(staging_root: Path, payload_dirname: str, mpv_dist_path: Path) -> None:
    if not mpv_dist_path.exists() or not mpv_dist_path.is_dir():
        raise FileNotFoundError(f"mpv distribution path does not exist or is not a directory: {mpv_dist_path}")

    target = staging_root / payload_dirname / "mpv"
    shutil.copytree(mpv_dist_path, target, dirs_exist_ok=True)


def main() -> int:
    args = parse_args()
    project_root = args.project_root.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    include_mpv_dist, mpv_dist_path = resolve_mpv_options(args)

    zid = current_zid()
    artifact_stem = args.artifact_name or f"{zid}-{ARTIFACT_SUFFIX}"

    with tempfile.TemporaryDirectory(prefix="kardenwort-build-") as temp_dir:
        staging_root = Path(temp_dir)
        copy_payload(project_root, staging_root, artifact_stem)
        if include_mpv_dist:
            copy_mpv_distribution(staging_root, artifact_stem, mpv_dist_path)
        archive_base = output_dir / artifact_stem
        archive_path = shutil.make_archive(str(archive_base), "zip", root_dir=staging_root)

    print(archive_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
