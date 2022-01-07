
# CFLAGS=-O
LBFLAGS=-Llib
OFLAGS=-ltdmrf -lm 
CFLAGSC=-Iinclude -c -O3
OFLAGSC=
LFLAGSC=-Llib

all:
	gfortran -c -O3 inv_fsub.f 
	gcc $(CFLAGSC) exit_prg.c
	gcc $(CFLAGSC) tdmrf_inv_spa_grid.c  
	gfortran *.o -o tdmrf_inv_spa_grid -lm
	
cleanup:
	rm *.o 


