Set-Location -Path  C:\Projects\DE2_115\tbs\cpu86\mem_ctrl -PassThru | Out-Null

$BinFolder = "bin"
$AsmFolder = "asm"

if (Test-Path $BinFolder) {

    Write-Host "clear bin folder..."
    Get-ChildItem -Path $BinFolder -Filter *.* -Recurse | Remove-Item

} else {
    #PowerShell Create directory if not exists
    New-Item $BinFolder -ItemType Directory
}

$ObjList = ""


##
Write-Host "assembler..."
Get-ChildItem -Path . -Filter *.asm | ForEach-Object {
    &'C:\Program Files\NASM\nasm.exe' -felf -o "$($_.DirectoryName)\$BinFolder\$($_.BaseName).o" $_.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    " $_.FullName " - fail"
        exit
    } else {
        Write-Host "    " $_.FullName " - ok"
    }
    $ObjList = $ObjList + "$($_.DirectoryName)\$BinFolder\$($_.BaseName).o" + " "
}

##
Write-Host "compiling..."
Get-ChildItem -Path . -Filter *.c | ForEach-Object {
    ia16-elf-gcc -O1 -Wall  -ffreestanding -std=gnu99 -mtune=i80186 -march=i80186 -c -o "$($_.DirectoryName)\$BinFolder\$($_.BaseName).o" $_.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    " $_.FullName " - fail"
        exit
    } else {
        Write-Host "    " $_.FullName " - ok"
    }
    $ObjList = $ObjList + "$($_.DirectoryName)\$BinFolder\$($_.BaseName).o" + " "
}

##
Write-Host "linking..."

Invoke-Expression "ia16-elf-ld -o .\bin\bootstrap.bin -T linker.lds $($ObjList)"

##
Write-Host "Disassembling..."
if (Test-Path $AsmFolder) {

    Write-Host "clear asm folder..."
    Get-ChildItem -Path $AsmFolder -Filter *.* -Recurse | Remove-Item

} else {
    #PowerShell Create directory if not exists
    New-Item $AsmFolder -ItemType Directory
}

ia16-elf-objdump.exe -M i8086 -d .\bin\kernel.o > .\asm\kernel.s
ia16-elf-objdump.exe -M i8086 -d .\bin\x86uart.o > .\asm\x86uart.s
ia16-elf-objdump.exe -M i8086 -d .\bin\x86mmu.o > .\asm\x86mmu.s
&'C:\Program Files\NASM\ndisasm.exe' -b 16 .\bin\bootstrap.bin > .\asm\bootstrap.s

Write-Host "generate rom"

C:\Projects\srecord-1.63-win32\srec_cat.exe  .\bin\bootstrap.bin -binary -fill 0x00 -within .\bin\bootstrap.bin -binary -range-pad 4 -o .\bootstrap.vmem -vmem
Copy-Item .\bootstrap.vmem C:\Projects\DE2_115\rtl\soc\onchip_ram\altera\bootstrap.vmem
