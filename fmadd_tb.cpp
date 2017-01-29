#include "unistd.h"
#include "getopt.h"
#include "Vfmadd.h"
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
  
  fr x, y, z;
  int xe, ye, ze;
  int i, nloop, flag;
  char *e;
  char vcdfile[VCD_PATH_LENGTH];

  fr rslt, expect;

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));
  i=0;

  if(argc==4){
    x.i = strtol(argv[1],&e,16);
    y.i = strtol(argv[2],&e,16);
    z.i = strtol(argv[3],&e,16);
    nloop=1;
  }else if(argc==2){
      nloop = atoi(argv[1]);
  }
  
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vfmadd* verilator_top = new Vfmadd;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  //  while (!Verilated::gotFinish()) {
  while ((i<nloop)|(argc==1)) {
    verilator_top->reset = ((main_time%1000) < 100) ? 1 : 0;
    verilator_top->req   = ((main_time%1000) < 200) ? 1 : 0;
    if((main_time>0)&((main_time%1000)==0)){
      rslt.i = verilator_top->rslt;
      if((expect.i==rslt.i)&((flag==-1)|(flag==verilator_top->flag))){
        if((argc!=1)|(i%100==0))
          printf("PASSED %04d : %08x * %08x + %08x = %08x .. %02x\n",i,x.i,y.i,z.i,rslt.i,flag&0xff);
      }else{
        printf("FAILED %04d : %08x * %08x + %08x = %08x .. %02x != %08x .. %02x\n",i,x.i,y.i,z.i,expect.i,flag&0xff,rslt.i,verilator_top->flag);
      }
      i++;
    }
    if((main_time%1000)==0){
      if(argc==2){
        x.i = (rand()<<1)^rand();
        y.i = (rand()<<1)^rand();
        z.i = (rand()<<1)^rand();
        xe = (x.i>>23)&0xff;
        ye = rand()%64 - 32 + 128;
        ze = rand()%32;
        if(z.i&0x80){ze=(xe+ye-128)+(ze);}
        else        {ze=(xe+ye-128)-(ze);}
        if(xe<0){xe=0;}
        if(xe>254){xe=254;}
        x.i = x.i&0x807fffff|(xe<<23);
        if(ye<0){ye=0;}
        if(ye>254){ye=254;}
        y.i = y.i&0x807fffff|(ye<<23);
        if(ze<0){ze=0;}
        if(ze>254){ze=254;}
        z.i = z.i&0x807fffff|(ze<<23);
        expect.f = (double)x.f * (double)y.f + (double)z.f;
        flag = -1;
      }else if(argc==1){
        if(scanf("%08x %08x %08x %08x %02x", &x.i, &y.i, &z.i, &expect.i, &flag)==EOF){
          break;}
      }else{
        expect.f = (double)x.f * (double)y.f + (double)z.f;
        flag = -1;
      }
      verilator_top->x = x.i;
      verilator_top->y = y.i;
      verilator_top->z = z.i;
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
