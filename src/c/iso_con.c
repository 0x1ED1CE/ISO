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

#ifdef _WIN32
#include <conio.h>
#include <windows.h>
#endif

#include "arger.h"
#include "iso_vm.h"
#include "iso_io.h"
#include "iso_aux.h"

#define DEFAULT_STACK_SIZE 64000

void about() {
	printf(
		"ISO v0.6 Copyright (C) 2023 Dice\n"
		"Usage: iso -i <file>\n"
		"Options:\n"
		"-i\tImport binary\n"
		"-m\tMemory size\n"
		"-d\tEnable debug\n"
	);
}

int main(
	int argc,
	char *argv[]
) {
	if (argc==1) {
		about();
		
		return 0;
	}
	
	int opt_import,par_import;
	int opt_memory,par_memory;
	int opt_debug;
	
	arger_parse(
		argc,
		argv,
		"i",
		&opt_import,
		&par_import
	);
	arger_parse(
		argc,
		argv,
		"m",
		&opt_memory,
		&par_memory
	);
	arger_parse(
		argc,
		argv,
		"d",
		&opt_debug,
		NULL
	);
	
	if (!(opt_import)) {
		about();
		
		return 0;
	}
	
	unsigned int program_size = 0;
	unsigned int stack_size   = DEFAULT_STACK_SIZE;
	
	if (opt_memory && par_memory) { //Set stack size
		stack_size=atoi(argv[opt_memory+1]);
	}
	
	if (opt_import) { //Determine program size
		for (
			int i=opt_import+1;
			i<=opt_import+par_import;
			i++
		) {
			char *file_name=argv[i];
			FILE *fp=fopen(file_name,"r");
			
			if (fp==NULL) {
				printf("Cannot open file: %s",file_name);
				
				return -1;
			}
			
			fseek(fp,0,SEEK_END);
			program_size+=ftell(fp);
			fclose(fp);
		}
	}
	
	iso_char program[program_size];
	iso_uint stack[stack_size];
	
	if (opt_import) { //Load the program
		unsigned int program_address=0;
		
		for (
			int i=opt_import+1;
			i<=opt_import+par_import;
			i++
		) {
			char *file_name=argv[i];
			FILE *fp=fopen(file_name,"r");
			unsigned int file_size=0;
			
			if (fp==NULL) {
				printf("Cannot open file: %s",file_name);
				
				return -1;
			}
			
			fseek(fp,0,SEEK_END);
			file_size+=ftell(fp);
			fseek(fp,0,SEEK_SET);
			fread(
				program+program_address,
				(long int)file_size,
				1,
				fp
			);
			program_address+=file_size;
			fclose(fp);
		}
	}
	
	iso_vm vm;
	vm.INT          = 0;
	vm.PC           = 0;
	vm.SP           = 0;
	vm.program_size = program_size;
	vm.stack_size   = stack_size;
	vm.program      = program;
	vm.stack        = stack;
	
	do { //Run program
		if (opt_debug) {
			#ifdef _WIN32
				char title[256];
				
				sprintf(
					title,
					"INT: %.8X PC: %.8X SP: %.8X",
					vm.INT,
					vm.PC,
					vm.SP
				);
				
				SetConsoleTitle(title);
				
				if (getch()==0x1B)
					break;
			#endif
		}
		
		iso_vm_run(&vm,opt_debug);
		iso_io_run(&vm);
		iso_aux_run(&vm);
	} while (vm.INT==0);
	
	return vm.INT;
}