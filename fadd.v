module fadd
  (
   input         clk,
   input         reset,
   input         req,
   input [31:0]  x,
   input [31:0]  y,
   output [31:0] rslt
   );

   reg           sgn1, sgn0;
   reg [7:0]     expr, expd;
   reg [23:0]    frac1, frac0;
   reg [24:0]    guard;
   reg [25:0]    fracr;

   wire [25+3:0] nrmi,nrm0,nrm1,nrm2,nrm3,nrm4;
   wire          rnd;
   wire [7:0]    expn;

   wire [7:0]    expx = (x[30:23]==8'h00) ? 8'h01 : x[30:23];
   wire [7:0]    expy = (y[30:23]==8'h00) ? 8'h01 : y[30:23];

   integer       i;

   always @ (posedge clk) begin
      if(req) begin
         if(x[30:23]>=y[30:23]) begin
            sgn1 <= x[31];
            sgn0 <= y[31];
            expr <= expx;
            expd <= expx - expy;
            frac1 <= {(x[30:23]!=8'h00),x[22:0]};
            frac0 <= {(y[30:23]!=8'h00),y[22:0]}; 
         end else begin
            sgn0 <= x[31];
            sgn1 <= y[31];
            expr <= expy;
            expd <= expy - expx;
            frac0 <= {(x[30:23]!=8'h00),x[22:0]};
            frac1 <= {(y[30:23]!=8'h00),y[22:0]};
         end
         i <= 2;
      end else if(i==2) begin
         if(expd>=25)
           if(sgn0^sgn1) {fracr,guard} <= {frac1,25'h0}-({frac0,25'h0}>>25);
           else          {fracr,guard} <= {frac1,25'h0}+({frac0,25'h0}>>25);
         else
           if(sgn0^sgn1) {fracr,guard} <= {frac1,25'h0}-({frac0,25'h0}>>expd);
           else          {fracr,guard} <= {frac1,25'h0}+({frac0,25'h0}>>expd);
         i <= 1;
      end else if(i==1) begin
         if(~nrmi[28])begin
            if((expr[7:1]==7'h7f)&(nrmi[27]))
              rslt[30:0] <= 31'h7f800000;
            else
              rslt[30:0] <= {expn,nrm4[26:4]}+rnd;
            rslt[31] <= sgn1;
         end else begin
            rslt[30:0] <= {expn,~nrm4[26:4]}+rnd;
            rslt[31] <= ~sgn1;
         end
         i <= 0;
      end
   end

   wire [2:0]  grs = {guard[24],guard[23],|guard[22:0]};
   wire [4:0]  nrmsft;                                        // expr >= nrmsft : subnormal output
   assign nrmsft[4] = (~(|nrmi[25+3:9+3]) |(&nrmi[25+3:9+3]) )& (expr[7:4]!=4'h0);
   assign nrmsft[3] = (~(|nrm0[25+3:17+3])|(&nrm0[25+3:17+3]))&((expr[7:3]&{3'h7, ~nrmsft[4],  1'b1})!=5'h00);
   assign nrmsft[2] = (~(|nrm1[25+3:21+3])|(&nrm1[25+3:21+3]))&((expr[7:2]&{4'hf, ~nrmsft[4:3],1'b1})!=6'h00);
   assign nrmsft[1] = (~(|nrm2[25+3:23+3])|(&nrm2[25+3:23+3]))&((expr[7:1]&{5'h1f,~nrmsft[4:2],1'b1})!=7'h00);
   assign nrmsft[0] = (~(|nrm3[25+3:24+3])|(&nrm3[25+3:24+3]))&((expr[7:0]&{6'h3f,~nrmsft[4:1],1'b1})!=8'h00);

   assign nrmi = {fracr,grs};
   assign nrm0 = (~nrmsft[4]) ? nrmi : {nrmi[9+3 :0], 16'h0000};
   assign nrm1 = (~nrmsft[3]) ? nrm0 : {nrm0[17+3:0], 8'h00};
   assign nrm2 = (~nrmsft[2]) ? nrm1 : {nrm1[21+3:0], 4'h0};
   assign nrm3 = (~nrmsft[1]) ? nrm2 : {nrm2[23+3:0], 2'b00};
   assign nrm4 = (~nrmsft[0]) ? nrm3 : {nrm3[24+3:0], 1'b0};
   wire [2:0]  grsn = {nrm4[4:3],|nrm4[2:0]};
   assign rnd = (~nrmi[28]) ? (grsn[1:0]==2'b11)|(grsn[2:1]==2'b11)
                            : ((grsn[1:0]==2'b00)|                          // inc
                               ((grsn[1]^grsn[0])     &(grsn[0]))|          // rs=11
                               ((grsn[2]^(|grsn[1:0]))&(grsn[1]^grsn[0]))); // gr=11
   assign expn = expr-nrmsft+(nrmi[28]^nrm4[27]); // subnormal(+0) or normal(+1)

endmodule
