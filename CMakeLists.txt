CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

PROJECT(libpruw1 Fbc)

# constants
SET(PROJ_NAME "${CMAKE_PROJECT_NAME}" CACHE STRING "project name" FORCE)
SET(PROJ_DESC "One wire (W1) driver for Beaglebone hardware based on libpruio" CACHE STRING "project description" FORCE)
SET(PROJ_VERS "0.0"     CACHE STRING "project version" FORCE)
SET(PROJ_AUTH "DTJF"    CACHE STRING "project authors" FORCE)
SET(PROJ_MAIL "Thomas{ doT ]Freiherr[ At ]gmx[ DoT }net"  CACHE STRING "project mail address" FORCE)
SET(PROJ_WEBS "https://github.com/DTJF/libpruw1" CACHE STRING "project website" FORCE)
SET(PROJ_LICE "LGPLv2.1" CACHE STRING "project licence" FORCE)
#STRING(TIMESTAMP tmp "%Y" UTC)
#SET(PROJ_YEAR "${tmp}"             CACHE STRING "project year" FORCE)
SET(PROJ_YEAR "2016"   CACHE STRING "project year" FORCE)

FIND_PACKAGE(LIBPRUSSDRV)
CONFIGURE_FILE(src/doc/ReadMe.md.in ${CMAKE_SOURCE_DIR}/ReadMe.md @ONLY)

ADD_SUBDIRECTORY(src/bas)
ADD_SUBDIRECTORY(doxy)

IF(PASM_ASSEMBER_WORKS AND LIBPRUSSDRV_LIBRARY)
  ADD_LIBRARY(pruw1 SHARED $<TARGET_OBJECTS:pruw1fbcode>)
  #ADD_DEPENDENCIES(pruw1 pruw1fbcode)

  ADD_CUSTOM_TARGET(examples)
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

SET(C_HEADERS
  "src/c_include/pruw1.h"
  )
#INSTALL(FILES ${C_HEADERS}
  #DESTINATION include
  #COMPONENT dev
  #)
