`include "vscale_md_constants.vh"

module vscale_mul_div
  (
   input                     clk,
   input                     reset,
   input                     req_valid,
   output                    req_ready,
   input                     req_in_1_signed,
   input                     req_in_2_signed,
   input [`MDF_OP_WIDTH-1:0] req_op,
   input [2:0]               req_rm,//TEMP//TEMP//
   input                     req_out_sel,
   input [31:0]              req_in_1,
   input [31:0]              req_in_2,
   input [31:0]              req_in_3,
   output reg                resp_valid,
   output [31:0]             resp_result,
   output reg [31:0]         resp_fbypass,
   output [31:0]             resp_fresult,
   output wire [4:0]         resp_fflag
   );

   reg                       x_signed;
   reg                       y_signed;
   reg [31:0]                x;
   reg [31:0]                y;
   reg                       out_sel;
   reg [`MDF_OP_WIDTH-1:0]   op;
   reg [`MDF_OP_WIDTH-1:0]   fop;
   reg [31:0]                xh, xl;

   reg [31:0]                frslt;
   reg [4:0]                 fflag;

   always @(posedge clk) begin
      if(req_valid & req_ready) begin
         x_signed <= req_in_1_signed;
         y_signed <= req_in_2_signed;
         x <= req_in_1;
         if((req_op==`MDF_OP_FML)|(req_op==`MDF_OP_FMA)|(req_op==`MDF_OP_FNA)|(req_op==`MDF_OP_FMS)|(req_op==`MDF_OP_FNS))
           y<={(req_in_2[30:23]!=8'h00),req_in_2[22:0],8'h00};
         else
           y <= req_in_2;
         out_sel <= req_out_sel;
         op <= req_op;
      end
   end

   reg [4:0]     i;
   reg [32:0]    buf0,buf1,buf2;
   assign resp_result = (out_sel==`MD_OUT_HI) ? buf2[31:0] : buf1[31:0];
   assign req_ready = (i == 5'b00000);
   always @ (posedge clk)
     resp_fbypass <= (out_sel==`MD_OUT_HI) ? buf2[31:0] : buf1[31:0];

   assign resp_fresult = (fop==`MDF_OP_NOP) ? resp_fbypass : frslt;
   assign resp_fflag   = (fop==`MDF_OP_NOP) ? 0            : fflag;

///////////////// MUL Only vvvvvvvvvvvvvvvvvvvvvvvvvvvv
   wire [2:0]    br0 = {xh[1:0],1'b0};
   wire [2:0]    br1 = xh[3:1];
   wire [2:0]    br2 = xh[5:3];
   wire [2:0]    br3 = xh[15:13];
   wire [2:0]    br4 = xh[17:15];
   wire [2:0]    br5 = xh[19:17];

   wire [35:0]   by0, by1, by2;
   wire [35:0]   by3, by4, by5;

   wire          ng0 = (br0[2:1]==2'b10)|(br0[2:0]==3'b110);
   wire          ng1 = (br1[2:1]==2'b10)|(br1[2:0]==3'b110);
//   wire          ng2 = (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
   reg           ng2;
   wire          ng3 = (br3[2:1]==2'b10)|(br3[2:0]==3'b110);
   wire          ng4 = (br4[2:1]==2'b10)|(br4[2:0]==3'b110);
//   wire          ng5 = (br5[2:1]==2'b10)|(br5[2:0]==3'b110);
   reg           ng5;

   booth booth0(.i(1'b0), .y_signed(y_signed), .br(br0), .y(y), .by(by0));
   booth booth1(.i(1'b1), .y_signed(y_signed), .br(br1), .y(y), .by(by1));
   booth booth2(.i(1'b1), .y_signed(y_signed), .br(br2), .y(y), .by(by2));
   booth booth3(.i(1'b1), .y_signed(y_signed), .br(br3), .y(y), .by(by3));
   booth booth4(.i(1'b1), .y_signed(y_signed), .br(br4), .y(y), .by(by4));
   booth booth5(.i(1'b1), .y_signed(y_signed), .br(br5), .y(y), .by(by5));

   wire [50:18]  ms =  buf0[32:0];
   wire [64:0]   m  = {buf2[32:0],buf1[31:0]};
   reg [32:0]    in00,in01,in02,in10,in11,in12,in20,in21,in22;
   reg [1:0]     in0v,in1v,in2v;

///////////////// MUL Only ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
///////////////// DIV Only vvvvvvvvvvvvvvvvvvvvvvvvvvvv
   reg [31:0]    q;
   reg           sign;
   reg           plus;

   wire [31:0]   sxh;
   assign sxh = (sign!=buf0[32]) ? xh :
                (sign!=buf1[32]) ? buf0[31:0] :
                (sign!=buf2[32]) ? buf1[31:0] :
                buf2[31:0];

   wire [1:0]    dq;
   assign dq  = (sign!=buf0[32]) ? 0 :
                (sign!=buf1[32]) ? 1 :
                (sign!=buf2[32]) ? 2 :
                3;
///////////////// DIV Only ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
///////////////// FPU Only vvvvvvvvvvvvvvvvvvvvvvvvvvvv
   reg [1:0]     fpu_ex;  // [0] use buf0 / [1] exp field [] is flag  //TEMP//TEMP//not pipe
                            //TEMP//TEMP//not pipe also buf0 @ fpu_ex=1
   reg           sgn1, sgn0;//TEMP//TEMP//not pipe
   reg [9:0]     expr, expd;
   reg           subn;

   wire [7:0]    expx = (req_in_1[30:23]==8'h00) ? 8'h01 : req_in_1[30:23];
   wire [7:0]    expy = (req_in_2[30:23]==8'h00) ? 8'h01 : req_in_2[30:23];
   wire [7:0]    expz = (req_in_3[30:23]==8'h00) ? 8'h01 : req_in_3[30:23];
   wire [9:0]    expm = expx + expy - 127;
   wire [9:0]    exps = ( ((req_op==`MDF_OP_FAD)|(req_op==`MDF_OP_FSB)) ? {1'b0,expx}-{1'b0,expy} :
                          (req_op==`MDF_OP_FML) ? expm :
                          ((req_op==`MDF_OP_FMA)|(req_op==`MDF_OP_FNA)|
                           (req_op==`MDF_OP_FMS)|(req_op==`MDF_OP_FNS)) ? expm - {1'b0,expz} :
                          {9{1'bx}});

   reg [25:0]    fracr;
   reg [30:0]    guard;

//   wire [2:0]    grs = {guard[30],guard[29],|guard[28:0]};
   wire [5:0]    nrmsft;                                        // expr >= nrmsft : subnormal output
   wire [56:0]   nrmi,nrm0,nrm1,nrm2,nrm3,nrm4,nrm5;

   assign nrmsft[5] = (~(|nrmi[56:24])|(&nrmi[56:24]))& (expr[8:5]!=4'h0);
   assign nrmsft[4] = (~(|nrm5[56:40])|(&nrm5[56:40]))&((expr[8:4]&{3'h7,~nrmsft[5],  1'b1})!=5'h00);
   assign nrmsft[3] = (~(|nrm4[56:48])|(&nrm4[56:48]))&((expr[8:3]&{3'h7,~nrmsft[5:4],1'b1})!=6'h00);
   assign nrmsft[2] = (~(|nrm3[56:52])|(&nrm3[56:52]))&((expr[8:2]&{3'h7,~nrmsft[5:3],1'b1})!=7'h00);
   assign nrmsft[1] = (~(|nrm2[56:54])|(&nrm2[56:54]))&((expr[8:1]&{3'h7,~nrmsft[5:2],1'b1})!=8'h00);
   assign nrmsft[0] = (~(|nrm1[56:55])|(&nrm1[56:55]))&((expr[8:0]&{3'h7,~nrmsft[5:1],1'b1})!=9'h000);

   assign nrmi = (subn) ? {{26{1'b0}},fracr,guard[30:27],(|guard[26:0])} : {fracr,guard};
   assign nrm5 = (~nrmsft[5]) ? nrmi : {nrmi[24:0], 32'h0000};
   assign nrm4 = (~nrmsft[4]) ? nrm5 : {nrm5[40:0], 16'h0000};
   assign nrm3 = (~nrmsft[3]) ? nrm4 : {nrm4[48:0], 8'h00};
   assign nrm2 = (~nrmsft[2]) ? nrm3 : {nrm3[52:0], 4'h0};
   assign nrm1 = (~nrmsft[1]) ? nrm2 : {nrm2[54:0], 2'b00};
   assign nrm0 = (~nrmsft[0]) ? nrm1 : {nrm1[55:0], 1'b0};
   wire [1:0] ssn = {nrm0[30],(|nrm0[29:0])};
   wire [2:0] grsn = {nrm0[32:31],(|ssn)};

   assign rnd = (~nrmi[56]) ? (grsn[1:0]==2'b11)|(grsn[2:1]==2'b11)
                            : ((grsn[1:0]==2'b00)|                          // inc
                               ((grsn[1]^grsn[0])     &(grsn[0]))|          // rs=11
                               ((grsn[2]^(|grsn[1:0]))&(grsn[1]^grsn[0]))); // gr=11
   wire [9:0]  expn = expr-nrmsft+(nrm0[56]^nrm0[55]); // subnormal(+0) or normal(+1)

   always @(*)begin
      fflag=0;
      if(fpu_ex[0])begin
         frslt[31] = buf0[31];
         frslt[22:0] = buf0[22:0];
         if(fpu_ex[1])begin
            frslt[30:23] = {8{buf0[30]}};
            fflag[4:2] = buf0[29:27];
         end else begin
            frslt[30:23] = buf0[30:23];
         end
      end else if({fracr,guard}==0)begin
         frslt[31:0] = {sgn0&sgn1,31'h0};
      end else if(expn[9])begin
         frslt[31] = sgn1;
         frslt[30:0] = 31'h00000000;
         fflag[0] = 1'b1;
         fflag[1] = 1'b1;
      end else if(~nrmi[56])begin
         fflag[0]=|grsn[1:0];
         if((expn[8:0]>=9'h0ff)&(~expn[9]))begin
            frslt[30:0] = 31'h7f800000;
            fflag[2]=1'b1;
            fflag[0]=1'b1;
         end else begin
            frslt[30:0] = {expn[7:0],nrm0[54:32]}+rnd;
            fflag[0]=|grsn[1:0];
            fflag[1]=((frslt[30:23]==8'h00)|((expn[7:0]==8'h00)&~ssn[1]))&(fflag[0]);
            fflag[2]=(frslt[30:23]==8'hff);
         end
         frslt[31] = sgn1;
      end else begin
         frslt[30:0] = {expn[7:0],~nrm0[54:32]}+rnd;
         frslt[31] = ~sgn1;
         fflag[0]=|grsn[1:0];
         fflag[1]=((frslt[30:23]==8'h00)|((expn[7:0]==8'h00)&((~ssn[1]&~ssn[0])|(ssn[1]&ssn[0])) ))&(fflag[0]);
      end
   end

///////////////// FPU Only ^^^^^^^^^^^^^^^^^^^^^^^^^^^^

   always @ (*) begin
      if(   (op==`MDF_OP_MUL)|(op==`MDF_OP_FML)|
         ( ((op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS)) &(i>1) )  )begin
         in0v = 2'b00;
         in1v = 2'b00;
         in2v = 2'b00;
         in10[32] = 1'b0; in11[32] = 1'b0; in12[32] = 1'b0;
         case(i)
           5: begin
              in00[32:0] = {3'b000,by0[35:14],8'h00};
              in01[32:0] = {1'b0,by1[35:12],8'h00};
              in02[32:0] = {1'b0,by2[33:10],8'h00};
              {in20[32:0],in10[31:0]} = {7'h00,by3[35:0],               by0[13:0]               ,8'h00};
              {in21[32:0],in11[31:0]} = {5'h00,by4[35:0],1'b0,ng3,      by1[11:0],1'b0,ng0      ,8'h00};
              {in22[32:0],in12[31:0]} = {3'h0 ,by5[35:0],1'b0,ng4,2'b00,by2[ 9:0],1'b0,ng1,2'b00,8'h00};
           end
           4,3: begin
              in00[32:0] = {3'b000,ms[50],~ms[50],ms[49:30],ms[29:22]};
              in01[32:0] = {1'b0,by1[35:12],8'h00};
              in02[32:0] = {1'b0,by2[33:10],8'h00};
              {in20[32:0],in10[31:0]} = {3'h0 , m[64], ~m[64], m[63:12]                       ,m[11:4]};
              {in21[32:0],in11[31:0]} = {5'h00,by4[35:0],1'b0,ng5,      by1[11:0],1'b0,ng2      ,8'h00};
              {in22[32:0],in12[31:0]} = {3'h0 ,by5[33:0],1'b0,ng4,2'b00,by2[ 9:0],1'b0,ng1,2'b00,8'h00};
           end
           2: begin
              in00[32:0] = {3'b000,ms[50],~ms[50],ms[49:30],ms[29:22]};//Dummy
              in01[32:0] = {1'b0,by1[35:12],8'h00};//Dummy
              in02[32:0] = {1'b0,by2[33:10],8'h00};//Dummy
              {in20[32:0],in10[31:0]} = {1'b0, m[63:0]};
              {in21[32:0],in11[31:0]} = {1'b0,by4[35:0],1'b0,ng5,26'h0};
              {in22[32:0],in12[31:0]} = {ms[50],~ms[50],ms[49:18],1'b0,ng2,12'h000};
           end
           default: begin // 1
              in00[32:0] = {3'b000,ms[50],~ms[50],ms[49:30],ms[29:22]};//Dummy
              in01[32:0] = {1'b0,by1[35:12],8'h00};//Dummy
              in02[32:0] = {1'b0,by2[33:10],8'h00};//Dummy
              {in20[32:0],in10[31:0]} = {1'b0, m[63:0]};
              {in21[32:0],in11[31:0]} = {1'b0,by3[33:0],1'b0,ng5,28'h0};
              {in22[32:0],in12[31:0]} = {1'b0,by4[31:0],1'b0,ng3,30'h0};
           end
         endcase
      end else if(op==`MDF_OP_DIV)begin
         if(y==0) begin
            in00 = {x_signed&sxh[30],sxh[30:0],xl[31]};
            in01 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in02 = {33{sign}};
            if(x_signed) begin
               in10 = {xh[0],xl[31:1]};
            end else begin
               in10 = xl[31:0];
            end
            in11 = ({33{1'b0}}); in12 = ({33{1'b0}});
            in20 = ({33{1'b0}}); in21 = ({33{1'b1}}); in22 = ({33{1'b0}});
            if(plus) begin in0v = 2'b00; in1v = 2'b00; in2v = 2'b00;
            end else begin in0v = 2'b00; in1v = 2'b00; in2v = 2'b00; end
         end else if((i>2)|(i>1)&(~x_signed))begin
            in00 = {x_signed&sxh[29],sxh[29:0],xl[31:30]};
            in01 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in02 = 33'h000000000;
            in10 = {x_signed&sxh[29],sxh[29:0],xl[31:30]};
            in11 = {y[31:0],1'b0}^{33{~plus}};
            in12 = 33'h000000000;
            in20 = {x_signed&sxh[29],sxh[29:0],xl[31:30]};
            in21 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in22 = {y[31:0],1'b0}^{33{~plus}};
            if(plus) begin in0v = 2'b00; in1v = 2'b00; in2v = 2'b00;
            end else begin in0v = 2'b01; in1v = 2'b01; in2v = 2'b11; end
         end else if(i>1)begin
            in00 = {x_signed&sxh[30],sxh[30:0],xl[31]};
            in01 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in02 = {33{sign}};
            in10 = {x_signed&sxh[30],sxh[30:0],xl[31]};
            in11 = {y[31:0],1'b0}^{33{~plus}};
            in12 = {33{sign}};
            in20 = {x_signed&sxh[30],sxh[30:0],xl[31]};
            in21 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in22 = {y[31:0],1'b0}^{33{~plus}};
            if(plus) begin in0v = 2'b00; in1v = 2'b00; in2v = 2'b00;
            end else begin in0v = 2'b01; in1v = 2'b01; in2v = 2'b11; end
//         end else if(i==1)begin
         end else begin
            in00 = {x_signed&sxh[30],sxh[30:0],xl[31]};
            in01 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in02 = {33{sign}};
            in10 = sxh;
            in11 = {{32{1'b0}},(buf0[32]&sign)};
            in12 = ({33{1'b0}});
            in20 = ({33{1'b0}});
            in21 = q^{33{plus}};
            in22 = dq^{33{plus}};
            if(plus) begin in0v = 2'b00; in1v = 2'b00; in2v = 2'b11;
            end else begin in0v = 2'b00; in1v = 2'b00; in2v = 2'b00; end
         end
      end else begin
//      end else if((op==`MDF_OP_FAD)|(op==`MDF_OP_FSB))begin
//      end else if((op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS))begin
         in0v = 2'b00; in1v = 2'b00; in2v = 2'b00;
         in10[32] = 1'b0; in11[32] = 1'b0; in12[32] = 1'b0;
         in00[32] = 1'b0; in01[32] = 1'b0; in02[32] = 1'b0;
         if(expd==10'h200)begin
            if(sgn0^sgn1)begin
               {in20[32:0],in10[31:0],in00[31:0]} =~({1'b0,32'h0,xl[31:0],xh[31:0]});
               {in21[32:0],in11[31:0],in01[31:0]} = ({1'b0,buf2[30:0],buf1[31:0],32'h0});
               {in22[32:0],in12[31:0],in02[31:0]} =  {{33{1'b0}},{32{1'b0}},{31{1'b0}},1'b1};
            end else begin
               {in20[32:0],in10[31:0],in00[31:0]} = ({1'b0,32'h0,xl[31:0],xh[31:0]});
               {in21[32:0],in11[31:0],in01[31:0]} = ({1'b0,buf2[30:0],buf1[31:0],32'h0});
               {in22[32:0],in12[31:0],in02[31:0]} =  {{33{1'b0}},{32{1'b0}},{31{1'b0}},1'b0};
            end
         end else if(expd>=27)begin
            if(sgn0^sgn1)begin
               {in20[32:0],in10[31:0],in00[31:0]} =~({1'b0,xh[31:0],xl[31:0],32'h0});
               {in21[32:0],in11[31:0],in01[31:0]} = ({1'b0,buf2[30:0],buf1[31:0],32'h0}>>27);
               {in22[32:0],in12[31:0],in02[31:0]} =  {{33{1'b0}},{32{1'b0}},{31{1'b0}},1'b1};
            end else begin
               {in20[32:0],in10[31:0],in00[31:0]} = ({1'b0,xh[31:0],xl[31:0],32'h0});
               {in21[32:0],in11[31:0],in01[31:0]} = ({1'b0,buf2[30:0],buf1[31:0],32'h0}>>27);
               {in22[32:0],in12[31:0],in02[31:0]} =  {{33{1'b0}},{32{1'b0}},{31{1'b0}},1'b0};
            end
         end else begin
            if(sgn0^sgn1)begin
               {in20[32:0],in10[31:0],in00[31:0]} =~({1'b0,xh[31:0],xl[31:0],32'h0});
               {in21[32:0],in11[31:0],in01[31:0]} = ({1'b0,buf2[30:0],buf1[31:0],32'h0}>>expd);
               {in22[32:0],in12[31:0],in02[31:0]} =  {{33{1'b0}},{32{1'b0}},{31{1'b0}},1'b1};
            end else begin
               {in20[32:0],in10[31:0],in00[31:0]} = ({1'b0,xh[31:0],xl[31:0],32'h0});
               {in21[32:0],in11[31:0],in01[31:0]} = ({1'b0,buf2[30:0],buf1[31:0],32'h0}>>expd);
               {in22[32:0],in12[31:0],in02[31:0]} =  {{33{1'b0}},{32{1'b0}},{31{1'b0}},1'b0};
            end
         end
      end
   end

   wire [32:0] sum0,sum1,sum2;
   wire [33:0] cry0,cry1,cry2;

   wire        sum64 = ((op==`MDF_OP_MUL)|(op==`MDF_OP_FAD)|(op==`MDF_OP_FSB)|(op==`MDF_OP_FML)|
                        (op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS));

   wire        sum96 =(((op==`MDF_OP_FAD)|(op==`MDF_OP_FSB))|
                       ((op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS))&(i==1));

   csa csa0(.in0(in00[32:0]), .in1(in01[32:0]), .in2(in02[32:0]), .sum(sum0[32:0]), .cry(cry0[33:1]));
   csa csa1(.in0(in10[32:0]), .in1(in11[32:0]), .in2(in12[32:0]), .sum(sum1[32:0]), .cry(cry1[33:1]));
   csa csa2(.in0(in20[32:0]), .in1(in21[32:0]), .in2(in22[32:0]), .sum(sum2[32:0]), .cry(cry2[33:1]));

   assign cry0[0] = in0v[0];
   assign cry1[0] = (sum96) ? cry0[32] : in1v[0];
   assign cry2[0] = (sum64) ? cry1[32] : in2v[0];

   wire [32:0] out0 = sum0[32:0] + {~sum96&cry0[32],cry0[31:0]} +  in0v[1];
   wire [32:0] out1 = sum1[32:0] + {~sum64&cry1[32],cry1[31:0]} + (in1v[1]|(sum96&out0[32]));
   wire [32:0] out2 = sum2[32:0] + {       cry2[32],cry2[31:0]} + (in2v[1]|(sum64&out1[32]));

   always @ (posedge clk) begin
      resp_valid <= 1'b0;
      fop <= `MDF_OP_NOP;
      if(~req_ready) begin
         buf2 <= out2;
         buf1 <= out1;
         if(~fpu_ex[0])begin
            buf0 <= out0;
         end
      end
      if(reset) begin
         i<=0;
         fpu_ex <= 2'b00;
      end else if(req_valid & req_ready) begin // req cycle
         fpu_ex <= 2'b00;
         if(req_op==`MDF_OP_MUL) begin // req cycle MUL
            i<=5;
            xh<=req_in_1;
         end else if(req_op==`MDF_OP_DIV) begin  // req cycle DIV
            i  <= 17;
            q  <= ({32{1'b0}});
            sign <=  req_in_1[31]&req_in_1_signed;
            plus <= (req_in_1[31]&req_in_1_signed)^(req_in_2[31]&req_in_1_signed);
            if(req_in_1_signed) begin
               xh <= ({32{req_in_1[31]}});
               xl <= {req_in_1[30:0],1'b0};
            end else begin
               xh <= ({32{1'b0}});
               xl <= req_in_1[31:0];
            end
            buf2[32] <= ~(req_in_1_signed&req_in_1[31]);
            buf1[32] <= ~(req_in_1_signed&req_in_1[31]);
            buf0[32] <= ~(req_in_1_signed&req_in_1[31]);
         end else if(req_op==`MDF_OP_NOP) begin // req cycle FPU MOV
            resp_valid <= 1'b1;
            buf2[31:0] <= req_in_1[31:0];
         end else if(req_op==`MDF_OP_SGN) begin // req cycle FPU SGN
            resp_valid <= 1'b1;
            case(req_rm)
              3'b000 : buf2[31:0] <= { req_in_2[31],req_in_1[30:0]};
              3'b001 : buf2[31:0] <= {~req_in_2[31],req_in_1[30:0]};
              3'b010 : buf2[31:0] <= {req_in_1[31]^req_in_2[31],req_in_1[30:0]};
            endcase
         end else if((req_op==`MDF_OP_FAD)|(req_op==`MDF_OP_FSB)) begin // req cycle FPU ADD SUB
            resp_valid <= 1'b1;
            {fpu_ex[1:0],buf0[31:0]} <= FAD_TYPE(req_in_1[31:0],req_in_2[31:0],(req_op==`MDF_OP_FSB));
            subn <= 0;

            if(~exps[9])begin
               sgn1 <= req_in_2[31]^(req_op==`MDF_OP_FSB);
               sgn0 <= req_in_1[31];
               expr <= expx+9;
               expd <= exps;
               buf1[32]<=1'b0;
               {xh,xl[31:0]}      <= {1'b0,(req_in_1[30:23]!=8'h00),req_in_1[22:0],23'h0};
               {buf2, buf1[31:0]} <= {1'b0,(req_in_2[30:23]!=8'h00),req_in_2[22:0],23'h0};
            end else begin
               sgn0 <= req_in_2[31]^(req_op==`MDF_OP_FSB);
               sgn1 <= req_in_1[31];
               expr <= expy+9;
               expd <=-exps;
               buf1[32]<=1'b0;
               {buf2, buf1[31:0]} <= {1'b0,(req_in_1[30:23]!=8'h00),req_in_1[22:0],23'h0};
               {xh,xl[31:0]}      <= {1'b0,(req_in_2[30:23]!=8'h00),req_in_2[22:0],23'h0};
            end
         end else if(req_op==`MDF_OP_FML) begin // req cycle FPU MUL
            {fpu_ex[1:0],buf0[31:0]} <= FML_TYPE(req_in_1[31:0],req_in_2[31:0]);

            i<=5;
            sgn0 <= req_in_1[31]^req_in_2[31];
            sgn1 <= req_in_1[31]^req_in_2[31];
            expr <= exps+1;
            xh<={8'h00,(req_in_1[30:23]!=8'h00),req_in_1[22:0]};
         end else if((req_op==`MDF_OP_FMA)|(req_op==`MDF_OP_FNA)|(req_op==`MDF_OP_FMS)|(req_op==`MDF_OP_FNS)) begin // req cycle FPU MADD
            {fpu_ex[1:0],buf0[31:0]} <= FMA_TYPE(req_in_1[31:0],req_in_2[31:0],req_in_3[31:0],
                                                 (req_op==`MDF_OP_FNA)|(req_op==`MDF_OP_FNS), (req_op==`MDF_OP_FMS)|(req_op==`MDF_OP_FNA));

            i<=5;
            xh<={8'h00,(req_in_1[30:23]!=8'h00),req_in_1[22:0]};
            xl<={8'h00,(req_in_3[30:23]!=8'h00),req_in_3[22:0]};
            sgn1 <= req_in_1[31]^req_in_2[31]^(req_op==`MDF_OP_FNA)^(req_op==`MDF_OP_FNS);
            sgn0 <= req_in_3[31]^(req_op==`MDF_OP_FNA)^(req_op==`MDF_OP_FMS);
            if(~exps[9])begin
               expr <= expm+1;
               expd <= exps;
            end else begin
               expr <= expz+1;
               expd <= exps;//save sign
            end
         end
      end else begin
         if(((op==`MDF_OP_MUL)&(i>0))|((op==`MDF_OP_FML)&(i>2))|
            (((op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS))&(i>2))) begin // cont cycle MUL

            ng2 <= (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
            if(i!=2)
              ng5 <= (br5[2:1]==2'b10)|(br5[2:0]==3'b110);
            else
              ng5 <= (br4[2:1]==2'b10)|(br4[2:0]==3'b110);

            if(i==1) resp_valid <= 1'b1;
            i<=i-1;

            xh<={{4{xh[31]&x_signed}},xh[31:4]};
         end else if((op==`MDF_OP_DIV)&(i>0)) begin // cont cycle DIV
            if(y==0) begin // DIV
               resp_valid <= 1'b1;
               i <= 0;
            end else if((i>2)|(i>1)&(~x_signed))begin
               q[31:2] <= q[29:0]|dq;
               xh <= {sxh[29:0],xl[31:30]};
               xl <= {xl[29:0],2'b00};
               i  <= i-1;
            end else if(i>1)begin
               q[31:1] <= q[30:0]|dq;
               xh <= {sxh[30:0],xl[31]};
               xl <= {xl[30:0],1'b0};
               i  <= i-1;
            end else if(i==1)begin
               resp_valid <= 1'b1;
               i  <= i-1;
            end
         end else if((op==`MDF_OP_FML)&(i==2))begin
            {fracr[25:0],guard[30:0]} <= {out2[25:0],out1[31:2],(|out1[1:0])};
            resp_valid <= 1'b1;
            i<=0;
            if((expr==0)|expr[9])begin
               expr <= expr+26;
               subn <= 1'b1;
            end else
              subn <= 1'b0;
         end else if(((op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS))&(i==2))begin
            subn <= 1'b0;
            if(expd[9])begin
               expd <= -expd;
               {xh,xl[31:0]}<={1'b0,xl[31:0],31'h0};
            end else if(expd<32)begin
               expd <= 0;
               {xh,xl[31:0]}<={1'b0,xl[31:0],31'h0}>>expd;
            end else if(expd<55)begin
               expd <= 10'h200;
               {xl,xh[31:0]}<={1'b0,xl[31:0],31'h0}>>(expd-32);
            end else begin
               expd <= 10'h200;
               {xl,xh[31:0]}<={1'b0,xl[31:0],31'h0}>>(55-32);
            end
            i<=i-1;
         end else if(((op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS))&(i==1)) begin // cont cycle FMADD
            {fracr[25:0],guard[30:0]} <= {out2[25:0],out1[31:2],(|out1[1:0])|(|out0[31:0])};
            resp_valid <= 1'b1;
            i<=0;
         end else if((op==`MDF_OP_FAD)|(op==`MDF_OP_FSB)) begin // cont cycle FAD FSB
            {fracr[25:0],guard[30:0]} <= {out2[25:0],out1[31:2],(|out1[1:0])|(|out0[31:0])};
            if(resp_valid) fop <= op;
         end else if(((op==`MDF_OP_FML)|(op==`MDF_OP_FMA)|(op==`MDF_OP_FNA)|(op==`MDF_OP_FMS)|(op==`MDF_OP_FNS))&(resp_valid))begin
            fop <= op;
         end
      end // cont cycle
   end

   function [33:0] FAD_TYPE
     (
      input [31:0] in_1,
      input [31:0] in_2,
      input        op
      );
      begin
         if((in_1[30:23]==8'hff)&(in_1[22:0]!=0))begin
            FAD_TYPE = {2'b11,                               //fpu_ex
                        in_1[31],                            //[31] : sign
                        in_1[30],                            //[30] : exp
                        ~in_1[22]|((in_2[30:23]==8'hff)&~in_2[22]&(in_2[21:0]!=0)), //[29] : Invalid
                        6'h00,                               //[28:23]
                        in_1[22:0]|23'h400000
                        };
         end else if((in_2[30:23]==8'hff)&(in_2[22:0]!=0))begin
            FAD_TYPE = {2'b11,                               //fpu_ex
                        in_2[31],                            //[31] : sign
                        in_2[30],                            //[30] : exp
                        ~in_2[22]|((in_1[30:23]==8'hff)&~in_1[22]&(in_1[21:0]!=0)), //[29] : Invalid
                        6'h00,                               //[28:23]
                        in_2[22:0]|23'h400000
                        };
         end else if((in_1[30:23]==8'hff)&(in_2[30:23]==8'hff))begin
            if(in_1[31]^in_2[31]^op)begin
               FAD_TYPE = {2'b11,                               //fpu_ex
`ifdef RISCV
                           1'b0,                                //[31] : sign
`else
                           1'b1,                                //[31] : sign
`endif
                           1'b1,                                //[30] : exp
                           1'b1,                                //[29] : Invalid
                           6'h00,                               //[28:23]
                           23'h400000
                           };
            end else begin
               FAD_TYPE = {2'b11,                               //fpu_ex
                           in_1[31],                            //[31] : sign
                           in_1[30],                            //[30] : exp
                           7'h00,                               //[29:23]
                           in_1[22:0]
                           };
            end
         end else if(in_1[30:23]==8'hff)begin
            FAD_TYPE = {2'b11,                               //fpu_ex
                        in_1[31],                            //[31] : sign
                        in_1[30],                            //[30] : exp
                        7'h00,                               //[29:23]
                        in_1[22:0]
                        };
         end else if(in_2[30:23]==8'hff)begin
            FAD_TYPE = {2'b11,                               //fpu_ex
                        in_2[31]^op,                         //[31] : sign
                        in_2[30],                            //[30] : exp
                        7'h00,                               //[29:23]
                        in_2[22:0]
                        };
         end else begin
            FAD_TYPE = 33'h0;
         end
      end
   endfunction

   function [33:0] FML_TYPE
     (
      input [31:0] in_1,
      input [31:0] in_2
      );
      begin
         if((in_1[30:23]==8'hff)&(in_1[22:0]!=0))begin
            FML_TYPE = {2'b11,                               //fpu_ex
                        in_1[31],                            //[31] : sign
                        in_1[30],                            //[30] : exp
                        ~in_1[22]|((in_2[30:23]==8'hff)&~in_2[22]&(in_2[21:0]!=0)), //[29] : Invalid
                        6'h00,                               //[28:23]
                        in_1[22:0]|23'h400000
                        };
         end else if((in_2[30:23]==8'hff)&(in_2[22:0]!=0))begin
            FML_TYPE = {2'b11,                               //fpu_ex
                        in_2[31],                            //[31] : sign
                        in_2[30],                            //[30] : exp
                        ~in_2[22]|((in_1[30:23]==8'hff)&~in_1[22]&(in_1[21:0]!=0)), //[29] : Invalid
                        6'h00,                               //[28:23]
                        in_2[22:0]|23'h400000
                        };
         end else if(in_1[30:23]==8'hff)begin
            if(in_2[30:0]==0)begin
               FML_TYPE = {2'b11,                               //fpu_ex
`ifdef RISCV
                           1'b0,                                //[31] : sign
`else
                           1'b1,                                //[31] : sign
`endif
                           1'b1,                                //[30] : exp
                           1'b1,                                //[29] : Invalid
                           6'h00,                               //[28:23]
                           23'h400000
                           };
            end else begin
               FML_TYPE = {2'b11,                               //fpu_ex
                           in_1[31]^in_2[31],                   //[31] : sign
                           in_1[30],                            //[30] : exp
                           7'h00,                               //[29:23]
                           in_1[22:0]
                           };
            end
         end else if(in_2[30:23]==8'hff)begin
            if(in_1[30:0]==0)begin
               FML_TYPE = {2'b11,                               //fpu_ex
`ifdef RISCV
                           1'b0,                                //[31] : sign
`else
                           1'b1,                                //[31] : sign
`endif
                           1'b1,                                //[30] : exp
                           1'b1,                                //[29] : Invalid
                           6'h00,                               //[28:23]
                           23'h400000
                           };
            end else begin
               FML_TYPE = {2'b11,                               //fpu_ex
                           in_2[31]^in_1[31],                   //[31] : sign
                           in_2[30],                            //[30] : exp
                           7'h00,                               //[29:23]
                           in_2[22:0]
                           };
            end
         end else begin
            FML_TYPE = 33'h0;
         end
      end
   endfunction

   function [33:0] FMA_TYPE
     (
      input [31:0] in_1,
      input [31:0] in_2,
      input [31:0] in_3,
      input        opm,
      input        opa
      );
      begin
         if((in_1[30:23]==8'hff)&(in_1[22:0]!=0))begin
            FMA_TYPE = {2'b11,                               //fpu_ex
                        in_1[31],                            //[31] : sign
                        in_1[30],                            //[30] : exp
                        ~in_1[22]|((in_2[30:23]==8'hff)&~in_2[22]&(in_2[21:0]!=0))
                                 |((in_3[30:23]==8'hff)&~in_3[22]&(in_3[21:0]!=0)), //[29] : Invalid
                        6'h00,                               //[28:23]
                        in_1[22:0]|23'h400000
                        };
         end else if((in_2[30:23]==8'hff)&(in_2[22:0]!=0))begin
            FMA_TYPE = {2'b11,                               //fpu_ex
                        in_2[31],                            //[31] : sign
                        in_2[30],                            //[30] : exp
                        ~in_2[22]|((in_1[30:23]==8'hff)&~in_1[22]&(in_1[21:0]!=0))
                                 |((in_3[30:23]==8'hff)&~in_3[22]&(in_3[21:0]!=0)), //[29] : Invalid
                        6'h00,                               //[28:23]
                        in_2[22:0]|23'h400000
                        };
         end else if(((in_1[30:23]==8'hff)&(in_2[30:0]==0))|
                     ((in_2[30:23]==8'hff)&(in_1[30:0]==0)))begin
            FMA_TYPE = {2'b11,                               //fpu_ex
`ifdef RISCV
                           1'b0,                                //[31] : sign
`else
                           1'b1,                                //[31] : sign
`endif
                        1'b1,                                //[30] : exp
                        1'b1,                                //[29] : Invalid
                        6'h00,                               //[28:23]
                        23'h400000
                        };
         end else if((in_3[30:23]==8'hff)&(in_3[22:0]!=0))begin
            FMA_TYPE = {2'b11,                               //fpu_ex
                        in_3[31],                            //[31] : sign
                        in_3[30],                            //[30] : exp
                        ~in_3[22]|((in_1[30:23]==8'hff)&~in_1[22]&(in_1[21:0]!=0))
                                 |((in_2[30:23]==8'hff)&~in_2[22]&(in_2[21:0]!=0)), //[29] : Invalid
                        6'h00,                               //[28:23]
                        in_3[22:0]|23'h400000
                        };
         end else if(((in_1[30:23]==8'hff)|(in_2[30:23]==8'hff))&(in_3[30:23]==8'hff))begin
            if(in_1[31]^in_2[31]^opm!=in_3[31]^opa)begin
               FMA_TYPE = {2'b11,                               //fpu_ex
`ifdef RISCV
                           1'b0,                                //[31] : sign
`else
                           1'b1,                                //[31] : sign
`endif
                           1'b1,                                //[30] : exp
                           1'b1,                                //[29] : Invalid
                           6'h00,                               //[28:23]
                           23'h400000
                           };
            end else begin
               FMA_TYPE = {2'b11,                               //fpu_ex
                           in_3[31],                            //[31] : sign
                           in_3[30]^opa,                        //[30] : exp
                           7'h00,                               //[29:23]
                           in_3[22:0]
                           };
            end
         end else if(in_1[30:23]==8'hff)begin
            FMA_TYPE = {2'b11,                               //fpu_ex
                        in_1[31]^in_2[31]^opm,               //[31] : sign
                        in_1[30],                            //[30] : exp
                        7'h00,                               //[29:23]
                        in_1[22:0]
                        };
         end else if(in_2[30:23]==8'hff)begin
            FMA_TYPE = {2'b11,                               //fpu_ex
                        in_2[31]^in_1[31]^opm,               //[31] : sign
                        in_2[30],                            //[30] : exp
                        7'h00,                               //[29:23]
                        in_2[22:0]
                        };
         end else if(in_3[30:23]==8'hff)begin
            FMA_TYPE = {2'b11,                               //fpu_ex
                        in_3[31]^opa,                        //[31] : sign
                        in_3[30],                            //[30] : exp
                        7'h00,                               //[29:23]
                        in_3[22:0]
                        };
         end else if((in_1[30:0]==0)|(in_2[30:0]==0))begin
            if(in_3[30:0]==0)begin
               FMA_TYPE = {2'b01,                               //fpu_ex
                           (in_3[31]^opa)&(in_1[31]^in_2[31]^opm),  //[31] : sign
                           in_3[30:23],                         //[30:23] : exp
                           in_3[22:0]
                           };
            end else begin
               FMA_TYPE = {2'b01,                               //fpu_ex
                           in_3[31]^opa,                        //[31] : sign
                           in_3[30:23],                         //[30:23] : exp
                           in_3[22:0]
                           };
            end
         end else begin
            FMA_TYPE = 33'h0;
         end
      end
   endfunction

endmodule

module booth
  (
   input             i,
   input             y_signed,
   input [2:0]       br,
   input [31:0]      y,
   output reg [35:0] by
   );

   wire              S = ((br==3'b000)|(br==3'b111)) ? 1'b0 : (y[31]&y_signed)^br[2] ;

   always @(*) begin
      case(br)
        3'b000: by[32:0] =  {33{1'b0}};
        3'b001: by[32:0] =  {y[31]&y_signed,y[31:0]};
        3'b010: by[32:0] =  {y[31]&y_signed,y[31:0]};
        3'b011: by[32:0] =  {y[31:0],1'b0};
        3'b100: by[32:0] = ~{y[31:0],1'b0};
        3'b101: by[32:0] = ~{y[31]&y_signed,y[31:0]};
        3'b110: by[32:0] = ~{y[31]&y_signed,y[31:0]};
        3'b111: by[32:0] =  {33{1'b0}};
      endcase
      if(i) by[35:33] = {2'b01,~S};
      else  by[35:33] = {~S,S,S};
   end
endmodule

module csa
  #(
    parameter w = 33
    )
   (
    input [w-1:0]  in0,
    input [w-1:0]  in1,
    input [w-1:0]  in2,
    output [w-1:0] sum,
    output [w:1]   cry
    );

   assign sum = in0^in1^in2;
   assign cry = (in0&in1)|(in1&in2)|(in2&in0);

endmodule
