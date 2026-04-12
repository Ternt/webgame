@echo off
cd /D "%~dp0"

:: -- Unpacking Cmdline Arguments -------------------------------------------------------

for %%a in (%*) do set "%%a=1"

if not "%debug%"=="1" if not "%release%"=="1" set debug=1
if "%debug%"=="1" set release=0 && echo [compile debug]
if "%release%"=="1" set debug=0 && echo [compile release]

if not "%msvc%"=="1" if not "%clang%"=="1" if not "%gcc%"=="1" if not "%wasm%"=="1" set msvc=1
if "%gcc%"=="1"   set msvc=0 && set wasm=0 && set clang=0 && echo [compile gcc]
if "%clang%"=="1" set msvc=0 && set wasm=0 && set gcc=0 && echo [compile clang]
if "%msvc%"=="1"  set clang=0 && set wasm=0 && set gcc=0 && echo [compile msvc]
if "%wasm%"=="1"  set clang=0 && set msvc=0 && set gcc=0 && echo [compile wasm]

if "%~1"==""                     echo [default mode, assuming `GAME` build] && set game=1
if "%~1"=="release" if "%~2"=="" echo [default mode, assuming `GAME` build] && set game=1

:: -- Build Variables ------------------------------------------------------------------

set root=../../
set include_paths=  %include_paths% /I%root%code/

:: -- Compile Flags & Build Options ----------------------------------------------------

if "%build_web%"=="1" echo [build web]

:: -- Compile/Link Line Definitions ----------------------------------------------------

set cl_common=      %include_paths% /nologo /FC /Z7
set cl_debug=       call cl /Od /Ob1 /DBUILD_DEBUG=1 %cl_common%
set cl_release=     call cl /O2 %cl_common%
set cl_link=        /link /MANIFEST:EMBED /INCREMENTAL:NO
set cl_out=         /out:
set clang_common=  
set clang_debug=   
set clang_release= 
set clang_link=    
set clang_out=     
set gcc_common=  
set gcc_debug=   
set gcc_release= 
set gcc_link=    
set gcc_out=     
set wasm_common=    -sWASM=1
set wasm_debug=     call emcc -O0 -g
set wasm_release=   call emcc -O3
set wasm_link=
set wasm_out=       -o 

:: -- Per-Build Settings ---------------------------------------------------------------

set link_dll=     -DLL
set lib_paths=    %lib_paths% /LIBPATH:%root%

if "%msvc%"=="1"  set linker=%cl_link%
if "%clang%"=="1" set linker=%clang_link%
if "%wasm%"=="1"  set linker=%emcc_link%
if "%msvc%"=="1"  set only_compile=/c
if "%clang%"=="1" set only_compile=-c
if "%wasm%"=="1"  set only_compile=-c
if "%msvc%"=="1"  set EHsc=/EHsc
if "%clang%"=="1" set EHsc=

:: -- Choose Compiler/Link Line --------------------------------------------------------

if "%msvc%"=="1"    set compile_debug=%cl_debug%
if "%msvc%"=="1"    set compile_release=%cl_release%
if "%msvc%"=="1"    set compile_link=%cl_link%
if "%msvc%"=="1"    set out=%cl_out%
if "%clang%"=="1"   set compile_debug=%clang_debug%
if "%clang%"=="1"   set compile_release=%clang_release%
if "%clang%"=="1"   set compile_link=%clang_link%
if "%clang%"=="1"   set out=%clang_out%
if "%gcc%"=="1"     set compile_debug=%gcc_debug%
if "%gcc%"=="1"     set compile_release=%gcc_release%
if "%gcc%"=="1"     set compile_link=%gcc_link%
if "%gcc%"=="1"     set out=%gcc_out%
if "%wasm%"=="1"    set compile_debug=%wasm_debug%
if "%wasm%"=="1"    set compile_release=%wasm_release%
if "%wasm%"=="1"    set compile_link=%wasm_link%
if "%wasm%"=="1"    set out=%wasm_out%
if "%debug%"=="1"   set compile=%compile_debug%
if "%release%"=="1" set compile=%compile_release%

:: -- Prepare Build Dir ----------------------------------------------------------------

if not exist build mkdir build
if not exist build/bin mkdir build/bin

:: -- Build ----------------------------------------------------------------------------

pushd build
pushd bin
if "%game%"=="1"      set didbuild=1 && %compile% %root%code/game/game.c      %out%game.wasm || exit /b 1
if "%test_wasm%"=="1" set didbuild=1 && %compile% %root%code/test/test_wasm.c %out%test_wasm.wasm || exit /b 1
popd bin
popd build

:: -- Post-Build Actions --------------------------------------------------------------

if "%build_web%"=="1" (
  if not exist build/web mkdir build/web
  if not exist build/web/static mkdir build/web/static
  call pnpm build >> NUL
  cp build/bin/*.wasm build/web/static/
)

:: -- Build Log -----------------------------------------------------------------------

if "%didbuild%"=="" (
  echo [WARNING] Please specify a build target.
  exit /b 1
)
