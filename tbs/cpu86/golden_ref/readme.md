# Golden Reference Testbench

This testbench executes series of code snippets stored in the asm folder. Each executed instruction is compared agains e8086 software CPU taken from the pce-0.2.2-ibmpc project.

If there is a mismatch between hardware and software implementation the testbench will report an error.

Testbench structure:

* asm - folder contains code snippets
* bin - service folder that stores compiled binaries
* e8086 - 8086 CPU simulator from the PCE project

Testbench contains bare CPU without any SOC subsystems except RAM and IO units.
