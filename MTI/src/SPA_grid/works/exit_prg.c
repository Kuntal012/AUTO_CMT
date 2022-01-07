#include "tdmrflib.h"  


/* eno = 0 : Normal End */
/* eno = 1 : File not found */ 
void exit_prg( eno, mes )  
	int eno ;
	 char *mes ;
{	
  if(eno==0)
    fprintf(stderr, "Normal end at[%s]\n",mes ) ;
  else{
    fprintf(stderr,"%s Error code %d\n",mes, eno ) ;
    perror( "" ) ;
    exit( eno ) ;
  }  
}












