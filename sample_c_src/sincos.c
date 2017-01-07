#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define LOOP 23

int main(int argc, char *args[])
{
  double d;
  int xi, yi;
  int xn, yn;
  int ri, ai;
  int i;
  d = atof(args[1]);
  printf("deg = %f\n",d);
  ri = d * M_PI / 180.0 * (1<<30); // input val
  printf("rad = %f(0x%08x)\n",(double)ri/(1<<30),ri);

  double x,y,r;
  r=1;
  for(i=0;i<=LOOP;i++){
    x=r;y=r/(1<<i);
    r=sqrt(x*x+y*y);
  }

  xi=1/r*(1<<30);  // FIX VAL
  yi=1/r*(1<<30);  // FIX VAL
  printf("initial                   = 0x%x\n",xi);

  ai = atan(1) * (1<<30); //TABLE[0]
  ri = ri - ai;

  printf("i = %2d, a = 0x%08x, x = %f, y = %f\n",0,ai,(double)xi/(1<<30),(double)yi/(1<<30));
  //  printf("i = %2d, a = 0x%08x, x = 0x%08x, y = 0x%08x\n",0,ai,xi,yi);

  for(i=1;i<=LOOP;i++){
    ai = atan((double)1/(1<<i)) * (1<<30); //TABLE[1:LOOP]
    if(ri<0){
      xn=xi+(yi>>i);
      yn=yi-(xi>>i);
      ri=ri+ai;
    }else{
      xn=xi-(yi>>i);
      yn=yi+(xi>>i);
      ri=ri-ai;
    }
    xi=xn;
    yi=yn;
    printf("i = %2d, a = 0x%08x, x = %f, y = %f\n",i,ai,(double)xi/(1<<30),(double)yi/(1<<30));
    //    printf("i = %2d, a = 0x%08x, x = 0x%08x, y = 0x%08x\n",0,ai,xi,yi);
  }
  return 0;
}
