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

   reg               rnd;

   always @(posedge clk)begin   
      if(reset)begin
         a <= 0;
         yl <= {2'b01,{28{1'b0}}};
         zl <= 0;
         expr <= (x[30:23]-1)/2+64;
         if(x[23])begin
            xl <= {1'b0,1'b1,x[22:0],5'h00};
         end else begin
            xl <= {1'b0,1'b1,x[22:0],6'h00};
         end
         i  <= 12;
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
         rslt[31] <= x[31];
         rslt[30:0] <= {expr[7:0],a[27:5]}+rnd;
         i <= i-1;
      end
   end

   reg g,r,s;
   always @(*)begin
//      if(sa[28]==1'b1)begin
         g = sa[5];
         r = sa[4];
         s = (|sa[3:0])|(|sx);
//      end else begin
//         g = rslt[4];
//         r = sa[3];
//         s = (|sa[2:0])|(|sx);
//      end
      rnd = r&s | g&r;
   end
endmodule
