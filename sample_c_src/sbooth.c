#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char *args[])
{
  int x, y;
  int64_t m;
  x = atoi(args[1]);
  y = atoi(args[2]);

  m=(int64_t)x*(int64_t)y;

  printf("expect %08x * %08x = %08x_%08x\n",x,y,(int)(m>>32),(int)m);

  int i;
  int sb;
  int sy;
  uint64_t sx;
  m = 0;
  sy = y;
  for(i=0;i<17;i++){
    if(i==0){
      sb = ((unsigned)sy%4)<<1;
      sy=sy>>1;
    }else{
      sb = (unsigned)sy%8;
      sy=sy>>2;
    }
    if     (sb==0){ sx= 0;}
    else if(sb==1){ sx= x;}
    else if(sb==2){ sx= x;}
    else if(sb==3){ sx= x; sx = sx*2;}
    else if(sb==4){ sx= x; sx = sx*2; sx = ~sx;}
    else if(sb==5){ sx= x;            sx = ~sx;}
    else if(sb==6){ sx= x;            sx = ~sx;}
    else if(sb==7){ sx= 0;}
    sx=sx&0x1ffffffff;
    if(i==0){
      if(sx&0x100000000){
        sx=sx|0x600000000;
      }else{
        sx=sx|0x800000000;
      }
    }else{
      if(sx&0x100000000){
        sx=sx|0x400000000;
      }else{
        sx=sx|0x600000000;
      }
    }
    //    printf("y=%08x, b=%d, sx=%01x%08x, ",y,sb,(int)(sx>>32),(int)sx);
    if(sb>=4&sb<7){
      sx=sx+1;
    }
    m = m+(sx<<(i*2));
    //    printf("u=%08x_%08x\n",(int)(m>>32),(int)m);
  }
  printf("result %08x * %08x = %08x_%08x\n",x,y,(int)(m>>32),(int)m);
  return 0;
}
