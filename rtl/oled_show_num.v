module oled_show_num(
	input clk,					//时钟信号
	input rst_n,				//按键复位
	input [15:0] num,			//需要显示的数字
	input [2:0] len,
	input [4:0] font_size,		//显示字符的字体大小 12，16和24
	input en_ram_wr,			//模块使能信号
	output reg wren,			//ram写使能
	output [9:0]wraddress,	//ram写地址
	output reg [7:0]data		//写进ram的数据
);
 
//状态说明
//清除RAM中的数据 等待模块使能 读取rom中的数据 保存数据1 保存数据2（rom地址改变地址后要第二个时钟值才会改变）  
//根据坐标改变数据 写数据 完成

parameter x = 0,y = 0; 
parameter ClearRAM=0,WaitEn=1,GetNum=2,InitAddress=3,ReadData=4,SaveData1=5,SaveData2=6,ChangeData=7,WriteData=8,Done=9,Lg_JS1=10,Lg_JS2=11,Lg_JS3=12;
reg [3:0] state,next_state;	//状态存储
reg [7:0] zm;						//rom中取出的数据
reg [7:0] ram_zm[127:0][7:0];	//写进ram的数据 因为需要根据坐标来变换 所以寄存一下数据 然后一次性写入
reg [3:0] zm_w_cnt;				//字模每一个字节的位计数器
reg [5:0] zm_cnt;					//字模个数计数器
reg [9:0] rom_address12;		//12号字体的rom地址
reg [10:0] rom_address16;		//16号字体的rom地址
reg [11:0] rom_address24;		//24号字体的rom地址
wire [7:0] zm12_data,zm16_data,zm24_data; //存储12，16和24号字体读出来的数据
 
reg [6:0] ram_zm_cntx;			//读取ram_zm时用到的x计数器
reg [2:0] ram_zm_cnty;			//读取ram_zm时用到的x计数器
reg [10:0] wraddress_cnt;		//ram地址计数器 用11位的有1024
 
reg [4:0] zm_cnty;					//y坐标计数
reg [2:0] num_cnt;
reg [7:0] ascll;

reg [6:0] xadd;
reg [5:0] yadd;
reg [7:0] zj;

wire [6:0] xadd1,xadd2;
//assign xadd1 = num_cnt*3'd6;
assign xadd2 = (zm_cnt-1'b1)/2'd2;
//wire [6:0] xadd = Lg_JS1 + (zm_cnt-1'b1)/2'd2;
 
//ram写地址赋值
assign wraddress = wraddress_cnt < 11'd1024 ? wraddress_cnt : 10'd0;
 
//状态机下一个状态确认
always @(*) begin
	if(!rst_n)
		next_state = ClearRAM;	//复位进入初始状态
	else begin
		case(state)
			//清除RAM
			ClearRAM: next_state = (wraddress_cnt == 11'd1023) ? WaitEn : ClearRAM;
			
			//等待模块使得能
			WaitEn: next_state = en_ram_wr ? GetNum : WaitEn;
			
			GetNum: next_state = InitAddress;
			
			InitAddress: next_state = ReadData;
			
			//读取rom数据（rden拉高）
			ReadData: next_state = SaveData1;
			//rom地址变化后，两个时钟周期才会出值
			SaveData1: next_state = SaveData2;
			
			SaveData2: next_state = Lg_JS1;
			
			Lg_JS1:next_state = Lg_JS2;
			Lg_JS2:next_state = Lg_JS3;
			Lg_JS3:next_state = ChangeData;
			//根据坐标变换数据
			ChangeData:begin
				case(font_size)
					//因为进入这个状态后 zm_cnt的值已经加到1了，所以判断的时候要多一个1
					//判断是否已经读取到最后一个字模数据了且最后一个字模的8位也全部改变完成则进入下一个状态
					//否则判断是否一个字模数据的8位已经改变完成 完成则读取下一个字模数据
					5'd12: next_state = (zm_cnt == 6'd13 && num_cnt==len) ? WriteData : (zm_cnt == 6'd13) ? GetNum : (zm_w_cnt == 4'd7) ? ReadData : Lg_JS1;
					5'd16: next_state = (zm_cnt == 6'd17 && num_cnt==len) ? WriteData : (zm_cnt == 6'd13) ? GetNum : (zm_w_cnt == 4'd7) ? ReadData : Lg_JS1;
					5'd24: next_state = (zm_cnt == 6'd37 && num_cnt==len) ? WriteData : (zm_cnt == 6'd13) ? GetNum : (zm_w_cnt == 4'd7) ? ReadData : Lg_JS1;
				endcase
			end
			
			//向RAM中写数据
			WriteData: begin
				next_state = (wraddress_cnt == 11'd1024) ? Done : WriteData;
			end
			
			//完成
			//完成一次写操作后开始下一次写操作
			//可以通过按键改变坐标
			//拨码开关改变ascll输入
			//显示不同的字符在不同的坐标
			Done:next_state = ClearRAM;
		endcase		
	end
end
 
//状态逻辑变量赋值
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		rom_address12 <= 12'd0;
		rom_address16 <= 12'd0;
		rom_address24 <= 12'd0;
		zm <= 8'd0;
		wren <= 1'b1;
		data <= 8'd0;
	end
	else begin
		case(state)
			//RAM清零
			ClearRAM:begin
				ram_zm[ram_zm_cntx][ram_zm_cnty] = 8'd0;//ram数据寄存器清零
				wren <= 1'b0;//写使能信号拉高 清除RAM中的数据//持续刷新的话，复位状态就不清除RAM中的数据了，把ram寄存器中数据清除就好
			end
			
			//等待模块使能
			WaitEn: begin
				wren <= 1'b0;//写使能信号拉低
			end
			
			GetNum:begin
				ascll <= (num/((len-num_cnt-1)*10))%10;
			end
			
			InitAddress:begin
				//到改变数据的时候地址已经加过1了，所以初始地址减1
				case(font_size)
					5'd12:rom_address12 <= (ascll-33)*12-1;//12号字体一个字模数据占12字节
					5'd16:rom_address16 <= (ascll-33)*16-1;//16号字体一个字模数据占16字节
					5'd24:rom_address24 <= (ascll-33)*36-1;//24号字体一个字模数据占36字节
				endcase
			end
			
			//读取ROM中的数据
			ReadData: begin
				case(font_size)//地址增加
					5'd12:rom_address12 <= rom_address12 + 1'b1;
					5'd16:rom_address16 <= rom_address16 + 1'b1;
					5'd24:rom_address24 <= rom_address24 + 1'b1;
				endcase
			end
			
			//保存读取到的值
			SaveData2:begin
				case(font_size)//保存读取到的数据
					5'd12: zm <= zm12_data;
					5'd16: zm <= zm16_data;
					5'd24: zm <= zm24_data;
				endcase
			end
			
			Lg_JS1:begin
				case(zm_cnt)
					6'd1,6'd2:xadd <= 7'd0;
					6'd3,6'd4:xadd <= 7'd1;
					6'd5,6'd6:xadd <= 7'd2;
					6'd7,6'd8:xadd <= 7'd3;
					6'd9,6'd10:xadd <= 7'd4;
					6'd11,6'd12:xadd <= 7'd5;
					6'd13,6'd14:xadd <= 7'd6;
					6'd15,6'd16:xadd <= 7'd7;
					/*6'd1,6'd2:xadd <= 7'd8;
					6'd1,6'd2:xadd <= 7'd9;
					6'd1,6'd2:xadd <= 7'd10;
					6'd1,6'd2:xadd <= 7'd11;
					6'd1,6'd2:xadd <= 7'd0;*/
				endcase
			end
			
			Lg_JS3:begin
				case(num_cnt)
					3'd0: xadd <= xadd+x;
					3'd1: xadd <= xadd+3'd1+x;
					3'd2: xadd <= xadd+3'd2+x;
					3'd3: xadd <= xadd+3'd3+x; 
				endcase
			end
			
			//根据坐标给要写进RAM中的数据赋值
			ChangeData:begin
				if(zm[7-zm_w_cnt]) begin
					//zm_cnt多加了一个 所以减1
					//如果该位为1 就把这个坐标的点置1
					/*case(font_size)
						5'd12:begin
							//xadd <= 
							ram_zm[xadd][(y+zm_cnty)/8] <=  ram_zm[xadd][(y+zm_cnty)/8] | 1<<(7-(y+zm_w_cnt)%8);//1左移多少位
						end
						5'd16:begin
							//xadd <= x+(zm_cnt-1)/2;
							ram_zm[xadd][(y+zm_cnty)/8] <=  ram_zm[xadd][(y+zm_cnty)/8] | 1<<(7-(y+zm_w_cnt)%8);//1左移多少位
						end
						5'd24:begin
							//xadd <= x+(zm_cnt-1)/3;
							ram_zm[xadd][(y+zm_cnty)/8] <=  ram_zm[xadd][(y+zm_cnty)/8] | 1<<(7-(y+zm_w_cnt)%8);//1左移多少位
						end
					endcase
					*/
					ram_zm[x+(zm_cnt-1)/2 ][(y+zm_cnty)/8] <=  1<<(7-(y+zm_w_cnt)%8);//1左移多少位
				end/*
				else begin
					case(font_size)
						5'd12:ram_zm[x+(zm_cnt-1)/2+num_cnt*6][(y+zm_cnty)/8] <=  ram_zm[x+(zm_cnt-1)/2+num_cnt*6][(y+zm_cnty)/8];
						5'd16:ram_zm[x+(zm_cnt-1)/2+num_cnt*8][(y+zm_cnty)/8] <=  ram_zm[x+(zm_cnt-1)/2+num_cnt*8][(y+zm_cnty)/8];
						5'd24:ram_zm[x+(zm_cnt-1)/3+num_cnt*18][(y+zm_cnty)/8] <=  ram_zm[x+(zm_cnt-1)/3+num_cnt*18][(y+zm_cnty)/8];
					endcase
				end*/
			end
			
			//把数据写进RAM中
			WriteData:begin
				wren <= 1'b1;//写使能信号拉高
				data <= ram_zm[ram_zm_cntx][ram_zm_cnty];//数据赋值
			end
			
			//完成
			Done:begin
				wren <= 1'b0;//写使能信号拉低
				data <= 8'd0;
			end
		endcase
	end
end
 
//当前状态赋值
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) 
		state <= ClearRAM;
	else
		state <= next_state;
end
 
//各种计数器控制
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		zm_cnt <= 6'd0;			//字模字节计数器
		zm_w_cnt <= 4'd0;			//一个字节的位计数器
		//比如一个16号的字体，按照从左往右的扫描就需要y坐标增加16x坐标才加1
		zm_cnty <= 5'd0;			//当前坐标开始的y坐标计数器
		
		ram_zm_cnty <= 3'd0;		//字模存储数组读取或者清零时用的计数器
		ram_zm_cntx <= 7'd0;
		wraddress_cnt <= 11'd0;	//写地址计数器				
	end
	else begin
		case(state)
			ClearRAM:begin
				//写地址增加 清除RAM中的数据
				wraddress_cnt <= wraddress_cnt + 1'b1;
				//字模寄存器计数器增加 将寄存器中内容清空
				ram_zm_cnty <= ram_zm_cnty + 1'b1;
				if(ram_zm_cnty == 3'd7)
					ram_zm_cntx <= ram_zm_cntx + 1'b1;
				else
					ram_zm_cntx <= ram_zm_cntx;
			end
			
			WaitEn:begin
				//等待模块使能 计数器的值清零
				wraddress_cnt <= 11'd0;
				ram_zm_cnty <= 3'd0;
				ram_zm_cntx <= 7'd0;
				
				zm_cnt <= 6'd0;
				zm_w_cnt <= 4'd0;
				zm_cnty <= 5'd0;
			end
			
			GetNum:begin
				num_cnt <= num_cnt + 1'b1;
			end
			
			//读取rom中的数据	
			ReadData:begin
				zm_cnt <= zm_cnt + 1'b1;//每读取字模的一个字节数据 计数器加1
				zm_w_cnt <= 4'd0;			//位计数器清零
				//存进ROM的字模数据是从上到下，从左到右扫描的
				//比如16号字体，一列就有两个字节，所以要读取两个字节后，增加的y坐标才清零
				//12号字体一列也是两个字节，24号字体一列是3个字节
				if(font_size==5'd24)		
					zm_cnty <= (zm_cnt%3==0) ? 5'd0 : zm_cnty;
				else
					zm_cnty <= (zm_cnt%2==0) ? 5'd0 : zm_cnty;
					
			end
			
			ChangeData:begin
				zm_w_cnt <= zm_w_cnt + 1'b1;//位计数器增加
				zm_cnty <= zm_cnty + 1'b1;//y坐标增加
			end
			
			WriteData: begin
				wraddress_cnt <= wraddress_cnt + 1'b1;//写地址计数器增加
				ram_zm_cntx <= ram_zm_cntx + 1'b1;//字模寄存器 计数器增加，读取寄存器中的内容写进ram中
				if(ram_zm_cntx == 7'd127)
					ram_zm_cnty <= ram_zm_cnty + 1'b1;
				else
					ram_zm_cnty <= ram_zm_cnty;
			end
			Done:begin
				wraddress_cnt <= 11'd0;//计数器清零
				ram_zm_cntx <= 7'd0;
				ram_zm_cnty <= 6'd0;
			end
		endcase
	end
end
 
//12号字体rom
zm_12 zm_12_inst(
	.clock(clk),
	.address(rom_address12),
	.q(zm12_data)
);
//16号字体rom
zm_16 zm_16_inst(
	.clock(clk),
	.address(rom_address16),
	.q(zm16_data)
);
//24号字体rom
zm_24 zm_24_inst(
	.clock(clk),
	.address(rom_address24),
	.q(zm24_data)
);
 
 
endmodule