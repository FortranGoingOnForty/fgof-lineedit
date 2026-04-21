module fgof_lineedit_types
  implicit none
  private

  public :: lineedit_state
  public :: prompt_spec

  type :: prompt_spec
    character(len=:), allocatable :: text
  end type prompt_spec

  type :: lineedit_state
    type(prompt_spec) :: prompt
    character(len=:), allocatable :: buffer
    integer :: cursor = 1
    logical :: active = .false.
  end type lineedit_state

end module fgof_lineedit_types
