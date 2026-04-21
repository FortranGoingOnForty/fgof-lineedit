program test_completion_menu
  use fgof_lineedit, only : &
    apply_selected_completion, &
    clear_completion_menu, &
    completion_count, &
    completion_item, &
    completion_span, &
    default_prompt, &
    init_lineedit, &
    lineedit_state, &
    move_cursor_left, &
    refresh_completion_menu, &
    select_next_completion, &
    select_previous_completion, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("> "))
  call set_buffer(editor, "bu", 3)
  call refresh_completion_menu(editor, provide_completions)

  if (completion_count(editor) /= 2) error stop "refresh_completion_menu should load provider results into editor state"
  if (.not. editor%completion_visible) error stop "completion menu should be visible after loading candidates"
  if (editor%completion_index /= 1) error stop "completion menu should select the first candidate initially"
  if (editor%completion_items(1)%text /= "build") error stop "completion menu should keep provider text"
  if (editor%completion_items(2)%display /= "bundle (dir)") error stop "completion menu should keep provider display labels"

  if (.not. select_next_completion(editor)) error stop "next completion should advance the current selection"
  if (editor%completion_index /= 2) error stop "next completion should move to the second candidate"
  if (.not. select_next_completion(editor)) error stop "next completion should wrap when more than one candidate exists"
  if (editor%completion_index /= 1) error stop "next completion should wrap to the first candidate"
  if (.not. select_previous_completion(editor)) error stop "previous completion should wrap backward"
  if (editor%completion_index /= 2) error stop "previous completion should wrap to the final candidate"

  if (.not. apply_selected_completion(editor)) error stop "apply_selected_completion should apply the selected replacement"
  if (editor%buffer /= "bundle") error stop "apply_selected_completion should replace the active word with the selected candidate"
  if (editor%cursor /= 7) error stop "apply_selected_completion should place the cursor after the replacement"
  if (completion_count(editor) /= 0) error stop "apply_selected_completion should clear the menu state"
  if (editor%completion_visible) error stop "apply_selected_completion should hide the completion menu"

  call set_buffer(editor, "bu", 3)
  call refresh_completion_menu(editor, provide_completions)
  if (.not. move_cursor_left(editor)) error stop "cursor movement should still work while completions are visible"
  if (completion_count(editor) /= 0) error stop "cursor movement should clear stale completion results"

  call refresh_completion_menu(editor, provide_none)
  if (completion_count(editor) /= 0) error stop "empty provider results should clear the menu"
  if (editor%completion_visible) error stop "empty provider results should hide the completion menu"

  call clear_completion_menu(editor)
  if (select_next_completion(editor)) error stop "select_next_completion should fail with no menu items"

contains

  subroutine provide_completions(editor, span, items)
    type(lineedit_state), intent(in) :: editor
    type(completion_span), intent(in) :: span
    type(completion_item), allocatable, intent(out) :: items(:)

    if (editor%buffer /= "bu") error stop "provider should see the current editor state"
    if (span%prefix == "bu") then
      allocate(items(2))
      items(1)%text = "build"
      items(2)%text = "bundle"
      items(2)%display = "bundle (dir)"
    else
      allocate(items(0))
    end if
  end subroutine provide_completions

  subroutine provide_none(editor, span, items)
    type(lineedit_state), intent(in) :: editor
    type(completion_span), intent(in) :: span
    type(completion_item), allocatable, intent(out) :: items(:)

    if (.not. allocated(editor%buffer)) error stop "provider should always see a normalized editor buffer"
    if (.not. allocated(span%prefix)) error stop "provider should always see a normalized completion prefix"
    allocate(items(0))
  end subroutine provide_none

end program test_completion_menu
