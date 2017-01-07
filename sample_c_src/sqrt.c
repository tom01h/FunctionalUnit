#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define LOOP 23

int main(int argc, char *args[])
{
  double d, r;
  unsigned int x;
  d = atof(args[1]);
  r = sqrt(d);
  x = d * (1<<28); // input val
  printf("d = %f root = %f\n",d,r);

  int i;
  int c3, c2, c1;
  unsigned int z, y, a;
  a=0;
  y = (1<<28);
  z = 0;
  for(i=0;i<27;i+=2){
    c1 = x - (z|(y>>1))/2;
    c2 = x - ((z|y)*2)/2;
    c3 = x - ((z|y|(y>>1)))/2 - ((z|y|(y>>1))*2)/2;
    if(c3>=0){
      x = c3;
      a = a | y | y>>1;
      z = z | y<<1 | y;
    }else if(c2>=0){
      x = c2;
      a = a | y;
      z = z | y<<1;
    }else if(c1>=0){
      x = c1;
      a = a | y>>1;
      z = z | y;
    }
    printf("x = %f z = %f root = %f\n",(double)x/(1<<28),(double)z/(1<<28),(double)a/(1<<28));
    y=y>>2;
    x=x<<2;
  }
  return 0;
}
