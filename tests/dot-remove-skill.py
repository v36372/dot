#!/usr/bin/env python3
"""Run with: python3 tests/dot-remove-skill.py (uses only temporary fixtures)."""
import copy
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RemoveSkillTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dot-remove-skill-test-")
        self.addCleanup(self.tmp.cleanup)
        self.repo = Path(self.tmp.name) / "repo"
        self.home = Path(self.tmp.name) / "home"
        self.repo_agents = self.repo / "home/.agents"
        self.home_agents = self.home / ".agents"
        scripts = self.repo_agents / "skills/scripts"
        scripts.mkdir(parents=True)
        shutil.copy2(ROOT / "dot", self.repo / "dot")
        shutil.copy2(ROOT / "home/.agents/skills/scripts/remove-skill.sh", scripts)
        self.lock = {
            "version": 3,
            "skills": {
                "example": {"skillPath": "upstream/skills/example/SKILL.md", "source": "owner/repo"},
                "keep": {"skillPath": "upstream/skills/keep/SKILL.md", "source": "other/repo"},
            },
            "dismissed": {"notice": True},
        }
        for agents in (self.repo_agents, self.home_agents):
            for name in ("example", "keep", "personal"):
                folder = agents / "skills" / name
                folder.mkdir(parents=True)
                (folder / "SKILL.md").write_text(f"skill: {name}\n")
                (folder / "references").mkdir()
                (folder / "references/notes.md").write_text("notes\n")
        self.write_locks()

    def write_locks(self):
        for agents in (self.repo_agents, self.home_agents):
            (agents / ".skill-lock.json").write_text(json.dumps(self.lock, indent=2) + "\n")

    def run_dot(self, *args, success=True):
        result = subprocess.run(
            [str(self.repo / "dot"), *args],
            env={**os.environ, "HOME": str(self.home)},
            cwd=self.tmp.name,
            text=True,
            capture_output=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def assert_removed(self, name="example", keys=("example",)):
        expected = copy.deepcopy(self.lock)
        for key in keys:
            del expected["skills"][key]
        for agents in (self.repo_agents, self.home_agents):
            self.assertFalse((agents / "skills" / name).exists())
            self.assertFalse((agents / "skills" / name).is_symlink())
            self.assertEqual(json.loads((agents / ".skill-lock.json").read_text()), expected)
            self.assertEqual((agents / "skills/keep/SKILL.md").read_text(), "skill: keep\n")
        self.assertTrue((self.repo_agents / "skills/scripts").is_dir())

    def assert_unchanged(self):
        for agents in (self.repo_agents, self.home_agents):
            self.assertTrue((agents / "skills/example/SKILL.md").is_file())
            self.assertTrue((agents / "skills/keep/SKILL.md").is_file())
            self.assertTrue((agents / "skills/personal/SKILL.md").is_file())
            self.assertEqual(json.loads((agents / ".skill-lock.json").read_text()), self.lock)

    def test_removes_skill_copies_and_locks(self):
        self.run_dot("remove-skill", "example")
        self.assert_removed()

    def test_display_names_windows_paths_and_duplicate_entries(self):
        del self.lock["skills"]["example"]
        self.lock["skills"]["Example Display Name"] = {"skillPath": "upstream\\example\\SKILL.md"}
        self.lock["skills"]["Another Label"] = {"skillPath": "other/example/SKILL.md"}
        self.write_locks()
        self.run_dot("remove-skill", "example")
        self.assert_removed(keys=("Example Display Name", "Another Label"))

    def test_cli_sanitized_name_without_skill_path(self):
        del self.lock["skills"]["example"]
        self.lock["skills"]["Example!"] = {"source": "owner/repo"}
        self.write_locks()
        self.run_dot("remove-skill", "example")
        self.assert_removed(keys=("Example!",))

    def test_cli_sanitized_folder_fallback(self):
        self.lock["skills"]["example"]["skillPath"] = "upstream/different-folder/SKILL.md"
        self.write_locks()
        self.run_dot("remove-skill", "example")
        self.assert_removed()

    def test_existing_upstream_folder_takes_precedence_over_lock_label(self):
        self.lock["skills"]["Example"] = {"skillPath": "upstream/keep/SKILL.md"}
        self.write_locks()
        self.run_dot("remove-skill", "example")
        self.assert_removed()

    def test_orphaned_lock_entry_can_be_removed(self):
        shutil.rmtree(self.repo_agents / "skills/example")
        del self.lock["skills"]["example"]
        self.lock["skills"]["Example Label"] = {"skillPath": "upstream/example/SKILL.md"}
        self.write_locks()
        self.run_dot("remove-skill", "example")
        self.assert_removed(keys=("Example Label",))

    def test_personal_skill_leaves_locks_byte_for_byte_unchanged(self):
        before = (self.repo_agents / ".skill-lock.json").read_bytes()
        self.run_dot("remove-skill", "personal")
        self.assert_removed(name="personal", keys=())
        for agents in (self.repo_agents, self.home_agents):
            self.assertEqual((agents / ".skill-lock.json").read_bytes(), before)

    def test_personal_skill_without_lock_files(self):
        for agents in (self.repo_agents, self.home_agents):
            (agents / ".skill-lock.json").unlink()
        self.run_dot("remove-skill", "personal")
        for agents in (self.repo_agents, self.home_agents):
            self.assertFalse((agents / "skills/personal").exists())
            self.assertFalse((agents / ".skill-lock.json").exists())

    def test_missing_home_agents_is_not_created(self):
        shutil.rmtree(self.home_agents)
        self.run_dot("remove-skill", "example")
        self.assertFalse((self.repo_agents / "skills/example").exists())
        self.assertFalse(self.home_agents.exists())

    def test_unrelated_home_lock_entries_are_preserved(self):
        home_lock = copy.deepcopy(self.lock)
        home_lock["skills"]["home-only"] = {"skillPath": "skills/home-only/SKILL.md"}
        (self.home_agents / ".skill-lock.json").write_text(json.dumps(home_lock))
        self.run_dot("remove-skill", "example")
        del home_lock["skills"]["example"]
        self.assertEqual(json.loads((self.home_agents / ".skill-lock.json").read_text()), home_lock)

    def test_stowed_skills_directory_with_copied_lock(self):
        shutil.rmtree(self.home_agents / "skills")
        (self.home_agents / "skills").symlink_to(self.repo_agents / "skills", target_is_directory=True)
        self.run_dot("remove-skill", "example")
        self.assert_removed()
        self.assertTrue((self.home_agents / "skills").is_symlink())

    def test_stowed_skills_directory_and_lock(self):
        shutil.rmtree(self.home_agents / "skills")
        (self.home_agents / "skills").symlink_to(self.repo_agents / "skills", target_is_directory=True)
        (self.home_agents / ".skill-lock.json").unlink()
        (self.home_agents / ".skill-lock.json").symlink_to(self.repo_agents / ".skill-lock.json")
        self.run_dot("remove-skill", "example")
        self.assert_removed()
        self.assertTrue((self.home_agents / "skills").is_symlink())
        self.assertTrue((self.home_agents / ".skill-lock.json").is_symlink())

    def test_stowed_agents_directory(self):
        shutil.rmtree(self.home_agents)
        self.home_agents.symlink_to(self.repo_agents, target_is_directory=True)
        self.run_dot("remove-skill", "example")
        self.assert_removed()
        self.assertTrue(self.home_agents.is_symlink())

    def test_individually_stowed_skill(self):
        shutil.rmtree(self.home_agents / "skills/example")
        (self.home_agents / "skills/example").symlink_to(self.repo_agents / "skills/example", target_is_directory=True)
        self.run_dot("remove-skill", "example")
        self.assert_removed()

    def test_skill_symlinks_do_not_delete_external_targets(self):
        external = Path(self.tmp.name) / "external-skill"
        external.mkdir()
        (external / "SKILL.md").write_text("external\n")
        for agents in (self.repo_agents, self.home_agents):
            shutil.rmtree(agents / "skills/example")
            (agents / "skills/example").symlink_to(external, target_is_directory=True)
        self.run_dot("remove-skill", "example")
        self.assert_removed()
        self.assertEqual((external / "SKILL.md").read_text(), "external\n")

    def test_external_home_lock_symlink_is_detached_not_modified(self):
        external = Path(self.tmp.name) / "external-lock.json"
        external.write_text(json.dumps(self.lock))
        (self.home_agents / ".skill-lock.json").unlink()
        (self.home_agents / ".skill-lock.json").symlink_to(external)
        self.run_dot("remove-skill", "example")
        self.assert_removed()
        self.assertFalse((self.home_agents / ".skill-lock.json").is_symlink())
        self.assertEqual(json.loads(external.read_text()), self.lock)

    def test_invalid_names_and_unknown_skills_leave_files_unchanged(self):
        for name in ("", ".", "..", "../keep", "example/", "example/SKILL.md", "/tmp", "--all", "scripts", "Scripts", "missing"):
            with self.subTest(name=name):
                self.run_dot("remove-skill", name, success=False)
                self.assert_unchanged()

    def test_help_and_argument_count(self):
        self.run_dot("remove-skill", success=False)
        self.run_dot("remove-skill", "example", "keep", success=False)
        self.assertIn("Usage: remove-skill", self.run_dot("remove-skill", "--help").stdout)
        self.assertIn("remove-skill", self.run_dot("help").stdout)
        self.assert_unchanged()

    def test_invalid_locks_fail_before_removing_any_skill(self):
        for agents in (self.repo_agents, self.home_agents):
            for content in ("{invalid", "{}", '{"skills": []}', '{"skills": {"example": null}}'):
                with self.subTest(agents=agents, content=content):
                    lock_path = agents / ".skill-lock.json"
                    lock_path.write_text(content)
                    result = self.run_dot("remove-skill", "example", success=False)
                    self.assertIn("invalid skill lock", result.stderr)
                    self.assertEqual(lock_path.read_text(), content)
                    self.assertTrue((self.repo_agents / "skills/example/SKILL.md").exists())
                    self.assertTrue((self.home_agents / "skills/example/SKILL.md").exists())
                    self.write_locks()

    def test_non_directory_target_fails_before_changes(self):
        shutil.rmtree(self.home_agents / "skills/example")
        (self.home_agents / "skills/example").write_text("not a directory")
        self.run_dot("remove-skill", "example", success=False)
        self.assertTrue((self.repo_agents / "skills/example/SKILL.md").exists())
        self.assertEqual(json.loads((self.repo_agents / ".skill-lock.json").read_text()), self.lock)


if __name__ == "__main__":
    unittest.main()
