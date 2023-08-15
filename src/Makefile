CC = gcc -std=gnu99 -Wall -O2
#CC = i586-pc-msdosdjgpp-gcc -std=gnu99 -Wall -O2

all: iso

iso: isocon.c arger.o isoaux.o isovm.o isoasm.o
	$(CC) isocon.c -o iso arger.o isovm.o isoasm.o isoaux.o

arger.o: arger.h arger.c
	$(CC) -c arger.c -o arger.o

isovm.o: iso.h isovm.h isovm.c
	$(CC) -c isovm.c -o isovm.o

isoasm.o: iso.h isoasm.h isoasm.c
	$(CC) -c isoasm.c -o isoasm.o

isoaux.o: isovm.h isoasm.h isoaux.h isoaux.c
	$(CC) -c isoaux.c -o isoaux.o

clean:
	rm -f isovm.o isoasm.o isoaux.o arger.o iso