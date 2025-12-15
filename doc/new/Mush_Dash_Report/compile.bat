@echo off
setlocal

rem Use UTF-8 codepage so Chinese output isn't garbled in cmd.
chcp 65001 >nul

set TEXFILE=Muse_Dash
set SCRIPT_DIR=%~dp0
set TEXDIR=%SCRIPT_DIR%
set OUTDIR=build

if not exist "%TEXDIR%\\%TEXFILE%.tex" (
    echo ERROR: TeX file not found: "%TEXDIR%\\%TEXFILE%.tex"
    exit /b 1
)

echo Compiling %TEXFILE%.tex with xelatex...

pushd "%TEXDIR%"

if not exist "%OUTDIR%" (
    mkdir "%OUTDIR%"
)

rem Clean previous build artifacts to keep intermediates under build\
del /Q "%OUTDIR%\\%TEXFILE%.*" 2>nul
if exist "%OUTDIR%\\_minted-%TEXFILE%" rd /s /q "%OUTDIR%\\_minted-%TEXFILE%"
if exist "_minted-%TEXFILE%" rd /s /q "_minted-%TEXFILE%"

xelatex -interaction=nonstopmode -shell-escape -output-directory "%OUTDIR%" "%TEXFILE%.tex"
if errorlevel 1 goto end

rem No biber/bibtex for this report
xelatex -interaction=nonstopmode -shell-escape -output-directory "%OUTDIR%" "%TEXFILE%.tex"
xelatex -interaction=nonstopmode -shell-escape -output-directory "%OUTDIR%" "%TEXFILE%.tex"

set BUILDPDF=%OUTDIR%\\%TEXFILE%.pdf

if not exist "%BUILDPDF%" (
    echo Build finished but PDF not found; check the log for details.
    goto end
)

echo Build succeeded: %TEXDIR%\\%BUILDPDF%
echo Copying to "%SCRIPT_DIR%%TEXFILE%.pdf" ...
copy /Y "%BUILDPDF%" "%SCRIPT_DIR%%TEXFILE%.pdf" >nul

:end
popd
endlocal
