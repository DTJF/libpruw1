SET(EXA_SRC
  "dallas"
  "onlyDS18S20"
  )

SET(CMAKE_VERBOSE_MAKEFILE 1)
ADD_CUSTOM_TARGET(examples)

IF(CMAKE_Fbc_COMPILER_WORKS)
  SET(CMAKE_LINK_LIBRARY_FLAG "-l ")
  ADD_CUSTOM_TARGET(fb_examples DEPENDS pruw1)
  FOREACH(tar ${EXA_SRC})
    ADD_EXECUTABLE(${tar} EXCLUDE_FROM_ALL ${tar}.bas)
    TARGET_LINK_LIBRARIES(${tar} pruw1 pruio fbgfx X11 Xext Xpm Xrandr Xrender)
    SET_TARGET_PROPERTIES(${tar} PROPERTIES
      COMPILE_FLAGS "-m ${tar} -gen gcc -Wc -O2,-D_FORTIFY_SOURCE=2,-fstack-protector-strong,-Wformat,-Werror=format-security"
      LINK_FLAGS "-Wl -z,relro"
      )
    ADD_DEPENDENCIES(fb_examples ${tar})
  ENDFOREACH(tar)
  ADD_DEPENDENCIES(examples fb_examples)
ELSE()
  MSG_LOG("!! FreeBASIC compiler not working -> no target fb_examples")
ENDIF()

IF(CMAKE_C_COMPILER_WORKS)
  ADD_CUSTOM_TARGET(c_examples DEPENDS pruw1)
  FOREACH(tar ${EXA_SRC})
    ADD_EXECUTABLE(${tar}_c EXCLUDE_FROM_ALL ${tar}.c)
    TARGET_LINK_LIBRARIES(${tar}_c pruw1 pruio)
    ADD_DEPENDENCIES(c_examples ${tar}_c)
  ENDFOREACH(tar)
  ADD_DEPENDENCIES(examples c_examples)
ELSE()
  MSG_LOG("!! C compiler not working -> no target c_examples")
ENDIF()

