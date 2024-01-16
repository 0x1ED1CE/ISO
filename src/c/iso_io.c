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

#include "iso_io.h"

FILE *files[MAX_FILES];

void iso_io_run(
	iso_vm *vm
) {
	if (vm->INT==ISO_INT_NONE)
		return;
	
	switch(vm->INT) {
		case ISO_INT_CONSOLE_OUTPUT:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			putc(iso_vm_pop(vm),stdout);
			
			break;
		case ISO_INT_CONSOLE_INPUT:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint A = 0;
				iso_uint B = 0;
				
				do {
					B=(iso_uint)getc(stdin);
					
					if (B=='\n')
						break;
					
					iso_vm_push(vm,B);
					A+=1;
				} while (vm->INT==ISO_INT_NONE);
				
				iso_vm_push(vm,A);
			}
			
			break;
		case ISO_INT_FILE_INIT:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			for (iso_uint i=0; i<MAX_FILES; i++) {
				files[i]=NULL;
			}
			
			break;
		case ISO_INT_FILE_DEINIT:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			for (iso_uint i=0; i<MAX_FILES; i++) {
				FILE *file=files[i];
				
				if (file!=NULL) {
					fclose(file);
					files[i]=NULL;
				}
			}
			
			break;
		case ISO_INT_FILE_OPEN:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint name_address = iso_vm_pop(vm);
				iso_uint name_size    = iso_vm_get(vm,name_address);
				iso_uint mode         = iso_vm_pop(vm);
				
				iso_uint file_id = MAX_FILES;
				
				char file_name[name_size+4];
				
				for (iso_uint i=0; i<name_size; i+=4) {
					iso_uint word = iso_vm_get(vm,name_address+i/4+1);
					
					file_name[i]   = (char)(word>>24);
					file_name[i+1] = (char)(word>>16&0xFF);
					file_name[i+2] = (char)(word>>8&0xFF);
					file_name[i+3] = (char)(word&0xFF);
				}
				
				file_name[name_size] = '\0';
				
				for (iso_uint i=0; i<MAX_FILES; i++) {
					if (files[i]==NULL) {
						file_id=i;
						break;
					}
				}
				
				if (file_id<MAX_FILES) {
					switch(mode) {
						case ISO_FILE_MODE_READ:
							files[file_id]=fopen(file_name,"rb");
							
							break;
						case ISO_FILE_MODE_WRITE:
							files[file_id]=fopen(file_name,"wb");
							
							break;
						case ISO_FILE_MODE_BOTH:
							files[file_id]=fopen(file_name,"rb+");
							
							break;
						case ISO_FILE_MODE_APPEND:
							files[file_id]=fopen(file_name,"ab");
					}
				}
				
				iso_vm_push(vm,file_id);
			}
			
			break;
		case ISO_INT_FILE_CLOSE:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint file_id = iso_vm_pop(vm);
				FILE       *file = files[file_id];
				
				if (file!=NULL) {
					fclose(file);
					files[file_id]=NULL;
				}
			}
			
			break;
		case ISO_INT_FILE_SIZE:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint file_id   = iso_vm_pop(vm);
				FILE       *file   = files[file_id];
				iso_uint file_size = 0;
				
				if (file!=NULL) {
					long int origin=ftell(file);
					
					fseek(file,0,SEEK_END);
					file_size=(iso_uint)ftell(file);
					fseek(file,origin,SEEK_SET);
				}
				
				iso_vm_push(vm,file_size);
			}
			
			break;
		case ISO_INT_FILE_SEEK_SET:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint file_id = iso_vm_pop(vm);
				long int address = iso_vm_pop(vm);
				FILE       *file = files[file_id];
				
				if (file!=NULL) {
					fseek(file,(long int)address,SEEK_SET);
				}
			}
			
			break;
		case ISO_INT_FILE_SEEK_GET:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint file_id = iso_vm_pop(vm);
				FILE       *file = files[file_id];
				
				if (file!=NULL) {
					iso_vm_push(vm,(iso_uint)ftell(file));
				}
			}
			
			break;
		case ISO_INT_FILE_READ:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint file_id        = iso_vm_pop(vm);
				iso_uint buffer_address = iso_vm_pop(vm);
				iso_uint buffer_size    = iso_vm_get(vm,buffer_address);
				FILE       *file        = files[file_id];
				
				if (file!=NULL) {
					char buffer[buffer_size+4];
					
					memset(buffer,0,buffer_size+4);
					fread(buffer,1,buffer_size,file);
					
					for (iso_uint i=0; i<buffer_size; i+=4) {
						iso_vm_set(
							vm,
							buffer_address+i/4+1,
							(iso_uint)buffer[i]<<24|
							(iso_uint)buffer[i+1]<<16|
							(iso_uint)buffer[i+2]<<8|
							(iso_uint)buffer[i+3]
						);
					}
				}
			}
			
			break;
		case ISO_INT_FILE_WRITE:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			{
				iso_uint file_id        = iso_vm_pop(vm);
				iso_uint buffer_address = iso_vm_pop(vm);
				iso_uint buffer_size    = iso_vm_get(vm,buffer_address);
				FILE       *file        = files[file_id];
				
				if (file!=NULL) {
					char buffer[buffer_size+4];
					
					for (iso_uint i=0; i<buffer_size; i+=4) {
						iso_uint word = iso_vm_get(vm,buffer_address+i/4+1);
						
						buffer[i]   = (char)(word>>24);
						buffer[i+1] = (char)(word>>16&0xFF);
						buffer[i+2] = (char)(word>>8&0xFF);
						buffer[i+3] = (char)(word&0xFF);
					}
					
					fwrite(buffer,1,buffer_size,file);
				}
			}
			
			break;
		case ISO_INT_CLOCK:
			break;
		case ISO_INT_TERMINATE:
			iso_vm_interrupt(vm,ISO_INT_NONE);
			
			exit((int)iso_vm_pop(vm));
	}
}