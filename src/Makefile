CC  = gcc -std=gnu99 -Wall -Wextra -O2
#CC = i586-pc-msdosdjgpp-gcc -std=gnu99 -Wall -Wextra -O2 --ffast-math

all: iso

iso: isocon.c arger.o isoasm.o isovm.o isofp.o isoio.o isoaux.o
	$(CC) isocon.c -o \
	iso \
	arger.o \
	isoasm.o \
	isovm.o \
	isofp.o \
	isoio.o \
	isoaux.o 

arger.o: arger.h arger.c
	$(CC) -c arger.c -o arger.o

isoasm.o: iso.h isoasm.h isoasm.c
	$(CC) -c isoasm.c -o isoasm.o

isovm.o: iso.h isovm.h isovm.c
	$(CC) -c isovm.c -o isovm.o

isofp.o: iso.h isovm.h isofp.h isofp.c
	$(CC) -c isofp.c -o isofp.o

isoio.o: iso.h isovm.h isoio.h isoio.c
	$(CC) -c isoio.c -o isoio.o

isoaux.o: iso.h isovm.h isoaux.h isoaux.c
	$(CC) -c isoaux.c -o isoaux.o

clean:
	rm -f \
	iso \
	arger.o \
	isoasm.o \
	isovm.o \
	isofp.o \
	isoio.o \
	isoaux.o 