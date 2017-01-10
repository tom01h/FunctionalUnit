#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define LOOP 23

typedef union {
  double f;
  struct{
    int l;
    int u;
  };
} dr;
typedef union {
  float f;
  int i;
} fr;

int main(int argc, char *args[])
{
  dr xf, yf, tf;
  fr rr;
  int xi, yi, ri, ai, xe, ye;
  int xn, yn;
  int i;
  xf.f = atof(args[1]);
  yf.f = atof(args[2]);
  printf("x = %08x %08x, y = %08x %08x\n",xf.u,xf.l,yf.u,yf.l);
  xe = (xf.u >> 20)&0x7ff;
  ye = (yf.u >> 20)&0x7ff;
  xi=(xf.u&0x000fffff|0x00100000)<<9;
  yi=(yf.u&0x000fffff|0x00100000)<<9;
  xi=xi|((unsigned)xf.l>>(32-9));
  yi=yi|((unsigned)yf.l>>(32-9));

  if(xe>ye){
    xi=xi;
    if((xe-ye)>=32){
      yi=0;
    }else{
      yi=yi >> (xe-ye);
    }
    tf.u = (xe<<20);
    tf.l = 0;
  } else {
    if((ye-xe)>=32){
      xi=0;
    }else{
      xi=xi >> (ye-xe);
    }
    yi=yi;
    tf.u = (ye<<20);
    tf.l = 0;
  }

  if(xf.u&0x80000000){xi = -xi;}
  if(yf.u&0x80000000){yi = -yi;}

  printf("xi = %08x, yi = %08x, tf = %08x %08x\n\n",xi,yi,tf.u,tf.l);

  ri = 0;
  printf("        x = %f, y = %f, r=%f\n",xi*tf.f/(1<<29),yi*tf.f/(1<<29),(double)ri/(1<<30)*180/M_PI);
  for(i=0;i<=LOOP;i++){
    ai = atan((double)1/(1<<i)) * (1<<30); //TABLE[0:LOOP]
    if(yi>=0){
      xn = xi+(yi>>i);
      yn = yi-(xi>>i);
      ri = ri+ai;
    } else {
      xn = xi-(yi>>i);
      yn = yi+(xi>>i);
      ri = ri-ai;
    }
    xi=xn;
    yi=yn;
    printf("i = %2d, x = %f, y = %f, r=%f\n",i,xi*tf.f/(1<<29),yi*tf.f/(1<<29),(double)ri/(1<<30)*180/M_PI);
  }


  double x,y,r;
  r=1;
  for(i=0;i<=LOOP;i++){
    x=r;y=r/(1<<i);
    r=sqrt(x*x+y*y);
  }//r FIX VAL
  printf("sqrt(x^2+y^2) = %f\n",xi*tf.f/(1<<29)/r);
  rr.f=1/r;
  printf("r = %x\n",rr.i);

  return 0;
}
