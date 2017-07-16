module fsqrt
  (
   input             clk,
   input             reset,
   input             req,
   input [31:0]      x,
   output reg [31:0] rslt,
   output reg [4:0]  flag
   );

   reg [31:0]        a;
   reg [31:0]        xl;
   reg [31:0]        yl;
   reg [31:0]        zl;
   reg [32:0]        tmp1, tmp2, tmp3;
   reg [9:0]         expr;
   integer           i;

   wire [31:0]       sx;
   wire [31:0]       sz;
   wire [31:0]       sa;

   wire [32:0]       tmp1s = {sx[31:0]}-(zl[31:1]|yl[31:2]);
   wire [32:0]       tmp2s = {sx[31:0]}-(zl[31:0]|yl[31:0]);
   wire [32:0]       tmp3s = {sx[31:0]}-(zl[31:1]|yl[31:1]|yl[31:2])-(zl[31:0]|yl[31:0]|yl[31:1]);

   assign sx = (tmp1[32]) ? xl :
               (tmp2[32]) ? {tmp1[31:0],2'b00}:
               (tmp3[32]) ? {tmp2[31:0],2'b00}:
               {tmp3[31:0],2'b00};

   assign sz = (tmp1s[32]) ? zl :
               (tmp2s[32]) ? zl| yl :
               (tmp3s[32]) ? zl|{yl,1'b0} :
               zl|yl|{yl,1'b0};

   assign sa = (tmp1s[32]) ? a :
               (tmp2s[32]) ? a|yl[31:1] :
               (tmp3s[32]) ? a|yl :
               a|yl|yl[31:1];

   wire [56:0]       nrmi,nrm0,nrm1,nrm2,nrm3,nrm4,nrm5;
   wire              rnd;
   wire [9:0]        expn;
   wire [30:0]       rslt_r;

   always @(posedge clk)begin   
      if(reset)begin
         a <= 0;
         yl <= {2'b01,{28{1'b0}}};
         zl <= 0;
         flag <= 0;
         if(x[30:23]==8'h0)begin
            if(|x[22:15])begin
               expr <= 64+17;
               xl <= {1'b0,1'b0,x[22:0],5'h00};
            end else if(|x[14:7])begin
               expr <= 64+17-4;
               xl <= {1'b0,1'b0,x[14:0],13'h0000};
            end else begin
               expr <= 64+17-8;
               xl <= {1'b0,1'b0,x[6:0],21'h0000};
            end
            i  <= 16;
         end else begin
            expr <= (x[30:23]-1)/2+64+17;
            i  <= 12;
            if(x[23])begin
               xl <= {1'b0,1'b1,x[22:0],5'h00};
            end else begin
               xl <= {1'b0,1'b1,x[22:0],6'h00};
            end
         end
         tmp1[32] <= 1'b1;
      end else if(i>0)begin
         tmp1 <= {sx[31:0]}-(zl[31:1]|yl[31:2]);
         tmp2 <= {sx[31:0]}-(zl[31:0]|yl[31:0]);
         tmp3 <= {sx[31:0]}-(zl[31:1]|yl[31:1]|yl[31:2])-(zl[31:0]|yl[31:0]|yl[31:1]);
         yl <= yl[31:2];
         xl <= {sx[29:0],2'b00};
         zl <= sz;
         a <= sa;
         i <= i-1;
      end else if(i==0)begin
         if((x[30:23]==8'hff)&(x[22:0]!=0))begin
            rslt <= x|32'h00400000;
            flag[4] <= ~x[22];
         end else if(x[30:0]==0)begin
            rslt[31:0] <= x[31:0];
         end else if(x[31])begin
            rslt[31:0] <= 32'hffc00000;
            flag[4] <= 1'b1;
         end else if(x[30:23]==8'hff)begin
            rslt[31:0] <= x[31:0];
         end else begin
            rslt[31] <= 1'b0;
            rslt[30:0] <= rslt_r;
            i <= i-1;
            if((|sa[4:0])|(sx))begin
               flag[0] <= 1'b1;
            end
         end
      end
   end

   assign rslt_r = {expn[7:0],nrm0[54:32]} + rnd;

   wire [5:0]  nrmsft;                                // expr >= nrmsft : subnormal output
//   assign nrmsft[5] = (~(|nrmi[56:24])|(&nrmi[56:24]))& (expr[8:5]!=4'h0);
   assign nrmsft[5] = 1'b0;
   assign nrmsft[4] = (~(|nrm5[56:40])|(&nrm5[56:40]))&((expr[8:4]&{3'h7,~nrmsft[5],  1'b1})!=5'h00);
   assign nrmsft[3] = (~(|nrm4[56:48])|(&nrm4[56:48]))&((expr[8:3]&{3'h7,~nrmsft[5:4],1'b1})!=6'h00);
   assign nrmsft[2] = (~(|nrm3[56:52])|(&nrm3[56:52]))&((expr[8:2]&{3'h7,~nrmsft[5:3],1'b1})!=7'h00);
   assign nrmsft[1] = (~(|nrm2[56:54])|(&nrm2[56:54]))&((expr[8:1]&{3'h7,~nrmsft[5:2],1'b1})!=8'h00);
   assign nrmsft[0] = (~(|nrm1[56:55])|(&nrm1[56:55]))&((expr[8:0]&{3'h7,~nrmsft[5:1],1'b1})!=9'h000);

   assign nrmi = {1'b0,{26{1'b0}},sa[28:0],(|sx),8'h00};
   assign nrm5 = (~nrmsft[5]) ? nrmi : {nrmi[24:0], 32'h0000};
   assign nrm4 = (~nrmsft[4]) ? nrm5 : {nrm5[40:0], 16'h0000};
   assign nrm3 = (~nrmsft[3]) ? nrm4 : {nrm4[48:0], 8'h00};
   assign nrm2 = (~nrmsft[2]) ? nrm3 : {nrm3[52:0], 4'h0};
   assign nrm1 = (~nrmsft[1]) ? nrm2 : {nrm2[54:0], 2'b00};
   assign nrm0 = (~nrmsft[0]) ? nrm1 : {nrm1[55:0], 1'b0};

   wire [1:0]  ssn = {nrm0[30],(|nrm0[29:0])};

   wire [2:0]  grsn = {nrm0[32:31],|ssn};

   assign rnd = (~nrmi[56]) ? (grsn[1:0]==2'b11)|(grsn[2:1]==2'b11)
                            : ((grsn[1:0]==2'b00)|                          // inc
                               ((grsn[1]^grsn[0])     &(grsn[0]))|          // rs=11
                               ((grsn[2]^(|grsn[1:0]))&(grsn[1]^grsn[0]))); // gr=11
   assign expn = expr-{1'b0,nrmsft}+nrm0[55]; // subnormal(+0) or normal(+1)

endmodule
