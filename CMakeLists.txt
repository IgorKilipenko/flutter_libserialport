cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "serialport")
project(${PROJECT_NAME} LANGUAGES C)

#set(UNIVERSAL_SERIAL "true")
option(UNIVERSAL_SERIAL "Do you want to use an another UNIVERSAL_SERIAL?" ON)

if (DEFINED UNIVERSAL_SERIAL)
    message("Use UNIVERSAL_SERIAL = [${UNIVERSAL_SERIAL}]")
endif()

set(COMPILE_OPTIONS -std=c17)
set(DEFS "")

set(SOURCE_PATH "../../third_party/libserialport")
set(UTILS_PATH "../../third_party/utils")

set(LIBS 
    "${SOURCE_PATH}/serialport.c"
    "${SOURCE_PATH}/timing.c"
    "${UTILS_PATH}/utils.h"
    "${UTILS_PATH}/utils.c"
)

set(INCLUDE_DIRS 
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE_PATH}"
    "${CMAKE_CURRENT_SOURCE_DIR}/${UTILS_PATH}"
)