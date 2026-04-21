program test_word_moves
  use fgof_lineedit, only : &
    default_prompt, &
    init_lineedit, &
    lineedit_state, &
    move_cursor_word_left, &
    move_cursor_word_right, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("> "))

  call set_buffer(editor, "alpha  beta gamma", 10)
  if (.not. move_cursor_word_left(editor)) error stop "word-left should move to the start of the current word"
  if (editor%cursor /= 8) error stop "word-left should land on the start of beta"
  if (.not. move_cursor_word_left(editor)) error stop "word-left should move to the previous word start"
  if (editor%cursor /= 1) error stop "word-left should land on the start of alpha"
  if (move_cursor_word_left(editor)) error stop "word-left should stop at the first word boundary"

  call set_buffer(editor, "alpha  beta gamma", 1)
  if (.not. move_cursor_word_right(editor)) error stop "word-right should move to the next word start"
  if (editor%cursor /= 8) error stop "word-right should skip alpha and following spaces"
  if (.not. move_cursor_word_right(editor)) error stop "word-right should move to the start of gamma"
  if (editor%cursor /= 13) error stop "word-right should land on the start of gamma"
  if (.not. move_cursor_word_right(editor)) error stop "word-right should move to the end after the last word"
  if (editor%cursor /= 18) error stop "word-right should land just past the final character"
  if (move_cursor_word_right(editor)) error stop "word-right should stop at the buffer end"

  call set_buffer(editor, "  alpha", 1)
  if (.not. move_cursor_word_right(editor)) error stop "word-right should skip leading separators"
  if (editor%cursor /= 3) error stop "word-right should land on the first non-separator character"

  call set_buffer(editor, "alpha  ", 8)
  if (.not. move_cursor_word_left(editor)) error stop "word-left should skip trailing separators"
  if (editor%cursor /= 1) error stop "word-left should land on the word start after trailing spaces"
end program test_word_moves
