`timescale 1ns/1ns //仿真单位为1ns，精度为1ns

module spi_writebyte_tb ( );

	reg clk;
	reg ena;
	reg rst;
	reg [7:0]data;
	wire sclk;
	wire mosi;
	wire done;
	
	spi_writebyte spi_writebyte_inst(
		.clk(clk),
		.ena_write(ena),
		.rst_n(rst),
		.data(data),
		.sclk(sclk),
		.mosi(mosi),
		.write_done(done)
	);
	
	initial begin
		#0 	clk = 0;//clk初始为0
				data = 8'b11010011;
				ena = 0;
				rst = 0;
				
		#20	ena = 1;
				rst = 1;
	end
	
	always #5 clk = ~clk;//每5个时钟单位 clk取反一次
		
endmodule