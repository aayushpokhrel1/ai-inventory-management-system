# Working in this repo

AI inventory management system.

## Where things are written down

| File | What it holds |
| --- | --- |
| `README.md` | What it is and how to run it |
| `Project-Description.md` | What the project is for |
| `User_Stories.md` | User stories |

## When Aayush says "update"

"Update the docs", "update everything", or just "update" means **all of it, in this turn**:

1. **The knowledge vault** - `C:\Users\aayus\Documents\Knowledge-Vault\Projects\AI-Inventory\`
   (the path is per-machine). Add what this session learned that is worth keeping: a decision and
   its WHY, a non-obvious gotcha or fix, a research finding, a cross-project learning. This is the
   part that gets forgotten, and it is the part that compounds.
2. **Every doc in this repo**, not only the one already open.
3. **The handover**, but only its current-state numbers.

**Vault writes go through WSL, and note content must never appear on the command line.** The Bash
tool re-quotes the wrapper, so backticks and apostrophes inside a note get executed or break the
command. Write the note to a file first, then pass only literal paths:

```
wsl -d Ubuntu -- bash -lc 'cat /mnt/c/<tmp>/note.md >> /mnt/c/Users/aayus/Documents/Knowledge-Vault/Projects/AI-Inventory/index.md'
```

**Updating docs means making them TRUE, not just appending what shipped.** Correct or strike a
stale claim where it sits rather than adding a newer entry underneath it, because the next reader
may hit the old one first. Cross-check every number (versions, counts, commit) against reality
instead of trusting what the file says.

## Where knowledge goes

A lesson has exactly one home, chosen by how far it reaches:

- **A rule about specific code goes in a comment AT that code.** The most reliable form there is:
  you cannot edit the function without reading the warning above it. A note filed elsewhere is the
  least reliable, because nobody goes back to read it.
- **A lesson that generalises goes in the vault**, phrased so it is useful on a different
  project, with this one as the example.
- **A dated narrative of what you did today goes in `git log`.** It is already there, in detail.

Keep any one lesson in a single place. Two copies drift, and the drift is what causes wrong work
later.
