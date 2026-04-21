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
- line editor and prompt-state types
- prompt constructor and basic reset helper
- smoke-test coverage and CI wiring

Still to implement:

- editable buffer operations
- history and completion hooks
- terminal integration and redraw behavior

## Why Use It

- line editing is repeatedly hand-built in shells, REPLs, and text tools
- the Fortran ecosystem still lacks an obvious small default package here
- it is meant to compose cleanly with `fgof-pty`, future `fgof-termios`, and future `fgof-keys`

## Public API Shape

Primary modules:

- `fgof_lineedit`
- `fgof_lineedit_types`

Public types:

- `lineedit_state`
- `prompt_spec`

Current public procedures:

- `default_prompt`
- `init_lineedit`
- `reset_lineedit`

## Quick Start

```fortran
program demo_lineedit
  use fgof_lineedit, only : default_prompt, init_lineedit, lineedit_state
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("> "))
  print "(A)", editor%prompt%text
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
