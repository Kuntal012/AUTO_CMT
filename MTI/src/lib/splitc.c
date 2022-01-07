#include "tdmrflib.h"
/* *********************
void splitc( strc,mesg,delm ) ;
**************** */

/* #### separate mesg(strings) by char.(delm) ###### */
/* Y.Ito  2003 03 17 */
void splitc( struct INARGV *strc, char *mesg, char delm )
{
  int i,j,k,meslen ;
  meslen=strlen( mesg ) ;
  i=j=k=0 ;
  while( i < meslen ){ 
    if( mesg[i]==delm ){
      strc->elemc[j][k]='\0' ;
      k=0 ;
      j++ ;
    }
    else{
      strc->elemc[j][k]=mesg[i] ;
      k++ ;
    }
    i++ ;
    
  }
  strc->elemc[j][k]='\0' ;
  strc->elen=j+1 ;
  
}
