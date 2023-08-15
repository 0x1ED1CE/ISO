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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "arger.h"

void arger_parse( /* Very basic arg parser */
	int argc,
	char *argv[],
	const char *option,
	int *flag,
	int *parameters
) {
	if (flag==NULL)
		return;
	
	*flag=0;
	
	for (int i=1; i<argc; i++) {
		if (argv[i][0]!='-')
			continue;
		
		if (strcmp(argv[i]+sizeof(char),option)==0) {
			*flag=i;
			
			if (parameters==NULL)
				return;
			
			*parameters=0;
			
			int j;
			
			for (j=i+1; j<argc; j++) {
				if (argv[j][0]=='-')
					break;
			}
			
			*parameters=(j-1)-i;
			
			break;
		}
	}
}