module fgof_lineedit
  use fgof_lineedit_types, only : history_entry, lineedit_state, prompt_spec
  implicit none
  private

  public :: add_history_entry
  public :: buffer_length
  public :: delete_left
  public :: delete_right
  public :: default_prompt
  public :: history_count
  public :: history_next
  public :: history_previous
  public :: init_lineedit
  public :: insert_text
  public :: lineedit_state
  public :: move_cursor_end
  public :: move_cursor_home
  public :: move_cursor_left
  public :: move_cursor_right
  public :: prompt_spec
  public :: reset_lineedit
  public :: set_buffer

contains

  function default_prompt(text) result(prompt)
    character(len=*), intent(in) :: text
    type(prompt_spec) :: prompt

    prompt%text = text
  end function default_prompt

  subroutine init_lineedit(editor, prompt)
    type(lineedit_state), intent(out) :: editor
    type(prompt_spec), intent(in), optional :: prompt

    if (present(prompt)) then
      editor%prompt = prompt
    else
      editor%prompt = default_prompt("> ")
    end if

    editor%buffer = ""
    editor%cursor = 1
    editor%active = .true.
    editor%history_index = 0
    editor%browsing_history = .false.
    editor%stashed_buffer = ""
    editor%stashed_cursor = 1
    call normalize_lineedit(editor)
  end subroutine init_lineedit

  subroutine reset_lineedit(editor)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    editor%buffer = ""
    editor%cursor = 1
    editor%active = .false.
    call clear_history_navigation(editor)
  end subroutine reset_lineedit

  integer function buffer_length(editor) result(length)
    type(lineedit_state), intent(in) :: editor

    if (allocated(editor%buffer)) then
      length = len(editor%buffer)
    else
      length = 0
    end if
  end function buffer_length

  subroutine set_buffer(editor, text, cursor)
    type(lineedit_state), intent(inout) :: editor
    character(len=*), intent(in) :: text
    integer, intent(in), optional :: cursor

    call normalize_lineedit(editor)
    call assign_buffer(editor, text, cursor, clear_history=.true.)
  end subroutine set_buffer

  subroutine insert_text(editor, text)
    type(lineedit_state), intent(inout) :: editor
    character(len=*), intent(in) :: text
    integer :: insert_at
    integer :: old_length

    call normalize_lineedit(editor)
    if (len(text) == 0) return
    call clear_history_navigation(editor)

    insert_at = editor%cursor
    old_length = len(editor%buffer)

    if (old_length == 0) then
      editor%buffer = text
    else if (insert_at <= 1) then
      editor%buffer = text // editor%buffer
    else if (insert_at > old_length) then
      editor%buffer = editor%buffer // text
    else
      editor%buffer = editor%buffer(:insert_at - 1) // text // editor%buffer(insert_at:)
    end if

    editor%cursor = insert_at + len(text)
  end subroutine insert_text

  logical function delete_left(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: delete_at
    integer :: old_length

    call normalize_lineedit(editor)
    old_length = len(editor%buffer)

    if (old_length == 0 .or. editor%cursor <= 1) then
      changed = .false.
      return
    end if

    call clear_history_navigation(editor)

    delete_at = editor%cursor - 1
    if (old_length == 1) then
      editor%buffer = ""
    else if (delete_at == 1) then
      editor%buffer = editor%buffer(2:)
    else if (delete_at == old_length) then
      editor%buffer = editor%buffer(:old_length - 1)
    else
      editor%buffer = editor%buffer(:delete_at - 1) // editor%buffer(delete_at + 1:)
    end if

    editor%cursor = editor%cursor - 1
    changed = .true.
  end function delete_left

  logical function delete_right(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: delete_at
    integer :: old_length

    call normalize_lineedit(editor)
    old_length = len(editor%buffer)

    if (old_length == 0 .or. editor%cursor > old_length) then
      changed = .false.
      return
    end if

    call clear_history_navigation(editor)

    delete_at = editor%cursor
    if (old_length == 1) then
      editor%buffer = ""
    else if (delete_at == 1) then
      editor%buffer = editor%buffer(2:)
    else if (delete_at == old_length) then
      editor%buffer = editor%buffer(:old_length - 1)
    else
      editor%buffer = editor%buffer(:delete_at - 1) // editor%buffer(delete_at + 1:)
    end if

    call clamp_cursor(editor)
    changed = .true.
  end function delete_right

  logical function move_cursor_left(editor) result(moved)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    if (editor%cursor <= 1) then
      moved = .false.
      return
    end if

    editor%cursor = editor%cursor - 1
    moved = .true.
  end function move_cursor_left

  logical function move_cursor_right(editor) result(moved)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    if (editor%cursor >= len(editor%buffer) + 1) then
      moved = .false.
      return
    end if

    editor%cursor = editor%cursor + 1
    moved = .true.
  end function move_cursor_right

  subroutine move_cursor_home(editor)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    editor%cursor = 1
  end subroutine move_cursor_home

  subroutine move_cursor_end(editor)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    editor%cursor = len(editor%buffer) + 1
  end subroutine move_cursor_end

  integer function history_count(editor) result(count)
    type(lineedit_state), intent(in) :: editor

    if (allocated(editor%history)) then
      count = size(editor%history)
    else
      count = 0
    end if
  end function history_count

  subroutine add_history_entry(editor, text)
    type(lineedit_state), intent(inout) :: editor
    character(len=*), intent(in) :: text
    type(history_entry), allocatable :: new_history(:)
    integer :: count
    integer :: i

    call normalize_lineedit(editor)
    if (len_trim(text) == 0) return

    count = history_count(editor)
    allocate(new_history(count + 1))
    do i = 1, count
      new_history(i)%text = editor%history(i)%text
    end do
    new_history(count + 1)%text = text

    call move_alloc(new_history, editor%history)
    call clear_history_navigation(editor)
  end subroutine add_history_entry

  logical function history_previous(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: count

    call normalize_lineedit(editor)
    count = history_count(editor)
    if (count == 0) then
      changed = .false.
      return
    end if

    if (.not. editor%browsing_history) then
      editor%stashed_buffer = editor%buffer
      editor%stashed_cursor = editor%cursor
      editor%browsing_history = .true.
      editor%history_index = count
    else if (editor%history_index > 1) then
      editor%history_index = editor%history_index - 1
    else
      changed = .false.
      return
    end if

    call assign_buffer(editor, editor%history(editor%history_index)%text, len(editor%history(editor%history_index)%text) + 1, &
      clear_history=.false.)
    changed = .true.
  end function history_previous

  logical function history_next(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: count

    call normalize_lineedit(editor)
    if (.not. editor%browsing_history) then
      changed = .false.
      return
    end if

    count = history_count(editor)
    if (count == 0) then
      call clear_history_navigation(editor)
      changed = .false.
      return
    end if

    if (editor%history_index < count) then
      editor%history_index = editor%history_index + 1
      call assign_buffer(editor, editor%history(editor%history_index)%text, len(editor%history(editor%history_index)%text) + 1, &
        clear_history=.false.)
      changed = .true.
      return
    end if

    call assign_buffer(editor, editor%stashed_buffer, editor%stashed_cursor, clear_history=.false.)
    call clear_history_navigation(editor)
    changed = .true.
  end function history_next

  subroutine normalize_lineedit(editor)
    type(lineedit_state), intent(inout) :: editor

    if (.not. allocated(editor%prompt%text)) editor%prompt%text = ""
    if (.not. allocated(editor%buffer)) editor%buffer = ""
    if (.not. allocated(editor%stashed_buffer)) editor%stashed_buffer = ""
    call clamp_cursor(editor)
  end subroutine normalize_lineedit

  subroutine assign_buffer(editor, text, cursor, clear_history)
    type(lineedit_state), intent(inout) :: editor
    character(len=*), intent(in) :: text
    integer, intent(in), optional :: cursor
    logical, intent(in) :: clear_history

    editor%buffer = text
    if (present(cursor)) then
      editor%cursor = cursor
    else
      editor%cursor = len(text) + 1
    end if

    call clamp_cursor(editor)
    if (clear_history) call clear_history_navigation(editor)
  end subroutine assign_buffer

  subroutine clear_history_navigation(editor)
    type(lineedit_state), intent(inout) :: editor

    editor%browsing_history = .false.
    editor%history_index = 0
    editor%stashed_buffer = ""
    editor%stashed_cursor = 1
  end subroutine clear_history_navigation

  subroutine clamp_cursor(editor)
    type(lineedit_state), intent(inout) :: editor
    integer :: max_cursor

    if (.not. allocated(editor%buffer)) then
      max_cursor = 1
    else
      max_cursor = len(editor%buffer) + 1
    end if

    if (editor%cursor < 1) editor%cursor = 1
    if (editor%cursor > max_cursor) editor%cursor = max_cursor
  end subroutine clamp_cursor

end module fgof_lineedit
