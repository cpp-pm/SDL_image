option(HUNTER_ENABLED "Enable Hunter package manager" OFF)

if(HUNTER_ENABLED)
cmake_minimum_required(VERSION 3.2)

include(cmake/HunterGate.cmake)
HunterGate(
	URL "https://github.com/cpp-pm/hunter/archive/v0.23.309.tar.gz"
	SHA1 "15e84e1f23eb079360db727d373dab82890420b7"
)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
endif()

cmake_minimum_required(VERSION 3.3.2)
project(SDL_image C)

if(NOT HUNTER_ENABLED)
if (NOT ANDROID AND NOT (TARGET SDL2 OR TARGET SDL2-static))
	find_package(SDL2 REQUIRED)
endif()
else()
	hunter_add_package(SDL2)
	find_package(SDL2 CONFIG REQUIRED)
endif()

option(SUPPORT_JPG "Support loading JPEG images" ON)
option(SUPPORT_PNG "Support loading PNG images" ON)
option(SUPPORT_WEBP "Support loading WEBP images" OFF)
option(BUILD_SHOWIMAGE "Build the showimage sample program" OFF)
option(BUILD_SHARED_LIBS "Build the library as a shared library" ON)
if (APPLE AND NOT IOS)
	option(ENABLE_APPLE_IMAGEIO "Use native Mac OS X frameworks for loading images" ON)
endif()


if (NOT BUILD_SHARED_LIBS)
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

add_library(SDL2_image)

set(IMAGEIO_SOURCES)
if (APPLE)
	if (ENABLE_APPLE_IMAGEIO)
		target_link_options(SDL2_image PRIVATE -Wl,-framework,ApplicationServices)
		target_link_libraries(SDL2_image PRIVATE objc)
		set(IMAGEIO_SOURCES "IMG_ImageIO.m")
	else()
		target_compile_definitions(SDL2_image PRIVATE SDL_IMAGE_USE_COMMON_BACKEND)
	endif()
endif()

target_sources(SDL2_image PRIVATE IMG.c IMG_png.c IMG_bmp.c IMG_gif.c
		IMG_jpg.c IMG_lbm.c IMG_pcx.c IMG_pnm.c IMG_svg.c IMG_tga.c
		IMG_tif.c IMG_webp.c IMG_WIC.c IMG_xcf.c IMG_xpm.c IMG_xv.c IMG_xxx.c ${IMAGEIO_SOURCES})

target_compile_definitions(SDL2_image PRIVATE
		-DLOAD_BMP -DLOAD_GIF -DLOAD_LBM -DLOAD_PCX -DLOAD_PNM
		-DLOAD_TGA -DLOAD_XCF -DLOAD_XPM -DLOAD_XV -DLOAD_XPM)

if (SUPPORT_JPG)
	target_compile_definitions(SDL2_image PRIVATE -DLOAD_JPG)
  if(NOT HUNTER_ENABLED)
	add_subdirectory(external/jpeg-9b)
	target_link_libraries(SDL2_image PRIVATE jpeg)
  else()
  	hunter_add_package(Jpeg)
	find_package(JPEG CONFIG REQUIRED)
	target_link_libraries(SDL2_image PRIVATE JPEG::jpeg)
  endif()
endif()

if (SUPPORT_PNG)
	# missing libpng.vers
	set(HAVE_LD_VERSION_SCRIPT OFF CACHE BOOL "" FORCE)
	target_compile_definitions(SDL2_image PRIVATE -DLOAD_PNG)

  if(NOT HUNTER_ENABLED)
  if (NOT TARGET zlib)
	add_subdirectory(external/zlib-1.2.11 "${CMAKE_CURRENT_BINARY_DIR}/external/zlib-1.2.11")
	set(ZLIB_INCLUDE_DIR "external/zlib-1.2.11")
	set(SKIP_INSTALL_ALL ON) # SDL_image doesn't support installing currently
	if (BUILD_SHARED_LIBS)
		set(ZLIB_LIBRARY zlib)
	else()
		set(ZLIB_LIBRARY zlibstatic)
	endif()
	target_include_directories(${ZLIB_LIBRARY} PUBLIC
		"${ZLIB_INCLUDE_DIR}"
		"${CMAKE_CURRENT_BINARY_DIR}/external/zlib-1.2.11" # zconf.h is generated there
	)
  endif()

	add_subdirectory(external/libpng-1.6.37)
	include_directories(external/libpng-1.6.37)
	if(BUILD_SHARED_LIBS)
		target_link_libraries(SDL2_image PRIVATE png)
	else()
		target_link_libraries(SDL2_image PRIVATE png_static)
	endif()
  else()
	hunter_add_package(PNG)
	find_package(PNG CONFIG REQUIRED)
	target_link_libraries(SDL2_image PRIVATE PNG::PNG)
  endif()
endif()

if (SUPPORT_WEBP)
	target_compile_definitions(SDL2_image PRIVATE -DLOAD_WEBP)
  if(NOT HUNTER_ENABLED)
	# missing cpufeatures
	add_subdirectory(external/libwebp-1.0.2)
	include_directories(external/libwebp-1.0.2/src)
	target_link_libraries(SDL2_image PRIVATE webp)
  else()
	hunter_add_package(WebP)
	find_package(WebP CONFIG REQUIRED)
	target_link_libraries(SDL2_image PRIVATE WebP::webp)
  endif()
endif()

add_library(SDL2::image ALIAS SDL2_image)

if(NOT HUNTER_ENABLED)
target_include_directories(SDL2_image PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
else()
target_include_directories(SDL2_image PUBLIC $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/SDL2>)
endif()

if (BUILD_SHARED_LIBS OR HUNTER_ENABLED)
	target_link_libraries(SDL2_image PUBLIC SDL2::SDL2)
else()
	target_link_libraries(SDL2_image PUBLIC SDL2::SDL2-static)
endif()

if(BUILD_SHOWIMAGE)
	add_executable(showimage showimage.c)
	target_link_libraries(showimage PRIVATE SDL2::image)
	if (WIN32)
		target_link_libraries(showimage PRIVATE SDL2::SDL2main)
	endif()
endif()

if(HUNTER_ENABLED)
set(PKG_PREFIX "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

install(
  TARGETS SDL2_image
  EXPORT SDL2_imageTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
install(
  FILES SDL_image.h
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/SDL2
)

write_basic_package_version_file("${CMAKE_BINARY_DIR}/SDL_imageConfigVersion.cmake"
  VERSION 2.0.5
  COMPATIBILITY AnyNewerVersion
)

install(
  EXPORT SDL2_imageTargets
  FILE SDL2_imageTargets.cmake
  NAMESPACE SDL2_image::
  DESTINATION ${PKG_PREFIX}
)

install(
  FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/SDL_imageConfig.cmake
    ${CMAKE_BINARY_DIR}/SDL_imageConfigVersion.cmake
  DESTINATION ${PKG_PREFIX}
  COMPONENT Devel
)
endif()
