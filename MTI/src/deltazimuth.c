#include "tdmrflib.h"


/* ###########################
  COMMENT

############################## */

extern void exit_prg() ;

extern void splitc() ;
extern int check_fileline() ;

struct INARGV inargv ;

void usage(){
  static char *mes[] = {
    " PROGRAM NAME   VAR   by Y.Ito", /*1*/
    0
  } ;
  static int no_ln = 1 ;
  int i ;
  for( i=0 ; i< no_ln ; i++)
    fprintf( stderr, "%s\n", mes[i] ) ;
}

int main( int argc, char *argv[] ){
  
  /***********************/
  FILE *fp ;
  int i,j,k ;
  char dmy[200], infname[200], *buffer ;
  /****** USER **********/
  int geograph ;
  float eepi[2],spos[2]  ;
  float delt,deltdg,deltkm,azes,azesdg,azse,azsedg ;
  /***********************/
  static char *param[]={
    "-h", /* 0:help */
    "-e", /* 1:eq epicenter */
    "-s", /* 2:station position */
    NULL, /* 3 */
  } ;
  static int no_param=3 ;
  /* DEFAULT */
  
  /* SET PARAMETER */
  for( i=1 ; i<argc ; i++ ){
    if( argv[i][0]!='-'){
      strcpy( infname, argv[i] ) ;
    }
    else{
      buffer=calloc( 100, sizeof(char)) ;
      for( j=0 ; j<no_param ; j++ ){
        if( strncmp( param[j],argv[i],2 )==0){
          k=0 ;
          while(argv[i][k+2]!='\0'){
            buffer[k]=argv[i][k+2] ;
            k++ ;
          }
          buffer[k]='\0' ;
          break ;
        }
      }
      
      switch( j ){
      case 0:
        usage() ; exit_prg( 0, "main()" ) ; exit(1) ;
	/*********** SWITCH OPTION *************/
      case 1:
	splitc( &inargv, buffer, '/') ;
	eepi[0]=atof( inargv.elemc[0]) ;
	eepi[1]=atof( inargv.elemc[1]) ;
	break ;
      case 2:
	splitc( &inargv,buffer,'/') ;
	spos[0]=atof( inargv.elemc[0]) ;
	spos[1]=atof( inargv.elemc[1])  ;
	break ;
	/****************************************/
      default:
        usage() ;
        exit_prg( 2, "main()[main .c]" ) ;
      }
      free(buffer) ;
    }
  }
  //fprintf( stderr, "%lf %lf\n",eepi[0],eepi[1] ) ;
  //fprintf( stderr, "%lf %lf\n",spos[0],spos[1] ) ;
  geograph=0 ;
  /****** MAIN PART *********/
  delaz5_(&eepi[1],&eepi[0],&spos[1],&spos[0],&delt,&deltdg,
	  &deltkm,&azes,&azesdg,&azse,&azsedg,&geograph);
  printf( "%f %f\n", deltkm, azesdg) ;
  
  /***** Free memory ********/
  
}


/*Distance Subroutine - Spherical Earth*/
int delaz5_(thei, alei, thsi, alsi, delt, deltdg, deltkm, 
            azes, azesdg, azse, azsedg, i)

float *thei, *alei, *thsi, *alsi, *delt, *deltdg, *deltkm, *azes;
float *azesdg, *azse, *azsedg;
int *i;
{
    double d__1, d__2, d__3;

    double tan(), atan(), sin(), cos(), acos(), atan2(), sqrt(), asin();

    /* Local variables */
    static double a, b, c, d, e, g, h;
    static float c1, c3, c4, c5, c6;
    static double ak, ap, bp, cp, dp, ep, gp, hp;
    static float aaa, ale;
    static double akp;
    static float als, the, ths;

    if (*i <= 0) {
	goto L50;
    } else {
	goto L51;
    }
/*     IF  COORDINATES ARE GEOGRAPH DEG I=0 */
/*     IF COORDINATES ARE GEOCENT RADIAN  I=1 */
L50:
    the = *thei * (float).01745329252;
    ale = *alei * (float).01745329252;
    ths = *thsi * (float).01745329252;
    als = *alsi * (float).01745329252;
    aaa = tan(the) * (float).9931177;
    the = atan(aaa);
    aaa = tan(ths) * (float).9931177;
    ths = atan(aaa);
    goto L32;
L51:
    the = *thei;
    ale = *alei;
    ths = *thsi;
    als = *alsi;
L32:
    c = sin(the);
    ak = -(double)cos(the);
    d = sin(ale);
    e = -(double)cos(ale);
    a = ak * e;
    b = -ak * d;
    g = -c * e;
    h = c * d;
    cp = sin(ths);
    akp = -(double)cos(ths);
    dp = sin(als);
    ep = -(double)cos(als);
    ap = akp * ep;
    bp = -akp * dp;
    gp = -cp * ep;
    hp = cp * dp;
    c1 = a * ap + b * bp + c * cp;
    if (c1 - (float).94 >= (float)0.) {
	goto L31;
    } else {
	goto L30;
    }
L30:
    if (c1 + (float).94 <= (float)0.) {
	goto L28;
    } else {
	goto L29;
    }
L29:
    *delt = acos(c1);
L33:
    *deltkm = *delt * (float)6371.;
/* Computing 2nd power */
    d__1 = ap - d;
/* Computing 2nd power */
    d__2 = bp - e;
/* Computing 2nd power */
    d__3 = cp;
    c3 = d__1 * d__1 + d__2 * d__2 + d__3 * d__3 - (float)2.;
/* Computing 2nd power */
    d__1 = ap - g;
/* Computing 2nd power */
    d__2 = bp - h;
/* Computing 2nd power */
    d__3 = cp - ak;
    c4 = d__1 * d__1 + d__2 * d__2 + d__3 * d__3 - (float)2.;
/* Computing 2nd power */
    d__1 = a - dp;
/* Computing 2nd power */
    d__2 = b - ep;
/* Computing 2nd power */
    d__3 = c;
    c5 = d__1 * d__1 + d__2 * d__2 + d__3 * d__3 - (float)2.;
/* Computing 2nd power */
    d__1 = a - gp;
/* Computing 2nd power */
    d__2 = b - hp;
/* Computing 2nd power */
    d__3 = c - akp;
    c6 = d__1 * d__1 + d__2 * d__2 + d__3 * d__3 - (float)2.;
    *deltdg = *delt * (float)57.29577951;
    *azes = atan2(c3, c4);
    if (*azes >= (float)0.) {
	goto L81;
    } else {
	goto L80;
    }
L80:
    *azes += (float)6.283185308;
L81:
    *azse = atan2(c5, c6);
    if (*azse >= (float)0.) {
	goto L71;
    } else {
	goto L70;
    }
L70:
    *azse += (float)6.283185308;
L71:
    *azesdg = *azes * (float)57.29577951;
    *azsedg = *azse * (float)57.29577951;
    return 0;
L31:
/* Computing 2nd power */
    d__1 = a - ap;
/* Computing 2nd power */
    d__2 = b - bp;
/* Computing 2nd power */
    d__3 = c - cp;
    c1 = d__1 * d__1 + d__2 * d__2 + d__3 * d__3;
    c1 = sqrt(c1);
    c1 /= (float)2.;
    *delt = asin(c1);
    *delt *= (float)2.;
    goto L33;
L28:
/* Computing 2nd power */
    d__1 = a + ap;
/* Computing 2nd power */
    d__2 = b + bp;
/* Computing 2nd power */
    d__3 = c + cp;
    c1 = d__1 * d__1 + d__2 * d__2 + d__3 * d__3;
    c1 = sqrt(c1);
    c1 /= (float)2.;
    *delt = acos(c1);
    *delt *= (float)2.;
    goto L33;
} /* delaz5_ */

