`timescale 1ns/1ns //仿真单位为1ns，精度为1ns

module ram_read_tb();

reg clk;
reg rst_n;
wire write_done;
reg init_done;
wire [7:0]ram_data;
wire rden;
wire[9:0] rdaddress;
wire ena_write;
wire oled_dc;
wire[7:0] data;

wire wren;
wire [9:0] wraddress;
wire [7:0] wrdata;

wire oled_sclk;
wire oled_mosi;

ram_read ram_read_inst(
	.clk(clk),
	.rst_n(rst_n),
	.write_done(write_done),
	.init_done(init_done),
	.rden(rden),
	.rdaddress(rdaddress),
	.ena_write(ena_write),
	.oled_dc(oled_dc),
	.ram_data(ram_data),
	.data(data)
);

ram_write ram_write_inst(
	.clk(clk),
	.rst_n(rst_n),
	.init_done(1'b1),
	.wren(wren),
	.wraddress(wraddress),
	.data(wrdata)
);

ram_show ram_show_inst(
	.clock(clk),
	.aclr(1'b0),
	.data(wrdata),
	.rdaddress(rdaddress),
	.rden(rden),
	.wraddress(wraddress),
	.wren(wren),
	.q(ram_data)
);

//spi传输模块
spi_writebyte spi_writebyte_inst(
	.clk(clk),
	.rst_n(rst_n),
	.ena_write(ena_write),
	.data(data),
	.sclk(oled_sclk),
	.mosi(oled_mosi),
	.write_done(write_done)
);

initial begin
	#0 	clk = 0;
			rst_n = 0;
			init_done = 1;
	
	#20 rst_n = 1;

end

always #5 clk = ~clk;

endmodule