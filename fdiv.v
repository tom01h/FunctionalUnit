module fdiv
  (
   input         clk,
   input         reset,
   input         req,
   input [31:0]  x,
   input [31:0]  y,
   output [31:0] rslt,
   output [4:0]  flag
   );

   reg [31:0]    xl;
   reg [32:0]    tmp1, tmp2, tmp3;
   integer       i;

   wire [31:0]   sx;
   assign sx = (tmp1[32]) ? xl :
               (tmp2[32]) ? tmp1[31:0] :
               (tmp3[32]) ? tmp2[31:0] :
               tmp3[31:0];

   wire [1:0]    dq;
   assign dq = (tmp1[32]) ? 0 :
               (tmp2[32]) ? 1 :
               (tmp3[32]) ? 2 :
               3;

   reg          rnd,g,r,s;

   always @(posedge clk)begin   
      if(reset)begin
         rslt <= ({32{1'b0}});
         xl <= {2'b01,x[22:0]};
         i  <= 14;
         tmp1[32] <= 1'b1;
      end else if(i>0)begin
         rslt[31:2] <= rslt[29:0]|dq;
         xl <= {sx[29:0],2'b00};
         i  <= i-1;
         tmp1 <= {sx[29:0],2'b00}-{2'b01,y[22:0],2'b00};
         tmp2 <= {sx[29:0],2'b00}                      -{2'b01,y[22:0],3'b000};
         tmp3 <= {sx[29:0],2'b00}-{2'b01,y[22:0],2'b00}-{2'b01,y[22:0],3'b000};
      end else if(i==0)begin
         if(rslt[26]==1'b1)begin
            rslt[22:0] <= rslt[25:3] + rnd;
            rslt[31] <= x[31]^y[31];
            rslt[30:23] <= x[30:23]-y[30:23]+127;
         end else begin
            rslt[22:0] <= rslt[24:2] + rnd;
            rslt[31] <= x[31]^y[31];
            rslt[30:23] <= x[30:23]-y[30:23]+126;
         end
         i <= i-1;
      end
   end

   always @(*)begin
      if(rslt[26]==1'b1)begin
         g = rslt[3];
         r = rslt[2];
         s = (|dq[1:0])|(|sx);
      end else begin
         g = rslt[2];
         r = dq[1];
         s = ( dq[0])  |(|sx);
      end
      rnd = r&s | g&r;
   end
endmodule
