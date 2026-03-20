# worktree-fns

`~/.zshrc` helper functions for efficient git worktrees.

## Installation

Clone the repo, then:

```sh
# Point your `~/.zshrc` at it:
source ~/Sites/personal/worktree-fns/worktree-fns.zsh
```

Optional: add `.worktrees/*` directory to your `.gitignore`. Worktrees are managed here; ignoring them in the git index makes for a seamless experience.

## Usage

You can now use these in your CLI:

```sh
# list current worktrees
gwls

# (a)dd new worktree in `.worktrees/`, then cd into it
# (branch name optional)
gwa <name> [branch]

# cd into specified worktree
gwcd <name>

# cd back to (p)roject
gwp

# cd back to worktree (r)oot
gwr

# (d)elete speified worktree (print diff if delete fails)
gwd <name-or-path>

# delete --force (if changes detected)
gwdf <name-or-path>

# log worktree diff
gwdiff <name-or-path>
```

## Other features

### Worktree name completion

Commands that accept a worktree name use shell completion from the nearest
repo's `.worktrees` directory. That means you can use tab-completion with:

- `gwcd`
- `gwd`
- `gwdf`
- `gwdiff`


### Local files copied into new worktrees

`git worktree add` only checks out tracked files. To make fresh worktrees more
usable, `gwa` also copies selected local files when they exist and are missing
from the new worktree:

- `.env`
- `.gitignore`

This helps with common local-only setup, including nested ignore rules that
prevent generated files from showing up as false-positive changes.

