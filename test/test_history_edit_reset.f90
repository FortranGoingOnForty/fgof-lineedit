program test_history_edit_reset
  use fgof_lineedit, only : &
    add_history_entry, &
    default_prompt, &
    history_next, &
    history_previous, &
    init_lineedit, &
    insert_text, &
    lineedit_state
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("> "))
  call add_history_entry(editor, "status")
  call add_history_entry(editor, "build")

  if (.not. history_previous(editor)) error stop "history_previous should enter history browsing"
  if (editor%buffer /= "build") error stop "history_previous should recall the newest line"

  call insert_text(editor, "!")
  if (editor%buffer /= "build!") error stop "editing a recalled history entry should mutate the current buffer"
  if (history_next(editor)) error stop "editing should leave history browsing so next-history should no longer advance"
  if (editor%buffer /= "build!") error stop "history_next after edit should leave the edited buffer untouched"
end program test_history_edit_reset
