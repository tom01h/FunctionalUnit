#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *args[])
{
  int xh, xl, y;
  int tmp1, tmp2, tmp3;
  int q, i;
  int plus, sign;

  xl = atoi(args[1]);
  y  = atoi(args[2]);
  sign = 0;
  plus = 0;
  xh = 0;
  q=0;
  xh=xh<<2;
  xh=xh+(((unsigned)xl)>>30);
  xl=xl<<2;

  for(i=15;i>=0;i--){
    tmp1=xh-y;
    tmp2=xh-y*2;
    tmp3=xh-y*3;
    if(tmp3>=0){
      xh=tmp3;
      q=q+3;
    }else if(tmp2>=0){
      xh=tmp2;
      q=q+2;
    }else if(tmp1>=0){
      xh=tmp1;
      q=q+1;
    }
    printf("i=%2d, q=%u, r=%u %8x\n",i,(unsigned)q,(unsigned)xh,xl);
    if(i>0){
      xh=xh<<2;
      xh=xh+(((unsigned)xl)>>30);
      xl=xl<<2;
      q=q<<2;
    }
  }

  printf("fix q=%u, r=%u %8x\n",(unsigned)q,(unsigned)xh,xl);
  printf("god q=%u, r=%u\n",(unsigned)atoi(args[1])/(unsigned)atoi(args[2]),(unsigned)atoi(args[1])%(unsigned)atoi(args[2]));

  return 0;
}
