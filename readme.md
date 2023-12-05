# STM32 CMake Environment Setup Script

This script is for windows user who want to use cmake environment but afraid of bunch of install lists.

## In a nutshell

Run on powershell (administrator mode)
```
.\setup.ps1
```

## Setup components
- CMake
- Ninja
- ARM-GCC compiler
- OpenOCD
- (7zip)

## Environment variable connections
If you have STM32CubeIDE, this script support connection to toolchains as well. 

But, if you use openocd, you can skip it.

- STM32_Programmer_CLI
- ST-LINK_gdbserver

It searches toolchain and connect its path to user environment variable. Default search path is default installation path ```C:\ST\STM32CubeIDE_version```. If you install STM32CubeIDE on different path, you can modify search path manually. 
```
Directory 'C:\ST' does not exist. Do you want to skip to map CubeIDE toolchains? (Y/N): N
Enter an alternative directory path:: C:\STx
Using alternative directory: 'C:\STx'
File 'STM32_Programmer_CLI.exe' found in directory: C:\STx\STM32CubeIDE_1.12.
...
```

***Note***

Using compiler bundled in STM32CubeIDE is not good idea due to it's long path name. It make weird problem only happens on windows system. Refer this [thread](https://stackoverflow.com/questions/4643197/missing-include-bits-cconfig-h-when-cross-compiling-64-bit-program-on-32-bit).

## Ready to run?

Now you can run stm32 cmake projects. I recommend to use vscode. Sample projects are ready.


