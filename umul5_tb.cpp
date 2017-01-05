#include "unistd.h"
#include "getopt.h"
#include "Vmul5.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#define VCD_PATH_LENGTH 256

int main(int argc, char **argv, char **env) {
  
  int x, y;
  int i, nloop;
  char vcdfile[VCD_PATH_LENGTH];

  uint64_t m;
  int mh, ml;

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));
  i=0;

  if(argc==3){
    x = atoi(argv[1]);
    y = atoi(argv[2]);
    nloop=1;
  }else{
    x = (rand()<<1)^rand();
    y = (rand()<<1)^rand();
    if(argc==2){
      nloop = atoi(argv[1]);
    }else{
      nloop = 1000;
    }
  }
  
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vmul5* verilator_top = new Vmul5;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  verilator_top->x_signed = 0;
  verilator_top->y_signed = 0;
  verilator_top->x = x;
  verilator_top->y = y;
  //  while (!Verilated::gotFinish()) {
  while (i<nloop) {
    verilator_top->reset = ((main_time%1000) < 200) ? 1 : 0;
    if((main_time>0)&((main_time%1000)==0)){
      mh = verilator_top->mh;
      ml = verilator_top->ml;
      m=(int64_t)(unsigned)x*(int64_t)(unsigned)y;
      if(((int)(m>>32)==mh) & (((int)m)==ml)){
        printf("PASSED %04d : %08x * %08x = %08x_%08x\n",i,x,y,mh,ml);
      }else{
        printf("FAILED %04d : %08x * %08x = %08x_%08x != %08x_%08x\n",i,x,y,(int)(m>>32),(int)m,mh,ml);
      }
      x = (rand()<<1)^rand();
      y = (rand()<<1)^rand();
      verilator_top->x = x;
      verilator_top->y = y;
      i++;
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
