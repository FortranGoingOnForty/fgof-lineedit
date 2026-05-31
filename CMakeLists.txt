cmake_minimum_required(VERSION 3.25)

project(fgof_lineedit VERSION 0.1.0 LANGUAGES Fortran)

add_library(fgof_lineedit
  src/fgof_lineedit_types.f90
  src/fgof_lineedit.f90
)
add_library(fgof::lineedit ALIAS fgof_lineedit)

set_target_properties(fgof_lineedit PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod"
)

target_include_directories(fgof_lineedit PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
)

target_compile_options(fgof_lineedit PRIVATE
  $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-std=f2018 -Wall -Wextra -Wpedantic -Werror>
)
