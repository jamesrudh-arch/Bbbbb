# Pushing LEVERAGE to a Git repository

The project is already a committed git repo (`main` branch, 1 commit, 230 files).
You do not need to `git init` or `git add` anything — just point it at a remote and push.

There is **no remote configured yet**, because that is the one step only you can do
(it requires your account credentials).

---

## Step 1 — Create an empty repository

**GitHub:** https://github.com/new → name it `leverage` → **Private** or Public →
**do NOT** tick "Add a README", "Add .gitignore" or "Choose a license". You want a
completely empty repo, otherwise the first push conflicts.

**GitLab:** https://gitlab.com/projects/new → "Create blank project" → same rule: no
README.

Copy the URL it gives you. It looks like:
- `https://github.com/YOURNAME/leverage.git`
- `git@github.com:YOURNAME/leverage.git` (SSH)

---

## Step 2 — Unzip and push

Unzip `LEVERAGE-v0.9.0-source.zip`, then:

```bash
cd leverage

git remote add origin https://github.com/YOURNAME/leverage.git

git push -u origin main
```

That's it. `-u` sets `origin/main` as the default, so every later push is just `git push`.

**If you get "repository not found"** → check the URL for typos and that the repo exists.
**If you get "authentication failed"** → GitHub no longer accepts account passwords. Use
a Personal Access Token (Settings → Developer settings → Personal access tokens →
classic → scope `repo`) and paste it as the password. Or use SSH instead:

```bash
git remote set-url origin git@github.com:YOURNAME/leverage.git
git push -u origin main
```

---

## Step 3 — Verify

```bash
git remote -v          # shows origin
git log --oneline      # shows 9c908a0 LEVERAGE v0.9.0
git status             # should say "working tree clean"
```

On GitHub you should see 230 files, with `.godot/` correctly absent.

---

## What is and is not in the repo

**Included (230 files, ~11 MB):**

| Path | Contents |
|------|----------|
| `project.godot` | engine config, autoloads, input map |
| `scenes/` | boot, main_menu, player, world |
| `scripts/` | 30 GDScript files, ~6,000 lines |
| `assets/` | 19 GLB models + texture |
| `audio/` | 32 original WAVs |
| `tests/` | 112 assertions |
| `docs/` | 17 documents |
| `shots/` | 20 verification screenshots |
| `.gitignore` `.gitattributes` | Godot-aware ignore rules, binary handling |

**Deliberately excluded:**

- `.godot/` — Godot's import cache. It is ~5.4 MB of generated data that Godot rebuilds
  automatically the first time you open the project. Committing it causes constant merge
  conflicts on every machine. This is the standard Godot practice.
- `node_modules/` — only used by the asset-conversion tooling, not the game.

**Consequence:** when someone clones the repo, the first open in Godot takes an extra
~20–60 seconds while it reimports assets. That is normal and expected.

If you *do* want the import cache committed for some reason (e.g. shipping a
ready-to-open folder), use `LEVERAGE-v0.9.0-playable.zip` instead — it contains `.godot/`
and opens instantly.

---

## Pushing later changes

```bash
cd leverage
git add -A
git commit -m "describe what changed"
git push
```

Because `.gitignore` excludes `.godot/`, you will never accidentally commit reimport noise.

---

## Using GitHub Desktop or the web UI instead

**GitHub Desktop:** File → Add Local Repository → pick the `leverage` folder → it detects
the existing repo → Publish repository.

**Web upload:** works for the source zip's contents but is painful for 230 files —
use the CLI. If you must use the web UI, upload as a single commit via
"Add file → Upload files" and drag the whole `leverage` folder; GitHub keeps the directory
structure.

---

## If you want the repo to include the screenshots in the README

They are already committed under `shots/`. Markdown images will render on GitHub:

```markdown
![Neon Mile](shots/final_night_neon.png)
![Driving](shots/07_driving.png)
```

A ready-made README for the repo root is at `docs/REPO_README.md` — copy it to `README.md`
at the project root if you want GitHub to show the project summary on the repo landing page:

```bash
cp docs/REPO_README.md README.md
git add README.md && git commit -m "Add README" && git push
```

---

## Branch strategy suggestion

For a solo project the simplest thing that works:

- `main` is always openable in Godot.
- Feature work on `feat/<thing>`, merge to `main` when the test suite passes
  (112/112) and `syntax_check.sh` reports `REAL ERRORS: 0`.
- Tag releases: `git tag -a v0.9.0 -m "Playable vertical slice" && git push --tags`

Consider a pre-commit hook that blocks a commit if tests fail:

```bash
# .git/hooks/pre-commit
#!/bin/sh
/home/user/tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  res://tests/test_suite.tscn | grep -q "FAILED: 0" || {
  echo "Tests failed — commit blocked"; exit 1; }
```

(chmod +x .git/hooks/pre-commit — note hooks are not committed, so do this per machine.)
