find_package(SDL2 CONFIG REQUIRED)
find_package(JPEG CONFIG)
find_package(PNG CONFIG)
find_package(WebP CONFIG)
include("${CMAKE_CURRENT_LIST_DIR}/SDL2_imageTargets.cmake")

if(NOT TARGET SDL_image::SDL_image)
  set_target_properties(
      SDL2_image::SDL2_image
      PROPERTIES
      IMPORTED_GLOBAL True
  )
  add_library(SDL_image::SDL_image ALIAS SDL2_image::SDL2_image)
endif()
