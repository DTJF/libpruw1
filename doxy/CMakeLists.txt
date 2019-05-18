# Build the documentation by Doxygen
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

IF(NOT COMMAND FB_DOCUMENTATION)
  INCLUDE(UseFbDoc)
  IF(NOT COMMAND FB_DOCUMENTATION)
    MSG_LOG("!! no targets <doc...> (UseFbDoc.cmake failed)")
    RETURN()
  ENDIF()
ENDIF()

SET(CMAKE_VERBOSE_MAKEFILE 1)

FB_DOCUMENTATION(
BAS_SRC
  ${SRC_BAS}
  ${SRC_BI}
DEPENDS
  pruw1.hp
  "../src/c_include/pruw1.h"
  "../src/doc/_1_introduction.md"
  "../src/doc/_2_preparation.md"
  "../src/doc/_9_monitor.md"
  "../src/doc/_z_changelog.md"
  ../CMakeLists.txt
  ../ReadMe.md
  Doxyfile
  libpruw1.css
  libpruw1.xml
  )
