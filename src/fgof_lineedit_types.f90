module fgof_lineedit_types
  implicit none
  private

  public :: history_entry
  public :: lineedit_state
  public :: prompt_spec

  type :: prompt_spec
    character(len=:), allocatable :: text
  end type prompt_spec

  type :: history_entry
    character(len=:), allocatable :: text
  end type history_entry

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
  end type lineedit_state

end module fgof_lineedit_types
