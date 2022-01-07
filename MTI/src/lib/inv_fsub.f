      
      subroutine dcp(m1,m2,m3,m4,m5,m6,f1,d1,a1,sm,dsm,evl1,evl2,evl3)
      
*     << to interpret a moment-tensor in terms of a double-couple. >>
*     output
*     moment      sm +- dsm
*     fault mechanism (f1,t1,a1)
*     tension axis   ax()
*     input
*     vector v(6)
*     mij(*) = moment tensor   (x:north, y:east, z:downward vertical)
*     eg(i)  = eigen values of moment-tensor (to be modified later)
*     ev(*,i)= eigen vector for i-th eigen-value
      
      real v(6),ax(3),eg1(3),eg2(3),ev(3,3),wk1(3),mij(3,3)
      real f1,d1,a1,sm,dsm,m1,m2,m3,m4,m5,m6,e1,e2
      
      pi=3.1415926
      rad=pi/180
      root2=1.41421356
      v(1)=m1
      v(2)=m2
      v(3)=m3
      v(4)=m4
      v(5)=m5
      v(6)=m6
      call mtrx(v,mij)
*******************************************************
      call eig1(mij,3,3,2,eg1,eg2,ev,wk1,icon)
      if(icon.ne.0) print *,'  seig1.cond= ',icon
*******************************************************
      evl1=eg1(1)
      evl2=eg1(2)
      evl3=eg1(3)
      
      e1=eg1(1)
      e3=eg1(1)
      i1=1
      i3=1
      do 2 ii=2,3
         if(e1.ge.eg1(ii)) goto 1
         e1=eg1(ii)
         i1=ii
 1       if(e3.lt.eg1(ii)) goto 2
         e3=eg1(ii)
         i3=ii
    2 continue
      sm=(e1-e3)/2
      dsm=sm-e1
      do 3 ii=1,3
*     ax(ii)=ev(ii,i1)
         eg1(ii)=(ev(ii,i3)-ev(ii,i1))/root2
 3       eg2(ii)=(ev(ii,i1)+ev(ii,i3))/root2
         
*     eg2 = normal vector for a fault plane
*     eg1 = slip vector
         
         d1=acos(eg2(3))
         f1=atan2(eg2(2),eg2(1))+pi/2
         cf=cos(f1)
         sf=sin(f1)
         c=eg1(1)*cf+eg1(2)*sf
         if(d1.ne.0.) s=eg1(3)/sin(d1)
         if(d1.eq.0.) s=eg1(1)*sf-eg1(2)*cf
         f1=f1/rad
         d1=d1/rad
         a1=-atan2(s,c)/rad
         if(d1.lt.90.) return
         a1=-a1
         d1=180-d1
         f1=f1+180
         if(f1.gt.360) f1=f1-360
         end
      
      subroutine mtrx(v,m)
      
*     < basis tensor:v(n) to moment-tensor:m(i,j)
      real v(6),m(3,3)
      
      m(1,1)=v(2)-v(5)+v(6)
      m(1,2)=v(1)
      m(2,1)=m(1,2)
      m(1,3)=v(4)
      m(3,1)=m(1,3)
      m(2,2)=-v(2)+v(6)
      m(2,3)=v(3)
      m(3,2)=m(2,3)
      m(3,3)=v(5)+v(6)
      end
      
      subroutine eig1(a,k,n,mode,e,dum,u,wk,icon)
      
      real a(k,n),u(k,n),e(n),dum(n),wk(n)
      
      call jacobi(a,n,k,e,u,m)
      call eigsrt(e,u,n,k)
      icon=0
      end
      
      
      subroutine jacobi(a,n,np,d,v,nrot)
      
      parameter (nmax=100)                                              
      dimension a(np,np),d(np),v(np,np),b(nmax),z(nmax)
      
      do 12 ip=1,n                                                      
         do 11 iq=1,n                                                    
            v(ip,iq)=0.                                                   
 11      continue                                                        
         v(ip,ip)=1.                                                     
 12   continue                                                          
      do 13 ip=1,n                                                      
         b(ip)=a(ip,ip)                                                  
         d(ip)=b(ip)                                                     
         z(ip)=0.                                                        
 13   continue                                                          
      nrot=0                                                            
      do 24 i=1,50                                                      
         sm=0.                                                           
         do 15 ip=1,n-1                                                  
            do 14 iq=ip+1,n                                               
               sm=sm+abs(a(ip,iq))                                         
 14         continue                                                      
 15      continue                                                        
         if(sm.eq.0.)return                                              
         if(i.lt.4)then                                                  
            tresh=0.2*sm/n**2                                             
         else                                                            
            tresh=0.                                                      
         endif                                                           
         do 22 ip=1,n-1                                                  
            do 21 iq=ip+1,n                                               
               g=100.*abs(a(ip,iq))                                        
               if((i.gt.4).and.(abs(d(ip))+g.eq.abs(d(ip)))                
     *              .and.(abs(d(iq))+g.eq.abs(d(iq))))then                   
                  a(ip,iq)=0.                                               
               else if(abs(a(ip,iq)).gt.tresh)then                         
                  h=d(iq)-d(ip)                                             
                  if(abs(h)+g.eq.abs(h))then                                
                     t=a(ip,iq)/h                                            
                  else                                                      
                     theta=0.5*h/a(ip,iq)                                    
                     t=1./(abs(theta)+sqrt(1.+theta**2))                     
                     if(theta.lt.0.)t=-t                                     
                  endif                                                     
                  c=1./sqrt(1+t**2)                                         
                  s=t*c                                                     
                  tau=s/(1.+c)                                              
                  h=t*a(ip,iq)                                              
                  z(ip)=z(ip)-h                                             
                  z(iq)=z(iq)+h                                             
                  d(ip)=d(ip)-h                                             
                  d(iq)=d(iq)+h                                             
                  a(ip,iq)=0.                                               
                  do 16 j=1,ip-1                                            
                     g=a(j,ip)                                               
                     h=a(j,iq)                                               
                     a(j,ip)=g-s*(h+g*tau)                                   
                     a(j,iq)=h+s*(g-h*tau)                                   
 16               continue                                                  
                  do 17 j=ip+1,iq-1                                         
                     g=a(ip,j)                                               
                     h=a(j,iq)                                               
                     a(ip,j)=g-s*(h+g*tau)                                   
                     a(j,iq)=h+s*(g-h*tau)                                   
 17               continue                                                  
                  do 18 j=iq+1,n                                            
                     g=a(ip,j)                                               
                     h=a(iq,j)                                               
                     a(ip,j)=g-s*(h+g*tau)                                   
                     a(iq,j)=h+s*(g-h*tau)                                   
 18               continue                                                  
                  do 19 j=1,n                                               
                     g=v(j,ip)                                               
                     h=v(j,iq)                                               
                     v(j,ip)=g-s*(h+g*tau)                                   
                     v(j,iq)=h+s*(g-h*tau)                                   
 19               continue                                                  
                  nrot=nrot+1                                               
               endif                                                       
 21         continue                                                      
 22      continue                                                        
         do 23 ip=1,n                                                    
            b(ip)=b(ip)+z(ip)                                             
            d(ip)=b(ip)                                                   
            z(ip)=0.                                                      
 23      continue                                                        
 24   continue                                                          
      pause '50 iterations should never happen'                         
      return                                                            
      end 
      
      subroutine eigsrt(d,v,n,np)
      
      dimension d(np),v(np,np) 
      
      do 13 i=1,n-1                                                     
         k=i                                                             
         p=d(i)                                                          
         do 11 j=i+1,n                                                   
            if(d(j).ge.p)then                                             
               k=j                                                         
               p=d(j)                                                      
            endif                                                         
 11      continue                                                        
         if(k.ne.i)then                                                  
            d(k)=d(i)                                                     
            d(i)=p                                                        
            do 12 j=1,n                                                   
               p=v(j,i)                                                    
               v(j,i)=v(j,k)                                               
               v(j,k)=p                                                    
 12         continue                                                      
         endif                                                           
 13   continue                                                          
      return                                                            
      end
      
      
      subroutine dcp2(m1,m2,m3,m4,m5,m6,f1,d1,a1,sm,dsm )
      
*     << to interpret a moment-tensor in terms of a double-couple. >>
*     output
*     moment      sm +- dsm
*     fault mechanism (f1,t1,a1)
*     tension axis   ax()
*     input
*     vector v(6)
*     mij(*) = moment tensor   (x:north, y:east, z:downward vertical)
*     eg(i)  = eigen values of moment-tensor (to be modified later)
*     ev(*,i)= eigen vector for i-th eigen-value
      
      real v(6),ax(3),eg1(3),eg2(3),ev(3,3),wk1(3),mij(3,3)
      real m1,m2,m3,m4,m5,m6,f1,d1,a1,sm,dsm
      pi=3.1415926
      rad=pi/180
      root2=1.41421356
      v(1)=m1
      v(2)=m2
      v(3)=m3
      v(4)=m4
      v(5)=m5
      v(6)=m6
      
      call mtrx(v,mij)
*******************************************************
      call eig1(mij,3,3,2,eg1,eg2,ev,wk1,icon)
      if(icon.ne.0) print *,'  seig1.cond= ',icon
*******************************************************
      e1=eg1(1)
      e3=eg1(1)
      i1=1
      i3=1
      do 2 ii=2,3
         if(e1.ge.eg1(ii)) goto 1
         e1=eg1(ii)
         i1=ii
 1       if(e3.lt.eg1(ii)) goto 2
         e3=eg1(ii)
         i3=ii
    2 continue
      sm=(e1-e3)/2
      dsm=sm-e1
      do 3 ii=1,3
*     ax(ii)=ev(ii,i1)
         eg2(ii)=(ev(ii,i3)-ev(ii,i1))/root2
 3       eg1(ii)=(ev(ii,i1)+ev(ii,i3))/root2
         
*     eg2 = normal vector for a fault plane
*     eg1 = slip vector
         
         d1=acos(eg2(3))
         f1=atan2(eg2(2),eg2(1))+pi/2
         cf=cos(f1)
         sf=sin(f1)
         c=eg1(1)*cf+eg1(2)*sf
         if(d1.ne.0.) s=eg1(3)/sin(d1)
         if(d1.eq.0.) s=eg1(1)*sf-eg1(2)*cf
         f1=f1/rad
         d1=d1/rad
         a1=-atan2(s,c)/rad
         if(d1.lt.90.) return
         a1=-a1
         d1=180-d1
         f1=f1+180
         if(f1.gt.360) f1=f1-360
         end
      
      
