program test_render_state
  use fgof_lineedit, only : &
    completion_item, &
    default_prompt, &
    init_lineedit, &
    lineedit_render_state, &
    lineedit_state, &
    refresh_completion_menu, &
    render_lineedit, &
    select_next_completion, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor
  type(lineedit_render_state) :: view

  call init_lineedit(editor, default_prompt("line> "))
  call set_buffer(editor, "build", 3)
  view = render_lineedit(editor)

  if (view%prompt /= "line> ") error stop "render_lineedit should preserve the prompt text"
  if (view%buffer /= "build") error stop "render_lineedit should preserve the buffer text"
  if (view%line /= "line> build") error stop "render_lineedit should expose the concatenated rendered line"
  if (view%cursor_column /= 9) error stop "render_lineedit should place the cursor at the rendered insertion column"
  if (view%completion_visible) error stop "render_lineedit should hide completions when no menu is active"
  if (allocated(view%completions)) error stop "render_lineedit should not allocate completion rows when no menu is active"

  call set_buffer(editor, "bu", 3)
  call refresh_completion_menu(editor, provide_completions)
  view = render_lineedit(editor)

  if (.not. view%completion_visible) error stop "render_lineedit should expose visible completion menus"
  if (.not. allocated(view%completions)) error stop "render_lineedit should expose completion rows when a menu is active"
  if (size(view%completions) /= 2) error stop "render_lineedit should mirror the completion menu size"
  if (view%completions(1)%text /= "build") error stop "render_lineedit should prefer display text or fallback text"
  if (.not. view%completions(1)%selected) error stop "render_lineedit should mark the selected completion row"
  if (view%completions(2)%text /= "bundle (dir)") error stop "render_lineedit should use display text when available"
  if (view%completions(2)%selected) error stop "render_lineedit should not mark unselected completion rows"

  if (.not. select_next_completion(editor)) error stop "completion cycling should still work before rendering again"
  view = render_lineedit(editor)
  if (.not. view%completions(2)%selected) error stop "render_lineedit should track updated completion selection"

contains

  subroutine provide_completions(editor, span, items)
    use fgof_lineedit, only : completion_span
    type(lineedit_state), intent(in) :: editor
    type(completion_span), intent(in) :: span
    type(completion_item), allocatable, intent(out) :: items(:)

    if (editor%buffer /= "bu") error stop "provider should still see the current editor buffer"
    if (span%prefix /= "bu") error stop "provider should still see the active prefix"

    allocate(items(2))
    items(1)%text = "build"
    items(2)%text = "bundle"
    items(2)%display = "bundle (dir)"
  end subroutine provide_completions

end program test_render_state
