/*
MIT License

Copyright (c) 2023 Dice

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include "iso_vm.h"
#include "iso_io.h"
#include "iso_aux.h"

#define DEFAULT_STACK_SIZE 65536

int main(
	int argc,
	char *argv[]
) {
	if (argc==1) {
		printf(
			"ISO v%u Copyright (C) 2023 Dice\n"
			"Usage: iso <file>\n",
			ISO_VERSION
		);
		
		return 0;
	}
	
	iso_vm vm;
	
	vm.INT        = 0;
	vm.PC         = 0;
	vm.SP         = 0;
	vm.stack_size = DEFAULT_STACK_SIZE;
	vm.stack      = calloc(
		(long int)vm.stack_size,
		sizeof(iso_uint)
	);
	
	//Load program
	char *program_name=argv[1];
	FILE *program_file=fopen(program_name,"rb");
	
	if (program_file==NULL) {
		printf("Cannot open file: %s",program_name);
		
		return -1;
	}
	
	fseek(program_file,0,SEEK_END);
	vm.program_size=ftell(program_file);
	//iso_char program[vm.program_size];
	vm.program=malloc((long int)vm.program_size);
	fseek(program_file,0,SEEK_SET);
	fread(
		vm.program,
		(long int)vm.program_size,
		1,
		program_file
	);
	fclose(program_file);
	
	//Run program
	do {
		iso_vm_run(&vm);
		iso_io_run(&vm);
	} while (!vm.INT);
	
	iso_aux_run(&vm);
	
	free(vm.stack);
	free(vm.program);
	
	return (int)vm.INT;
}