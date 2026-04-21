module fgof_lineedit
  use fgof_lineedit_types, only : &
    FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT, &
    FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT, &
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
    completion_item, &
    completion_span, &
    history_entry, &
    lineedit_action, &
    lineedit_render_completion, &
    lineedit_render_state, &
    lineedit_state, &
    prompt_spec
  implicit none
  private

  public :: accept_line
  public :: add_history_entry
  public :: apply_completion
  public :: apply_selected_completion
  public :: apply_action
  public :: buffer_length
  public :: clear_completion_menu
  public :: completion_count
  public :: completion_item
  public :: completion_span
  public :: completion_span_at_cursor
  public :: delete_left
  public :: delete_word_left
  public :: delete_word_right
  public :: delete_right
  public :: default_prompt
  public :: FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT
  public :: FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT
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
  public :: lineedit_completion_provider
  public :: lineedit_action
  public :: lineedit_render_completion
  public :: lineedit_render_state
  public :: lineedit_state
  public :: move_cursor_end
  public :: move_cursor_home
  public :: move_cursor_left
  public :: move_cursor_right
  public :: move_cursor_word_left
  public :: move_cursor_word_right
  public :: prompt_spec
  public :: refresh_completion_menu
  public :: render_lineedit
  public :: reset_lineedit
  public :: select_next_completion
  public :: select_previous_completion
  public :: set_buffer
  public :: set_completion_items
  public :: simple_action

  abstract interface
    subroutine lineedit_completion_provider(editor, span, items)
      import :: completion_item, completion_span, lineedit_state
      type(lineedit_state), intent(in) :: editor
      type(completion_span), intent(in) :: span
      type(completion_item), allocatable, intent(out) :: items(:)
    end subroutine lineedit_completion_provider
  end interface

contains

  function default_prompt(text) result(prompt)
    character(len=*), intent(in) :: text
    type(prompt_spec) :: prompt

    prompt%text = text
  end function default_prompt

  subroutine accept_line(editor, line, store_history)
    type(lineedit_state), intent(inout) :: editor
    character(len=:), allocatable, intent(out) :: line
    logical, intent(in), optional :: store_history
    logical :: should_store

    call normalize_lineedit(editor)
    line = editor%buffer

    if (present(store_history)) then
      should_store = store_history
    else
      should_store = len_trim(line) > 0
    end if

    if (should_store) call add_history_entry(editor, line)

    editor%buffer = ""
    editor%cursor = 1
    call clear_history_navigation(editor)
    call clear_completion_menu(editor)
  end subroutine accept_line

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
    editor%completion_index = 0
    editor%completion_visible = .false.
    call normalize_lineedit(editor)
  end subroutine init_lineedit

  subroutine reset_lineedit(editor)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    editor%buffer = ""
    editor%cursor = 1
    editor%active = .false.
    call clear_history_navigation(editor)
    call clear_completion_menu(editor)
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
    call clear_completion_menu(editor)
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
    call clear_completion_menu(editor)

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
    call clear_completion_menu(editor)

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
    call clear_completion_menu(editor)

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

  logical function delete_word_left(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: delete_start

    call normalize_lineedit(editor)
    if (editor%cursor <= 1) then
      changed = .false.
      return
    end if

    delete_start = previous_delete_cursor(editor%buffer, editor%cursor)
    if (delete_start >= editor%cursor) then
      changed = .false.
      return
    end if

    call clear_history_navigation(editor)
    call clear_completion_menu(editor)
    call delete_span(editor, delete_start, editor%cursor)
    changed = .true.
  end function delete_word_left

  logical function delete_word_right(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: delete_end

    call normalize_lineedit(editor)
    if (editor%cursor > len(editor%buffer)) then
      changed = .false.
      return
    end if

    delete_end = next_delete_cursor(editor%buffer, editor%cursor)
    if (delete_end <= editor%cursor) then
      changed = .false.
      return
    end if

    call clear_history_navigation(editor)
    call clear_completion_menu(editor)
    call delete_span(editor, editor%cursor, delete_end)
    changed = .true.
  end function delete_word_right

  logical function move_cursor_left(editor) result(moved)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    if (editor%cursor <= 1) then
      moved = .false.
      return
    end if

    editor%cursor = editor%cursor - 1
    call clear_completion_menu(editor)
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
    call clear_completion_menu(editor)
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
    call clear_completion_menu(editor)
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
    call clear_completion_menu(editor)
    moved = .true.
  end function move_cursor_word_right

  subroutine move_cursor_home(editor)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    editor%cursor = 1
    call clear_completion_menu(editor)
  end subroutine move_cursor_home

  subroutine move_cursor_end(editor)
    type(lineedit_state), intent(inout) :: editor

    call normalize_lineedit(editor)
    editor%cursor = len(editor%buffer) + 1
    call clear_completion_menu(editor)
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
    case (FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT)
      changed = delete_word_left(editor)
    case (FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT)
      changed = delete_word_right(editor)
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

  function completion_span_at_cursor(editor) result(span)
    type(lineedit_state), intent(in) :: editor
    type(completion_span) :: span
    integer :: start_cursor
    integer :: end_cursor
    integer :: prefix_end
    character(len=:), allocatable :: buffer

    if (allocated(editor%buffer)) then
      buffer = editor%buffer
    else
      buffer = ""
    end if

    call word_bounds_at_cursor(buffer, editor%cursor, start_cursor, end_cursor)
    span%start_cursor = start_cursor
    span%end_cursor = end_cursor

    if (end_cursor > start_cursor) then
      span%text = buffer(start_cursor:end_cursor - 1)
    else
      span%text = ""
    end if

    prefix_end = min(max(editor%cursor - 1, 0), end_cursor - 1)
    if (prefix_end >= start_cursor) then
      span%prefix = buffer(start_cursor:prefix_end)
    else
      span%prefix = ""
    end if
  end function completion_span_at_cursor

  logical function apply_completion(editor, replacement) result(changed)
    type(lineedit_state), intent(inout) :: editor
    character(len=*), intent(in) :: replacement
    type(completion_span) :: span
    character(len=:), allocatable :: before
    character(len=:), allocatable :: after
    character(len=:), allocatable :: new_buffer

    call normalize_lineedit(editor)
    span = completion_span_at_cursor(editor)

    if (span%start_cursor > 1) then
      before = editor%buffer(:span%start_cursor - 1)
    else
      before = ""
    end if

    if (span%end_cursor <= len(editor%buffer)) then
      after = editor%buffer(span%end_cursor:)
    else
      after = ""
    end if

    new_buffer = before // replacement // after
    if (new_buffer == editor%buffer .and. editor%cursor == span%start_cursor + len(replacement)) then
      changed = .false.
      return
    end if

    call clear_history_navigation(editor)
    call clear_completion_menu(editor)
    editor%buffer = new_buffer
    editor%cursor = span%start_cursor + len(replacement)
    call clamp_cursor(editor)
    changed = .true.
  end function apply_completion

  integer function completion_count(editor) result(count)
    type(lineedit_state), intent(in) :: editor

    if (allocated(editor%completion_items)) then
      count = size(editor%completion_items)
    else
      count = 0
    end if
  end function completion_count

  subroutine clear_completion_menu(editor)
    type(lineedit_state), intent(inout) :: editor

    if (allocated(editor%completion_items)) deallocate(editor%completion_items)
    editor%completion_index = 0
    editor%completion_visible = .false.
  end subroutine clear_completion_menu

  subroutine set_completion_items(editor, items)
    type(lineedit_state), intent(inout) :: editor
    type(completion_item), intent(in) :: items(:)
    integer :: i

    call clear_completion_menu(editor)
    if (size(items) == 0) return

    editor%completion_items = items
    do i = 1, size(editor%completion_items)
      if (.not. allocated(editor%completion_items(i)%text)) then
        if (allocated(editor%completion_items(i)%display)) then
          editor%completion_items(i)%text = editor%completion_items(i)%display
        else
          editor%completion_items(i)%text = ""
        end if
      end if
      if (.not. allocated(editor%completion_items(i)%display)) then
        editor%completion_items(i)%display = editor%completion_items(i)%text
      end if
    end do

    editor%completion_index = 1
    editor%completion_visible = .true.
  end subroutine set_completion_items

  subroutine refresh_completion_menu(editor, provider)
    type(lineedit_state), intent(inout) :: editor
    procedure(lineedit_completion_provider) :: provider
    type(completion_span) :: span
    type(completion_item), allocatable :: items(:)

    call normalize_lineedit(editor)
    span = completion_span_at_cursor(editor)
    call provider(editor, span, items)

    if (.not. allocated(items)) then
      call clear_completion_menu(editor)
      return
    end if

    call set_completion_items(editor, items)
  end subroutine refresh_completion_menu

  logical function select_next_completion(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: count

    count = completion_count(editor)
    if (count <= 1) then
      changed = .false.
      return
    end if

    editor%completion_index = mod(editor%completion_index, count) + 1
    editor%completion_visible = .true.
    changed = .true.
  end function select_next_completion

  logical function select_previous_completion(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: count

    count = completion_count(editor)
    if (count <= 1) then
      changed = .false.
      return
    end if

    editor%completion_index = mod(editor%completion_index + count - 2, count) + 1
    editor%completion_visible = .true.
    changed = .true.
  end function select_previous_completion

  logical function apply_selected_completion(editor) result(changed)
    type(lineedit_state), intent(inout) :: editor
    integer :: count
    character(len=:), allocatable :: replacement

    count = completion_count(editor)
    if (count == 0) then
      changed = .false.
      return
    end if

    if (editor%completion_index < 1 .or. editor%completion_index > count) then
      call clear_completion_menu(editor)
      changed = .false.
      return
    end if

    replacement = editor%completion_items(editor%completion_index)%text
    changed = apply_completion(editor, replacement)
    call clear_completion_menu(editor)
  end function apply_selected_completion

  function render_lineedit(editor) result(view)
    type(lineedit_state), intent(in) :: editor
    type(lineedit_render_state) :: view
    integer :: i
    integer :: count

    if (allocated(editor%prompt%text)) then
      view%prompt = editor%prompt%text
    else
      view%prompt = ""
    end if

    if (allocated(editor%buffer)) then
      view%buffer = editor%buffer
    else
      view%buffer = ""
    end if

    view%line = view%prompt // view%buffer
    view%cursor_column = len(view%prompt) + max(editor%cursor, 1)

    count = completion_count(editor)
    if (count > 0) then
      allocate(view%completions(count))
      do i = 1, count
        if (allocated(editor%completion_items(i)%display)) then
          view%completions(i)%text = editor%completion_items(i)%display
        else if (allocated(editor%completion_items(i)%text)) then
          view%completions(i)%text = editor%completion_items(i)%text
        else
          view%completions(i)%text = ""
        end if
        view%completions(i)%selected = editor%completion_index == i
      end do
    end if
    view%completion_visible = editor%completion_visible .and. count > 0
  end function render_lineedit

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

    call clear_completion_menu(editor)
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
      call clear_completion_menu(editor)
      call assign_buffer(editor, editor%history(editor%history_index)%text, len(editor%history(editor%history_index)%text) + 1, &
        clear_history=.false.)
      changed = .true.
      return
    end if

    call clear_completion_menu(editor)
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

  subroutine delete_span(editor, start_cursor, end_cursor)
    type(lineedit_state), intent(inout) :: editor
    integer, intent(in) :: start_cursor
    integer, intent(in) :: end_cursor
    character(len=:), allocatable :: before
    character(len=:), allocatable :: after

    if (start_cursor > 1) then
      before = editor%buffer(:start_cursor - 1)
    else
      before = ""
    end if

    if (end_cursor <= len(editor%buffer)) then
      after = editor%buffer(end_cursor:)
    else
      after = ""
    end if

    editor%buffer = before // after
    editor%cursor = start_cursor
    call clamp_cursor(editor)
  end subroutine delete_span

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

  integer function previous_delete_cursor(buffer, cursor) result(new_cursor)
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
  end function previous_delete_cursor

  integer function next_delete_cursor(buffer, cursor) result(new_cursor)
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

    do while (idx <= limit .and. is_word_separator(buffer(idx:idx)))
      idx = idx + 1
    end do
    do while (idx <= limit .and. .not. is_word_separator(buffer(idx:idx)))
      idx = idx + 1
    end do

    new_cursor = idx
  end function next_delete_cursor

  subroutine word_bounds_at_cursor(buffer, cursor, start_cursor, end_cursor)
    character(len=*), intent(in) :: buffer
    integer, intent(in) :: cursor
    integer, intent(out) :: start_cursor
    integer, intent(out) :: end_cursor
    integer :: idx
    integer :: limit
    integer :: position

    limit = len(buffer)
    position = min(max(cursor, 1), limit + 1)

    if (limit == 0) then
      start_cursor = 1
      end_cursor = 1
      return
    end if

    if (position > 1 .and. .not. is_word_separator(buffer(position - 1:position - 1))) then
      idx = position - 1
    else if (position <= limit .and. .not. is_word_separator(buffer(position:position))) then
      idx = position
    else
      start_cursor = position
      end_cursor = position
      return
    end if

    start_cursor = idx
    do while (start_cursor > 1 .and. .not. is_word_separator(buffer(start_cursor - 1:start_cursor - 1)))
      start_cursor = start_cursor - 1
    end do

    end_cursor = idx + 1
    do while (end_cursor <= limit .and. .not. is_word_separator(buffer(end_cursor:end_cursor)))
      end_cursor = end_cursor + 1
    end do
  end subroutine word_bounds_at_cursor

end module fgof_lineedit
