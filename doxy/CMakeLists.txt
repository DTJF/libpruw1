# Build the documentation by Doxygen
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

IF(NOT COMMAND FB_DOCUMENTATION)
  INCLUDE(UseFb-Doc)
ENDIF()

FB_DOCUMENTATION(
BAS_SRC
  ${SRC_BAS}
  ${SRC_BI}
DEPENDS
  ${PASM_SRC}.hp
  "../src/doc/_1_introduction.md"
  "../src/doc/_2_preparation.md"
  "../src/doc/_9_debug.md"
  "../src/doc/_z_changelog.md"
  ../CMakeLists.txt
  ../ReadMe.md
  Doxyfile
  libpruw1.css
  libpruw1.xml
  )
