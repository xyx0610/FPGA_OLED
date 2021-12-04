`timescale 1ns/1ns //仿真单位为1ns，精度为1ns

module oled_drive_tb();

reg clk;
reg rst_n;
wire oled_rst;
wire oled_dc;
wire oled_sclk;
wire oled_mosi;
wire oled_cs;

oled_drive oled_drive_inst(
	.clk(clk),
	.rst_n(rst_n),
	.oled_rst(oled_rst),
	.oled_dc(oled_dc),
	.oled_sclk(oled_sclk),
	.oled_mosi(oled_mosi)
);

initial begin
	#0	clk = 0;
		rst_n = 0;
	#20 rst_n = 1;
end

always #5 clk = ~clk;

endmodule