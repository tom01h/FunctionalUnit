#include "unistd.h"
#include "getopt.h"
#include "Vcordic.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#define VCD_PATH_LENGTH 256

int main(int argc, char **argv, char **env) {
  
  int deg;
  int sinf, cosf;
  int i, nloop;
  char vcdfile[VCD_PATH_LENGTH];
  double err, errs, errc;

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));
  i=0;

  if(argc==2){
    deg = atoi(argv[1]);
    nloop=1;
  }else{
    deg = 0;
    nloop=90;
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
  verilator_top->op = 0;
  verilator_top->x = deg * M_PI / 180.0 * (1<<30);
  verilator_top->y = 0;
  //  while (!Verilated::gotFinish()) {
  while (i<=nloop) {
    verilator_top->reset = ((main_time%3000) < 100) ? 1 : 0;
    verilator_top->req   = ((main_time%3000) < 200) ? 1 : 0;
    if((main_time>0)&((main_time%3000)==0)){
      sinf = verilator_top->yn;
      cosf = verilator_top->xn;
      errs = abs(sin(deg * M_PI / 180.0)-(double)sinf/(1<<30));
      errc = abs(cos(deg * M_PI / 180.0)-(double)cosf/(1<<30));
      if(errs>errc){err = errs;}
      else{err = errc;}
      if(err<(double)1/(1<<24)){
        printf("PASSED : ");
      }else{
        printf("FAILED : ");
      }
      printf("deg = %2d, sin = %f, cos = %f, err = %e\n",deg,(double)sinf/(1<<30),(double)cosf/(1<<30),err);
      deg = deg+1;
      verilator_top->x = deg * M_PI / 180.0 * (1<<30);
      verilator_top->y = 0;
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
