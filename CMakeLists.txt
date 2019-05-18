CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

#SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

# constants
SET(PROJ_NAME "libpruw1" CACHE STRING "project name" FORCE)
SET(PROJ_DESC "One wire (W1) driver for Beaglebone hardware based on libpruio" CACHE STRING "project description" FORCE)
SET(PROJ_VERS "0.2"     CACHE STRING "project version" FORCE)
SET(PROJ_AUTH "DTJF"    CACHE STRING "project authors" FORCE)
SET(PROJ_MAIL "Thomas{ doT ]Freiherr[ At ]gmx[ DoT }net"  CACHE STRING "project mail address" FORCE)
SET(PROJ_WEBS "https://github.com/DTJF/libpruw1" CACHE STRING "project website" FORCE)
SET(PROJ_LICE "LGPLv2.1" CACHE STRING "project licence" FORCE)
#STRING(TIMESTAMP tmp "%Y" UTC)
#SET(PROJ_YEAR "${tmp}"             CACHE STRING "project year" FORCE)
SET(PROJ_YEAR "2019"   CACHE STRING "project year" FORCE)

PROJECT(${PROJ_NAME} Fbc C)

#FIND_PACKAGE(LIBPRUSSDRV)
FUNCTION(MSG_LOG Txt)
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log "${Txt}\n\n")
  MESSAGE(STATUS ${Txt})
ENDFUNCTION()

IF(NOT CMAKE_Fbc_COMPILER_WORKS)
  MSG_LOG("!! no targets <all> <fb_examples> <c_examples> (fbc compiler problem)")
  RETURN()
ENDIF()

CONFIGURE_FILE(src/doc/ReadMe.md.in ${CMAKE_SOURCE_DIR}/ReadMe.md @ONLY)
ADD_SUBDIRECTORY(src/bas)
IF(NOT DEFINED PASM_ASSEMBER_WORKS)
  MSG_LOG(">> no target all")
  RETURN()
ENDIF()
ADD_LIBRARY(pruw1 SHARED $<TARGET_OBJECTS:pruw1fbcode>)
SET_TARGET_PROPERTIES(pruw1 PROPERTIES
  SOVERSION "o" # adapt <Package: ...> in debian/control
  #NO_SONAME "YES"
  )

ADD_SUBDIRECTORY(src/c_include)
ADD_SUBDIRECTORY(doxy)

#ADD_DEPENDENCIES(pruw1 pruw1fbcode)

ADD_SUBDIRECTORY(src/examples)

#ADD_DEPENDENCIES(examples pruw1)

INSTALL(TARGETS pruw1
  LIBRARY DESTINATION lib/
  COMPONENT bin
  )

