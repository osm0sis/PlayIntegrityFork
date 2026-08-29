cmake_minimum_required(VERSION 3.22.1)

project(playintegrityfix)

find_package(cxx REQUIRED CONFIG)

link_libraries(cxx::cxx)

set(SHADOWHOOK_STATIC ON)

add_subdirectory(shadowhook/shadowhook/src/main/cpp)

include_directories(shadowhook/shadowhook/src/main/cpp/include)

add_library(${CMAKE_PROJECT_NAME} SHARED main.cpp local_cxa_atexit_finalize_impl/atexit.cpp)

target_compile_features(${CMAKE_PROJECT_NAME} PRIVATE c_std_23 cxx_std_23)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE log shadowhook)
