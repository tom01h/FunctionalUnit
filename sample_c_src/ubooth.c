#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char *args[])
{
  int x, y;
  uint64_t u;
  x = atoi(args[1]);
  y = atoi(args[2]);

  u=(uint64_t)(unsigned)x*(uint64_t)(unsigned)y;

  printf("unsigned %08x * %08x = %08x_%08x\n",x,y,(int)(u>>32),(int)u);

  int i;
  int b;
  int uy;
  uint64_t ux;
  u = 0;
  uy = y;
  for(i=0;i<17;i++){
    if(i==0){
      b = ((unsigned)uy%4)<<1;
      uy=(unsigned)uy>>1;
    }else{
      b = (unsigned)uy%8;
      uy=uy>>2;
    }
    if     (b==0){ ux=           0;}
    else if(b==1){ ux= (unsigned)x;}
    else if(b==2){ ux= (unsigned)x;}
    else if(b==3){ ux= (unsigned)x; ux = ux*2;}
    else if(b==4){ ux= (unsigned)x; ux = ux*2; ux = ~ux;}
    else if(b==5){ ux= (unsigned)x;            ux = ~ux;}
    else if(b==6){ ux= (unsigned)x;            ux = ~ux;}
    else if(b==7){ ux=           0;}
    ux=ux&0x1ffffffff;
    if(i==0){
      if(b>=4&b<7){
        ux=ux|0x600000000;
      }else{
        ux=ux|0x800000000;
      }
    }else{
      if(b>=4&b<7){
        ux=ux|0x400000000;
      }else{
        ux=ux|0x600000000;
      }
    }
    //    printf("y=%08x, b=%d, ux=%01x%08x, ",y,b,(int)(ux>>32),(int)ux);
    if(b>=4&b<7){
      ux=ux+1;
    }
    u = u+(ux<<(i*2));
    //    printf("u=%08x_%08x\n",(int)(u>>32),(int)u);
  }
  printf("unsigned %08x * %08x = %08x_%08x\n",x,y,(int)(u>>32),(int)u);
  return 0;
}
