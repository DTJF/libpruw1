SET(FB_EXA_SRC
  "dallas"
  "onlyDS18S20"
  )

#SET(CMAKE_VERBOSE_MAKEFILE 1)

SET(CMAKE_LINK_LIBRARY_FLAG "-l ")
SET(CMAKE_EXE_LINKER_FLAGS "-Wl -z,relro") # must be global

FOREACH(tar ${FB_EXA_SRC})
  ADD_EXECUTABLE(${tar} EXCLUDE_FROM_ALL ${tar}.bas)
  TARGET_LINK_LIBRARIES(${tar} pruw1 pruio fbgfx X11 Xext Xpm Xrandr Xrender)
  SET_TARGET_PROPERTIES(${tar} PROPERTIES
    COMPILE_FLAGS "-m ${tar} -gen gcc -Wc -O2,-D_FORTIFY_SOURCE=2,-fstack-protector-strong,-Wformat,-Werror=format-security")
  ADD_DEPENDENCIES(fb_examples ${tar})
ENDFOREACH(tar)
