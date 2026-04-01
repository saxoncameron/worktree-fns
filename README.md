# worktree-fns

Installable git worktree helpers for zsh.

You get both:

- a standalone `worktree-fns` CLI
- shell wrappers like `gwa`, `gwcd`, `gwd`, and `gwm` for workflows that need
  to change the current shell directory

## Installation

### Install to your local prefix

```sh
make install PREFIX="$HOME/.local"
```

Then add the binary and shell integration to `~/.zshrc`:

```sh
export PATH="$HOME/.local/bin:$PATH"
eval "$(worktree-fns init zsh)"
```

For local development without installing:

```sh
source ~/Sites/personal/worktree-fns/worktree-fns.zsh
```

Optional: add `.worktrees/*` to your repo `.gitignore`. Worktrees are managed
there, so ignoring the directory in the main checkout keeps the index clean.

## Usage

### Shell wrappers

Once sourced, you can use the short `gw*` commands directly:

```sh
gwls

gwa <name> [branch]

gwcd <name>

gwp

gwr
gwd <name-or-path>
gwdf <name-or-path>
gwdiff <name-or-path>
gwh [<name-or-path>]
gwm [<name-or-path>]
```

### Standalone CLI

The binary exposes the same behavior as subcommands:

```sh
worktree-fns list
worktree-fns add <name> [branch]
worktree-fns cd <name>
worktree-fns delete <name-or-path>
worktree-fns force-delete <name-or-path>
worktree-fns diff <name-or-path>
worktree-fns handoff [<name-or-path>]
worktree-fns merge [<name-or-path>]
worktree-fns project-root
worktree-fns worktree-root
```

Path-oriented commands like `add`, `cd`, `project-root`, and `worktree-root`
print absolute paths when run through the standalone binary. The sourced shell
wrappers consume those paths and `cd` for you.

## Features

### Worktree name completion

Commands that accept a worktree name use shell completion from the nearest
repo's `.worktrees` directory. That means you can use tab-completion with:

- `gwcd`
- `gwd`
- `gwdf`
- `gwdiff`
- `gwh`
- `gwm`

### Local files copied into new worktrees

`git worktree add` only checks out tracked files. To make fresh worktrees more
usable, `gwa` also copies selected local files when they exist and are missing
from the new worktree:

- `.env`
- `.gitignore`

This helps with common local-only setup, including nested ignore rules that
prevent generated files from showing up as false-positive changes.

### Styled logging

Interactive commands use emoji + colored status lines by default. For
machine-friendlier output, set:

```sh
GW_LOG_STYLE=plain
```

## Development

```sh
make test
```
