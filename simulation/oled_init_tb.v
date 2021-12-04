`timescale 1ns/1ns //仿真单位为1ns，精度为1ns

module oled_init_tb();

reg clk;
reg rst_n;
reg write_done;
wire oled_rst;
wire oled_dc;
wire [7:0] data;
wire ena_write;
wire init_done;

oled_init oled_init_inst(
	.clk(clk),
	.rst_n(rst_n),
	.write_done(write_done),
	.oled_rst(oled_rst),
	.oled_dc(oled_dc),
	.data(data),
	.ena_write(ena_write),
	.init_done(init_done)
);

initial begin
	#0	clk = 0;
		rst_n = 0;
		write_done = 1;
	#20 rst_n = 1;
end

always #5 clk = ~clk;

endmodule