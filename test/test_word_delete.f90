program test_word_delete
  use fgof_lineedit, only : &
    FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT, &
    default_prompt, &
    delete_word_left, &
    delete_word_right, &
    init_lineedit, &
    lineedit_state, &
    set_buffer, &
    apply_action, &
    simple_action
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("> "))

  call set_buffer(editor, "alpha  beta", 8)
  if (.not. delete_word_left(editor)) error stop "delete_word_left should delete the previous word and separator run before the cursor"
  if (editor%buffer /= "beta") error stop "delete_word_left should remove the previous word when the cursor is at the next word"
  if (editor%cursor /= 1) error stop "delete_word_left should leave the cursor at the start of the deleted span"

  call set_buffer(editor, "alpha  beta", 6)
  if (.not. delete_word_right(editor)) error stop "delete_word_right should delete the next word when the cursor is inside separators"
  if (editor%buffer /= "alpha") error stop "delete_word_right should remove separators and the next word"
  if (editor%cursor /= 6) error stop "delete_word_right should keep the cursor at the deletion point"

  call set_buffer(editor, "alpha beta", 3)
  if (.not. delete_word_right(editor)) error stop "delete_word_right should delete the remainder of the current word"
  if (editor%buffer /= "al beta") error stop "delete_word_right should delete from the cursor to the next word boundary"

  call set_buffer(editor, "alpha  ", 8)
  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT))) then
    error stop "delete-word-left action should reuse word deletion semantics"
  end if
  if (editor%buffer /= "") error stop "delete-word-left action should remove a trailing word and spaces"
  if (editor%cursor /= 1) error stop "delete-word-left action should clamp the cursor at the buffer start"
end program test_word_delete
