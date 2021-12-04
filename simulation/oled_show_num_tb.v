`timescale 1ns/1ns //仿真单位为1ns，精度为1ns

module oled_show_num_tb();

reg clk;
reg rst_n;
reg [15:0]num;
reg [2:0] len;
reg [4:0]font_size;
reg [6:0]x;
reg [5:0]y;
reg en_ram_wr;

wire wren;
wire [9:0] wraddress;
wire [7:0] data;

oled_show_num oled_show_num_inst(
	.clk(clk),
	.rst_n(rst_n),
	.num(num),
	.len(len),
	.font_size(font_size),
	.x(x),
	.y(y),
	.en_ram_wr(en_ram_wr),
	.wren(wren),
	.wraddress(wraddress),
	.data(data)
);

initial begin
	#0	clk = 0;
		rst_n = 0;
		num = 16'd123;
		len = 3'd3;
		font_size = 5'd12;
		x = 7'd0;
		y = 6'd3;
		en_ram_wr = 1'b1;
		
	#20 rst_n = 1;
end


always #5 clk = ~clk;


endmodule