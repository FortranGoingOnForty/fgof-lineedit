program test_accept_line
  use fgof_lineedit, only : &
    accept_line, &
    add_history_entry, &
    completion_count, &
    default_prompt, &
    history_count, &
    history_next, &
    history_previous, &
    init_lineedit, &
    lineedit_state, &
    refresh_completion_menu, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor
  character(len=:), allocatable :: line

  call init_lineedit(editor, default_prompt("> "))

  call set_buffer(editor, "build", 3)
  call accept_line(editor, line)
  if (line /= "build") error stop "accept_line should return the current buffer contents"
  if (editor%buffer /= "") error stop "accept_line should clear the buffer for the next prompt"
  if (editor%cursor /= 1) error stop "accept_line should reset the cursor to the first insertion column"
  if (history_count(editor) /= 1) error stop "accept_line should store non-empty lines in history by default"
  if (.not. editor%active) error stop "accept_line should not deactivate the editor"

  call accept_line(editor, line)
  if (line /= "") error stop "accept_line should return an empty line when the buffer is empty"
  if (history_count(editor) /= 1) error stop "accept_line should not store empty lines by default"

  call set_buffer(editor, "scratch", 8)
  call accept_line(editor, line, store_history=.false.)
  if (line /= "scratch") error stop "accept_line should still return the buffer when history storage is disabled"
  if (history_count(editor) /= 1) error stop "accept_line should honor store_history=.false."

  call add_history_entry(editor, "echo one")
  call add_history_entry(editor, "echo two")
  if (.not. history_previous(editor)) error stop "history_previous should recall the newest entry before accept_line"
  call refresh_completion_menu(editor, provide_completions)
  if (completion_count(editor) /= 1) error stop "completion menu should be visible before accept_line clears it"

  call accept_line(editor, line)
  if (line /= "echo two") error stop "accept_line should accept recalled history lines"
  if (completion_count(editor) /= 0) error stop "accept_line should clear transient completion state"
  if (editor%completion_visible) error stop "accept_line should hide the completion menu"
  if (history_next(editor)) error stop "accept_line should clear transient history-navigation state"
  if (history_count(editor) /= 4) error stop "accept_line should add accepted recalled lines to history by default"

contains

  subroutine provide_completions(editor, span, items)
    use fgof_lineedit, only : completion_item, completion_span
    type(lineedit_state), intent(in) :: editor
    type(completion_span), intent(in) :: span
    type(completion_item), allocatable, intent(out) :: items(:)

    if (editor%buffer /= "echo two") error stop "provider should see the recalled history line"
    if (span%prefix /= "two") error stop "provider should see the active word prefix"

    allocate(items(1))
    items(1)%text = "echo"
  end subroutine provide_completions

end program test_accept_line
