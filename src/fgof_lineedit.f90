module fgof_lineedit
  use fgof_lineedit_types, only : lineedit_state, prompt_spec
  implicit none
  private

  public :: default_prompt
  public :: init_lineedit
  public :: lineedit_state
  public :: prompt_spec
  public :: reset_lineedit

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
  end subroutine init_lineedit

  subroutine reset_lineedit(editor)
    type(lineedit_state), intent(inout) :: editor

    editor%buffer = ""
    editor%cursor = 1
    editor%active = .false.
  end subroutine reset_lineedit

end module fgof_lineedit
