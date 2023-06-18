SET(SRC_BAS
  ${CMAKE_CURRENT_SOURCE_DIR}/pruw1.bas
  ${CMAKE_CURRENT_SOURCE_DIR}/pruw1_C_wrapper.bas
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
  FIND_PROGRAM(pasm_bin pasm DOC "pasm assembler" HINTS /usr/local/bin)
  IF(NOT pasm_bin)
    MSG_LOG("!! no target <all> (missing pasm assembler)")
    RETURN()
  ENDIF()
  EXECUTE_PROCESS(
    COMMAND ${pasm_bin} # no ARGS -> helptext
    RESULT_VARIABLE assembler_works
    OUTPUT_VARIABLE pasm_vers
    ERROR_VARIABLE pasm_opts
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
    )

  IF(assembler_works EQUAL "1")
    STRING(REGEX REPLACE "\r?\n" ";" output_lines "${pasm_opts}\n${pasm_vers}\n")
    FOREACH(line IN LISTS output_lines)
      IF(line MATCHES "PRU Assembler Version")
        SET(PASM_ASSEMBER_ID ${line})
        BREAK()
      ENDIF()
    ENDFOREACH()

    SET(fb_option FALSE)
    FOREACH(line IN LISTS output_lines)
      IF(line MATCHES "f  - Create 'FreeBasic array' binary output")
        SET(fb_option "f")
        BREAK()
      ELSEIF(line MATCHES "y  - Create 'FreeBasic array' binary output")
        SET(fb_option "y")
        BREAK()
      ENDIF()
    ENDFOREACH()

    IF(fb_option)
      MSG_LOG("Check for PASM assembler OK ==> Option -${fb_option} in ${PASM_ASSEMBER_ID}")
      FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
        "Determining if the pasm assembler works passed with "
        "the following output:\n${output}\n\n")
      SET(PASM_ASSEMBER_WORKS "${fb_option}" CACHE STRING "pasm assembler" FORCE)
      MARK_AS_ADVANCED(PASM_ASSEMBER_WORKS)
    ELSE()
      MSG_LOG("PASM assembler insufficient! (${PASM_ASSEMBER_ID})")
      FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
        "Determining if the pasm assembler works failed with "
        "the following output:\n${output}\n\n")
    ENDIF()
  ELSE()
    MSG_LOG("PASM assembler not found (command pasm)!")
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Finding the pasm assembler failed!")
  ENDIF()
ENDIF()

IF(NOT DEFINED PASM_ASSEMBER_WORKS)
  MSG_LOG("!! no target <all> (pasm assembler problem)")
  RETURN()
ENDIF()

ADD_CUSTOM_COMMAND(OUTPUT ${PASM_SRC}.bi
  COMMAND pasm ARGS -V3 -${PASM_ASSEMBER_WORKS} -CPru_W1 ${PASM_SRC}.p
  COMMAND ${CMAKE_COMMAND} -E touch_nocreate pruw1.bas
  DEPENDS ${PASM_SRC}.p pruw1.hp
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )

ADD_CUSTOM_TARGET(pasm DEPENDS ${PASM_SRC}.bi  ${PASM_SRC}.p  pruw1.hp)

ADD_LIBRARY(pruw1fbcode OBJECT ${SRC_BAS})
SET_TARGET_PROPERTIES(pruw1fbcode PROPERTIES
  COMPILE_FLAGS "-gen gcc -Wc -O2,-fPIC,-D_FORTIFY_SOURCE=2,-Wno-maybe-uninitialized"
  )
ADD_DEPENDENCIES(pruw1fbcode pasm)
ADD_Fbc_SRC_DEPS(pruw1fbcode)

# install the header files (*.bi)
GET_FILENAME_COMPONENT(fbpath ${CMAKE_Fbc_COMPILER} PATH)
INSTALL(FILES ${SRC_BI}
  DESTINATION ${fbpath}/../include/freebasic/BBB
  COMPONENT fbdev
  )
