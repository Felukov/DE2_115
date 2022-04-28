Set-Location -Path  C:\Projects\DE2_115\tbs\cpu86\simple_boot -PassThru | Out-Null

Write-Host "assembling tests..."

Write-Host "assembler..."
Get-ChildItem -Path . -Filter *.asm | ForEach-Object {
    #Write-Host $_.BaseName
    &'C:\Program Files\NASM\nasm.exe' -felf -o "$($_.DirectoryName)\$($_.BaseName).o" $_.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    " $_.FullName " - fail"
        exit
    } else {
        Write-Host "    " $_.FullName " - ok"
    }

}

Write-Host "compiling..."
Get-ChildItem -Path . -Filter *.c | ForEach-Object {
    # ia16-elf-gcc -O1 -Wall -ffunction-sections -Werror -ffreestanding -std=gnu99 -mtune=i80186 -march=i80186 -c -o "$($_.DirectoryName)\$($_.BaseName).o" $_.FullName
    ia16-elf-gcc -O1 -Wall  -ffreestanding -std=gnu99 -mtune=i80186 -march=i80186 -c -o "$($_.DirectoryName)\$($_.BaseName).o" $_.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    " $_.FullName " - fail"
        exit
    } else {
        Write-Host "    " $_.FullName " - ok"
    }
}

Write-Host "linking..."
ia16-elf-ld -o bootstrap.bin -T linker.lds boot.o kernel.o x86uart.o x86platform.o
ia16-elf-objdump.exe -M i8086 -d .\kernel.o > .\kernel.s
ia16-elf-objdump.exe -M i8086 -d .\x86uart.o > .\x86uart.s
& 'C:\Program Files\NASM\ndisasm.exe' -b 16 .\bootstrap.bin > .\bootstrap.s

Write-Host "generate rom"
#C:\Projects\srecord-1.63-win32\srec_cat.exe  .\bootstrap.bin -binary -fill 0x00 -within .\bootstrap.bin -binary -range-pad 4 -o .\bootstrap.mif -mif 32
#C:\Projects\srecord-1.63-win32\srec_cat.exe  .\bootstrap.bin -binary -fill 0x00 -within .\bootstrap.bin -binary -range-pad 4 -o .\bootstrap.hex -intel

C:\Projects\srecord-1.63-win32\srec_cat.exe  .\bootstrap.bin -binary -fill 0x00 -within .\bootstrap.bin -binary -range-pad 4 -o .\bootstrap.vmem -vmem
Copy-Item .\bootstrap.vmem C:\Projects\DE2_115\rtl\soc\onchip_ram\altera\bootstrap.vmem
