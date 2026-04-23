# vim-circuit

Agent CLI terminal integration for Vim. One keypress opens your agent in a split.
Another hides it. Your session persists across toggles.

## Features

- **Persistent terminal** with automatic session resume via `--continue`
- **Session switching**: resume, continue, new, from-PR -- all tab-completable
- **Worktree support**: `--worktree` integration with optional tmux mode
- **Mode control**: plan, auto, default, acceptEdits via `--permission-mode`
- **Model switching**: sonnet, opus, haiku, or any full model name
- **Zoom toggle**: maximize/restore the agent split (tmux-style)
- **Send selection**: pipe visual selection to the agent with file context
- **Auto buffer reload**: detects files changed by the agent and reloads them
- **Lifecycle hooks**: `User CTOpen`, `CTReload`, etc.
- **Fully configurable**: every keymap, behavior, and CLI flag via `g:circuit_*`

## Requirements

- Vim 8.0+ with `+terminal`
- An agent CLI (e.g. [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)) in `$PATH`
- Git

## Installation

### vim-plug (local)

```vim
Plug '~/Documents/personal_projects/circuit'
```

### vim-plug (GitHub)

```vim
Plug 'inknos/vim-circuit'
```

### Native packages

```bash
git clone https://github.com/inknos/vim-circuit.git \
  ~/.vim/pack/plugins/start/vim-circuit
```

Then run `:helptags ALL` in Vim.

## Quick Start

```vim
:CTerm          " Toggle agent terminal (or <leader>c)
:CTerm resume   " Interactive session picker (or <leader>cr)
:CTerm plan     " Toggle plan mode (or <leader>cmp)
:CTerm fast     " Toggle fast mode (or <leader>cmf)
:CTerm model opus " Switch to opus (or <leader>cmo)
:CTerm worktree   " Launch in a git worktree (or <leader>cw)
:CTworktree!      " Launch worktree in tmux pane
```

## Commands

| Long Form | Short | Keymap | Description |
|---|---|---|---|
| `:CTerm` | `:CT` | `<leader>c` | Toggle terminal |
| `:CTerm resume` | `:CTresume` | `<leader>cr` | Session picker |
| `:CTerm continue` | `:CTcontinue` | `<leader>cc` | Resume last chat |
| `:CTerm new` | `:CTnew` | `<leader>cn` | New session |
| `:CTerm kill` | `:CTkill` | `<leader>ck` | Kill terminal |
| `:CTerm pr` | `:CTpr` | `<leader>cp` | Resume from PR |
| `:CTerm worktree` | `:CTworktree` | `<leader>cw` | Launch in git worktree |
| `:CTerm plan` | `:CTplan` | `<leader>cmp` | Toggle plan mode (sends `/plan`) |
| `:CTerm fast` | `:CTfast` | `<leader>cmf` | Toggle fast mode (sends `/fast`) |
| `:CTerm zoom` | `:CTzoom` | `<leader>cz` | Zoom toggle |
| `:CTerm send` | `:CTsend` | `<leader>cs` (visual) | Send selection |
| `:CTerm chat` | `:CTchat` | `<leader>ch` | Free-form chat |
| `:CTerm model {name}` | `:CTmodel {name}` | `<leader>cms/o/h` | Switch model |
| `:CTerm verbose` | `:CTverbose` | `<leader>cv` | Verbose toggle |
| `:CTerm doctor` | `:CTdoctor` | -- | Health check |
| `:CTerm version` | `:CTversion` | -- | Show versions |

## Configuration

Set any of these in your `.vimrc` before the plugin loads:

```vim
let g:circuit_position = 'bottom'       " right (default), left, top, bottom
let g:circuit_split_ratio = 0.3         " fraction of screen (default 0.4)
let g:circuit_permission_mode = 'plan'  " default mode for new sessions
let g:circuit_model = 'sonnet'          " default model
let g:circuit_worktree_tmux = 1        " always use tmux for worktree
let g:circuit_map_keys = 0              " disable all default keymaps
```

See `:help circuit-configuration` for the full list.

## Hooks

```vim
autocmd User CTOpen echo "Agent session started"
autocmd User CTReload echohl WarningMsg | echo "Buffers reloaded" | echohl None
```

Events: `Open`, `ToggleShow`, `ToggleHide`, `Kill`, `ZoomIn`, `ZoomOut`,
`Reload`, `ModeChange`, `SessionChange`, `Worktree`.

See `:help circuit-hooks` for details.

## Documentation

Full documentation is available via `:help circuit` after installation.

HTML docs are generated from the vimdoc source and available as a CI artifact
on the Actions tab.

## License

MIT
