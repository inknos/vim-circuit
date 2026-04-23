# AGENTS.md — vim-claudeterm

## Overview

A Vim plugin that embeds the Claude Code CLI (`claude`) in Vim's built-in
`:terminal`. Single persistent terminal per project, toggle show/hide without
losing session state, commands and keymaps for session control, mode switching,
model selection, worktree support, and more.

**Language:** Vimscript only. No Python, Lua, Node, or external build tools.

**Runtime requirements:** Vim 8.0+ with `+terminal`, `claude` on `$PATH`, Git.

## Architecture

```
plugin/claudeterm.vim          ← loaded once at startup
  • g:loaded_claudeterm guard, +terminal feature check
  • g:claudeterm_* config defaults (get(g:, ...) pattern)
  • :CTerm dispatcher + short command aliases
  • keymap registration (guarded by g:claudeterm_map_keys)
  • FocusGained/BufEnter autocommand for checktime

autoload/claudeterm.vim        ← lazy-loaded on first claudeterm# call
  • s: script-local state (term_bufnr, zoom, timer, mode, model)
  • s: helpers (get, git_root, build_cmd, open_split, ...)
  • claudeterm# public functions (toggle, resume, continue, new, ...)
  • tab-completion via claudeterm#complete()

autoload/claudeterm/hooks.vim  ← thin hook dispatcher
  • claudeterm#hooks#fire(event) → doautocmd User ClaudeTerm{Event}

doc/claudeterm.txt             ← vimdoc (generates HTML via CI)
  • full user documentation, 78-char width, vim help format
```

## Vimscript Conventions

### Functions

- Always `function! Name() abort` — `!` allows redefinition, `abort` fails
  fast on errors.
- Public API: `claudeterm#function_name()` — autoloaded.
- Private helpers: `s:function_name()` — script-local.
- Hooks submodule: `claudeterm#hooks#fire()`.

### Configuration variables

- Global: `g:claudeterm_*`, initialized with `get(g:, 'claudeterm_X', default)`.
- Buffer-local overrides: `b:claudeterm_*` take precedence (via `s:get()`).

### String comparisons

Use `==#` and `!=#` for case-sensitive compares. Never bare `==`.

### File headers

Every `.vim` file starts with:

```vim
" vim-claudeterm: <brief purpose>
" Maintainer: inknos
" License: MIT
```

### Section separators

```vim
" ---------------------------------------------------------------------------
" Section Name
" ---------------------------------------------------------------------------
```

### Formatting

- Two-space indentation, no tabs.
- Use `\` for line continuations.
- Use `l:` prefix for local variables inside functions.

## Vimdoc Conventions

File: `doc/claudeterm.txt`. Format: Vim help (`:help write-local-help`).

- Tags: `*claudeterm-name*` — lowercase, hyphen-separated.
- Command tags: `*:CTcommandname*`
- Config variable tags: `*g:claudeterm_variable*`
- Text width: 78 characters.
- Section separators: `=====` lines. Subsection separators: `-----` lines.
- `doc/tags` is gitignored — never commit it.

When editing source files, verify that any new or changed commands, keymaps,
config variables, or hooks are reflected in `doc/claudeterm.txt`.

## Adding a :CTerm Subcommand

Every subcommand touches four files. Work through them in order.

### 1. Implement the function (`autoload/claudeterm.vim`)

Add a public `claudeterm#yourcommand()` function in the appropriate section.
Use `s:` helpers for internal logic and `s:get()` to read config variables.

```vim
" ---------------------------------------------------------------------------
" Your Feature
" ---------------------------------------------------------------------------

function! claudeterm#yourcommand() abort
  if !s:term_alive()
    echo 'claudeterm: no active terminal'
    return
  endif
  " ... implementation ...
  call claudeterm#hooks#fire('YourEvent')
endfunction
```

### 2. Wire up the dispatcher (`plugin/claudeterm.vim`)

Add an `elseif` branch in `s:dispatch()`:

```vim
elseif l:cmd ==# 'yourcommand'
  call claudeterm#yourcommand()
```

For subcommands with arguments, guard with `a:0 >= 2`:

```vim
elseif l:cmd ==# 'yourcommand'
  if a:0 >= 2
    call claudeterm#yourcommand(a:2)
  else
    echoerr 'claudeterm: yourcommand requires an argument'
  endif
```

### 3. Register short alias and keymap (`plugin/claudeterm.vim`)

```vim
" Short alias
command! -nargs=0 CTyourcommand call claudeterm#yourcommand()

" Config variable (in "Configuration defaults" section)
let g:claudeterm_map_yourcommand = get(g:, 'claudeterm_map_yourcommand', '<leader>cy')

" Keymap (inside the `if g:claudeterm_map_keys` block)
execute 'nnoremap <silent> ' . g:claudeterm_map_yourcommand . ' :call claudeterm#yourcommand()<CR>'
```

### 4. Add tab-completion (`autoload/claudeterm.vim`)

Add `'yourcommand'` to the `l:subs` list in `claudeterm#complete()`. If the
subcommand takes sub-arguments, add a new `elseif l:sub ==# 'yourcommand'`
block.

### 5. Document (`doc/claudeterm.txt`)

- Add the command under the appropriate subsection in section 5 (Commands)
  with tag `*:CTyourcommand*`.
- Add the keymap to the table in section 6 (Keymaps).
- Add any new `g:claudeterm_*` variable to section 9 (Configuration).
- Add any new hook event to section 8 (Hooks).
- Update the TOC if you added a new subsection.

### Existing patterns to reference

| Feature | Function | Dispatcher | Alias | Keymap var |
|---|---|---|---|---|
| Toggle | `claudeterm#toggle()` | (default) | `:CT` | `g:claudeterm_map_toggle` |
| Resume | `claudeterm#resume()` | `resume` | `:CTresume` | `g:claudeterm_map_resume` |
| Zoom | `claudeterm#zoom()` | `zoom` | `:CTzoom` | `g:claudeterm_map_zoom` |
| Model | `claudeterm#set_model()` | `model` | `:CTmodel` | `g:claudeterm_map_model_*` |

## Constraints

- **No external dependencies.** Pure Vim plugin — no npm, pip, cargo.
- **No Neovim-only APIs.** Must work on Vim 8.0+ with `+terminal`.
- **No generated files.** Don't commit `doc/tags` or `build/`.
- **No unnecessary comments.** Comments explain *why*, not *what*.
