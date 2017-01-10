#include "unistd.h"
#include "getopt.h"
#include "Vcordic.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#define VCD_PATH_LENGTH 256

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

int main(int argc, char **argv, char **env) {
  
  dr xf, yf, tf;
  fr rr;
  int xi, yi, xe, ye, ri;
  int i, j, nloop;
  double r, err;
  char vcdfile[VCD_PATH_LENGTH];

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));
  i=0;

  if(argc==3){
    xf.f = atof(argv[1]);
    yf.f = atof(argv[2]);
    nloop=1;
  }else{
    if(argc==2){
      nloop = atoi(argv[1]);
    }else{
      nloop = 1000;
    }
  }
  
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vcordic* verilator_top = new Vcordic;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  verilator_top->x_signed = 0;
  verilator_top->y_signed = 0;
  verilator_top->op = 1;
  verilator_top->x = xi;
  verilator_top->y = yi;
  //  while (!Verilated::gotFinish()) {
  while (i<nloop) {
    verilator_top->reset = ((main_time%3000) < 100) ? 1 : 0;
    verilator_top->req   = ((main_time%3000) < 200) ? 1 : 0;
    if((main_time>0)&((main_time%3000)==0)){
      ri = verilator_top->ri;
      r=(double)ri/(1<<30);
      if(xf.f<0){r=-r+M_PI;}
      if(yf.f<0){r=-r;}
      err = abs(atan2(yf.f,xf.f)-r);
      if(err<(double)1/(1<<23)){
        printf("PASSED : ");
      }else{
        printf("FAILED : ");
      }
      printf("x = %e, y = %e, r = %f, err = %e\n",xf.f, yf.f, r*180/M_PI, err);
      //      rr.i = 0x3f1b74ee;
      //      printf("sqrt(x^2+y^2) = %f\n",verilator_top->xn*tf.f/(1<<29)*rr.f);
      i++;
    }
    if((main_time%3000)==0){
      if(argc!=3){
        xf.u = (rand()<<1)^rand();
        yf.u = (rand()<<1)^rand();
        xf.l = (rand()<<1)^rand();
        yf.l = (rand()<<1)^rand();
        xe = (xf.u >> 20)&0x7ff;
        ye = rand();
        for(j=0; j<=31; j++){
          if(ye&(1<<j)){
            if(rand()%2){
              ye=xe+j;
            }else{
              ye=xe-j;
            }
            break;
          }
        } 
        if(xe<1){xe=1;}
        if(xe>2046){xe=2046;}
        xf.u = xf.u&0x800fffff|(xe<<20);
        if(ye<1){ye=1;}
        if(ye>2046){ye=2046;}
        yf.u = yf.u&0x800fffff|(ye<<20);
      }
      xe = (xf.u >> 20)&0x7ff;
      ye = (yf.u >> 20)&0x7ff;

      xi=(xf.u&0x000fffff|0x00100000)<<9;
      yi=(yf.u&0x000fffff|0x00100000)<<9;
      xi=xi|((unsigned)xf.l>>(32-9));
      yi=yi|((unsigned)yf.l>>(32-9));
      if(xe>=ye){
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
        tf.u = (ye<<20);
        tf.l = 0;
      }
      verilator_top->x = xi;
      verilator_top->y = yi;
    }
    
    if (main_time % 100 == 0)
      verilator_top->clk = 0;
    if (main_time % 100 == 50)
      verilator_top->clk = 1;
    verilator_top->eval();
    tfp->dump(main_time);
    main_time += 50;
  }
  delete verilator_top;
  tfp->close();

  
  exit(0);
}
