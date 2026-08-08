# superspec - local vendoring notes
Vendored from https://github.com/WangX0111/superspec (pinned - see PINNED_SHA.txt).
Excluded: scripts/ (test harness), .github/, examples/, extension.yml, README*, .git.
Local patches (re-apply after update):
1. SKILL.md Prerequisites - Claude Code plugin note: superpowers invokable via Skill tool wherever placed.
2. references/superpowers-bridge.md Detection Logic - precedence step 0 (Skill tool, location-independent).
Update: clone upstream, git diff <PINNED_SHA> HEAD -- SKILL.md commands references templates, review, re-vendor, re-apply patches.
