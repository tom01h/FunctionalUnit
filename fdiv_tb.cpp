#include "unistd.h"
#include "getopt.h"
#include "Vfdiv.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#define VCD_PATH_LENGTH 256

typedef union {
  float f;
  int i;
} fr;
int main(int argc, char **argv, char **env) {
  
  fr x, y;
  int xe, ye;
  int i, nloop, flag;
  char *e;
  char vcdfile[VCD_PATH_LENGTH];

  fr rslt, expect;

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));
  i=0;

  if(argc==3){
    x.i = strtol(argv[1],&e,16);
    y.i = strtol(argv[2],&e,16);
    nloop=1;
  }else if(argc==2){
      nloop = atoi(argv[1]);
  }

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vfdiv* verilator_top = new Vfdiv;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  //  while (!Verilated::gotFinish()) {
  while ((i<nloop)|(argc==1)) {
    verilator_top->reset = ((main_time%2000) < 100) ? 1 : 0;
    verilator_top->req   = ((main_time%2000) < 200) ? 1 : 0;
    if((main_time>0)&((main_time%2000)==0)){
      rslt.i = verilator_top->rslt;
      if((expect.i==rslt.i)&((flag==-1)|(flag==verilator_top->flag))){
        printf("PASSED %04d : %08x / %08x = %08x .. %02x\n",i,x.i,y.i,rslt.i,flag&0xff);
      }else{
        printf("FAILED %04d : %08x / %08x = %08x .. %02x != %08x .. %02x\n",i,x.i,y.i,expect.i,flag&0xff,rslt.i,verilator_top->flag);
      }
      i++;
    }
    if((main_time%2000)==0){
      if(argc==2){
        x.i = (rand()<<1)^rand();
        y.i = (rand()<<1)^rand();
        xe = (x.i>>23)&0xff;
        //xe = rand()%32;  // for subnormal test
        ye = rand()%32;
        //ye = rand()%3;   // for normalize test
        if(y.i&0x80){ye=xe+(ye);}
        else        {ye=xe-(ye);}
        //        if(xe<0){xe=0;}
        if(xe<=0){xe=1;}
        if(xe>254){xe=254;}
        x.i = x.i&0x807fffff|(xe<<23);
        //        if(ye<0){ye=0;}
        if(ye<=0){ye=1;}
        if(ye>254){ye=254;}
        y.i = y.i&0x807fffff|(ye<<23);
        expect.f = x.f / y.f;
        flag = -1;
      }else if(argc==1){
        if(scanf("%08x %08x %08x %02x", &x.i, &y.i, &expect.i, &flag)==EOF){
          break;}
      }else{
        expect.f = x.f / y.f;
        flag = -1;
      }
      verilator_top->x = x.i;
      verilator_top->y = y.i;
    }
    if (main_time % 100 == 0)
      verilator_top->clk = 0;
    if (main_time % 100 == 50)
      verilator_top->clk = 1;
    verilator_top->eval();
    if(argc!=1){
      tfp->dump(main_time);}
    main_time += 50;
  }
  delete verilator_top;
  tfp->close();

  
  exit(0);
}
