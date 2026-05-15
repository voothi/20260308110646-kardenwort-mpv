#!/usr/bin/env python3
"""
Deploy kardenwort-mpv payload into mpv config directory.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Deploy kardenwort-mpv distribution")
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("."),
        help="Path to repo root or built zip artifact",
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path.home() / "AppData" / "Roaming" / "mpv",
        help="Destination mpv config directory",
    )
    parser.add_argument(
        "--mode",
        choices=("copy", "junction"),
        default="copy",
        help="Deploy mode: copy files or create a directory junction",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Allow replacing existing target content",
    )
    return parser.parse_args()


def ensure_absent(path: Path, force: bool) -> None:
    if not path.exists():
        return
    if not force:
        raise FileExistsError(f"Target already exists: {path}. Re-run with --force to replace it.")
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def extract_zip_to_temp(zip_path: Path) -> Path:
    temp_dir = Path(tempfile.mkdtemp(prefix="kardenwort-deploy-"))
    with zipfile.ZipFile(zip_path, "r") as archive:
        archive.extractall(temp_dir)

    candidates = [p for p in temp_dir.iterdir() if p.is_dir()]
    if len(candidates) != 1:
        raise RuntimeError(
            f"Expected one root folder in {zip_path.name}, found {len(candidates)} entries."
        )
    return candidates[0]


def copy_tree(source_dir: Path, target_dir: Path) -> None:
    target_dir.mkdir(parents=True, exist_ok=True)
    for rel_path in INCLUDE_PATHS:
        src = source_dir / rel_path
        if not src.exists():
            raise FileNotFoundError(f"Missing required path in payload: {src}")
        dst = target_dir / rel_path
        if src.is_dir():
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)


def create_junction(source: Path, target: Path) -> None:
    subprocess.run(
        ["cmd", "/c", "mklink", "/J", str(target), str(source)],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    target = args.target.resolve()

    if args.mode == "junction":
        if source.suffix.lower() == ".zip":
            raise ValueError("Junction mode requires --source to be a directory, not a zip file.")
        ensure_absent(target, args.force)
        target.parent.mkdir(parents=True, exist_ok=True)
        create_junction(source, target)
        print(f"Junction created: {target} -> {source}")
        return 0

    if source.suffix.lower() == ".zip":
        payload_root = extract_zip_to_temp(source)
    else:
        payload_root = source

    ensure_absent(target, args.force)
    copy_tree(payload_root, target)
    print(f"Deployed by copy to: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
