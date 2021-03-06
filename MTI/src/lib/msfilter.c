#include "tdmrflib.h"

/* 
   for description of parameters, see 
   # M. SAITO, 1978, An automatic design algorithm for band selective
   # recursive digital filters, Butsuri Tanko, 31, 112-135.

   # AR- FILTER
   # smeadl(db,n,&zero)  remove off set 
   # getar(db,nm,&sd,&m,c,&zero,0 )  get AR From first NM
   # digfil(db,db2,n,c,m,rec,&sd);   apply AR filter (db->db2) 
*/


smeadl(x,n,xmean)
  double *x,*xmean;
  int n;
{
  int i;
  double xm;
  xm=0.0;
  for(i=0;i<n;i++) xm+=x[i];
  xm/=(double)n;
  for(i=0;i<n;i++) x[i]-=xm;
  *xmean=xm;
}

getar(x,n,sd,m,c,z,lh)
     double *x;  /* input data */
     int n;    /* n of data */
     double *sd; /* standard deviation */
     int *m;   /* order of filter */
     double *c;  /* filter coefficients */
     double *z;  /* mean level */
     int lh;   /* maximum lag */
{
  double fpe,*cxx;
  int lagh;
  lagh=(int)(3.0*sqrt((double)n));
  if(lh>0 && lh<lagh) lagh=lh;
  cxx=(double *)malloc(sizeof(*cxx)*(lagh+1));
  autcor(x,n,lagh,cxx,z);
  fpeaut(lagh,n,lagh,cxx,&fpe,sd,m,c);
  if(*sd<0.0) *sd=0.0;
  free((char *)cxx);
  if(*m==lagh) return -1;
  return *m;
}


digfil(x,y,n,c,m,r,sd)
     double *x;  /* input data */
     double *y;  /* output data */
     int n;    /* n of data */
     double *c;  /* filter coefficients */
     int m;    /* order of filter */
     double *r;  /* last m data */
     double *sd; /* sd (mean-square of residuals) */
{
  int i,j,k;
  double t,s;
  for(i=0;i<n;i++){
    t=0.0;
    if((k=m-i)<0) k=0;
    for(j=0;j<k;j++) t+=c[m-j-1]*r[j+i];
    for(j=k;j<m;j++) t+=c[m-j-1]*x[j+i-m];
    s=((y[i]=t)-x[i]);
    *sd+=s*s;
  }
  for(i=0;i<m;i++) r[i]=x[n-m+i];
  *sd/=(double)n;
}

autcor(x,n,lagh,cxx,z)
     double *x;    /* original data */
     int n;      /* N of original data */
     int lagh;   /* largest lag */
     double *cxx;  /* (output) autocovariances (cxx[0] - cxx[lagh]) */
     double *z;    /* mean level */
{
  /* mean deletion */
  smeadl(x,n,z);
  /* auto covariance computation */
  crosco(x,x,n,cxx,lagh+1);
}


crosco(x,y,n,c,lagh1)
     double *x,*y;
     int n;
     double *c;
     int lagh1;
{
  int i,j,il;
  double t,bn;
  bn=1.0/(double)n;
  for(i=0;i<lagh1;i++){
    t=0.0;
    il=n-i;
    for(j=0;j<il;j++){
      t+=x[j+i]*y[j];
    }
    c[i]=t*bn;
  }
}


fpeaut(l,n,lagh,cxx,ofpe,osd,mo,ao)
     int l;      /* upper limit of model order */
     int n;      /* n of original data */
     int lagh;   /* highest lag */
     double *cxx;  /* autocovariances, cxx[0]-cxx[lagh] */
     double *ofpe; /* minimum FPE */
     double *osd;  /* SIGMA^2, variance of residual for minimum FPE */
     int *mo;    /* model order for minimum FPE */
     double *ao;   /* coefficients of AR process, ao[0]-ao[mo-1] */
{
  double sd,an,anp1,anm1,oofpe,se,d,orfpe,a[500],d2,fpe,rfpe,chi2,
    b[500];
  int np1,nm1,m,mp1,i,im,lm;
  sd=cxx[0];
  an=n;
  np1=n+1;
  nm1=n-1;
  anp1=np1;
  anm1=nm1;
  *mo=0;
  *osd=sd;
  if(sd==0.0) return; 
  *ofpe=(anp1/anm1)*sd;
  oofpe=1.0/(*ofpe);
  orfpe=1.0;
  se=cxx[1];
  for(m=1;m<=l;m++){
    mp1=m+1;
    d=se/sd;
    a[m-1]=d;
    d2=d*d;
    sd=(1.0-d2)*sd;
    anp1=np1+m;
    anm1=nm1-m;
    fpe=(anp1/anm1)*sd;
    rfpe=fpe*oofpe;
    chi2=d2*anm1;
    if(m>1){
      lm=m-1;
      for(i=0;i<lm;i++) a[i]=a[i]-d*b[i];
    }
    for(i=1;i<=m;i++){
      im=mp1-i;
      b[i-1]=a[im-1];
    }
    /*fprintf(stderr,"(%f %f %d) ",fpe,sd,m);*/
    if(*ofpe>=fpe){
      *ofpe=fpe;
      orfpe=rfpe;
      *osd=sd;
      *mo=m;
      for(i=0;i<m;i++) ao[i]=a[i];
    }
    if(m<l){
      se=cxx[mp1];
      for(i=0;i<m;i++) se=se-b[i]*cxx[i+1];
    }
  }
  /*fprintf(stderr,"\n");*/
}

/*
+   RECURSIVE FILTERING IN SERIES
+
+   ARGUMENTS
+   X : INPUT TIME SERIES
+   Y : OUTPUT TIME SERIES  (MAY BE EQUIVALENT TO X)
+   N : LENGTH OF X & Y
+   H : COEFFICIENTS OF FILTER
+   M : ORDER OF FILTER
+   NML : >0 ; FOR NORMAL  DIRECTION FILTERING
+       <0 ;   REVERSE DIRECTION FILTERING
+   uv  : past data and results saved
+
+   SUBROUTINE REQUIRED : RECFIL
+
+   M. SAITO  (6/XII/75)
*/      
/* 
   tandem(dbuf,dbuf,sr,tbl[ch].f.coef,tbl[ch].f.m_filt,1,tbl[ch].uv);
   for(j=0;j<sr;j++) dbuf[j]*=tbl[ch].f.gn_filt;
*/
tandem(x,y,n,h,m,nml,uv)
     double *x,*y,*h,*uv;
     int n,m,nml;
{
  int i;
  if(n<=0 || m<=0){
    fprintf(stderr,"? (tandem) invalid input : n=%d m=%d ?\n",n,m);
    return 1;
  }
  /****  1-ST CALL */
  recfil(x,y,n,h,nml,uv);
  /****  2-ND AND AFTER */
  if(m>1) for(i=1;i<m;i++) recfil(y,y,n,&h[i*4],nml,&uv[i*4]);
  return 0;
}

/*
+   RECURSIVE FILTERING : F(Z) = (1+A*Z+AA*Z**2)/(1+B*Z+BB*Z**2)
+
+   ARGUMENTS
+   X : INPUT TIME SERIES
+   Y : OUTPUT TIME SERIES  (MAY BE EQUIVALENT TO X)
+   N : LENGTH OF X & Y
+   H : FILTER COEFFICIENTS ; H(1)=A, H(2)=AA, H(3)=B, H(4)=BB
+   NML : >0 ; FOR NORMAL  DIRECTION FILTERING
+       <0 ; FOR REVERSE DIRECTION FILTERING
+   uv  : past data and results saved
+
+   M. SAITO  (6/XII/75)
*/
recfil(x,y,n,h,nml,uv)
     int n,nml;
     double *x,*y,*h,*uv;
{
  int i,j,jd;
  double a,aa,b,bb,u1,u2,u3,v1,v2,v3;
  if(n<=0){
    fprintf(stderr,"? (recfil) invalid input : n=%d ?\n",n);
    return 1;
  }
  if(nml>=0){
    j=0;
    jd=1;
  }
  else{
    j=n-1;
    jd=(-1);
  }
  a =h[0];
  aa=h[1];
  b =h[2];
  bb=h[3];
  u1=uv[0];
  u2=uv[1];
  v1=uv[2];
  v2=uv[3];
  /****  FILTERING */
  for(i=0;i<n;i++){
    u3=u2;
    u2=u1;
    u1=x[j];
    v3=v2;
    v2=v1;
    v1=u1+a*u2+aa*u3-b*v2-bb*v3;
    y[j]=v1;
    j+=jd;
  }
  uv[0]=u1;
  uv[1]=u2;
  uv[2]=v1;
  uv[3]=v2;
  return 0;
}

/*
+   BUTTERWORTH LOW PASS FILTER COEFFICIENT
+
+   ARGUMENTS
+   H : FILTER COEFFICIENTS
+   M : ORDER OF FILTER  (M=(N+1)/2)
+   GN  : GAIN FACTOR
+   N : ORDER OF BUTTERWORTH FUNCTION
+   FP  : PASS BAND FREQUENCY  (NON-DIMENSIONAL)
+   FS  : STOP BAND FREQUENCY
+   AP  : MAX. ATTENUATION IN PASS BAND
+   AS  : MIN. ATTENUATION IN STOP BAND
+
+   M. SAITO  (17/XII/75)
*/
butlop(h,m,gn,n,fp,fs,ap,as)
     double *h,fp,fs,ap,as,*gn;
     int *m,*n;
{
  double wp,ws,tp,ts,pa,sa,cc,c,dp,g,fj,c2,sj,tj,a;
  int k,j;
  if(fabs(fp)<fabs(fs)) wp=fabs(fp)*PI;
  else wp=fabs(fs)*PI;
  if(fabs(fp)>fabs(fs)) ws=fabs(fp)*PI;
  else ws=fabs(fs)*PI;
  if(wp==0.0 || wp==ws || ws>=HP){
    fprintf(stderr,"? (butlop) invalid input : fp=%14.6e fs=%14.6e ?\n",fp,fs);
    return 1;
  }
  /****  DETERMINE N & C */
  tp=tan(wp);
  ts=tan(ws);
  if(fabs(ap)<fabs(as)) pa=fabs(ap);
  else pa=fabs(as);
  if(fabs(ap)>fabs(as)) sa=fabs(ap);
  else sa=fabs(as);
  if(pa==0.0) pa=0.5;
  if(sa==0.0) sa=5.0;
  if((*n=(int)(fabs(log(pa/sa)/log(tp/ts))+0.5))<2) *n=2;
  cc=exp(log(pa*sa)/(double)(*n))/(tp*ts);
  c=sqrt(cc);
  
  dp=HP/(double)(*n);
  *m=(*n)/2;
  k=(*m)*4;
  g=fj=1.0;
  c2=2.0*(1.0-c)*(1.0+c);
  
  for(j=0;j<k;j+=4){
    sj=pow(cos(dp*fj),2.0);
    tj=sin(dp*fj);
    fj=fj+2.0;
    a=1.0/(pow(c+tj,2.0)+sj);
    g=g*a;
    h[j  ]=2.0;
    h[j+1]=1.0;
    h[j+2]=c2*a;
    h[j+3]=(pow(c-tj,2.0)+sj)*a;
  }
  /****  EXIT */
  *gn=g;
  if(*n%2==0) return 0;
  /****  FOR ODD N */
  *m=(*m)+1;
  *gn=g/(1.0+c);
  h[k  ]=1.0;
  h[k+1]=0.0;
  h[k+2]=(1.0-c)/(1.0+c);
  h[k+3]=0.0;
  return 0;
}
/*
+   BUTTERWORTH HIGH PASS FILTER COEFFICIENT
+
+   ARGUMENTS
+   H : FILTER COEFFICIENTS
+   M : ORDER OF FILTER  (M=(N+1)/2)
+   GN  : GAIN FACTOR
+   N : ORDER OF BUTTERWORTH FUNCTION
+   FP  : PASS BAND FREQUENCY  (NON-DIMENSIONAL)
+   FS  : STOP BAND FREQUENCY
+   AP  : MAX. ATTENUATION IN PASS BAND
+   AS  : MIN. ATTENUATION IN STOP BAND
+
+   M. SAITO  (7/I/76)
*/
buthip(h,m,gn,n,fp,fs,ap,as)
     double *h,fp,fs,ap,as,*gn;
     int *m,*n;
{
  double wp,ws,tp,ts,pa,sa,cc,c,dp,g,fj,c2,sj,tj,a;
  int k,j;
  if(fabs(fp)>fabs(fs)) wp=fabs(fp)*PI;
  else wp=fabs(fs)*PI;
  if(fabs(fp)<fabs(fs)) ws=fabs(fp)*PI;
  else ws=fabs(fs)*PI;
  if(wp==0.0 || wp==ws || wp>=HP){
    fprintf(stderr,"? (buthip) invalid input : fp=%14.6e fs=%14.6e ?\n",fp,fs);
    return 1;
  }
  /****  DETERMINE N & C */
  tp=tan(wp);
  ts=tan(ws);
  if(fabs(ap)<fabs(as)) pa=fabs(ap);
  else pa=fabs(as);
  if(fabs(ap)>fabs(as)) sa=fabs(ap);
  else sa=fabs(as);
  if(pa==0.0) pa=0.5;
  if(sa==0.0) sa=5.0;
  if((*n=(int)(fabs(log(sa/pa)/log(tp/ts))+0.5))<2) *n=2;
  cc=exp(log(pa*sa)/(double)(*n))*(tp*ts);
  c=sqrt(cc);
  
  dp=HP/(double)(*n);
  *m=(*n)/2;
  k=(*m)*4;
  g=fj=1.0;
  c2=(-2.0)*(1.0-c)*(1.0+c);
  
  for(j=0;j<k;j+=4){
    sj=pow(cos(dp*fj),2.0);
    tj=sin(dp*fj);
    fj=fj+2.0;
    a=1.0/(pow(c+tj,2.0)+sj);
    g=g*a;
    h[j  ]=(-2.0);
    h[j+1]=1.0;
    h[j+2]=c2*a;
    h[j+3]=(pow(c-tj,2.0)+sj)*a;
  }
  /****  EXIT */
  *gn=g;
  if(*n%2==0) return 0;
  /****  FOR ODD N */
  *m=(*m)+1;
  *gn=g/(c+1.0);
  h[k  ]=(-1.0);
  h[k+1]=0.0;
  h[k+2]=(c-1.0)/(c+1.0);
  h[k+3]=0.0;
  return 0;
}

/*
+   BUTTERWORTH BAND PASS FILTER COEFFICIENT
+
+   ARGUMENTS
+   H : FILTER COEFFICIENTS
+   M : ORDER OF FILTER
+   GN  : GAIN FACTOR
+   N : ORDER OF BUTTERWORTH FUNCTION
+   FL  : LOW  FREQUENCY CUT-OFF  (NON-DIMENSIONAL)
+   FH  : HIGH FREQUENCY CUT-OFF
+   FS  : STOP BAND FREQUENCY
+   AP  : MAX. ATTENUATION IN PASS BAND
+   AS  : MIN. ATTENUATION IN STOP BAND
+
+   M. SAITO  (7/I/76)
*/
butpas(h,m,gn,n,fl,fh,fs,ap,as)
     double *h,fl,fh,fs,ap,as,*gn;
     int *m,*n;
{
  double wl,wh,ws,clh,op,ww,ts,os,pa,sa,cc,c,dp,g,fj,rr,tt,
    re,ri,a,wpc,wmc;
  int k,l,j,i;
  struct {
    double r;
    double c;
  } oj,aa,cq,r[2];
  if(fabs(fl)<fabs(fh)) wl=fabs(fl)*PI;
  else wl=fabs(fh)*PI;
  if(fabs(fl)>fabs(fh)) wh=fabs(fl)*PI;
  else wh=fabs(fh)*PI;
  ws=fabs(fs)*PI;
  if(wl==0.0 || wl==wh || wh>=HP || ws==0.0 || ws>=HP ||
     (ws-wl)*(ws-wh)<=0.0){
    fprintf(stderr,
	    "? (butpas) invalid input : fl=%14.6e fh=%14.6e fs=%14.6e ?\n",
	    fl,fh,fs);
    *m=0;
    *gn=1.0;
    return 1;
  }
  /****  DETERMINE N & C */
  clh=1.0/(cos(wl)*cos(wh));
  op=sin(wh-wl)*clh;
  ww=tan(wl)*tan(wh);
  ts=tan(ws);
  os=fabs(ts-ww/ts);
  if(fabs(ap)<fabs(as)) pa=fabs(ap);
  else pa=fabs(as);
  if(fabs(ap)>fabs(as)) sa=fabs(ap);
  else sa=fabs(as);
  if(pa==0.0) pa=0.5;
  if(sa==0.0) sa=5.0;
  if((*n=(int)(fabs(log(pa/sa)/log(op/os))+0.5))<2) *n=2;
  cc=exp(log(pa*sa)/(double)(*n))/(op*os);
  c=sqrt(cc);
  ww=ww*cc;
  
  dp=HP/(double)(*n);
  k=(*n)/2;
  *m=k*2;
  l=0;
  g=fj=1.0;
  
  for(j=0;j<k;j++){
    oj.r=cos(dp*fj)*0.5;
    oj.c=sin(dp*fj)*0.5;
    fj=fj+2.0;
    aa.r=oj.r*oj.r-oj.c*oj.c+ww;
    aa.c=2.0*oj.r*oj.c;
    rr=sqrt(aa.r*aa.r+aa.c*aa.c);
    tt=atan(aa.c/aa.r);
    cq.r=sqrt(rr)*cos(tt/2.0);
    cq.c=sqrt(rr)*sin(tt/2.0);
    r[0].r=oj.r+cq.r;
    r[0].c=oj.c+cq.c;
    r[1].r=oj.r-cq.r;
    r[1].c=oj.c-cq.c;
    g=g*cc;
    
    for(i=0;i<2;i++){
      re=r[i].r*r[i].r;
      ri=r[i].c;
      a=1.0/((c+ri)*(c+ri)+re);
      g=g*a;
      h[l  ]=0.0;
      h[l+1]=(-1.0);
      h[l+2]=2.0*((ri-c)*(ri+c)+re)*a;
      h[l+3]=((ri-c)*(ri-c)+re)*a;
      l=l+4;
    }
  }
  /****  EXIT */
  *gn=g;
  if(*n==(*m)) return 0;
  /****  FOR ODD N */
  *m=(*m)+1;
  wpc=  cc *cos(wh-wl)*clh;
  wmc=(-cc)*cos(wh+wl)*clh;
  a=1.0/(wpc+c);
  *gn=g*c*a;
  h[l  ]=0.0;
  h[l+1]=(-1.0);
  h[l+2]=2.0*wmc*a;
  h[l+3]=(wpc-c)*a;
  return 0;
}



