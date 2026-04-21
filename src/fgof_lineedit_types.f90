module fgof_lineedit_types
  implicit none
  private

  public :: FGOF_LINEEDIT_ACT_NONE
  public :: FGOF_LINEEDIT_ACT_INSERT
  public :: FGOF_LINEEDIT_ACT_DELETE_LEFT
  public :: FGOF_LINEEDIT_ACT_DELETE_RIGHT
  public :: FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT
  public :: FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT
  public :: FGOF_LINEEDIT_ACT_MOVE_LEFT
  public :: FGOF_LINEEDIT_ACT_MOVE_RIGHT
  public :: FGOF_LINEEDIT_ACT_MOVE_WORD_LEFT
  public :: FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT
  public :: FGOF_LINEEDIT_ACT_MOVE_HOME
  public :: FGOF_LINEEDIT_ACT_MOVE_END
  public :: FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS
  public :: FGOF_LINEEDIT_ACT_HISTORY_NEXT
  public :: completion_item
  public :: completion_span
  public :: history_entry
  public :: lineedit_action
  public :: lineedit_render_completion
  public :: lineedit_render_state
  public :: lineedit_state
  public :: prompt_spec

  integer, parameter :: FGOF_LINEEDIT_ACT_NONE = 0
  integer, parameter :: FGOF_LINEEDIT_ACT_INSERT = 1
  integer, parameter :: FGOF_LINEEDIT_ACT_DELETE_LEFT = 2
  integer, parameter :: FGOF_LINEEDIT_ACT_DELETE_RIGHT = 3
  integer, parameter :: FGOF_LINEEDIT_ACT_DELETE_WORD_LEFT = 12
  integer, parameter :: FGOF_LINEEDIT_ACT_DELETE_WORD_RIGHT = 13
  integer, parameter :: FGOF_LINEEDIT_ACT_MOVE_LEFT = 4
  integer, parameter :: FGOF_LINEEDIT_ACT_MOVE_RIGHT = 5
  integer, parameter :: FGOF_LINEEDIT_ACT_MOVE_WORD_LEFT = 6
  integer, parameter :: FGOF_LINEEDIT_ACT_MOVE_WORD_RIGHT = 7
  integer, parameter :: FGOF_LINEEDIT_ACT_MOVE_HOME = 8
  integer, parameter :: FGOF_LINEEDIT_ACT_MOVE_END = 9
  integer, parameter :: FGOF_LINEEDIT_ACT_HISTORY_PREVIOUS = 10
  integer, parameter :: FGOF_LINEEDIT_ACT_HISTORY_NEXT = 11

  type :: prompt_spec
    character(len=:), allocatable :: text
  end type prompt_spec

  type :: completion_item
    character(len=:), allocatable :: text
    character(len=:), allocatable :: display
  end type completion_item

  type :: completion_span
    integer :: start_cursor = 1
    integer :: end_cursor = 1
    character(len=:), allocatable :: prefix
    character(len=:), allocatable :: text
  end type completion_span

  type :: history_entry
    character(len=:), allocatable :: text
  end type history_entry

  type :: lineedit_render_completion
    character(len=:), allocatable :: text
    logical :: selected = .false.
  end type lineedit_render_completion

  type :: lineedit_render_state
    character(len=:), allocatable :: prompt
    character(len=:), allocatable :: buffer
    character(len=:), allocatable :: line
    integer :: cursor_column = 1
    type(lineedit_render_completion), allocatable :: completions(:)
    logical :: completion_visible = .false.
  end type lineedit_render_state

  type :: lineedit_action
    integer :: kind = FGOF_LINEEDIT_ACT_NONE
    character(len=:), allocatable :: text
  end type lineedit_action

  type :: lineedit_state
    type(prompt_spec) :: prompt
    character(len=:), allocatable :: buffer
    integer :: cursor = 1
    logical :: active = .false.
    type(history_entry), allocatable :: history(:)
    integer :: history_index = 0
    logical :: browsing_history = .false.
    character(len=:), allocatable :: stashed_buffer
    integer :: stashed_cursor = 1
    type(completion_item), allocatable :: completion_items(:)
    integer :: completion_index = 0
    logical :: completion_visible = .false.
  end type lineedit_state

end module fgof_lineedit_types
