`include "vscale_md_constants.vh"

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

module mul5
  (
   input         clk,
   input         reset,
   input         req,
   input         x_signed,
   input         y_signed,
   input [31:0]  x,
   input [31:0]  y,
   output [31:0] mh,
   output [31:0] ml
   );

/* vscale_mul_div mul_div
  (
   .clk(clk),
   .reset(reset),
   .req_valid(req),
   .req_ready(),
   .req_in_1_signed(x_signed),
   .req_in_2_signed(y_signed),
   .req_op(`MD_OP_MUL),
   .req_out_sel(`MD_OUT_LO),
   .req_in_1(x),
   .req_in_2(y),
   .resp_valid(),
   .resp_result(ml)
   );

   assign mh = mul_div.m[63:32];
*/
   reg [46:14]   ms;
   reg [64:0]    m;

   reg [31:0]    sy;
   
   integer       i;

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
   wire          ng16 = 1'b0;

   booth booth0(.i(0), .x_signed(x_signed), .br(br0), .x(x), .bx(bx0));
   booth booth1(.i(1), .x_signed(x_signed), .br(br1), .x(x), .bx(bx1));
   booth booth2(.i(1), .x_signed(x_signed), .br(br2), .x(x), .bx(bx2));
   booth booth3(.i(1), .x_signed(x_signed), .br(br3), .x(x), .bx(bx3));
   booth booth4(.i(1), .x_signed(x_signed), .br(br4), .x(x), .bx(bx4));
   booth booth5(.i(1), .x_signed(x_signed), .br(br5), .x(x), .bx(bx5));

   always @ (posedge clk) begin
      if(reset|req) begin
         i<=0;
         sy<=y;
      end else begin
         ng2 <= (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
         if(i!=3)
           ng5 <= (br5[2:1]==2'b10)|(br5[2:0]==3'b110);
         else
           ng5 <= (br4[2:1]==2'b10)|(br4[2:0]==3'b110);
         case(i)
           0: begin
              ms[46:22] <= {3'b000,bx0[35:14]}+{1'b0,bx1[35:12]}+{1'b0,bx2[33:10]} + {ng16,{18{1'b0}}};
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
           end
           4: begin
              m[64:0] <= m[64:0]+
                         {1'b0,bx3[33:0],1'b0,ng5,28'h0}+
                         {1'b0,bx4[31:0],1'b0,ng3,30'h0};
           end
         endcase
         i<=i+1;
         if(y_signed)
           sy<={{4{sy[31]}},sy[31:4]};
         else
           sy<={4'h0       ,sy[31:4]};
      end
   end

   assign mh = m[63:32];
   assign ml = m[31:0];

endmodule
