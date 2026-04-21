# fgof-lineedit

[![CI](https://github.com/FortranGoingOnForty/fgof-lineedit/actions/workflows/ci.yml/badge.svg)](https://github.com/FortranGoingOnForty/fgof-lineedit/actions/workflows/ci.yml)

Fortran-native line editing helpers for interactive CLI tools.

`fgof-lineedit` is intended to be a small, standalone library that gives Fortran shells, REPLs, and interactive CLIs a friendlier editing surface than raw terminal reads.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules) catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- editable line buffer and cursor model
- prompt handling and rendered line state
- history navigation and history storage hooks
- completion and key-handling integration points
- clean boundaries with future `fgof-termios` and `fgof-keys`

Future scope:

- richer readline-style editing commands
- completion engines and menu UIs
- prompt widgets and multi-line editing

## Status

Initial scaffold is in place.

Implemented today:

- public `fgof_lineedit` and `fgof_lineedit_types` modules
- line editor, action, completion, history, prompt, and render-state types
- prompt constructor, editable buffer core, cursor movement and deletion helpers, word-wise navigation, history navigation, action dispatch, completion helpers, completion-menu state, and render snapshots
- smoke-test coverage and CI wiring

Still to implement:

- terminal integration and redraw policy
- richer completion menus and callback policies

## Why Use It

- line editing is repeatedly hand-built in shells, REPLs, and text tools
- the Fortran ecosystem still lacks an obvious small default package here
- it is meant to compose cleanly with `fgof-pty`, future `fgof-termios`, and future `fgof-keys`

## Public API Shape

Primary modules:

- `fgof_lineedit`
- `fgof_lineedit_types`

Public types:

- `completion_item`
- `completion_span`
- `lineedit_action`
- `lineedit_render_completion`
- `lineedit_render_state`
- `lineedit_state`
- `prompt_spec`
- `history_entry`

Action constants:

- `FGOF_LINEEDIT_ACT_NONE`
- `FGOF_LINEEDIT_ACT_INSERT`
- `FGOF_LINEEDIT_ACT_DELETE_LEFT`
- `FGOF_LINEEDIT_ACT_DELETE_RIGHT`
- `FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT`
- `FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT`
- `FGOF_LINEEDIT_ACT_MOVE_LEFT`
- `FGOF_LINEEDIT_ACT_MOVE_RIGHT`
- `FGOF_LINEEDIT_ACT_MOVE_WORD_LEFT`
- `FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT`
- `FGOF_LINEEDIT_ACT_MOVE_HOME`
- `FGOF_LINEEDIT_ACT_MOVE_END`
- `FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS`
- `FGOF_LINEEDIT_ACT_HISTORY_NEXT`

Current public procedures:

- `add_history_entry`
- `apply_completion`
- `apply_selected_completion`
- `apply_action`
- `buffer_length`
- `clear_completion_menu`
- `completion_count`
- `completion_span_at_cursor`
- `delete_word_left`
- `delete_word_right`
- `set_buffer`
- `set_completion_items`
- `insert_text`
- `insert_action`
- `delete_left`
- `delete_right`
- `default_prompt`
- `history_count`
- `history_previous`
- `history_next`
- `init_lineedit`
- `move_cursor_left`
- `move_cursor_right`
- `move_cursor_word_left`
- `move_cursor_word_right`
- `move_cursor_home`
- `move_cursor_end`
- `lineedit_completion_provider`
- `render_lineedit`
- `refresh_completion_menu`
- `reset_lineedit`
- `select_next_completion`
- `select_previous_completion`
- `simple_action`

## Quick Start

```fortran
program demo_lineedit
  use fgof_lineedit, only : &
    default_prompt, &
    init_lineedit, &
    lineedit_render_state, &
    lineedit_state, &
    render_lineedit, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor
  type(lineedit_render_state) :: view

  call init_lineedit(editor, default_prompt("> "))
  call set_buffer(editor, "build", 3)
  view = render_lineedit(editor)
  print "(A)", view%line
  print "(I0)", view%cursor_column
end program demo_lineedit
```

## Build And Test

```bash
fpm test
```

That is the baseline verification command locally and in CI.

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on editing state and library ergonomics, not full shell implementation
- terminal-mode control should stay in a future companion package

## License

MIT
