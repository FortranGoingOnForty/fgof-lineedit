program test_action_dispatch
  use fgof_lineedit, only : &
    FGOF_LINEEDIT_ACT_DELETE_LEFT, &
    FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT, &
    FGOF_LINEEDIT_ACT_HISTORY_NEXT, &
    FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS, &
    FGOF_LINEEDIT_ACT_MOVE_HOME, &
    FGOF_LINEEDIT_ACT_MOVE_LEFT, &
    FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT, &
    add_history_entry, &
    apply_action, &
    default_prompt, &
    init_lineedit, &
    insert_action, &
    lineedit_action, &
    lineedit_state, &
    set_buffer, &
    simple_action
  implicit none

  type(lineedit_state) :: editor
  type(lineedit_action) :: action

  call init_lineedit(editor, default_prompt("> "))

  if (apply_action(editor, simple_action(999))) error stop "unknown actions should leave the editor unchanged"
  if (.not. apply_action(editor, insert_action("abc"))) error stop "insert action should edit the buffer"
  if (editor%buffer /= "abc") error stop "insert action should insert text through the shared edit path"
  if (editor%cursor /= 4) error stop "insert action should advance the cursor"

  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_MOVE_LEFT))) then
    error stop "move-left action should move the cursor"
  end if
  if (editor%cursor /= 3) error stop "move-left action should update the insertion column"

  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_DELETE_LEFT))) then
    error stop "delete-left action should remove the character before the cursor"
  end if
  if (editor%buffer /= "ac") error stop "delete-left action should reuse delete_left semantics"
  if (editor%cursor /= 2) error stop "delete-left action should move the cursor back one column"

  call set_buffer(editor, "alpha beta", 3)
  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT))) then
    error stop "delete-word-right action should delete to the next word boundary"
  end if
  if (editor%buffer /= "al beta") error stop "delete-word-right action should reuse word deletion semantics"
  if (editor%cursor /= 3) error stop "delete-word-right action should keep the cursor at the deletion point"

  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_MOVE_HOME))) then
    error stop "move-home action should move the cursor when it is not already home"
  end if
  if (editor%cursor /= 1) error stop "move-home action should place the cursor at the first insertion column"
  if (apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_MOVE_HOME))) then
    error stop "move-home action should report no change when already home"
  end if

  call set_buffer(editor, "alpha  beta", 1)
  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT))) then
    error stop "word-right action should move to the next word boundary"
  end if
  if (editor%cursor /= 8) error stop "word-right action should land on the next word start"

  action = simple_action(0)
  if (apply_action(editor, action)) error stop "none action should report no change"
  if (apply_action(editor, insert_action(""))) error stop "empty insert action should report no change"

  call add_history_entry(editor, "build")
  call add_history_entry(editor, "test")
  call set_buffer(editor, "draft", 6)

  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS))) then
    error stop "history-previous action should recall history"
  end if
  if (editor%buffer /= "test") error stop "history-previous action should recall the newest entry first"

  if (.not. apply_action(editor, simple_action(FGOF_LINEEDIT_ACT_HISTORY_NEXT))) then
    error stop "history-next action should restore the stashed current buffer"
  end if
  if (editor%buffer /= "draft") error stop "history-next action should restore the draft buffer"
  if (editor%cursor /= 6) error stop "history-next action should restore the stashed cursor"
end program test_action_dispatch
