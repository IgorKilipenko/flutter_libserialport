cmake_minimum_required(VERSION 3.10)

message("Start build for Android platform")
include("${CMAKE_CURRENT_SOURCE_DIR}/../../CMakeLists.txt")

list(APPEND DEFS LIBSERIALPORT_ATBUILD)
list(APPEND COMPILE_OPTIONS -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow)

if (DEFINED UNIVERSAL_SERIAL AND UNIVERSAL_SERIAL)
  set(LIBS "${UTILS_PATH}/utils.c")
  set(INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/${UTILS_PATH}")
  list(APPEND DEFS UNIVERSAL_SERIAL)
else()
  list(APPEND LIBS 
    "${SOURCE_PATH}/linux.c"
    "${SOURCE_PATH}/linux_termios.c"
  )
endif()

add_library(${PROJECT_NAME} SHARED
  ${LIBS}
)

target_compile_options(${PROJECT_NAME} PRIVATE
  ${COMPILE_OPTIONS})
target_compile_definitions(${PROJECT_NAME} PRIVATE ${DEFS})
target_include_directories(${PROJECT_NAME} PRIVATE
  ${INCLUDE_DIRS}
)