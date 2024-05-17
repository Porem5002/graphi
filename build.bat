@echo off

if "%1%" == "clean" (
    echo Cleaning...
    del *.exe
    del *.pdb
) else if "%1%" == "release" (
    echo Building Release Build...
    odin build src -out:graphi.exe -o:speed -subsystem:windows -vet
) else (
    echo Building Debug Build...
    odin build src -out:graphi.exe -o:none -debug -vet
)