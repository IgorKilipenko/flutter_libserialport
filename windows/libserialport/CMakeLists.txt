cmake_minimum_required(VERSION 3.10)

message("Start build for Windows platform")
include("${CMAKE_CURRENT_SOURCE_DIR}/../../CMakeLists.txt")

list(APPEND DEFS LIBSERIALPORT_MSBUILD)
set(LINK_LIBS cfgmgr32 SetupAPI)
#list(APPEND DEFS LIBSERIALPORT_ATBUILD)
#list(APPEND COMPILE_OPTIONS -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow)

list(APPEND LIBS 
  "${SOURCE_PATH}/windows.c"
)

add_library(${PROJECT_NAME} SHARED
  ${LIBS}
)

target_compile_options(${PROJECT_NAME} PRIVATE
  ${COMPILE_OPTIONS})
target_compile_definitions(${PROJECT_NAME} PRIVATE ${DEFS})
target_include_directories(${PROJECT_NAME} PRIVATE
  ${INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME} ${LINK_LIBS})
