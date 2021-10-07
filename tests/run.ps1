function Test-CompilationResult {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    compilation - fail"
        exit
    }

}

Set-Location -Path C:\Projects\DE2_115\tests -PassThru | Out-Null

$SimFolder = "sim_data"
$LogFolder = "logs"
$WorkFolder = "work"

if (Test-Path vsim.wlf) {
    Remove-Item vsim.wlf
}

if (Test-Path $SimFolder) {

    Write-Host "clear sim_data folder..."
    Get-ChildItem -Path $SimFolder -Filter *.* -Recurse | Remove-Item

} else {
    #PowerShell Create directory if not exists
    New-Item $SimFolder -ItemType Directory
}

if (Test-Path $LogFolder) {

    Write-Host "clear logs folder..."
    Get-ChildItem -Path $LogFolder -Filter *.* -Recurse | Remove-Item

} else {
    #PowerShell Create directory if not exists
    New-Item $LogFolder -ItemType Directory
}

Write-Host "clear asm logs..."
Get-ChildItem -Path asm -Filter *.bin | Remove-Item
Get-ChildItem -Path asm -Filter *.txt | Remove-Item


Write-Host "assembling tests..."
Get-ChildItem -Path asm -Filter *.s | ForEach-Object {
    C:\emu8086\fasm\FASM.EXE $_.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    " $_.FullName " - fail"
        exit
    } else {
        Write-Host "    " $_.FullName " - ok"
    }
}
Write-Host "software simulation..."
Get-ChildItem -Path asm -Filter *.bin | ForEach-Object {
    C:\Projects\Sharp86\bin\Release\net5.0\Sharp86.exe $_.FullName
}

Write-Host "generating testlist..."
Get-ChildItem -Path asm -Filter *.bin | ForEach-Object {
    $_.FullName
} | Out-File -FilePath $SimFolder\test_list.txt -Encoding oem

if (Test-Path $WorkFolder) {
    Write-Host "delete work folder..."
    Remove-Item $WorkFolder -Recurse
}

Write-Host "running simulation..."

vlib work | Tee-Object $LogFolder\msim.log

vlog "../rtl/sdram_input_efifo_module.v"
Test-CompilationResult
vlog "../rtl/sdram_ctrl.v"
Test-CompilationResult
vlog "../tbs/sdram/sdram_test_model_mem.v"
Test-CompilationResult
vlog "..\tbs\sdram\sdram_test_model.v"
Test-CompilationResult
vcom -explicit -2008 "../rtl/axis_sdram.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/utils/axis_fifo.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/types.vhd"
Test-CompilationResult
vcom -explicit -93 "../rtl/cpu86/decoder.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/cpu_flags.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/cpu_reg.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/register_reader.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/ifeu.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/exec.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/lsu.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/lsu_fifo.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/dcache.vhd"
Test-CompilationResult
vcom -explicit -2008 "../rtl/cpu86/mexec.vhd"
Test-CompilationResult
vcom -explicit -2008 ".\exec_bin.vhd"
Test-CompilationResult

#vsim -batch -do "run -all"  work.exec_bin | Tee-Object $LogFolder\msim.log
vsim -t ps -novopt -do exec_bin.tcl work.exec_bin

Write-Host "completed!"

