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
   input         x_signed,
   input         y_signed,
   input [31:0]  x,
   input [31:0]  y,
   output [31:0] mh,
   output [31:0] ml
   );

   reg [50:18]   ms;
   reg [64:0]    m;

   reg [31:0]    sy;
   
   integer       i;

   wire [2:0]    br0 = {sy[1:0],1'b0};
   wire [2:0]    br1 = sy[3:1];
   wire [2:0]    br2 = sy[5:3];
   wire [2:0]    br3 = sy[19:17];
   wire [2:0]    br4 = sy[21:19];
   wire [2:0]    br5 = sy[23:21];

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

   booth booth0(.i(0), .x_signed(x_signed), .br(br0), .x(x), .bx(bx0));
   booth booth1(.i(1), .x_signed(x_signed), .br(br1), .x(x), .bx(bx1));
   booth booth2(.i(1), .x_signed(x_signed), .br(br2), .x(x), .bx(bx2));
   booth booth3(.i(1), .x_signed(x_signed), .br(br3), .x(x), .bx(bx3));
   booth booth4(.i(1), .x_signed(x_signed), .br(br4), .x(x), .bx(bx4));
   booth booth5(.i(1), .x_signed(x_signed), .br(br5), .x(x), .bx(bx5));

   always @ (posedge clk) begin
      if(reset) begin
         i<=0;
         sy<=y;
      end
//      else if (i>10)
//        $finish;
      else begin
         ng2 <= (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
         ng5 <= (br5[2:1]==2'b10)|(br5[2:0]==3'b110);
         case(i)
           0: begin
              ms[50:30] <= {3'b000,bx0[35:18]}+{1'b0,bx1[35:16]}+{1'b0,bx2[33:14]};
              ms[29:18] <= ms[33:22];
              m[64:8] <= {3'b000,bx3[35:0],            bx0[17:0]}+
                         {1'b0,bx4[35:0],1'b0,ng3,      bx1[15:0],1'b0,ng0}+
                         {1'b0,bx5[33:0],1'b0,ng4,2'b00,bx2[13:0],1'b0,ng1,2'b00};
              m[7:0]  <= m[11:4];
           end
           1,2: begin
              ms[50:30] <= {3'b000,ms[50],~ms[50],ms[49:34]}+{1'b0,bx1[35:16]}+{1'b0,bx2[33:14]};
              ms[29:18] <= ms[33:22];
              m[64:8] <= {3'b000, m[64], ~m[64], m[63:12]}+
                         {1'b0,bx4[35:0],1'b0,ng5,      bx1[15:0],1'b0,ng2}+
                         {1'b0,bx5[33:0],1'b0,ng4,2'b00,bx2[13:0],1'b0,ng1,2'b00};
              m[7:0]  <= m[11:4];
           end
           3: begin
              ms[50:30] <= {3'b000,ms[50],~ms[50],ms[49:34]}+{1'b0,bx1[35:16]}+{1'b0,bx2[33:14]};
              ms[29:18] <= ms[33:22];

              m[64:8] <= {1'b0, m[63:8]}+
                         {1'b0,bx4[31:0],1'b0,ng5,  bx1[15:0],1'b0,ng2      ,4'h0}+
                         {           1'b0,ng4,2'b00,bx2[13:0],1'b0,ng1,2'b00,4'h0};
              m[7:0]  <= m[7:0];
           end
           4: begin
              m[64:0] <= {1'b0,m[63:0]}+{ms[50],~ms[50],ms[49:18],1'b0,ng2,16'h00000};
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
