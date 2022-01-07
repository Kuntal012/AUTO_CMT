# CFLAGS=-O
CFLAGS=-I../include -c -O -DENVIRONMENT
#CFLAGS=-O

SOURCE = getpar.c getarg.c splitc.c exit_prg.c msfilter.c complex.c
CFILES = getpar.o getarg.o splitc.o exit_prg.o msfilter.o complex.o
FFILES = fgetpar.o fgetarg.o splitc.o exit_prg.o 

all:
	gcc $(CFLAGS) $(SOURCE)
	ar r libtdmrf.a $(CFILES)
	ranlib libtdmrf.a
	ar tv libtdmrf.a


cleanup:
	rm *.o


