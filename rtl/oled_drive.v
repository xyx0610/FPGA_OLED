module oled_drive(
	input clk,			//时钟信号 50MHz
	input rst_n,		//按键复位
	input ram_rst,		//ram复位 高电平复位
	input change_show,//用来切换显示静态数据还是动态数据
	input [2:0] ascll_add,//ascll字符输入 用来动态显示
	input add_dec_x,	//按键控制显示的x坐标加减
	input add_dec_y,	//按键控制显示的y坐标加减
	output oled_rst,	//oled res 复位信号
	output oled_dc,	//oled dc 0：写命令 1：写数据
	output oled_sclk,	//oled do 时钟信号
	output oled_mosi	//oled d1 数据信号
);

wire clk_1m;			//分频后的1M时钟
wire ena_write;		//spi写使能信号
wire [7:0] data;		//spi写的数据

wire init_done;		//初始化完成信号
wire [7:0] init_data;//初始化输出给spi的数据
wire init_ena_wr;		//初始化的spi写使能信号
wire init_oled_dc;

wire [7:0] ram_data;	//读到的ram数据
wire [7:0] show_data;//输出给spi写的数据
wire rden;				//ram的读使能信号
wire [9:0] rdaddress;//ram读地址信号
wire ram_ena_wr;		//ram使能写信号
wire ram_oled_dc;		//ram模块中的oled dc信号

wire wren;				//ram写使能信号
wire [9:0] wraddress;//ram写地址
wire [7:0] wrdata;	//写到ram中的数据

//下面这样做 主要是把静态显示和动态显示分开，可以通过乒乓开关切换
wire wren_ramw;		//ram写模块输出的写使能信号
wire [9:0] wraddress_ramw;//ram写模块输出的写地址信号
wire [7:0] data_ramw;//ram写模块输出的数据信号

wire wren_showchar;	//显示字符模块输出的写使能信号
wire [9:0] wraddress_showchar;//显示字符模块输出的写地址信号
wire [7:0] data_showchar;//显示字符模块输出的数据

//一个信号只能由一个信号来驱动，所以需要选择一下
//判断是否初始化完成 完成则显示ram中的静态数据
assign data = init_done ? show_data : init_data;	
assign ena_write = init_done ? ram_ena_wr : init_ena_wr;
assign oled_dc = init_done ? ram_oled_dc : init_oled_dc;

//通过乒乓开关切换静态显示还是动态显示
assign wren = change_show ? wren_showchar : wren_ramw;
assign wraddress = change_show ? wraddress_showchar : wraddress_ramw;
assign wrdata = change_show ? data_showchar : data_ramw;
//改变模块使能信号
wire en_ram_wr = change_show ? 0 : 1;
wire en_showchar = change_show ? 1 : 0;

//时钟分频模块 产生1M的时钟
clk_fenpin clk_fenpin_inst(
	.clk(clk),
	.rst_n(rst_n),
	.clk_1m(clk_1m)
);

//spi传输模块
spi_writebyte spi_writebyte_inst(
	.clk(clk_1m),
	.rst_n(rst_n),
	.ena_write(ena_write),
	.data(data),
	.sclk(oled_sclk),
	.mosi(oled_mosi),
	.write_done(write_done)
);

//oled初始化模块 产生初始化数据
oled_init oled_init_inst(
	.clk(clk_1m),
	.rst_n(rst_n),
	.write_done(write_done),
	.oled_rst(oled_rst),
	.oled_dc(init_oled_dc),
	.data(init_data),
	.ena_write(init_ena_wr),
	.init_done(init_done)
);

//ram读模块
ram_read ram_read_inst(
	.clk(clk_1m),
	.rst_n(rst_n),
	.write_done(write_done),
	.init_done(init_done),
	.ram_data(ram_data),
	.rden(rden),
	.rdaddress(rdaddress),
	.ena_write(ram_ena_wr),
	.oled_dc(ram_oled_dc),
	.data(show_data)
);

//ram写模块
ram_write ram_write_inst(
	.clk(clk_1m),
	.rst_n(rst_n),
	.en_ram_wr(en_ram_wr),
	.wren(wren_ramw),
	.wraddress(wraddress_ramw),
	.data(data_ramw)
);

//oled显示数字
oled_show_num oled_show_num_inst(
	.clk(clk_1m),
	.rst_n(rst_n),
	//.num(123),
	.len(3'd3),
	.font_size(5'd24),
	//.x(7'd60),
	//.y(6'd10),
	.en_ram_wr(en_showchar),
	.wren(wren_showchar),
	.wraddress(wraddress_showchar),
	.data(data_showchar)
);

/*
//oled显示字符
oled_show_char oled_show_char_inst(
	.clk(clk_1m),
	.rst_n(rst_n),
	.ascll(8'd48+ascll_add),
	.font_size(5'd24),
	.x(7'd60),
	.y(6'd10),
	.add_dec_x(add_dec_x),
	.add_dec_y(add_dec_y),
	.en_ram_wr(en_showchar),
	.wren(wren_showchar),
	.wraddress(wraddress_showchar),
	.data(data_showchar)
);
*/

//ram ip核
ram_show ram_show_inst(
	.clock(clk_1m),
	.aclr(!ram_rst),
	.data(wrdata),
	.rdaddress(rdaddress),
	.rden(rden),
	.wraddress(wraddress),
	.wren(wren),
	.q(ram_data)
);

endmodule