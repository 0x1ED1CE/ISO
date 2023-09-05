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
#include "isovm.h"
#include "isofp.h"
#include "isoio.h"
#include "isoaux.h"

#define DEFAULT_STACK_SIZE 64000

void about() {
	printf(
		"ISO v1 Copyright (C) 2023 Dice\n"
		"Usage: iso -b <file> -r\n"
		"Options:\n"
		"-b\tImport binary\n"
		"-s\tStack size\n"
		"-d\tDebug mode\n"
		"-r\tRun program\n"
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
	
	int opt_import_binary,par_import_binary;
	int opt_set_stack,par_set_stack;
	int opt_debug;
	int opt_run;
	
	arger_parse(
		argc,
		argv,
		"b",
		&opt_import_binary,
		&par_import_binary
	);
	arger_parse(
		argc,
		argv,
		"s",
		&opt_set_stack,
		&par_set_stack
	);
	arger_parse(
		argc,
		argv,
		"d",
		&opt_debug,
		NULL
	);
	arger_parse(
		argc,
		argv,
		"r",
		&opt_run,
		NULL
	);
	
	if (!(
		opt_import_binary ||
		opt_set_stack ||
		opt_run
	)) {
		about();
		
		return 0;
	}
	
	unsigned int program_size = 0;
	unsigned int stack_size   = DEFAULT_STACK_SIZE;
	
	if (opt_set_stack && par_set_stack) { //Set stack size
		stack_size=atoi(argv[opt_set_stack+1]);
	}
	
	if (opt_import_binary) { //Determine total program size
		for (
			int i=opt_import_binary+1;
			i<=opt_import_binary+par_import_binary;
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
	
	if (opt_import_binary) { //Load the program
		unsigned int program_address=0;
		
		for (
			int i=opt_import_binary+1;
			i<=opt_import_binary+par_import_binary;
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
	
	if (opt_run) { //Run program
		iso_vm vm;
		vm.INT          = 0;
		vm.PC           = 0;
		vm.SP           = 0;
		vm.program_size = program_size;
		vm.stack_size   = stack_size;
		vm.program      = program;
		vm.stack        = stack;
		
		do {
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
			iso_fp_run(&vm);
			iso_io_run(&vm);
			iso_aux_run(&vm);
		} while (vm.INT==0);
		
		return vm.INT;
	}
	
	return 0;
}