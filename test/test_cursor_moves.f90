program test_cursor_moves
  use fgof_lineedit, only : &
    default_prompt, &
    init_lineedit, &
    lineedit_state, &
    move_cursor_end, &
    move_cursor_home, &
    move_cursor_left, &
    move_cursor_right, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("line> "))

  call set_buffer(editor, "abc", 0)
  if (editor%cursor /= 1) error stop "set_buffer should clamp cursor positions below the start"
  if (move_cursor_left(editor)) error stop "move_cursor_left should stop at the buffer start"

  call move_cursor_end(editor)
  if (editor%cursor /= 4) error stop "move_cursor_end should place the cursor after the last character"
  if (move_cursor_right(editor)) error stop "move_cursor_right should stop at the buffer end"

  call set_buffer(editor, "abc", 99)
  if (editor%cursor /= 4) error stop "set_buffer should clamp cursor positions beyond the buffer end"

  call move_cursor_home(editor)
  if (editor%cursor /= 1) error stop "move_cursor_home should restore the first insertion column"

  if (.not. move_cursor_right(editor)) error stop "move_cursor_right should move inside the buffer"
  if (editor%cursor /= 2) error stop "move_cursor_right should advance the cursor by one column"
end program test_cursor_moves
