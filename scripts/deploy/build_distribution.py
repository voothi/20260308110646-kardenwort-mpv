#!/usr/bin/env python3
"""
Build a distributable archive for kardenwort-mpv.

OS compatibility:
    Primary/validated target: Windows 11.
    Archive creation itself is cross-platform, but the bundled mpv path defaults to Windows.

Default artifact format:
    YYYYMMDDHHMMSS-kardenwort-mpv-lite.zip
    YYYYMMDDHHMMSS-kardenwort-mpv-full-windows-x64.zip
"""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
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


def build_archive(
    project_root: Path,
    output_dir: Path,
    artifact_stem: str,
    include_mpv_dist: bool,
    mpv_dist_path: Path,
) -> str:
    with tempfile.TemporaryDirectory(prefix="kardenwort-build-") as temp_dir:
        staging_root = Path(temp_dir)
        copy_payload(project_root, staging_root, artifact_stem)
        if include_mpv_dist:
            copy_mpv_distribution(staging_root, artifact_stem, mpv_dist_path)
        archive_base = output_dir / artifact_stem
        archive_path = shutil.make_archive(str(archive_base), "zip", root_dir=staging_root)
    return archive_path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_hash_manifest(output_dir: Path, artifact_paths: list[Path], zid: str) -> Path:
    manifest_path = output_dir / f"{zid}-{ARTIFACT_SUFFIX}-sha256.txt"
    lines: list[str] = []
    for artifact_path in artifact_paths:
        lines.append(f"{sha256_file(artifact_path)} *{artifact_path.name}")
    manifest_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return manifest_path


def write_sidecar_hash_file(artifact_path: Path) -> Path:
    sidecar_path = artifact_path.with_name(f"{artifact_path.name}.sha256")
    sidecar_path.write_text(f"{sha256_file(artifact_path)} *{artifact_path.name}\n", encoding="utf-8")
    return sidecar_path


def main() -> int:
    args = parse_args()
    project_root = args.project_root.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    _include_mpv_dist, mpv_dist_path = resolve_mpv_options(args)

    zid = current_zid()
    artifact_base = args.artifact_name or f"{zid}-{ARTIFACT_SUFFIX}"
    lite_stem = f"{artifact_base}-lite"
    full_stem = f"{artifact_base}-full-windows-x64"

    lite_archive = build_archive(
        project_root=project_root,
        output_dir=output_dir,
        artifact_stem=lite_stem,
        include_mpv_dist=False,
        mpv_dist_path=mpv_dist_path,
    )
    full_archive = build_archive(
        project_root=project_root,
        output_dir=output_dir,
        artifact_stem=full_stem,
        include_mpv_dist=True,
        mpv_dist_path=mpv_dist_path,
    )

    lite_archive_path = Path(lite_archive)
    full_archive_path = Path(full_archive)
    manifest_path = write_hash_manifest(output_dir, [lite_archive_path, full_archive_path], zid)
    lite_sidecar = write_sidecar_hash_file(lite_archive_path)
    full_sidecar = write_sidecar_hash_file(full_archive_path)

    print(lite_archive_path)
    print(full_archive_path)
    print(manifest_path)
    print(lite_sidecar)
    print(full_sidecar)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
