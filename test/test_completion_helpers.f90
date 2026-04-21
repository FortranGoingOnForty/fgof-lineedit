program test_completion_helpers
  use fgof_lineedit, only : &
    add_history_entry, &
    apply_completion, &
    completion_span, &
    completion_span_at_cursor, &
    default_prompt, &
    history_next, &
    history_previous, &
    init_lineedit, &
    lineedit_state, &
    set_buffer
  implicit none

  type(lineedit_state) :: editor
  type(completion_span) :: span

  call init_lineedit(editor, default_prompt("> "))

  span = completion_span_at_cursor(editor)
  if (span%start_cursor /= 1 .or. span%end_cursor /= 1) error stop "empty buffer should expose an empty completion span"
  if (span%text /= "") error stop "empty buffer should have empty completion text"
  if (span%prefix /= "") error stop "empty buffer should have empty completion prefix"

  call set_buffer(editor, "alpha beta", 6)
  span = completion_span_at_cursor(editor)
  if (span%start_cursor /= 1 .or. span%end_cursor /= 6) error stop "cursor after a word should keep that word active"
  if (span%text /= "alpha") error stop "span text should include the active word"
  if (span%prefix /= "alpha") error stop "span prefix should include the typed portion before the cursor"

  call set_buffer(editor, "alpha beta", 9)
  span = completion_span_at_cursor(editor)
  if (span%start_cursor /= 7 .or. span%end_cursor /= 11) error stop "cursor inside a word should expose the full word bounds"
  if (span%text /= "beta") error stop "span text should include the full active word"
  if (span%prefix /= "be") error stop "span prefix should stop at the cursor"

  call set_buffer(editor, "alpha  beta", 7)
  span = completion_span_at_cursor(editor)
  if (span%start_cursor /= 7 .or. span%end_cursor /= 7) error stop "cursor between separators should expose an empty span at the cursor"
  if (span%text /= "") error stop "empty separator span should have no word text"
  if (span%prefix /= "") error stop "empty separator span should have no prefix"

  call set_buffer(editor, "run bu now", 7)
  if (.not. apply_completion(editor, "build")) error stop "apply_completion should replace the active word"
  if (editor%buffer /= "run build now") error stop "apply_completion should replace the active word in place"
  if (editor%cursor /= 10) error stop "apply_completion should place the cursor after the replacement"

  call set_buffer(editor, "run  now", 5)
  if (.not. apply_completion(editor, "build")) error stop "apply_completion should insert at an empty span"
  if (editor%buffer /= "run build now") error stop "apply_completion should insert a completion at an empty separator span"
  if (editor%cursor /= 10) error stop "apply_completion should place the cursor after an inserted completion"

  call set_buffer(editor, "build", 6)
  if (apply_completion(editor, "build")) error stop "apply_completion should report no change when the buffer already matches"

  call add_history_entry(editor, "echo one")
  call add_history_entry(editor, "echo two")
  call set_buffer(editor, "ec", 3)
  if (.not. history_previous(editor)) error stop "history browsing should still start before completion is applied"
  if (.not. apply_completion(editor, "echo")) error stop "apply_completion should edit recalled history entries"
  if (history_next(editor)) error stop "apply_completion should clear history navigation after editing"
end program test_completion_helpers
