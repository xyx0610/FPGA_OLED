module spi_writebyte(
	input clk,			//时钟信号 1m的时钟
	input rst_n,		//复位信号 按键复位
	input ena_write,	//spi写使能信号
	input [7:0]data,	//spi写的数据
	output reg sclk,	//oled的时钟信号（d0）
	output reg mosi,	//oled的数据信号（d1）
	output write_done //spi写完成信号
);

parameter S0=0,S1=1,S2=2,Done=3;
reg[1:0] state,next_state;
reg[3:0] cnt;		//写数据的位计数器

//状态机下一个状态确认
always @(*) begin
	if(!rst_n) begin
		next_state <= 2'd0;
	end
	else begin
		case(state)
			S0: //等待写使能信号
				next_state = ena_write ? S1 : S0;
			
			S1: 
				next_state = S2;
			
			S2: //从s1到s2的位置cnt才加1所以需要cnt到8再到下一个状态
				next_state = (cnt == 4'd8) ? Done : S1;
			
			Done://这个状态主要用来产生done信号输出
				next_state = S0;
			
		endcase
	end
end

//赋值和状态转换分开
//解决reg输出Latch的问题
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		sclk = 1'b1;
		mosi = 1'b0;
	end
	else begin
		case(state)
			S0: begin//等待写使能信号
				sclk = 1'b1;
				mosi = 1'b0;
			end
			S1: begin
				sclk = 1'b0;
				mosi = data[3'd7-cnt] ? 1'b1 : 1'b0;
			end
			S2: begin//从s1到s2的位置cnt才加1所以需要cnt到8再到下一个状态
				sclk = 1'b1;
			end
		endcase
	end
end

//状态流转
always @(posedge clk,negedge rst_n) begin
	if(~rst_n)
		state <= S0;
	else
		state <= next_state;
end

//计数器计数
always @(posedge clk,negedge rst_n) begin
	if(~rst_n) begin
		cnt <= 4'd0;
	end
	else begin
		if(state == S1)
			cnt <= cnt + 1'b1;
		else if(state == S0)
			cnt <= 4'd0;
		else
			cnt <= cnt;
	end
end

assign write_done = (state==Done);//done信号输出
	
endmodule


