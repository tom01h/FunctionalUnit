module div17
  (
   input             clk,
   input             reset,
   input             x_signed,
   input             y_signed,
   input [31:0]      x,
   input [31:0]      y,
   output reg [31:0] q,
   output [31:0]     r
   );

   reg [31:0]    xh, xl;
   reg [32:0]    tmp1, tmp2, tmp3;
   wire          sign = x[31]&x_signed;
   wire          plus = (x[31]&x_signed)^(y[31]&y_signed);
   integer       i;

   wire [31:0]   sxh;
   assign sxh = (sign!=tmp1[32]) ? xh :
                (sign!=tmp2[32]) ? tmp1[31:0] :
                (sign!=tmp3[32]) ? tmp2[31:0] :
                tmp3[31:0];

   wire [1:0]    dq;
   assign dq  = (sign!=tmp1[32]) ? 0 :
                (sign!=tmp2[32]) ? 1 :
                (sign!=tmp3[32]) ? 2 :
                3;

   always @(posedge clk)begin   
      if(reset)begin
         q  <= ({32{1'b0}});
         if(x_signed) begin
            xh <= ({32{sign}});
            xl <= {x[30:0],1'b0};
         end else begin
            xh <= ({32{sign}});
            xl <= x[31:0];
         end
         i  <= 16;
         tmp3[32] <= ~sign;
         tmp2[32] <= ~sign;
         tmp1[32] <= ~sign;
      end else if((i>1)|(i>0)&(~x_signed)&(~y_signed))begin
         q[31:2] <= q[29:0]|dq;
         xh <= {sxh[29:0],xl[31:30]};
         xl <= {xl[29:0],2'b00};
         i  <= i-1;
         if(plus)begin
            tmp1 <= {x_signed&sxh[29],sxh[29:0],xl[31:30]}+{y_signed&y[31],y[31:0]};
            tmp2 <= {x_signed&sxh[29],sxh[29:0],xl[31:30]}                         +{y[31:0],1'b0};
            tmp3 <= {x_signed&sxh[29],sxh[29:0],xl[31:30]}+{y_signed&y[31],y[31:0]}+{y[31:0],1'b0};
         end else begin
            tmp1 <= {x_signed&sxh[29],sxh[29:0],xl[31:30]}-{y_signed&y[31],y[31:0]};
            tmp2 <= {x_signed&sxh[29],sxh[29:0],xl[31:30]}                         -{y[31:0],1'b0};
            tmp3 <= {x_signed&sxh[29],sxh[29:0],xl[31:30]}-{y_signed&y[31],y[31:0]}-{y[31:0],1'b0};
         end
      end else if(i>0)begin
         q[31:1] <= q[30:0]|dq;
         xh <= {sxh[30:0],xl[31]};
         xl <= {xl[30:0],1'b0};
         i  <= i-1;
         if(plus)begin
            tmp1 <= {x_signed&sxh[30],sxh[30:0],xl[31]}+{y_signed&y[31],y[31:0]}-sign;
            tmp2 <= {x_signed&sxh[30],sxh[30:0],xl[31]}                         +{y[31:0],1'b0}-sign;
            tmp3 <= {x_signed&sxh[30],sxh[30:0],xl[31]}+{y_signed&y[31],y[31:0]}+{y[31:0],1'b0};
         end else begin
            tmp1 <= {x_signed&sxh[30],sxh[30:0],xl[31]}-{y_signed&y[31],y[31:0]}-sign;
            tmp2 <= {x_signed&sxh[30],sxh[30:0],xl[31]}                         -{y[31:0],1'b0}-sign;
            tmp3 <= {x_signed&sxh[30],sxh[30:0],xl[31]}-{y_signed&y[31],y[31:0]}-{y[31:0],1'b0};
         end
      end else if(i==0)begin
         if(plus)
           q <= -q-dq;
         else
           q <= q+dq;
         if(tmp1[32]&sign)
           xh <= sxh+1;
         else
           xh <= sxh;
         i <= i-1;
      end
   end
   assign r = xh;

endmodule
