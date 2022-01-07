
# CFLAGS=-O
CFLAGS=-Iinclude -Llib 
LBFLAGS=-Llib
OFLAGS=-ltdmrf -lm 
CFLAGSC=-Iinclude -c
OFLAGSC=
LFLAGSC=-Llib

all:
	gcc $(CFLAGS) $(LIBFLAGS) deltazimuth.c -o deltazimuth $(OFLAGS)
	gcc $(CFLAGSC) tdmrf_inv.c $(OFLAGSC)
	gcc $(CFLAGSC) tdmrf2_inv.c $(OFLAGSC)
	gfortran -c inv_fsub.f $(OFLAGSC) 
	gfortran $(LFLAGSC) tdmrf_inv.o inv_fsub.o -o tdmrf_inv  $(OFLAGS)
	gfortran $(LFLAGSC) tdmrf2_inv.o inv_fsub.o -o tdmrf2_inv $(OFLAGS)

cleanup:
	rm *.o 


