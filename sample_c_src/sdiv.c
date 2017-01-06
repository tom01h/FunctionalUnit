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
  if(xl&0x80000000){
    if(y&0x80000000){
      sign = 1;
      plus = 0;
    }else{
      sign = 1;
      plus = 1;
    }
  }else{
    if(y&0x80000000){
      sign = 0;
      plus = 1;
    }else{
      sign = 0;
      plus = 0;
    }
  }    
  if(xl<0){
    xh = -1;
  }else{
    xh = 0;
  }
  q=0;
  xh=xh<<3;
  xh=xh+(((unsigned)xl)>>29);
  xl=xl<<3;

  for(i=15;i>=0;i--){
    if(plus==1){
      tmp1=xh+y;
      tmp2=xh+y*2;
      tmp3=xh+y*3;
    }else{
      tmp1=xh-y;
      tmp2=xh-y*2;
      tmp3=xh-y*3;
    }
    if(sign){
      //      if(tmp3<0 | (i==0)&(tmp3==0)){
      if(tmp3<0){
        xh=tmp3;
        q=q+3;
      }else if(tmp2<0 | (i==0)&(tmp2==0)){
        xh=tmp2;
        q=q+2;
      }else if(tmp1<0 | (i==0)&(tmp1==0)){
        xh=tmp1;
        q=q+1;
      }
    }else{
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
    }
    printf("i=%2d, q=%d, r=%d %8x\n",i,q,xh,xl);
    if(i>1){
      xh=xh<<2;
      xh=xh+(((unsigned)xl)>>30);
      xl=xl<<2;
      q=q<<2;
    }else if(i>0){
      xh=xh<<1;
      xh=xh+(((unsigned)xl)>>31);
      xl=xl<<1;
      q=q<<1;
    }
  }

  if(plus){q=-q;}
  printf("fix q=%d, r=%d %8x\n",q,xh,xl);
  printf("god q=%d, r=%d\n",atoi(args[1])/atoi(args[2]),atoi(args[1])%atoi(args[2]));

  return 0;
}
