
/****************************************
该模块用来不断读取ram中的数据，然后刷新OLED的显示
****************************************/
module ram_read(
	input clk,					//时钟信号
	input rst_n,				//按键复位信号
	input write_done,			//spi写完成信号
	input init_done,			//初始化完成
	input[7:0] ram_data,		//读取到的ram数据
	output reg rden,			//ram ip核的读使能信号
	output [9:0] rdaddress,	//ram ip核读地址
	output reg ena_write,	//spi 写使能信号
	output reg oled_dc,		//oled的dc写数据 写命令控制信号
	output reg[7:0] data		//传给 spi写的数据
);

parameter DELAY = 1_000;	//刷新率1000_000/1_000 = 1000Hz
reg [20:0] us_cnt;			//us计数器 上电延时等待
reg us_cnt_clr;				//计数器清零信号

//状态说明
//等待初始化完成 写命令 等待写命令完成
//读ram数据 写数据 等待写数据完成
//数据读取完成一遍
parameter WaitInit=0,WriteCmd=1,WaitWriteCmd=2,ReadData=3,WriteData=4,WaitWriteData=5,Done=6;
reg[2:0] state,next_state;	//当前状态 和 下一个状态

reg [7:0] write_cmd[24:0];	//清零命令存储
reg [4:0] write_cmd_cnt;	//清零命令计数
reg [10:0] address_cnt;		//地址计数器 

//读地址最多到1023 但是状态转换需要1024 所以使用额外的一个计数器来作为状态转换，同时也提供地址信号
//只是在地址计数器超过1024时，读地址就为0
assign rdaddress = (address_cnt >= 11'd1024) ? 10'd0 : address_cnt;

//oled清零命令
//也就是设置页地址，设置显示的低地址和设置显示的高地址
//第7页在靠近引脚的位置，从高页写到地页，这么写方便自己查看
initial begin
	write_cmd[0] = 8'hB7;write_cmd[1] = 8'h00;write_cmd[2] = 8'h10;//第7页
	write_cmd[3] = 8'hB6;write_cmd[4] = 8'h00;write_cmd[5] = 8'h10;//第6页
	write_cmd[6] = 8'hB5;write_cmd[7] = 8'h00;write_cmd[8] = 8'h10;//第5页
	write_cmd[9] = 8'hB4;write_cmd[10] = 8'h00;write_cmd[11] = 8'h10;//第4页
	write_cmd[12] = 8'hB3;write_cmd[13] = 8'h00;write_cmd[14] = 8'h10;//第3页
	write_cmd[15] = 8'hB2;write_cmd[16] = 8'h00;write_cmd[17] = 8'h10;//第2页
	write_cmd[18] = 8'hB1;write_cmd[19] = 8'h00;write_cmd[20] = 8'h10;//第1页
	write_cmd[21] = 8'hB0;write_cmd[22] = 8'h00;write_cmd[23] = 8'h10;//第0页
end
	
//1微秒计数器
always @ (posedge clk,negedge rst_n) begin
    if (!rst_n)
        us_cnt <= 21'd0;
    else if (us_cnt_clr)
        us_cnt <= 21'd0;
    else 
        us_cnt <= us_cnt + 1'b1;
end 

//下一个状态确认
always @(*) begin
	if(!rst_n) 
		next_state = WaitInit;
	else begin
		case(state)
			//等待初始化
			WaitInit: next_state = init_done ? WriteCmd : WaitInit;
			
			//写命令
			WriteCmd:
				next_state = WaitWriteCmd;
			
			//等待写命令
			//这些和初始化的地方的写法是一样的
			WaitWriteCmd:
				next_state = (write_cmd_cnt % 2'd3 == 0 && write_done) ? ReadData : (write_done ? WriteCmd: WaitWriteCmd);
			
			//读数据
			ReadData: 
				next_state = WriteData;
			
			//写数据
			WriteData:
				next_state = WaitWriteData;
			
			//等待写数据
			//这些和初始化的地方的写法是一样的
			WaitWriteData: 
				next_state = (address_cnt == 11'd1024&&write_done) ? Done : (address_cnt % 11'd128 == 0&&write_done ? WriteCmd : (write_done ? ReadData : WaitWriteData));
			
			//一次读写完成，等待100ms，进入下一次读写
			Done:begin
				if(us_cnt>DELAY)
					next_state = WriteCmd;
				else
					next_state = Done;
			end
				
		endcase
	end
end

//寄存器赋值和组合逻辑的状态转换分开
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		oled_dc <= 1'b1;
		ena_write <= 1'b0;
		rden <= 1'b0;
		us_cnt_clr <= 1'b1;
		data <= 8'd0;
	end
	else begin
		case(state)			
			WriteCmd:begin
				ena_write <= 1'b1;						//写命令 使能写信号
				oled_dc <= 1'b0;							//写命令 dc置0
				data <= write_cmd[write_cmd_cnt];	//获取写的数据
			end
			
			WaitWriteCmd:begin
				ena_write <= 1'b0;						//写使能信号拉低，等待写完成
			end
			
			ReadData: begin
			rden <= 1'b1;									//ram读使能信号拉高 开始读数据 这个信号可以一直拉高，因为地址不变，读出来的数据都是保持不变的
			end
			
			WriteData:begin
				ena_write <= 1'b1;						//写数据 写使能信号拉高
				oled_dc <= 1'b1;							//写的是数据 dc置1
				data <= ram_data;							//为即将要写的数据赋值
			end
			
			WaitWriteData: begin
				ena_write <= 1'b0;						//等待写完成 写使能信号拉低
			end
			
			Done:begin
				us_cnt_clr <= 1'b0;						//计数器复位信号拉低，开始计数
			end
				
		endcase
	end
end	

//状态转换
always @(posedge clk,negedge rst_n) begin
	if(!rst_n)
		state <= WaitInit;
	else
		state <= next_state;
end

//计数器计数
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		write_cmd_cnt <= 5'd0;
		address_cnt <= 11'd0;
	end
	else begin
		case(state)
			Done:begin						//完成状态 各计数器复位
				write_cmd_cnt <= 5'd0;
				address_cnt <= 11'd0;
			end
												
			WriteCmd: //写命令状态 写命令计数器增加
				write_cmd_cnt <= write_cmd_cnt + 1'b1;
			
			ReadData: //读数据状态 读地址增加
				address_cnt <= address_cnt + 1'b1;
			
			default:begin//其他状态 计数器值保持不变
				write_cmd_cnt <= write_cmd_cnt;
				address_cnt <= address_cnt;
			end
		endcase
	end
end


endmodule