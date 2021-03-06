#
# CMake Toolchain file for cross compiling OpenSCAD tests linux->mingw-win32
# --------------------------------------------------------------------------
# 
# Prerequisites: mingw-cross-env, ImageMagick 6.5.9.3 or newer, wine
#
# Usage:
#
#  - follow Brad Pitcher's mingw-cross-env for OpenSCAD setup:
#    http://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Cross-compiling_for_Windows_on_Linux_or_Mac_OS_X
#  - cross-compile openscad.exe, to verify your installation works properly.
#  - cd openscad/tests && mkdir build-mingw32 && cd build-mingw32
#  - cmake .. -DCMAKE_TOOLCHAIN_FILE=../CMingw-cross-env.cmake \
#             -DMINGW_CROSS_ENV_DIR=<where mingw-cross-env is installed>
#  - make should proceed as normal. 
#  - now run 'ctest' on your *nix machine.
#    The test .exe programs should run under Wine. 
#
# See also:
# 
# http://lists.gnu.org/archive/html/mingw-cross-env-list/2010-11/threads.html#00078
#  (thread "Qt with Cmake")
# http://lists.gnu.org/archive/html/mingw-cross-env-list/2011-01/threads.html#00012
#  (thread "Qt: pkg-config files?")
# http://mingw-cross-env.nongnu.org/#requirements
# http://www.vtk.org/Wiki/CMake_Cross_Compiling
# https://bitbucket.org/muellni/mingw-cross-env-cmake/src/2067fcf2d52e/src/cmake-1-toolchain-file.patch
# http://code.google.com/p/qtlobby/source/browse/trunk/toolchain-mingw.cmake
# http://gcc.gnu.org/onlinedocs/gcc-3.4.6/gcc/Link-Options.html
# Makefile.Release generated by qmake 
# cmake's FindQt4.cmake & Qt4ConfigDependentSettings.cmake files
# mingw-cross-env's qmake.conf and *.prl files
# mingw-cross-env's pkg-config files in usr/i686-pc-mingw32/lib/pkgconfig
# http://www.vtk.org/Wiki/CMake:How_To_Find_Libraries
#

#
# Notes: 
#
# To debug the build process run "make VERBOSE=1". 'strace -f' is also useful. 
#
# This file is actually called multiple times by cmake, so various 'if NOT set' 
# guards are used to keep programs from running twice.
#
# The test will not currently run under win32 because the ctest harness 
# is created by cmake on the machine that it is called on, not on the 
# machine it is targeting.
#

#
# Part 1. Find *nix-ImageMagick
#
# The tests run under Wine under *nix. Therefore we need to find the 
# ImageMagick comparison program on the *nix machine. It must be 
# searched before the 'cross-compile' environment is setup.
#

if (NOT imagemagick_cross_set)
  find_package(ImageMagick COMPONENTS convert REQUIRED)
  message(STATUS "ImageMagick convert executable found: " ${ImageMagick_convert_EXECUTABLE})
  set( SKIP_IMAGEMAGICK TRUE )
  set( imagemagick_cross_set )
endif()

#
# Part 2. cross-compiler setup
#

set(MINGW_CROSS_ENV_DIR $ENV{MINGW_CROSS_ENV_DIR})

set(BUILD_SHARED_LIBS OFF)
set(CMAKE_SYSTEM_NAME Windows)
set(MSYS 1)
set(CMAKE_FIND_ROOT_PATH ${MINGW_CROSS_ENV_DIR}/usr/i686-pc-mingw32)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)

set(CMAKE_C_COMPILER ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-gcc)
set(CMAKE_CXX_COMPILER ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-g++)
set(CMAKE_RC_COMPILER ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-windres)
set(QT_QMAKE_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-qmake)
set(PKG_CONFIG_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-pkg-config)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

#
# Part 3. library settings for mingw-cross-env
#

set( Boost_USE_STATIC_LIBS ON )
set( Boost_USE_MULTITHREADED ON )
set( Boost_COMPILER "_win32" )
# set( Boost_DEBUG TRUE ) # for debugging cmake's FindBoost, not boost itself

set( OPENSCAD_LIBRARIES ${CMAKE_FIND_ROOT_PATH} )
set( EIGEN2_DIR ${CMAKE_FIND_ROOT_PATH} )
set( CGAL_DIR ${CMAKE_FIND_ROOT_PATH}/lib/CGAL )
set( GLEW_DIR ${CMAKE_FIND_ROOT_PATH} )

#
# Qt4
# 
# To workaround problems with CMake's FindQt4.cmake when combined with 
# mingw-cross-env (circa early 2012), we here instead use pkg-config. To 
# workaround Cmake's insertion of -bdynamic, we stick 'static' on the 
# end of QT_LIBRARIES
#

set(QT_QMAKE_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-qmake)
set(QT_MOC_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-moc)
set(QT_UIC_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/i686-pc-mingw32-uic)

function(mingw_cross_env_find_qt)
  # called from CMakeLists.txt
  find_package( PkgConfig )
  pkg_check_modules( QTCORE QtCore )
  pkg_check_modules( QTGUI QtGui )
  pkg_check_modules( QTOPENGL QtOpenGL )

  set(QT_INCLUDE_DIRS ${QTCORE_INCLUDE_DIRS} ${QTGUI_INCLUDE_DIRS} ${QTOPENGL_INCLUDE_DIRS})
  set(QT_CFLAGS_OTHER "${QTCORE_CFLAGS_OTHER} ${QTGUI_CFLAGS_OTHER} ${QTOPENGL_CFLAGS_OTHER}")
  set(QT_LIBRARIES "${QTCORE_STATIC_LDFLAGS} ${QTGUI_STATIC_LDFLAGS} ${QTOPENGL_STATIC_LDFLAGS};-static")

  set(QT_INCLUDE_DIRS ${QT_INCLUDE_DIRS} PARENT_SCOPE)
  set(QT_CFLAGS_OTHER ${QT_CFLAGS_OTHER} PARENT_SCOPE)
  set(QT_LIBRARIES ${QT_LIBRARIES} PARENT_SCOPE)
endfunction()

function(mingw_cross_env_info)
  message(STATUS "QT INCLUDE_DIRS: ${QT_INCLUDE_DIRS}")
  message(STATUS "QT LIBRARIES: ${QT_LIBRARIES}")
  message(STATUS "QT_CFLAGS_OTHER: ${QT_CFLAGS_OTHER}")
endfunction()

#
# Part 4. -D definitions
#

if( NOT cross_defs_set )
  add_definitions( -DGLEW_STATIC ) # FindGLEW.cmake needs this
  add_definitions( -DBOOST_STATIC ) 
  add_definitions( -DBOOST_THREAD_USE_LIB )
  add_definitions( -DUNICODE ) # because qmake does it
  set(cross_defs_set 1)
endif()
