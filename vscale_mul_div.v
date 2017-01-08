`include "vscale_md_constants.vh"

module vscale_mul_div
  (
   input         clk,
   input         reset,
   input         req_valid,
   output        req_ready,
   input         req_in_1_signed,
   input         req_in_2_signed,
   input         req_op,
   input         req_out_sel,
   input [31:0]  req_in_1,
   input [31:0]  req_in_2,
   output reg    resp_valid,
   output [31:0] resp_result
   );

   reg           x_signed;
   reg           y_signed;
   reg [31:0]    x;
   reg [31:0]    y;
   reg           out_sel;
   reg           op;
   reg [31:0]    xh, xl;

   always @(posedge clk) begin
      if(req_valid & req_ready) begin
         x_signed <= req_in_1_signed;
         y_signed <= req_in_2_signed;
         x <= req_in_1;
         y <= req_in_2;
         out_sel <= req_out_sel;
         op <= req_op;
      end
   end

   reg [4:0]     i;
   reg [32:0]    buf0,buf1,buf2;
   assign resp_result = (out_sel==`MD_OUT_HI) ? buf2[31:0] : buf1[31:0];
   assign req_ready = (i == 5'b00000);

///////////////// MUL Only vvvvvvvvvvvvvvvvvvvvvvvvvvvv
   wire [2:0]    br0 = {xh[1:0],1'b0};
   wire [2:0]    br1 = xh[3:1];
   wire [2:0]    br2 = xh[5:3];
   wire [2:0]    br3 = xh[19:17];
   wire [2:0]    br4 = xh[21:19];
   wire [2:0]    br5 = xh[23:21];

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

   always @ (*) begin
      if(op==`MD_OP_MUL)begin
         in0v = 2'b00;
         in1v = 2'b00;
         in2v = 2'b00;
         in01[32] = 1'b0; in11[32] = 1'b0; in21[32] = 1'b0;
         case(i)
           5: begin
              in00[32:0] = {3'b000,by0[35:18],ms[33:22]};
              in01[32:0] = {1'b0,by1[35:16],12'h000};
              in02[32:0] = {1'b0,by2[33:14],12'h000};
              {in20[32:0],in10[31:0]} = {3'b000,by3[35:0],             by0[17:0]               ,m[11:4]};
              {in21[32:0],in11[31:0]} = {1'b0,by4[35:0],1'b0,ng3,      by1[15:0],1'b0,ng0      ,8'h00};
              {in22[32:0],in12[31:0]} = {1'b0,by5[33:0],1'b0,ng4,2'b00,by2[13:0],1'b0,ng1,2'b00,8'h00};
           end
           4,3: begin
              in00[32:0] = {3'b000,ms[50],~ms[50],ms[49:34],ms[33:22]};
              in01[32:0] = {1'b0,by1[35:16],12'h000};
              in02[32:0] = {1'b0,by2[33:14],12'h000};
              {in20[32:0],in10[31:0]} = {3'b000, m[64], ~m[64], m[63:12]                       ,m[11:4]};
              {in21[32:0],in11[31:0]} = {1'b0,by4[35:0],1'b0,ng5,      by1[15:0],1'b0,ng2      ,8'h00};
              {in22[32:0],in12[31:0]} = {1'b0,by5[33:0],1'b0,ng4,2'b00,by2[13:0],1'b0,ng1,2'b00,8'h00};
           end
           2: begin
              in00[32:0] = {3'b000,ms[50],~ms[50],ms[49:34],ms[33:22]};
              in01[32:0] = {1'b0,by1[35:16],12'h000};
              in02[32:0] = {1'b0,by2[33:14],12'h000};
              {in20[32:0],in10[31:0]} = {1'b0, m[63:8]                                          ,m[7:0]};
              {in21[32:0],in11[31:0]} = {1'b0,by4[31:0],1'b0,ng5,  by1[15:0],1'b0,ng2      ,4'h0,8'h00};
              {in22[32:0],in12[31:0]} = {           1'b0,ng4,2'b00,by2[13:0],1'b0,ng1,2'b00,4'h0,8'h00};
           end
           1: begin
              in00[32:0] = {3'b000,ms[50],~ms[50],ms[49:34],ms[33:22]};
              in01[32:0] = {1'b0,by1[35:16],12'h000};
              in02[32:0] = {1'b0,by2[33:14],12'h000};
              {in20[32:0],in10[31:0]} = {1'b0, m[63:0]};
              {in21[32:0],in11[31:0]} = {1'b0,ms[50],~ms[50],ms[49:18],1'b0,ng2,16'h0000};
              {in22[32:0],in12[31:0]} = 32'h00000000;
           end
           default: begin
              in00[32:0] = {3'b000,ms[50],~ms[50],ms[49:34],ms[33:22]};
              in01[32:0] = {1'b0,by1[35:16],12'h000};
              in02[32:0] = {1'b0,by2[33:14],12'h000};
              {in20[32:0],in10[31:0]} = {1'b0, m[63:0]};
              {in21[32:0],in11[31:0]} = 32'h00000000;
              {in22[32:0],in12[31:0]} = 32'h00000000;
           end
         endcase
      end else begin // DIV
         if(y==0) begin
            in00 = {x_signed&sxh[30],sxh[30:0],xl[31]};
            in01 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in02 = {33{sign}};
            if(x_signed) begin
               in10 = {xh[0],xl[31:1]};
            end else begin
               in10 = xl[31:0];
            end
            in11 = ({33{1'b0}});
            in12 = ({33{1'b0}});
            in20 = ({33{1'b0}});
            in21 = ({33{1'b1}});
            in22 = ({33{1'b0}});
            if(plus) begin
               in0v = 2'b00;
               in1v = 2'b00;
               in2v = 2'b00;
            end else begin
               in0v = 2'b00;
               in1v = 2'b00;
               in2v = 2'b00;
            end
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
            if(plus) begin
               in0v = 2'b00;
               in1v = 2'b00;
               in2v = 2'b00;
            end else begin
               in0v = 2'b01;
               in1v = 2'b01;
               in2v = 2'b11;
            end
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
            if(plus) begin
               in0v = 2'b00;
               in1v = 2'b00;
               in2v = 2'b00;
            end else begin
               in0v = 2'b01;
               in1v = 2'b01;
               in2v = 2'b11;
            end
         end else if(i==1)begin
            in00 = {x_signed&sxh[30],sxh[30:0],xl[31]};
            in01 = {y_signed&y[31],y[31:0]}^{33{~plus}};
            in02 = {33{sign}};
            in10 = sxh;
            in11 = {{32{1'b0}},(buf0[32]&sign)};
            in12 = ({33{1'b0}});
            in20 = ({33{1'b0}});
            in21 = q^{33{plus}};
            in22 = dq^{33{plus}};
            if(plus) begin
               in0v = 2'b00;
               in1v = 2'b00;
               in2v = 2'b11;
            end else begin
               in0v = 2'b00;
               in1v = 2'b00;
               in2v = 2'b00;
            end
         end
      end
   end

   wire [32:0] sum0,sum1,sum2;
   wire [33:0] cry0,cry1,cry2;

   wire        sum64 = (op==`MD_OP_MUL);

   csa csa0(.in0(in00[32:0]), .in1(in01[32:0]), .in2(in02[32:0]), .sum(sum0[32:0]), .cry(cry0[33:1]));
   csa csa1(.in0(in10[32:0]), .in1(in11[32:0]), .in2(in12[32:0]), .sum(sum1[32:0]), .cry(cry1[33:1]));
   csa csa2(.in0(in20[32:0]), .in1(in21[32:0]), .in2(in22[32:0]), .sum(sum2[32:0]), .cry(cry2[33:1]));

   assign cry0[0] = in0v[0];
   assign cry1[0] = in1v[0];
   assign cry2[0] = (sum64) ? cry1[32] : in2v[0];

   wire [32:0] out0 = sum0[32:0] + {       cry0[32],cry0[31:0]} +  in0v[1];
   wire [32:0] out1 = sum1[32:0] + {~sum64&cry1[32],cry1[31:0]} +  in1v[1];
   wire [32:0] out2 = sum2[32:0] + {       cry2[32],cry2[31:0]} + (in2v[1]|(sum64&out1[32]));

   always @ (posedge clk) begin
      resp_valid <= 1'b0;
      buf2 <= out2;
      buf1 <= out1;
      buf0 <= out0;
      if(reset) begin
         i<=0;
      end else if(req_valid & req_ready) begin
         if(req_op==`MD_OP_MUL) begin // MUL
            i<=5;
            xh<=req_in_1;
         end else begin  // DIV
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
         end
      end else if((op==`MD_OP_MUL)&(i>0)) begin // MUL
         ng2 <= (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
         ng5 <= (br5[2:1]==2'b10)|(br5[2:0]==3'b110);
         if(i==1)
           resp_valid <= 1'b1;
         i<=i-1;
         if(x_signed)
           xh<={{4{xh[31]}},xh[31:4]};
         else
           xh<={4'h0       ,xh[31:4]};
      end else if(y==0) begin // DIV
         if(i>0)
           resp_valid <= 1'b1;
         else
           resp_valid <= 1'b0;
         i <= 0;
      end else if((i>2)|(i>1)&(~x_signed))begin // DIV
         q[31:2] <= q[29:0]|dq;
         xh <= {sxh[29:0],xl[31:30]};
         xl <= {xl[29:0],2'b00};
         i  <= i-1;
      end else if(i>1)begin // DIV
         q[31:1] <= q[30:0]|dq;
         xh <= {sxh[30:0],xl[31]};
         xl <= {xl[30:0],1'b0};
         i  <= i-1;
      end else if(i==1)begin
         resp_valid <= 1'b1;
         i  <= i-1;
      end
   end

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
