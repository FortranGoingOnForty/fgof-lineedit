program test_scaffold
  use fgof_lineedit, only : default_prompt, init_lineedit, lineedit_state, reset_lineedit
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("line> "))
  if (.not. editor%active) error stop "editor should start active"
  if (editor%prompt%text /= "line> ") error stop "editor should preserve prompt text"
  if (editor%buffer /= "") error stop "editor should start with an empty buffer"
  if (editor%cursor /= 1) error stop "editor should start with cursor at 1"

  call reset_lineedit(editor)
  if (editor%active) error stop "reset should deactivate the editor"
  if (editor%buffer /= "") error stop "reset should clear the buffer"
  if (editor%cursor /= 1) error stop "reset should restore cursor position"
end program test_scaffold
