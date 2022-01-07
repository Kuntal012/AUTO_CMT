#include <stdio.h> 
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <malloc.h>
#include <dirent.h>
#include <errno.h>
#include <unistd.h>
#include <time.h>
#define SWAP(a,b) {temp=(a);(a)=(b);(b)=temp;}

#define    VPVS2   3.0             /*  (Vp/Vs)^2 */
#define    VPVS    (sqrt(VPVS2))   /*  Vp/Vs */

#define    MIN(a,b) (a)<(b) ? (a) : (b)
#define    MULT2(x) ((x)*(x))

#define    PI      3.14159265358979323846
#define    P2      1.57079632679489661923
#define    HP      (PI/2.0)
#define    PD      ((180.0)/(PI))
#define    EPS1    1.0e-8
#define    EPS2    1.0e-14
#define    LIT1    30
#define    LIT2    10

#define    GEOA     6377.397155
#define    GEOB     6356.078963

struct INARGV {
  int  elen ;
  char elemc[100][200] ;
}; 

