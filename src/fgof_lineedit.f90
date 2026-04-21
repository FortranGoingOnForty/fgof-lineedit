module fgof_lineedit
  use fgof_lineedit_types, only : &
    FGOF_LINEEDIT_ACT_DELETE_LEFT, &
    FGOF_LINEEDIT_ACT_DELETE_RIGHT, &
    FGOF_LINEEDIT_ACT_HISTORY_NEXT, &
    FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS, &
    FGOF_LINEEDIT_ACT_INSERT, &
    FGOF_LINEEDIT_ACT_MOVE_END, &
    FGOF_LINEEDIT_ACT_MOVE_HOME, &
    FGOF_LINEEDIT_ACT_MOVE_LEFT, &
    FGOF_LINEEDIT_ACT_MOVE_RIGHT, &
    FGOF_LINEEDIT_ACT_MOVE_WORD_LEFT, &
    FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT, &
    FGOF_LINEEDIT_ACT_NONE, &
    history_entry, &
    lineedit_action, &
    lineedit_state, &
    prompt_spec
  implicit none
  private

  public :: add_history_entry
  public :: apply_action
  public :: buffer_length
  public :: delete_left
  public :: delete_right
  public :: default_prompt
  public :: FGOF_LINEEDIT_ACT_DELETE_LEFT
  public :: FGOF_LINEEDIT_ACT_DELETE_RIGHT
  public :: FGOF_LINEEDIT_ACT_HISTORY_NEXT
  public :: FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS
  public :: FGOF_LINEEDIT_ACT_INSERT
  public :: FGOF_LINEEDIT_ACT_MOVE_END
  public :: FGOF_LINEEDIT_ACT_MOVE_HOME
  public :: FGOF_LINEEDIT_ACT_MOVE_LEFT
  public :: FGOF_LINEEDIT_ACT_MOVE_RIGHT
  public :: FGOF_LINEEDIT_ACT_MOVE_WORD_LEFT
  public :: FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT
  public :: FGOF_LINEEDIT_ACT_NONE
  public :: history_count
  public :: history_next
  public :: history_previous
  public :: init_lineedit
  public :: insert_action
  public :: insert_text
  public :: lineedit_action
  public :: lineedit_state
  public :: move_cursor_end
  public :: move_cursor_home
  public :: move_cursor_left
  public :: move_cursor_right
  public :: move_cursor_word_left
  public :: move_cursor_word_right
  public :: prompt_spec
  public :: reset_lineedit
  public :: set_buffer
  public :: simple_action

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

  logical function move_cursor_word_left(editor) result(moved)
    type(lineedit_state), intent(inout) :: editor
    integer :: new_cursor

    call normalize_lineedit(editor)
    new_cursor = previous_word_cursor(editor%buffer, editor%cursor)
    if (new_cursor == editor%cursor) then
      moved = .false.
      return
    end if

    editor%cursor = new_cursor
    moved = .true.
  end function move_cursor_word_left

  logical function move_cursor_word_right(editor) result(moved)
    type(lineedit_state), intent(inout) :: editor
    integer :: new_cursor

    call normalize_lineedit(editor)
    new_cursor = next_word_cursor(editor%buffer, editor%cursor)
    if (new_cursor == editor%cursor) then
      moved = .false.
      return
    end if

    editor%cursor = new_cursor
    moved = .true.
  end function move_cursor_word_right

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

  function simple_action(kind) result(action)
    integer, intent(in) :: kind
    type(lineedit_action) :: action

    action%kind = kind
  end function simple_action

  function insert_action(text) result(action)
    character(len=*), intent(in) :: text
    type(lineedit_action) :: action

    action%kind = FGOF_LINEEDIT_ACT_INSERT
    action%text = text
  end function insert_action

  logical function apply_action(editor, action) result(changed)
    type(lineedit_state), intent(inout) :: editor
    type(lineedit_action), intent(in) :: action
    character(len=:), allocatable :: old_buffer
    integer :: old_cursor

    call normalize_lineedit(editor)
    old_buffer = editor%buffer
    old_cursor = editor%cursor

    select case (action%kind)
    case (FGOF_LINEEDIT_ACT_NONE)
      changed = .false.
    case (FGOF_LINEEDIT_ACT_INSERT)
      if (.not. allocated(action%text)) then
        changed = .false.
      else
        call insert_text(editor, action%text)
        changed = editor%buffer /= old_buffer .or. editor%cursor /= old_cursor
      end if
    case (FGOF_LINEEDIT_ACT_DELETE_LEFT)
      changed = delete_left(editor)
    case (FGOF_LINEEDIT_ACT_DELETE_RIGHT)
      changed = delete_right(editor)
    case (FGOF_LINEEDIT_ACT_MOVE_LEFT)
      changed = move_cursor_left(editor)
    case (FGOF_LINEEDIT_ACT_MOVE_RIGHT)
      changed = move_cursor_right(editor)
    case (FGOF_LINEEDIT_ACT_MOVE_WORD_LEFT)
      changed = move_cursor_word_left(editor)
    case (FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT)
      changed = move_cursor_word_right(editor)
    case (FGOF_LINEEDIT_ACT_MOVE_HOME)
      call move_cursor_home(editor)
      changed = editor%cursor /= old_cursor
    case (FGOF_LINEEDIT_ACT_MOVE_END)
      call move_cursor_end(editor)
      changed = editor%cursor /= old_cursor
    case (FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS)
      changed = history_previous(editor)
    case (FGOF_LINEEDIT_ACT_HISTORY_NEXT)
      changed = history_next(editor)
    case default
      changed = .false.
    end select
  end function apply_action

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

  integer function previous_word_cursor(buffer, cursor) result(new_cursor)
    character(len=*), intent(in) :: buffer
    integer, intent(in) :: cursor
    integer :: idx

    idx = min(max(cursor - 1, 0), len(buffer))
    do while (idx >= 1 .and. is_word_separator(buffer(idx:idx)))
      idx = idx - 1
    end do
    do while (idx >= 1 .and. .not. is_word_separator(buffer(idx:idx)))
      idx = idx - 1
    end do

    new_cursor = idx + 1
  end function previous_word_cursor

  integer function next_word_cursor(buffer, cursor) result(new_cursor)
    character(len=*), intent(in) :: buffer
    integer, intent(in) :: cursor
    integer :: idx
    integer :: limit

    limit = len(buffer)
    idx = max(cursor, 1)
    if (idx > limit) then
      new_cursor = limit + 1
      return
    end if

    do while (idx <= limit .and. .not. is_word_separator(buffer(idx:idx)))
      idx = idx + 1
    end do
    do while (idx <= limit .and. is_word_separator(buffer(idx:idx)))
      idx = idx + 1
    end do

    new_cursor = idx
  end function next_word_cursor

  logical function is_word_separator(char) result(separator)
    character(len=1), intent(in) :: char

    separator = char == " " .or. char == achar(9)
  end function is_word_separator

end module fgof_lineedit
