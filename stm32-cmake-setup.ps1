Import-Module BitsTransfer

$compilerVersion = "10.3-2021.10"
$ninjaVersion    = "1.11.1"
$cmakeVersion    = "3.27.9"
$openocdVersion  = "0.12.0-2"

$dowloadPath = "C:\mcu_tool_download_tmp"
$compilerPath = "C:\arm-gcc"
$ninjaPath    = "C:\cmake"
$cmakePath    = "C:\cmake"
$openocdPath  = "C:\openocd"

$stToolPath = "C:\ST"

$compilerUrl= "https://developer.arm.com/-/media/Files/downloads/gnu-rm/$compilerVersion/gcc-arm-none-eabi-$compilerVersion-win32.zip"
$ninjaUrl   = "https://github.com/ninja-build/ninja/releases/download/v$ninjaVersion/ninja-win.zip"
$cmakeUrl   = "https://github.com/Kitware/CMake/releases/download/v$cmakeVersion/cmake-$cmakeVersion-windows-x86_64.zip"
$openocdUrl = "https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v$openocdVersion/xpack-openocd-$openocdVersion-win32-x64.zip"

function Test-7ZipInstallation {
    # Specify the expected path to 7-Zip executable
    $sevenZipPath = Join-Path $env:ProgramFiles "7-Zip\7z.exe"

    # Check if the 7-Zip executable exists
    if (Test-Path -Path $sevenZipPath) {
        Write-Host "7-Zip is installed. Path: $sevenZipPath"
        return $true
    } else {
        Write-Host "7-Zip is not installed or not found at the expected path."
        return $false
    }
}

function Add-ToPath {
    param(
        [string]$DirectoryToAdd
    )

    # Get the current user's environment variables
    $CurrentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)

    # Check if the directory is already in PATH
    if ($CurrentPath -notlike "*$DirectoryToAdd*") {
        # Append the new directory to PATH
        $NewPath = "$CurrentPath;$DirectoryToAdd"
        
        # Set the updated PATH value
        [System.Environment]::SetEnvironmentVariable("PATH", $NewPath, [System.EnvironmentVariableTarget]::User)

        Write-Host "Directory added to PATH. Changes will take effect in new sessions."
    } else {
        Write-Host "Directory is already in PATH."
    }
}

function Test-CommandExists {
    param (
        [string]$CommandName
    )

    # Check if the command exists
    if (Get-Command -Name $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "The command '$CommandName' exists."
        return $true
    } else {
        Write-Host "The command '$CommandName' does not exist."
        return $false
    }
}

function Confirm-DirectoryExists {
    param (
        [string]$Path
    )

    # Check if the directory exists
    if (-not (Test-Path -Path $Path -PathType Container)) {
        # If the directory doesn't exist, create it
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Directory created: $Path"
    } else {
        Write-Host "Directory already exists: $Path"
    }
}

function Remove-DirectoryAndContents {
    param (
        [string]$DirectoryPath
    )

    # Remove all files in the directory
    Get-ChildItem -Path $DirectoryPath | Remove-Item -Force

    # Remove the directory itself
    Remove-Item -Path $DirectoryPath -Force -Recurse
}

function Expand-7Zip {
    param (
        [string]$ZipFilePath,
        [string]$DestinationFolder
    )

    # Specify the path to 7-Zip executable
    $sevenZipExe = Join-Path $env:ProgramFiles "7-Zip\7z.exe"

    # Create the destination folder if it doesn't exist
    if (-not (Test-Path -Path $DestinationFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
    } else {
        # Remove all existing files and folders in the destination folder
        Get-ChildItem -Path $DestinationFolder | Remove-Item -Recurse -Force
    }

    # Use 7-Zip to extract the contents
    Start-Process -FilePath $sevenZipExe -ArgumentList "x `"$ZipFilePath`" -o`"$DestinationFolder`" -bso0 -bsp1" -NoNewWindow -Wait}

function Test-AndPromptDirectory {
    param (
        [string]$DirectoryPath,
        [string]$PromptMessage = "Enter an alternative directory path:"
    )

    # Check if the directory exists
    if (Test-Path -Path $DirectoryPath -PathType Container) {
        Write-Host "Directory '$DirectoryPath' exists."
        return $DirectoryPath
    }

    # Ask the user if they want to skip
    $skipResponse = Read-Host -Prompt "Directory '$DirectoryPath' does not exist. Do you want to skip to map CubeIDE toolchains? (Y/N)"

    if ($skipResponse -eq 'Y' -or $skipResponse -eq 'y') {
        Write-Host "Skipping directory check as per user request."
        return $null
    }

    # Prompt the user for an alternative directory
    do {
        $alternativePath = Read-Host -Prompt $PromptMessage
    } while (-not (Test-Path -Path $alternativePath -PathType Container))

    Write-Host "Using alternative directory: '$alternativePath'"
    return $alternativePath
}

function Search-FileDirectory {
    param (
        [string]$DirectoryPath,
        [string]$FileName
    )

    # Get all files in the directory and its subdirectories
    $files = Get-ChildItem -Path $DirectoryPath -Recurse -File -ErrorAction SilentlyContinue

    # Search for the specified file
    $foundFile = $files | Where-Object { $_.Name -eq $FileName }

    if ($null -ne $foundFile) {
        Write-Host "File '$FileName' found in directory: $($foundFile.Directory.FullName)"
        return $foundFile.Directory.FullName
    } else {
        Write-Host "File '$FileName' not found in the specified directory and its subdirectories."
        return $null
    }
}


Confirm-DirectoryExists -Path $dowloadPath

if (Test-7ZipInstallation) {
    # 7-Zip is installed, you can perform additional actions here
    Write-Host "7Zip already installed"
} else {
    # Install 7zip for extraction
    $sevenZipExe = Join-Path $env:ProgramFiles "7-Zip\7z.exe"
    $sevenZipUrl = "https://www.7-zip.org/a/7z2301-x64.exe"
    $tempDir = "$env:TEMP\7ZipInstaller"
    
    if (-not (Test-Path -Path $tempDir -PathType Container)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    
    $sevenZipPath = Join-Path $tempDir "7zInstaller.exe"
    Invoke-WebRequest -Uri $sevenZipUrl -OutFile $sevenZipPath
    Start-Process -FilePath $sevenZipPath -ArgumentList "/S" -Wait
}

if (Test-CommandExists cmake){
    Write-Host "CMake found. Skip installation"
} else{
    #Check installation directory
    Write-Host "CMake not found. Installation in progress.."
    Confirm-DirectoryExists -Path $cmakePath

    #Download
    $zipFilePath = Join-Path $dowloadPath "cmake.zip"
    Start-BitsTransfer $cmakeUrl $zipFilePath

    #Extract and move to installation path
    $extractedPath = $cmakePath
    Write-Host "Expanding file $zipFilePath to $extractedPath. It may takes few minutes"
    Get-ChildItem -Path $extractedPath | Remove-Item -Recurse -Force
    # [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $extractedPath)
    Expand-7Zip $zipFilePath $extractedPath

    $extractedFolder = Get-ChildItem -Path $extractedPath | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    Get-ChildItem -Path $extractedFolder.FullName | Move-Item -Destination $extractedPath -Force
    Remove-Item -Path $extractedFolder.FullName -Force

    #Add environment variable
    $env_path_cmake = Join-Path $cmakePath "bin"
    Add-ToPath -DirectoryToAdd $env_path_cmake
}

if (Test-CommandExists ninja){
    Write-Host "Ninja found. Skip installation"
} else{
    #Check installation directory
    Write-Host "Ninja not found. Installation in progress.."
    Confirm-DirectoryExists -Path $ninjaPath

    #Download
    $zipFilePath = Join-Path $dowloadPath "ninja.zip"
    Start-BitsTransfer $ninjaUrl $zipFilePath

    #Extract and move to installation path
    $extractedPath = Join-Path $ninjaPath "bin"
    Write-Host "Expand file $zipFilePath to $extractedPath. It may takes few minutes"

    Expand-Archive -Path $zipFilePath -DestinationPath $extractedPath -Force

    #Add environment variable
    Add-ToPath -DirectoryToAdd $extractedPath
}

if (Test-CommandExists openocd){
    Write-Host "OpenOCD found. Skip installation"
} else{
    #Check installation directory
    Write-Host "OpenOCD not found. Installation in progress.."
    Confirm-DirectoryExists -Path $openocdPath

    #Download
    $zipFilePath = Join-Path $dowloadPath "openocd.zip"
    Start-BitsTransfer $openocdUrl $zipFilePath

    #Extract and move to installation path
    $extractedPath = $openocdPath
    Write-Host "Expand file $openocdPath"

    Expand-7Zip $zipFilePath $extractedPath
    $extractedFolder = Get-ChildItem -Path $extractedPath | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    Get-ChildItem -Path $extractedFolder.FullName | Move-Item -Destination $extractedPath -Force
    Remove-Item -Path $extractedFolder.FullName -Force

    #Add environment variable
    $env_path_openocd = Join-Path $openocdPath "bin"
    $env_path_openocd_scripts = Join-Path $openocdPath "share\openocd\scripts"
    Add-ToPath -DirectoryToAdd $env_path_openocd
    Add-ToPath -DirectoryToAdd $env_path_openocd_scripts
}

if (Test-CommandExists arm-none-eabi-gcc){
    Write-Host "ARM compiler found. Skip installation"
} else{
    #Check installation directory
    Write-Host "ARM compiler not found. Installation in progress.."
    Confirm-DirectoryExists -Path $compilerPath

    #Download
    $zipFilePath = Join-Path $dowloadPath "compiler.zip"
    Start-BitsTransfer $compilerUrl $zipFilePath

    #Extract and move to installation path
    $extractedPath = $compilerPath
    Write-Host "Expanding file $zipFilePath to $extractedPath. It may takes few minutes"
    Get-ChildItem -Path $extractedPath | Remove-Item -Recurse -Force
    Expand-7Zip $zipFilePath $extractedPath
    $extractedFolder = Get-ChildItem -Path $extractedPath | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    Get-ChildItem -Path $extractedFolder.FullName | Move-Item -Destination $extractedPath -Force
    Remove-Item -Path $extractedFolder.FullName -Force

    #Add environment variable
    $env_path_compiler = Join-Path $compilerPath "bin"
    Add-ToPath -DirectoryToAdd $env_path_compiler
}

Remove-DirectoryAndContents -DirectoryPath $dowloadPath

$stToolPath = Test-AndPromptDirectory -DirectoryPath $stToolPath

if($null -eq $stToolPath){
    Write-Host "Skip to connect ST gdb and programmer tool."
}else{
    foreach($item in @("STM32_Programmer_CLI.exe", "ST-LINK_gdbserver.exe")){
        $foundDirectory = Search-FileDirectory -DirectoryPath $stToolPath -FileName $item
        if ($null -ne $foundDirectory) {
            Write-Host "Found $item location: $foundDirectory"
            Add-ToPath $foundDirectory
        } else {
            Write-Host "File $item not found in the specified directory and its subdirectories."
        }
    }
}


