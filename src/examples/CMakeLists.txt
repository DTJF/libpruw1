SET(fb_tar
  "dallas"
  "onlyDS18S20"
  )

ADD_CUSTOM_TARGET(fb_examples DEPENDS ${fb_tar})
SET_TARGET_PROPERTIES(fb_examples PROPERTIES EXCLUDE_FROM_ALL 1)
ADD_DEPENDENCIES(examples fb_examples)

FOREACH(tar ${fb_tar})
  ADD_EXECUTABLE(${tar} EXCLUDE_FROM_ALL ${tar}.bas)
  TARGET_LINK_LIBRARIES(${tar} pruw1 pruio prussdrv fbgfx X11 Xext Xpm Xrandr Xrender)
  SET_TARGET_PROPERTIES(${tar} PROPERTIES COMPILE_FLAGS "-m ${tar}")
  ADD_DEPENDENCIES(fb_examples ${tar})
ENDFOREACH(tar)
