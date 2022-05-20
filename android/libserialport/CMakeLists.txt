cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "serialport")
project(${PROJECT_NAME} LANGUAGES C)

include("${CMAKE_CURRENT_SOURCE_DIR}/../../CMakeLists.txt")

message("Start build for Android platform")

set(UTILS_PATH "../../third_party/utils")
set(LIBS "${UTILS_PATH}/utils.c")
set(DEFS LIBSERIALPORT_ATBUILD)
set(INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}/${UTILS_PATH}")

if (NOT DEFINED UNIVERSAL_SERIAL)
  set(SOURCE_PATH "../../third_party/libserialport")
  list(APPEND LIBS
    "${SOURCE_PATH}/linux.c"
    "${SOURCE_PATH}/linux_termios.c"
    "${SOURCE_PATH}/serialport.c"
    "${SOURCE_PATH}/timing.c"
  )
  list(APPEND INCLUDES
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE_PATH}"
  )
else()
  list(APPEND DEFS UNIVERSAL_SERIAL)
endif()

list(APPEND COMPILE_OPTIONS -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow)


add_library(${PROJECT_NAME} SHARED
  ${LIBS}
)

target_compile_options(${PROJECT_NAME} PRIVATE
  ${COMPILE_OPTIONS})
target_compile_definitions(${PROJECT_NAME} PRIVATE ${DEFS})
target_include_directories(${PROJECT_NAME} PRIVATE
  ${INCLUDES}
)