module fdiv
  (
   input             clk,
   input             reset,
   input             req,
   input [31:0]      x,
   input [31:0]      y,
   output reg [31:0] rslt,
   output reg [4:0]  flag
   );

   reg [33:0]        ql;
   reg [31:0]        xl;
   reg [32:0]        tmp1, tmp2, tmp3;
   reg [9:0]         expr;
   integer           i;

   wire [31:0]       sx;
   assign sx = (tmp1[32]) ? xl :
               (tmp2[32]) ? {tmp1[29:0],2'b00} :
               (tmp3[32]) ? {tmp2[29:0],2'b00} :
               {tmp3[29:0],2'b00};

   wire [1:0]        dq;
   assign dq = (tmp1[32]) ? 0 :
               (tmp2[32]) ? 1 :
               (tmp3[32]) ? 2 :
               3;

   wire [56:0]       nrmi,nrm0,nrm1,nrm2,nrm3,nrm4,nrm5;
   wire [1:0]        ssn;
   wire              rnd;
   wire [9:0]        expn;
   wire [30:0]       rslt_r;

   reg [31:0]        fx, fy;
   reg [7:0]         ex, ey;
   reg               ix, iy;

   always @(*)begin
      if(x[30:23]==0)begin
         if(|x[22:15])begin
            ex = 7;
            fx = {2'b00,x[22:0]};
         end else if(|x[14:7])begin
            ex = 15;
            fx = {2'b00,x[14:0],8'h00};
         end else begin
            ex = 23;
            fx = {2'b00,x[6:0],16'h0000};
         end
         ix = 1'b1;
      end else begin
         ex = 0;
         fx = {2'b01,x[22:0]};
         ix = 1'b0;
      end
      if(y[30:23]==0)begin
         if(|y[22:15])begin
            ey = 0;
            fy = {2'b00,y[22:0],7'h00};
         end else if(|y[14:7])begin
            ey = 8;
            fy = {2'b00,y[14:0],15'h0000};
         end else begin
            ey = 16;
            fy = {2'b00,y[6:0],23'h000000};
         end
         iy = 1'b1;
      end else begin
         ey = 2;
         fy = {2'b01,y[22:0]};
         iy = 1'b0;
      end
   end

   always @(posedge clk)begin   
      if(reset)begin
         ql <= ({34{1'b0}});
         expr <= x[30:23]-y[30:23]+127+27-ex+(ey-2);
         xl <= fx;
         i  <= 14 + ix*4 + iy*4;
         tmp1[32] <= 1'b1;
      end else if(i>0)begin
         ql[33:2] <= ql[31:0]|dq;
         xl <= {sx[29:0],2'b00};
         if(|ql[24:23])begin
            i <= 0;
            expr <= expr + (i-1)*2;
         end else begin
            i <= i-1;
         end
         tmp1 <= {sx[31:0]}-{fy};
         tmp2 <= {sx[31:0]}     -{fy,1'b0};
         tmp3 <= {sx[31:0]}-{fy}-{fy,1'b0};
      end else if(i==0)begin
         flag <= 0;
         if((x[30:23]==8'hff)&(x[22:0]!=0))begin
            rslt <= x|32'h00400000;
            flag[4] <= ~x[22]|((y[30:23]==8'hff)&~y[22]&(y[21:0]!=0));
         end else if((y[30:23]==8'hff)&(y[22:0]!=0))begin
            rslt <= y|32'h00400000;
            flag[4] <= ~y[22]|((x[30:23]==8'hff)&~x[22]&(x[21:0]!=0));
         end else if((x[30:23]==8'hff)&(y[30:23]==8'hff))begin
            rslt <= 32'hffc00000;
            flag[4] <= 1'b1;
         end else if(x[30:23]==8'hff)begin
            rslt[31:0] <= {x[31]^y[31],x[30:0]};
         end else if(y[30:23]==8'hff)begin
            rslt[31:0] <= {x[31]^y[31],31'h00000000};
         end else if((x[30:0]==0) && (y[30:0]==0))begin
            rslt <= 32'hffc00000;
            flag[4] <= 1'b1;
         end else if(x[30:0]==0)begin
            rslt[31] <= x[31]^y[31];
            rslt[30:0] <= 31'h00000000;
         end else if(y[30:0]==0)begin
            rslt[31] <= x[31]^y[31];
            rslt[30:0] <= 31'h7f800000;
            flag[3] <= 1'b1;
         end else if(expn[9])begin
            rslt[31] <= x[31]^y[31];
            rslt[30:0] <= 31'h00000000;
            flag[0] <= 1'b1;
            flag[1] <= 1'b1;
         end else if((expn[8:0]>=9'h0ff)&(~expn[9]))begin
            rslt[31] <= x[31]^y[31];
            rslt[30:0] <= 31'h7f800000;
            flag[0] <= 1'b1;
            flag[2] <= 1'b1;
         end else begin
            rslt[31] <= x[31]^y[31];
            rslt[30:0] <= rslt_r;
            flag[0] <= |grsn[1:0];
            flag[1] <= ((rslt_r[30:23]==8'h00)|((expn[7:0]==8'h00)&~ssn[1]))&(|grsn[1:0]);//&flag0
            flag[2] <= (rslt_r[30:23]==8'hff);
         end
         i <= i-1;
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

   assign nrmi = {1'b0,{26{1'b0}},ql[33:2],dq[1:0],(|sx)};
   assign nrm5 = (~nrmsft[5]) ? nrmi : {nrmi[24:0], 32'h0000};
   assign nrm4 = (~nrmsft[4]) ? nrm5 : {nrm5[40:0], 16'h0000};
   assign nrm3 = (~nrmsft[3]) ? nrm4 : {nrm4[48:0], 8'h00};
   assign nrm2 = (~nrmsft[2]) ? nrm3 : {nrm3[52:0], 4'h0};
   assign nrm1 = (~nrmsft[1]) ? nrm2 : {nrm2[54:0], 2'b00};
   assign nrm0 = (~nrmsft[0]) ? nrm1 : {nrm1[55:0], 1'b0};

   assign ssn = {nrm0[30],(|nrm0[29:0])};
   wire [2:0]  grsn = {nrm0[32:31],|ssn};

   assign rnd = (~nrmi[56]) ? (grsn[1:0]==2'b11)|(grsn[2:1]==2'b11)
                            : ((grsn[1:0]==2'b00)|                          // inc
                               ((grsn[1]^grsn[0])     &(grsn[0]))|          // rs=11
                               ((grsn[2]^(|grsn[1:0]))&(grsn[1]^grsn[0]))); // gr=11
   assign expn = expr -{1'b0,nrmsft}+nrm0[55]; // subnormal(+0) or normal(+1)
endmodule
