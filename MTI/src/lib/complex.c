#include "tdmrflib.h" 


fft( double *x2, double *y2, int n, double f )
{
  double *s=NULL, *c=NULL ;
  double sc, th, ss, ct, st, tx, ty ;
  int  l, n1, n2, n4, i, mx, isc, is, ix1, ix, lm, j, j1, j2 ;
  
  l = inv2pow( n ) ;
  n = ipow2( l ) ;
  
  n4 = n/4 ;
  n2 = n/2 ;
  
  s = calloc( n2+1, sizeof( double ) ) ;
  c = calloc( n2+1, sizeof( double ) ) ;
  if( s==NULL||c==NULL )
    {	perror( "memory allocation error in fft():" ) ;
    exit( 2 ) ;
    }
  th = 0.0 ;
  sc = 2.0*3.141592654/n ;
  for( i=0 ; i<=n4 ; i++ )
    {	ss = s[n2-i] = s[i] = sin( th ) ; 
    c[n4-i] = ss ;
    c[n4+i] = -ss ;
    th += sc ;
    }
  
  mx = n ;
  isc = 1 ;
  for( i=0 ; i<l ; i++ )
    {	ix1 = mx ;
    ix = mx - 1 ;
    mx /= 2 ;
    is = 0 ;
    for( lm=0 ; lm<mx ; lm++ )
      {	ct = c[is] ;
      st = f*s[is] ;
      
      for( j=ix ; j<n ; j+=ix1 )
	{	j1 = j-ix+lm ;
	j2 = j1 + mx ;
	tx = x2[j1] - x2[j2] ;
	ty = y2[j1] - y2[j2] ;
	x2[j1] = x2[j1] + x2[j2] ;
	y2[j1] = y2[j1] + y2[j2] ;
	x2[j2] = ct*tx + st*ty ;
	y2[j2] = ct*ty - st*tx ;
	}
      is += isc ;
      }
    isc *= 2 ;
    }

  j = 0 ;
  for( i=0 ; i<n-1 ; i++ )
    {	if( i<=j )
      {	tx = x2[i] ; x2[i] = x2[j] ; x2[j] = tx ;
      tx = y2[i] ; y2[i] = y2[j] ; y2[j] = tx ;
      }
    n2 = n/2 ;
    while( n2<=j )
      {	j -= n2 ;
      n2 /= 2 ;
      }
    j += n2 ;
    }
  
  free( c ) ;
  free( s ) ;
}

int inv2pow( int  n )
{	
  int  l ;
  
  l = -1 ;
  while( n!=0 )
    {	n /=2 ;
    l++ ;
    }
  
  return( l ) ;
}

int ipow2( int l )
{
  int n ;

  n = 1 ;
  while( l!=0 )
    {	n *=2 ;
    l-- ;
    }
  
  return( n ) ;
}


fourier( double *wave, int np, int nt, double dt,double df, 
	 double *real, double *image, double n )
{
  int i,j ;
  
  if( n < 0.0 ){
    for(i=0 ; i<np ; i++){
      real[i]=wave[i] ;
      image[i]=0.0 ;
    }
    for(i=np; i<nt ; i++){
      real[i]=0.0 ;
      image[i]=0.0 ;
    }
  }
  
  fft( real, image, nt, n ); 
  
  if( n < 0.0 ){
    for( i=0 ; i<nt ; i++ ){	
      real[i]  *= dt ;
      image[i] *= dt ;
    }
  }
  else 
    for( i=0 ; i<np; i++ )	
      wave[i]=real[i]*df ;
}

cmplx( double re, double im, double *nre, double *nim )
{
  double r,ang ;
  r=sqrt( re*re+im*im ) ;
  if( re >= 0.0 )
    ang=atan( im/re ) ;
  else if( re < 0.0 ){
    if( im>=0.0  )
      ang=atan( im/re )+3.1415921356 ;
    else
      ang=atan( im/re )-3.1415921356 ;
  }
  *nre= r*cos( ang ) ;
  *nim= r*sin( ang ) ;
  
}     

int cfilter( double *wave,  int ndt, double dt, 
	     double f1, double f2, int np)
{
  int nn, i,j ;
  double df,f, *real, *image, zc1, zc2,zc ;
  
  fprintf( stderr, "%d %lf %lf %lf %d\n",ndt,dt,f1,f2,np) ; 
  
  nn=(int)floor(log((double)ndt)/log(2.0))+1 ;
  nn=(int)pow(2,(double)nn) ;
  
  if( nn < ndt ) 
    nn=nn*2 ;
  df=1.0/dt/(double)nn ;
  real=calloc( nn, sizeof( double )) ;
  image=calloc( nn, sizeof( double )) ;
  
  for(i=0 ; i<ndt ; i++){
    real[i]=wave[i] ;
    image[i]=0.0 ;
  }
  for(i=ndt; i<nn ; i++){
    real[i]=0.0 ;
    image[i]=0.0 ;
  }
  
  fft( real, image, nn, -1.0 ); 
  
  for( i=0 ; i<nn ; i++ ){	
    real[i]  *= dt ;
    image[i] *= dt ;
  }
  
  
  for( i=0 ; i<nn/2-1; i++){
    f=df*((double)i+1.0) ;
    zc1=zc2=1 ;
    if( f1 !=0.0 )
      zc1=1.0-1.0/pow( 1.0+(f/f1),(double)np) ;
    if( f2 !=0.0 )
      zc2=1.0/pow(1.0+(f/f2),(double)np) ;
    zc=zc1*zc2 ; 
    real[i+1]*=zc ;
    image[i+1]*=zc ;
    real[nn-1-i]=real[i+1] ;
    image[nn-1-i]=-image[i+1] ;
  }
  
  real[0]=0.0 ;
  image[0]=0.0 ;
  real[nn/2]=0.0 ;
  image[nn/2]=0.0 ;
  
  fft( real, image, nn, 1.0 ); 
  
  
  for( i=0 ; i<ndt; i++ )	
    wave[i]=real[i]*df ;
  
 
  free( real ) ;   
  free( image) ;
  
  return(0) ;
}

int cfilter2( double *wave,  int ndt, double dt, 
	      double f1, double f2, int np1, int np2 )
{
  int nn, i,j ;
  double df,f, *real, *image, zc1, zc2,zc ;
  
  nn=(int)floor(log((double)ndt)/log(2.0))+1 ;
  nn=(int)pow(2,(double)nn) ;
  
  if( nn < ndt ) 
    nn=nn*2 ;
  df=1.0/dt/(double)nn ;
  real=calloc( nn, sizeof( double )) ;
  image=calloc( nn, sizeof( double )) ;
  
  for(i=0 ; i<ndt ; i++){
    real[i]=wave[i] ;
    image[i]=0.0 ;
  }
  for(i=ndt; i<nn ; i++){
    real[i]=0.0 ;
    image[i]=0.0 ;
  }
  
  fft( real, image, nn, -1.0 ); 
  
  for( i=0 ; i<nn ; i++ ){	
    real[i]  *= dt ;
    image[i] *= dt ;
  }
  
  
  for( i=0 ; i<nn/2-1; i++){
    f=df*((double)i+1.0) ;
    zc1=zc2=1 ;
    if( f1 !=0.0 )
      zc1=1.0-1.0/pow( 1.0+(f/f1),(double)np1) ;
    if( f2 !=0.0 )
      zc2=1.0/pow(1.0+(f/f2),(double)np2) ;
    zc=zc1*zc2 ; 
    real[i+1]*=zc ;
    image[i+1]*=zc ;
    real[nn-1-i]=real[i+1] ;
    image[nn-1-i]=-image[i+1] ;
  }
  
  real[0]=0.0 ;
  image[0]=0.0 ;
  real[nn/2]=0.0 ;
  image[nn/2]=0.0 ;
  
  fft( real, image, nn, 1.0 ); 
  
  
  for( i=0 ; i<ndt; i++ )	
    wave[i]=real[i]*df ;
  
  
  free( real ) ;
  free( image) ;
  
  return(0) ;
}
