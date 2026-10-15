#!/usr/bin/env python3
"""Run with: python3 tests/dot-skills-home.py (no GitHub or npm access)."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "home/.agents/skills/scripts"


def home_sync(script):
    text = (SCRIPTS / script).read_text()
    if script == "add-skill.sh":
        body = text.split("sync_repo_agents_to_home() {\n", 1)[1].split("\n}\n", 1)[0]
        return "sync_repo_agents_to_home() {\n" + body + "\n}\nsync_repo_agents_to_home\n"
    return text.split('echo "Syncing repo agents -> ~/.agents (repo is source of truth)..."', 1)[1].split("\necho\n", 1)[0]


class HomeSyncTests(unittest.TestCase):
    def test_copies_and_stow_links_preserve_repo_files(self):
        for script in ("add-skill.sh", "sync-skills.sh"):
            for layout in ("copies", "skills", "agents", "individual", "external"):
                with self.subTest(script=script, layout=layout), tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    repo = root / "repo/home/.agents"
                    home = root / "home/.agents"
                    (repo / "skills/example/references").mkdir(parents=True)
                    (repo / "skills/scripts").mkdir()
                    files = {
                        ".skill-lock.json": '{"version": 3, "skills": {}}\n',
                        "README.md": "repo README\n",
                        "skills/example/SKILL.md": "skill\n",
                        "skills/example/references/data": "reference\n",
                        "skills/scripts/sentinel": "keep scripts\n",
                    }
                    for name, content in files.items():
                        (repo / name).write_text(content)
                    home.parent.mkdir()
                    preserved = []
                    external = root / "external"
                    external.write_text("external\n")
                    if layout == "agents":
                        home.symlink_to(repo, target_is_directory=True)
                        preserved.append(home)
                    else:
                        home.mkdir()
                        if layout == "skills":
                            (home / "skills").symlink_to(repo / "skills", target_is_directory=True)
                            preserved.append(home / "skills")
                        else:
                            (home / "skills").mkdir()
                            if layout == "individual":
                                (home / "skills/example").symlink_to(repo / "skills/example", target_is_directory=True)
                                preserved.append(home / "skills/example")
                            else:
                                (home / "skills/example").mkdir()
                                (home / "skills/example/SKILL.md").write_text("stale\n")
                        for name in (".skill-lock.json", "README.md"):
                            if layout in ("skills", "individual"):
                                (home / name).symlink_to(repo / name)
                                preserved.append(home / name)
                            elif layout == "external":
                                (home / name).symlink_to(external)
                            else:
                                (home / name).write_text("stale\n")
                    env = {
                        **os.environ,
                        "HOME": str(home.parent),
                        "REPO_AGENTS": str(repo),
                        "REPO_SKILLS": str(repo / "skills"),
                        "REPO_LOCK": str(repo / ".skill-lock.json"),
                        "LOCK_FILE": str(repo / ".skill-lock.json"),
                    }
                    for _ in range(2):
                        result = subprocess.run(
                            ["bash", "-c", "set -euo pipefail\n" + home_sync(script)],
                            env=env, text=True, capture_output=True,
                        )
                        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                        for name, content in files.items():
                            self.assertEqual((repo / name).read_text(), content)
                            if not name.startswith("skills/scripts/"):
                                self.assertEqual((home / name).read_text(), content)
                        for path in preserved:
                            self.assertTrue(path.is_symlink(), str(path))
                        self.assertEqual(external.read_text(), "external\n")


if __name__ == "__main__":
    unittest.main()
