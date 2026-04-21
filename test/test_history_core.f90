program test_history_core
  use fgof_lineedit, only : &
    add_history_entry, &
    default_prompt, &
    history_count, &
    history_next, &
    history_previous, &
    init_lineedit, &
    lineedit_state, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("> "))
  call add_history_entry(editor, "")
  call add_history_entry(editor, "echo one")
  call add_history_entry(editor, "echo two")

  if (history_count(editor) /= 2) error stop "history should ignore empty entries and keep real ones"

  call set_buffer(editor, "draft", 3)
  if (.not. history_previous(editor)) error stop "history_previous should recall the newest entry"
  if (editor%buffer /= "echo two") error stop "history_previous should load the newest history line first"
  if (editor%cursor /= 9) error stop "history recall should place the cursor at the end of the line"

  if (.not. history_previous(editor)) error stop "history_previous should move to older entries"
  if (editor%buffer /= "echo one") error stop "history_previous should move backward through history"

  if (history_previous(editor)) error stop "history_previous should stop at the oldest history entry"

  if (.not. history_next(editor)) error stop "history_next should move toward newer history entries"
  if (editor%buffer /= "echo two") error stop "history_next should restore the next newer history line"

  if (.not. history_next(editor)) error stop "history_next should restore the stashed current buffer after the newest entry"
  if (editor%buffer /= "draft") error stop "history_next should restore the pre-navigation buffer"
  if (editor%cursor /= 3) error stop "history_next should restore the stashed cursor position"

  if (history_next(editor)) error stop "history_next should do nothing once history browsing ends"
end program test_history_core
