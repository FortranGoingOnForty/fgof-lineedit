program test_edit_core
  use fgof_lineedit, only : &
    buffer_length, &
    default_prompt, &
    delete_left, &
    delete_right, &
    init_lineedit, &
    insert_text, &
    lineedit_state, &
    move_cursor_left, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor

  call init_lineedit(editor, default_prompt("> "))
  call insert_text(editor, "abc")
  if (editor%buffer /= "abc") error stop "insert_text should append into an empty buffer"
  if (buffer_length(editor) /= 3) error stop "buffer_length should track inserted text"
  if (editor%cursor /= 4) error stop "cursor should advance after insertion"

  if (.not. move_cursor_left(editor)) error stop "cursor should move left inside the buffer"
  if (.not. move_cursor_left(editor)) error stop "cursor should keep moving left until the start"
  call insert_text(editor, "X")
  if (editor%buffer /= "aXbc") error stop "insert_text should splice text at the cursor"
  if (editor%cursor /= 3) error stop "cursor should sit after inserted text"

  if (.not. delete_left(editor)) error stop "delete_left should remove the character before the cursor"
  if (editor%buffer /= "abc") error stop "delete_left should restore the original text here"
  if (editor%cursor /= 2) error stop "delete_left should move the cursor back one column"

  call set_buffer(editor, "hello", 2)
  if (.not. delete_right(editor)) error stop "delete_right should remove the character at the cursor"
  if (editor%buffer /= "hllo") error stop "delete_right should remove the current character"
  if (editor%cursor /= 2) error stop "delete_right should keep the cursor at the same insertion point"
end program test_edit_core
