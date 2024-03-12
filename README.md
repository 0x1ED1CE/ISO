# Intermediate Script Object
![LICENSE](https://img.shields.io/badge/LICENSE-MIT-green.svg)

ISO is a minimal stack-oriented instruction format intended for embedded applications. It has a very simple Forth-like syntax, enough to write any programs sufficiently.

## Examples
Each statement consists of a block followed by literal value(s), depending on the type of block.

Annotations are done by using the ``REM`` block
```asm
REM "This is a comment and does not do anything"
```
Pushing two numbers to the stack and adding them together
```asm
NUM 1 2
ADD
```
Defining and calling a function
```asm
FUN "SUBTRACT","C","A","B"
    VAR "A" GET REM "Arguments are passed by reference."
    VAR "B" GET REM "VAR returns the pointer and GET pushes the value from that address"
    ADD
    VAR "C" SET
    RET         REM "Must return at end of the function or else it will fall through"
```
```asm
NUM 0 1 2       REM "0 is a placeholder value"
RUN "SUBTRACT"  REM "Call the SUBTRACT subroutine"
POP POP         REM "Pop arguments from the stack, leaving only the result"
```
## Interfacing with the host
ISO uses interrupts in order to communicate with the host program. Interrupts simply halts the VM and allows the host to perform any necessary actions before resuming.

As an example, assume ``0x1234`` is the print interrupt routine
```asm
POS GBL "Text" SET REM "Assigns current stack pointer to global variable"
NUM "Hello World!" 0

GBL "Text" GET     REM "Push pointer to the stack"
NUM 0x1234 INT     REM "Request host to print characters from that address"
...                REM "VM resumes executing instructions"
```
In C this may look like:
```c
do {
    iso_vm_run(&vm);
    do_io_stuff(&vm);
} while (!vm.INT);
```
## Blocks (mnemonics)
Most blocks directly translates to bytecode with a few exceptions.

Table of blocks and their corresponding opcode:

``NUM [0x00 - 0x0F]`` ``INT [0x10]``<br>
``JMP [0x20]`` ``JMC [0x21]`` ``CEQ [0x22]`` ``CNE [0x23]`` ``CLS [0x24]`` ``CLE [0x25]``<br>
``ADD [0x40]`` ``SUB [0x41]`` ``MUL [0x42]`` ``DIV [0x43]`` ``POW [0x44]`` ``MOD [0x45]``<br>
``NOT [0x50]`` ``AND [0x51]`` ``BOR [0x52]`` ``XOR [0x53]`` ``LSH [0x54]`` ``RSH [0x55]``<br>

Floating point extension:

``FPU [0x60 - 0x6F]``<br>
``FTU [0x70]`` ``UTF [0x71]`` ``FEQ [0x72]`` ``FNE [0x73]`` ``FLS [0x74]`` ``FLE [0x75]``<br>
``FAD [0x80]`` ``FSU [0x81]`` ``FMU [0x82]`` ``FDI [0x83]`` ``FPO [0x84]`` ``FMO [0x85]``<br>
``SIN [0x90]`` ``COS [0x91]`` ``TAN [0x92]`` ``SQR [0x93]`` ``LOG [0x94]`` ``EXP [0x95]``<br>

## Macros
Not every block directly translates to a single instruction. Some are macros which help organize the program structure, mainly functions and symbols.

List of built-in macros:

``REM`` ``RAW``<br>
``SEC`` ``REC``<br>
``GBL`` ``VAR``<br>
``FUN`` ``PTR``<br>
``RUN`` ``RET``<br>

## License
This software is free to use. You can modify it and redistribute it under the terms of the 
MIT license. Check [LICENSE](LICENSE) for further details.
