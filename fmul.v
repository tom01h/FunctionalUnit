module booth
  (
   input         i,
   input         x_signed,
   input [2:0]   br,
   input [31:0]  x,
   output [35:0] bx
   );

   assign S = ((br==3'b000)|(br==3'b111)) ? 1'b0 : (x[31]&x_signed)^br[2] ;

   always @(*) begin
      case(br)
        3'b000: bx[32:0] =  {33{1'b0}};
        3'b001: bx[32:0] =  {x[31]&x_signed,x[31:0]};
        3'b010: bx[32:0] =  {x[31]&x_signed,x[31:0]};
        3'b011: bx[32:0] =  {x[31:0],1'b0};
        3'b100: bx[32:0] = ~{x[31:0],1'b0};
        3'b101: bx[32:0] = ~{x[31]&x_signed,x[31:0]};
        3'b110: bx[32:0] = ~{x[31]&x_signed,x[31:0]};
        3'b111: bx[32:0] =  {33{1'b0}};
      endcase
      if(i) bx[35:33] = {2'b01,~S};
      else  bx[35:33] = {~S,S,S};
   end
endmodule

module fmul
  (
   input         clk,
   input         reset,
   input         req,
   input [31:0]  x,
   input [31:0]  y,
   output [31:0] rslt,
   output [4:0]  flag
   );

   reg [9:0]     expr;
   wire          sgnr = x[31]^y[31];
   reg           subn;

   reg [25:0]    fracr;

   wire [56:0]   nrmi,nrm0,nrm1,nrm2,nrm3,nrm4;
   wire [1:0]    ssn;
   wire          rnd;
   wire [9:0]    expn;

   wire [7:0]    expx = (x[30:23]==8'h00) ? 8'h01 : x[30:23];
   wire [7:0]    expy = (y[30:23]==8'h00) ? 8'h01 : y[30:23];

   integer       i;

   wire          x_signed = 1'b0;
   wire          y_signed = 1'b0;

   reg [46:14]   ms;
   reg [64:0]    m;

   reg [31:0]    sy;
   wire [31:0]   xf = {(x[30:23]!=8'h00),x[22:0],8'h00};

   wire [2:0]    br0 = {sy[1:0],1'b0};
   wire [2:0]    br1 = sy[3:1];
   wire [2:0]    br2 = sy[5:3];
   wire [2:0]    br3 = sy[15:13];
   wire [2:0]    br4 = sy[17:15];
   wire [2:0]    br5 = sy[19:17];

   wire [35:0]   bx0, bx1, bx2;
   wire [35:0]   bx3, bx4, bx5;

   wire          ng0 = (br0[2:1]==2'b10)|(br0[2:0]==3'b110);
   wire          ng1 = (br1[2:1]==2'b10)|(br1[2:0]==3'b110);
//   wire          ng2 = (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
   reg           ng2;
   wire          ng3 = (br3[2:1]==2'b10)|(br3[2:0]==3'b110);
   wire          ng4 = (br4[2:1]==2'b10)|(br4[2:0]==3'b110);
//   wire          ng5 = (br5[2:1]==2'b10)|(br5[2:0]==3'b110);
   reg           ng5;

   booth booth0(.i(0), .x_signed(x_signed), .br(br0), .x(xf), .bx(bx0));
   booth booth1(.i(1), .x_signed(x_signed), .br(br1), .x(xf), .bx(bx1));
   booth booth2(.i(1), .x_signed(x_signed), .br(br2), .x(xf), .bx(bx2));
   booth booth3(.i(1), .x_signed(x_signed), .br(br3), .x(xf), .bx(bx3));
   booth booth4(.i(1), .x_signed(x_signed), .br(br4), .x(xf), .bx(bx4));
   booth booth5(.i(1), .x_signed(x_signed), .br(br5), .x(xf), .bx(bx5));

   always @ (posedge clk) begin
      if(req) begin
         expr <= expx + expy - 127;
         i<=0;
         sy<={8'h00,(y[30:23]!=8'h00),y[22:0]}; 
      end else begin
         ng2 <= (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
         ng5 <= (br5[2:1]==2'b10)|(br5[2:0]==3'b110);
         case(i)
           0: begin
              ms[46:22] <= {3'b000,bx0[35:14]}+{1'b0,bx1[35:12]}+{1'b0,bx2[33:10]};
              ms[21:14] <= 8'h00;
              m[64:8] <= {7'h00,bx3[35:0],               bx0[13:0]}+
                         {5'h00,bx4[35:0],1'b0,ng3,      bx1[11:0],1'b0,ng0}+
                         {3'h0 ,bx5[35:0],1'b0,ng4,2'b00,bx2[ 9:0],1'b0,ng1,2'b00};
              m[7:0]  <= 8'h00;
           end
           1,2: begin
              ms[46:22] <= {3'b000,ms[46],~ms[46],ms[45:26]}+{1'b0,bx1[35:12]}+{1'b0,bx2[33:10]};
              ms[21:14] <= ms[25:18];
              m[64:8] <= {3'b000, m[64], ~m[64], m[63:12]}+
                         {5'h00,bx4[35:0],1'b0,ng5,      bx1[11:0],1'b0,ng2}+
                         {3'h0 ,bx5[33:0],1'b0,ng4,2'b00,bx2[ 9:0],1'b0,ng1,2'b00};
              m[7:0]  <= m[11:4];
           end
           3: begin
              m[64:0] <= m[64:0]+
                         {1'b0,bx4[35:0],1'b0,ng5,26'h0}+
                         {       ms[46], ~ms[46], ms[45:14],1'b0,ng2,12'h0000};
              if((expr==0)|expr[9])begin
                 expr <= expr+26;
                 subn <= 1'b1;
              end else
                 subn <= 1'b0;
           end
           4: begin
              rslt[31] = sgnr;
              flag=0;
              if((x[30:23]==8'hff)&(x[22:0]!=0))begin
                 rslt = x|32'h00400000;
                 flag[4]=~x[22]|((y[30:23]==8'hff)&~y[22]&(y[21:0]!=0));
              end else if((y[30:23]==8'hff)&(y[22:0]!=0))begin
                 rslt = y|32'h00400000;
                 flag[4]=~y[22]|((x[30:23]==8'hff)&~x[22]&(x[21:0]!=0));
              end else if(x[30:23]==8'hff)begin
                 if(y[30:0]==0)begin
                    rslt = 32'hffc00000;
                    flag[4] = 1'b1;
                 end else begin
                    rslt[31:0] = {x[31]^y[31],x[30:0]};
                 end
              end else if(y[30:23]==8'hff)begin
                 if(x[30:0]==0)begin
                    rslt = 32'hffc00000;
                    flag[4] = 1'b1;
                 end else begin
                    rslt[31:0] = {x[31]^y[31],y[30:0]};
                 end
              end else if(m[55:0]==0)begin
                 rslt[30:0] = 31'h00000000;
              end else if(expn[9])begin
                 rslt[30:0] = 31'h00000000;
                 flag[0] = 1'b1;
                 flag[1] = 1'b1;
              end else if((expn[8:0]>=9'h0ff)&(~expn[9]))begin
                 rslt[30:0] = 31'h7f800000;
                 flag[0] = 1'b1;
                 flag[2] = 1'b1;
              end else begin
                 rslt[30:0] = {expn[7:0],nrm0[54:32]}+rnd;
                 flag[0] = |grsn[1:0];
                 flag[1] = ((rslt[30:23]==8'h00)|((expn[7:0]==8'h00)&~ssn[1]))&(flag[0]);
                 flag[2] = (rslt[30:23]==8'hff);
              end
           end
         endcase
         i<=i+1;
         if(y_signed)
           sy<={{4{sy[31]}},sy[31:4]};
         else
           sy<={4'h0       ,sy[31:4]};
      end
   end

   wire [4:0]  nrmsft;                                // expr >= nrmsft : subnormal output
   assign nrmsft[4] = (~(|nrmi[56:40])|(&nrmi[56:40]))& (expr[7:4]!=4'h0);
   assign nrmsft[3] = (~(|nrm4[56:48])|(&nrm4[56:48]))&((expr[7:3]&{3'h7, ~nrmsft[4],  1'b1})!=5'h00);
   assign nrmsft[2] = (~(|nrm3[56:52])|(&nrm3[56:52]))&((expr[7:2]&{4'hf, ~nrmsft[4:3],1'b1})!=6'h00);
   assign nrmsft[1] = (~(|nrm2[56:54])|(&nrm2[56:54]))&((expr[7:1]&{5'h1f,~nrmsft[4:2],1'b1})!=7'h00);
   assign nrmsft[0] = (~(|nrm1[56:55])|(&nrm1[56:55]))&((expr[7:0]&{6'h3f,~nrmsft[4:1],1'b1})!=8'h00);

   assign nrmi = (subn) ? {1'b0,{26{1'b0}},m[55:27],(|m[26:0])} : {1'b0,m[55:0]};
   assign nrm4 = (~nrmsft[4]) ? nrmi : {nrmi[40:0], 16'h0000};
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
   assign expn = expr-nrmsft+nrm0[55]; // subnormal(+0) or normal(+1)

endmodule
