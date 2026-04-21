program test_scaffold
  use fgof_lineedit, only : buffer_length, default_prompt, history_count, init_lineedit, lineedit_state, reset_lineedit
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("line> "))
  if (.not. editor%active) error stop "editor should start active"
  if (editor%prompt%text /= "line> ") error stop "editor should preserve prompt text"
  if (editor%buffer /= "") error stop "editor should start with an empty buffer"
  if (buffer_length(editor) /= 0) error stop "editor should report zero length for an empty buffer"
  if (history_count(editor) /= 0) error stop "editor should start with empty history"
  if (editor%cursor /= 1) error stop "editor should start with cursor at 1"

  call reset_lineedit(editor)
  if (editor%active) error stop "reset should deactivate the editor"
  if (editor%buffer /= "") error stop "reset should clear the buffer"
  if (buffer_length(editor) /= 0) error stop "reset should restore zero buffer length"
  if (editor%cursor /= 1) error stop "reset should restore cursor position"
end program test_scaffold
