module cordic
  (
   input                    clk,
   input                    reset,
   input                    req,
   input                    op,
   input                    x_signed,
   input                    y_signed,
   input [31:0]             x,
   input [31:0]             y,
   output reg signed [32:0] xn,
   output reg signed [32:0] yn,
   output reg signed [31:0] ri
   );

   reg [4:0]     i;

   reg [31:0]     ai;

   always @ (*) begin
      casez(25-i)
        0: ai = 32'h3243f6a8;
        1: ai = 32'h1dac6705;
        2: ai = 32'h0fadbafc;
        3: ai = 32'h07f56ea6;
        4: ai = 32'h03feab76;
        5: ai = 32'h01ffd55b;
        6: ai = 32'h00fffaaa;
        7: ai = 32'h007fff55;
        8: ai = 32'h003fffea;
        9: ai = 32'h001ffffd;
        10: ai = 32'h000fffff;
        11: ai = 32'h0007ffff;
        12: ai = 32'h0003ffff;
        13: ai = 32'h0001ffff;
        14: ai = 32'h0000ffff;
        15: ai = 32'h00007fff;
        16: ai = 32'h00003fff;
        17: ai = 32'h00001fff;
        18: ai = 32'h00000fff;
        19: ai = 32'h000007ff;
        20: ai = 32'h000003ff;
        21: ai = 32'h000001ff;
        22: ai = 32'h000000ff;
        23: ai = 32'h0000007f;
        24: ai = 32'h0000003f;
        default: ai = 32'h0000001f;
      endcase
   end
   
   always @ (posedge clk) begin
      if(req) begin
         i <= 25;
         if(~op)
           ri <= x;
         else
           ri <= 0;
         xn <= x;  //arctan
         yn <= y;  //arctan
      end else if((i==25)&~op) begin
         ri <= ri - ai;
         xn <= 32'h26dd3b6a;
         yn <= 32'h26dd3b6a;
         i <= i-1;
      end else if(i>0) begin
         if((ri[31]&~op)|(~yn[32]&op))begin
            ri <= ri + ai;
            xn <= xn + (yn>>>(25-i));
            yn <= yn - (xn>>>(25-i));
         end else begin
            ri <= ri - ai;
            xn <= xn - (yn>>>(25-i));
            yn <= yn + (xn>>>(25-i));
         end
         i <= i-1;
      end
   end
endmodule
