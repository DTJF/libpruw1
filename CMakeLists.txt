CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

PROJECT(libpruw1 Fbc C)

# constants
SET(PROJ_NAME "${CMAKE_PROJECT_NAME}" CACHE STRING "project name" FORCE)
SET(PROJ_DESC "One wire (W1) driver for Beaglebone hardware based on libpruio" CACHE STRING "project description" FORCE)
SET(PROJ_VERS "0.4"     CACHE STRING "project version" FORCE)
SET(PROJ_AUTH "DTJF"    CACHE STRING "project authors" FORCE)
SET(PROJ_MAIL "Thomas{ doT ]Freiherr[ At ]gmx[ DoT }net"  CACHE STRING "project mail address" FORCE)
SET(PROJ_WEBS "https://github.com/DTJF/libpruw1" CACHE STRING "project website" FORCE)
SET(PROJ_LICE "LGPLv2.1" CACHE STRING "project licence" FORCE)
#STRING(TIMESTAMP tmp "%Y" UTC)
#SET(PROJ_YEAR "${tmp}"             CACHE STRING "project year" FORCE)
SET(PROJ_YEAR "2023"   CACHE STRING "project year" FORCE)

FUNCTION(MSG_LOG Txt)
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log "${Txt}\n\n")
  MESSAGE(STATUS ${Txt})
ENDFUNCTION()

CONFIGURE_FILE(src/doc/ReadMe.md.in ${CMAKE_SOURCE_DIR}/ReadMe.md @ONLY)

ADD_SUBDIRECTORY(doxy)
ADD_SUBDIRECTORY(src/bas)
ADD_SUBDIRECTORY(src/c_include)

IF(PASM_ASSEMBER_WORKS)

  ADD_LIBRARY(pruw1 SHARED $<TARGET_OBJECTS:pruw1fbcode>)
  #ADD_DEPENDENCIES(pruw1 pruw1fbcode)
  SET(CMAKE_SHARED_LINKER_FLAGS "") # must be global ??
  SET_TARGET_PROPERTIES(pruw1 PROPERTIES
    LINK_FLAGS "-v -Wl -z,relro"
    SOVERSION "o" # adapt <Package: ...> in debian/control
    #NO_SONAME "YES"
    )

  ADD_SUBDIRECTORY(src/examples)
  ADD_DEPENDENCIES(examples pruw1)
  #SET_TARGET_PROPERTIES(examples PROPERTIES EXCLUDE_FROM_ALL 1)

  INSTALL(TARGETS pruw1
    LIBRARY DESTINATION lib
    COMPONENT bin
    )
ELSE()
  MESSAGE(STATUS ">> no target all")

  SET_TARGET_PROPERTIES(doc PROPERTIES EXCLUDE_FROM_ALL 0)
ENDIF()

