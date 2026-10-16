import json
import os
from pathlib import Path
import select
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
CODEX = shutil.which("codex")
GIT = shutil.which("git")


class CloudSetupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="codex cloud test ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.harness = self.root / "harness"
        self.project = self.root / "project"
        self.home = self.root / "home"
        self.config = self.home / ".codex"
        self.bin = self.root / "bin"
        for path in [self.harness, self.project, self.config, self.bin]:
            path.mkdir(parents=True)
        subprocess.run([GIT, "init", "-q", str(self.project)], check=True)
        for name, text in {
            "claude-sync/CLAUDE.md": "Shared engineering rules.\n",
            "claude-sync/professional-mode.md": "Professional instructions.\n",
            "claude-sync/superdinq-mode.md": "Superdinq instructions.\n",
            "claude-sync/skills/shared/SKILL.md": "Shared skill.\n",
            "codex-sync/skills/personal/SKILL.md": "Personal skill.\n",
        }.items():
            path = self.harness / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        source = ROOT / "codex-cloud-setup.sh"
        if source.exists():
            shutil.copy2(source, self.harness / source.name)
        for name in ["celetis", "superpowers"]:
            bundle = self.root / "plugins" / name
            (bundle / "skills" / "example").mkdir(parents=True)
            (bundle / "skills" / "example" / "SKILL.md").write_text("Example skill.\n")
            (bundle / "docs").mkdir()
            (bundle / "docs" / "reference.md").write_text("Bundled reference.\n")
        self.executable("git", '#!/bin/bash\nif [[ "$*" == *" pull --ff-only" ]]; then exit 0; fi\nexec "$REAL_GIT" "$@"\n')
        self.executable("codex", '''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
if args[:2] == ['plugin', 'add']:
    if os.environ.get('FAIL_PLUGIN'):
        print('private repository access denied', file=sys.stderr)
        sys.exit(1)
    name = args[2].split('@')[0]
    path = str(pathlib.Path(os.environ['TEST_ROOT']) / 'plugins' / name)
    if os.environ.get('BAD_PLUGIN'):
        path = ''
    print(json.dumps({'pluginId': args[2], 'installedPath': path}))
elif args[:1] == ['plugin']:
    pass
else:
    os.execv(os.environ['REAL_CODEX'], [os.environ['REAL_CODEX'], *args])
''')
        self.executable("uv", "#!/bin/bash\nexit 0\n")
        self.tools = self.home / ".local" / "share" / "codex-cloud-tools"
        executable = self.tools / "node_modules" / ".bin" / "playwright-mcp"
        executable.parent.mkdir(parents=True)
        executable.write_text("#!/bin/bash\nexit 0\n")
        executable.chmod(0o755)
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "CODEX_HOME": str(self.config),
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "REAL_CODEX": CODEX,
            "REAL_GIT": GIT,
            "TEST_ROOT": str(self.root),
        }
        for name in ["GH_TOKEN", "GITHUB_TOKEN"]:
            self.env.pop(name, None)

    def executable(self, name, text):
        path = self.bin / name
        path.write_text(text)
        path.chmod(0o755)

    def server(self, command):
        process = subprocess.Popen(command, cwd=self.project, env=self.env, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        def close():
            process.terminate()
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            process.stdin.close()
            process.stdout.close()
        self.addCleanup(close)
        return process

    def request(self, process, message):
        process.stdin.write(json.dumps(message) + "\n")
        process.stdin.flush()
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            if not select.select([process.stdout], [], [], 1)[0]:
                continue
            line = process.stdout.readline()
            self.assertTrue(line, "server exited before its reply")
            response = json.loads(line)
            if response.get("id") == message["id"]:
                self.assertNotIn("error", response)
                return response["result"]
        self.fail("server reply timed out")

    def run_setup(self):
        return subprocess.run(
            ["/bin/bash", str(self.harness / "codex-cloud-setup.sh"), "start", str(self.project)],
            env=self.env, text=True, capture_output=True, timeout=30,
        )

    def test_fresh_setup_exposes_skills_and_keeps_bundle_references(self):
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        skills = self.project / ".agents" / "skills"
        self.assertEqual((skills / "claude-harness" / "shared" / "SKILL.md").read_text(), "Shared skill.\n")
        self.assertEqual((skills / "codex-harness" / "personal" / "SKILL.md").read_text(), "Personal skill.\n")
        self.assertEqual((skills / "celetis" / "docs" / "reference.md").read_text(), "Bundled reference.\n")
        self.assertEqual((self.config / "AGENTS.md").read_text(), "Shared engineering rules.\nProfessional instructions.\nSuperdinq instructions.\n")
        config = tomllib.loads((self.config / "config.toml").read_text())
        self.assertEqual(config["mcp_servers"]["context7"]["url"], "https://mcp.context7.com/mcp")
        playwright = config["mcp_servers"]["playwright"]
        self.assertEqual(playwright["command"], str(self.tools / "node_modules" / ".bin" / "playwright-mcp"))
        self.assertEqual(playwright["args"], ["--headless", "--isolated", "--browser", "chromium"])
        status = subprocess.check_output([GIT, "status", "--porcelain", "--untracked-files=all"], cwd=self.project, text=True)
        self.assertEqual(status, "")
        self.assertIn("codex-cloud: ready", result.stdout)

    def test_repeat_setup_updates_skills_without_duplicates_or_stale_files(self):
        first = self.run_setup()
        self.assertEqual(first.returncode, 0, first.stderr)
        shutil.rmtree(self.harness / "claude-sync" / "skills" / "shared")
        replacement = self.harness / "claude-sync" / "skills" / "replacement"
        replacement.mkdir()
        (replacement / "SKILL.md").write_text("Replacement skill.\n")
        second = self.run_setup()
        self.assertEqual(second.returncode, 0, second.stderr)
        skills = self.project / ".agents" / "skills" / "claude-harness"
        self.assertFalse((skills / "shared").exists())
        self.assertEqual((skills / "replacement" / "SKILL.md").read_text(), "Replacement skill.\n")
        self.assertEqual((self.config / "AGENTS.md").read_text().count("Shared engineering rules."), 1)

    def test_failed_private_plugin_install_never_reports_ready(self):
        self.env["FAIL_PLUGIN"] = "1"
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("private repository access denied", result.stderr)
        self.assertNotIn("codex-cloud: ready", result.stdout)

    def test_invalid_installed_path_never_reports_ready(self):
        self.env["BAD_PLUGIN"] = "1"
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("invalid Celetis installation metadata", result.stderr)
        self.assertNotIn("codex-cloud: ready", result.stdout)

    def test_existing_project_skill_directory_is_not_replaced(self):
        existing = self.project / ".agents" / "skills" / "celetis"
        existing.mkdir(parents=True)
        (existing / "keep.txt").write_text("Keep this file.\n")
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refusing to replace", result.stderr)
        self.assertEqual((existing / "keep.txt").read_text(), "Keep this file.\n")
        self.assertNotIn("codex-cloud: ready", result.stdout)

    def test_existing_codex_configuration_is_preserved(self):
        (self.config / "config.toml").write_text('model = "existing-model"\n[mcp_servers.existing]\nurl = "https://example.com/mcp"\n')
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        config = tomllib.loads((self.config / "config.toml").read_text())
        self.assertEqual(config["model"], "existing-model")
        self.assertEqual(config["mcp_servers"]["existing"]["url"], "https://example.com/mcp")

    def test_start_rejects_a_missing_pdf_skill_prerequisite(self):
        (self.bin / "uv").unlink()
        for name in ["gh", "jq", "perl", "node", "npm", "python3", "dirname"]:
            (self.bin / name).symlink_to(shutil.which(name))
        self.env["PATH"] = str(self.bin)
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("codex-cloud: uv is required", result.stderr)
        self.assertNotIn("codex-cloud: ready", result.stdout)

    def test_tracked_project_skill_symlink_is_not_replaced(self):
        existing = self.project / ".agents" / "skills" / "celetis"
        existing.parent.mkdir(parents=True)
        existing.symlink_to(self.harness / "claude-sync" / "skills", target_is_directory=True)
        subprocess.run([GIT, "add", ".agents/skills/celetis"], cwd=self.project, check=True)
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("refusing to replace", result.stderr)
        self.assertEqual(existing.readlink(), self.harness / "claude-sync" / "skills")

    def test_real_cli_discovers_nested_personal_and_plugin_skill_links(self):
        for path, name in [
            (self.harness / "claude-sync/skills/shared/SKILL.md", "cloud-shared"),
            (self.harness / "codex-sync/skills/personal/SKILL.md", "cloud-personal"),
            (self.root / "plugins/celetis/skills/example/SKILL.md", "cloud-celetis"),
            (self.root / "plugins/superpowers/skills/example/SKILL.md", "cloud-superpowers"),
        ]:
            path.write_text(f"---\nname: {name}\ndescription: Cloud discovery fixture.\n---\nFixture.\n")
        setup = self.run_setup()
        self.assertEqual(setup.returncode, 0, setup.stderr)
        process = self.server([CODEX, "app-server", "--stdio"])
        self.request(process, {"id": 1, "method": "initialize", "params": {"clientInfo": {"name": "cloud-test", "version": "1"}, "capabilities": {"experimentalApi": True}}})
        process.stdin.write('{"method":"initialized"}\n')
        process.stdin.flush()
        result = self.request(process, {"id": 2, "method": "skills/list", "params": {"cwds": [str(self.project)], "forceReload": True}})
        group = next(group for group in result["data"] if Path(group["cwd"]).resolve() == self.project.resolve())
        self.assertEqual(group["errors"], [])
        names = {skill["name"] for skill in group["skills"]}
        self.assertTrue({"cloud-shared", "cloud-personal", "cloud-celetis", "cloud-superpowers"} <= names, names)

    def test_non_root_install_supplies_a_missing_codex_cli(self):
        template = self.root / "codex-template"
        shutil.copy2(self.bin / "codex", template)
        (self.bin / "codex").unlink()
        for name in ["gh", "jq", "perl", "node", "python3", "curl"]:
            (self.bin / name).symlink_to(shutil.which(name))
        self.executable("uname", "#!/bin/bash\necho Linux\n")
        self.executable("id", "#!/bin/bash\necho 1000\n")
        self.executable("sudo", '#!/bin/bash\nshift\nexport TEST_SUDO=1\nexec "$@"\n')
        self.executable("npm", '''#!/bin/bash
if [[ "$*" == *" -g "* ]]; then
    [[ "${TEST_SUDO:-}" == 1 ]] || { echo EACCES >&2; exit 1; }
    cp "$TEST_CODEX_TEMPLATE" "$TEST_BIN/codex"
fi
''')
        playwright = self.tools / "node_modules/.bin/playwright"
        playwright.write_text("#!/bin/bash\nexit 0\n")
        playwright.chmod(0o755)
        self.env.update({"PATH": str(self.bin) + ":/usr/bin:/bin", "TEST_CODEX_TEMPLATE": str(template), "TEST_BIN": str(self.bin)})
        result = subprocess.run(
            ["/bin/bash", str(self.harness / "codex-cloud-setup.sh"), "install", str(self.project)],
            env=self.env, text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.config / "config.toml").is_file())

    def test_explanation_skill_check_command_works_from_its_loaded_directory(self):
        shutil.copytree(ROOT / "claude-sync/skills/explain-diff-html", self.harness / "claude-sync/skills/explain-diff-html")
        setup = self.run_setup()
        self.assertEqual(setup.returncode, 0, setup.stderr)
        skill = self.project / ".agents/skills/claude-harness/explain-diff-html"
        page = self.project / "example.html"
        page.write_text('<meta charset="utf-8"><div id="quiz-app"></div><script>getElementById("quiz-app")</script>')
        command = next(line for line in (skill / "SKILL.md").read_text().splitlines() if line.startswith("python3 "))
        command = command.replace("<skill-base-dir>", shlex.quote(str(skill))).replace("<file>", shlex.quote(str(page)))
        result = subprocess.run(["/bin/bash", "-c", command], cwd=self.project, env=self.env, capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("all resolve", result.stdout)

    @unittest.skipUnless(sys.platform == "linux" and os.environ.get("RUN_LINUX_INSTALL_TEST") == "1", "Linux package/browser installation runs in CI")
    def test_linux_install_prepares_a_working_headless_browser(self):
        shutil.rmtree(self.tools)
        (self.bin / "uv").unlink()
        result = subprocess.run(
            ["/bin/bash", str(self.harness / "codex-cloud-setup.sh"), "install", str(self.project)],
            env=self.env, text=True, capture_output=True, timeout=600,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        pdf = subprocess.run([shutil.which("uv", path=self.env["PATH"]), "run", "--with", "pdf-inspector", "python", "-c", "import pdf_inspector"], cwd=self.project, env=self.env, text=True, capture_output=True, timeout=120)
        self.assertEqual(pdf.returncode, 0, pdf.stdout + pdf.stderr)
        process = self.server([str(self.tools / "node_modules/.bin/playwright-mcp"), "--headless", "--isolated", "--browser", "chromium"])
        self.request(process, {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "cloud-test", "version": "1"}}})
        process.stdin.write('{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
        process.stdin.flush()
        page = self.request(process, {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "browser_navigate", "arguments": {"url": "data:text/html,<h1>Cloud tool ready</h1>"}}})
        self.assertFalse(page.get("isError", False), page)
        self.assertIn("Cloud tool ready", json.dumps(page["content"]))
        self.request(process, {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "browser_close", "arguments": {}}})


if __name__ == "__main__":
    unittest.main()
