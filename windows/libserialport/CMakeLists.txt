cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "serialport")
project(${PROJECT_NAME} LANGUAGES C)

message("Start build for Windows platform")

set(SOURCE_PATH "../../third_party/libserialport")
set(UTILS_PATH "../../third_party/utils")

add_library(${PROJECT_NAME} SHARED
  "${SOURCE_PATH}/serialport.c"
  "${SOURCE_PATH}/timing.c"
  "${SOURCE_PATH}/windows.c"
  "${UTILS_PATH}/utils.c"
)

#target_compile_options(${PROJECT_NAME} PRIVATE
#  -std=c99 -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow)
target_compile_definitions(${PROJECT_NAME} PRIVATE LIBSERIALPORT_MSBUILD)
target_compile_options(${PROJECT_NAME} PRIVATE -std=c20)
#target_compile_definitions(${PROJECT_NAME} PRIVATE UNICODE _WIN32)
#target_compile_options(${PROJECT_NAME} PRIVATE -g)
target_include_directories(${PROJECT_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE_PATH}"
  "${CMAKE_CURRENT_SOURCE_DIR}/${UTILS_PATH}")
target_link_libraries(${PROJECT_NAME} PRIVATE cfgmgr32 SetupAPI)
