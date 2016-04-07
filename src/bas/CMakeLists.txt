SET(SRC_BAS
  ${CMAKE_CURRENT_SOURCE_DIR}/pruw1.bas
  CACHE FILEPATH "BASIC source files" FORCE
  )

SET(SRC_BI
  ${CMAKE_CURRENT_SOURCE_DIR}/pruw1.bi
  CACHE FILEPATH "header files" FORCE
  )

SET(PASM_SRC
  ${CMAKE_CURRENT_SOURCE_DIR}/w1_prucode
  CACHE FILEPATH "ASM source files" FORCE
  )


# Check the PRU assembler pasm (presence and version):
IF(NOT DEFINED PASM_ASSEMBER_WORKS)
  EXECUTE_PROCESS(
    COMMAND pasm
    RESULT_VARIABLE assembler_works
    OUTPUT_VARIABLE output
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )

  IF(assembler_works EQUAL "1")
    STRING(REGEX REPLACE "\r?\n" ";" output_lines "${output}")
    SET(works FALSE)
    FOREACH(line IN LISTS output_lines)
      IF(line MATCHES "PRU Assembler Version")
        SET(PASM_ASSEMBER_ID ${line})
      ELSEIF(line MATCHES "y  - Create 'FreeBasic array' binary output")
        SET(works TRUE)
        BREAK()
      ENDIF()
    ENDFOREACH()

    IF(works)
      MESSAGE(STATUS "Check for working PASM assembler OK ==> ${PASM_ASSEMBER_ID}")
      FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
        "Determining if the pasm assembler works passed with "
        "the following output:\n${output}\n\n")
      SET(PASM_ASSEMBER_WORKS "${works}" CACHE FILEPATH "pasm assembler" FORCE)
      MARK_AS_ADVANCED(PASM_ASSEMBER_WORKS)
    ELSE()
      MESSAGE(STATUS "Wrong PASM assembler version!")
      FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
        "Determining if the pasm assembler works failed with "
        "the following output:\n${output}\n\n")
    ENDIF()
  ELSE()
    MESSAGE(STATUS "PASM assembler not found (command pasm)!")
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Finding the pasm assembler failed!\n")
  ENDIF()
ENDIF()

IF(NOT PASM_ASSEMBER_WORKS)
  RETURN()
ENDIF()

FIND_PACKAGE(LIBPRUSSDRV)

ADD_CUSTOM_COMMAND(OUTPUT ${PASM_SRC}.bi
  COMMAND pasm ARGS -V3 -y -CPru_W1 ${PASM_SRC}.p
  COMMAND ${CMAKE_COMMAND} -E touch_nocreate pruw1.bas
  DEPENDS ${PASM_SRC}.p
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )

ADD_CUSTOM_TARGET(pasm DEPENDS ${PASM_SRC}.bi)

ADD_LIBRARY(pruw1fbcode OBJECT ${SRC_BAS})
SET_TARGET_PROPERTIES(pruw1fbcode PROPERTIES
  COMPILE_FLAGS "-Wc -fPIC"
  )
ADD_DEPENDENCIES(pruw1fbcode pasm)
ADD_Fbc_SRC_DEPS(pruw1fbcode)

# install the header files (*.bi)
GET_FILENAME_COMPONENT(fbpath ${CMAKE_Fbc_COMPILER} PATH)
IF(UNIX)
  SET(bi_dest ${fbpath}/../include)
ELSE()
  SET(bi_dest ${fbpath}/../inc)
ENDIF()
INSTALL(FILES ${SRC_BI}
  DESTINATION ${bi_dest}/freebasic/BBB
  COMPONENT fbdev
  )
