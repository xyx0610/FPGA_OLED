module oled_init(
	input clk,					//时钟信号 1m的时钟
	input rst_n,				//复位信号
	input write_done,			//spi写完成信号 获得该信号后开启下一次写
	output reg oled_rst,		//oled的复位引脚信号
	output reg oled_dc,		//oled的dc写数据 写命令控制信号
	output reg [7:0] data,	//输出数据用于spi中写入数据
	output reg ena_write,	//spi写使能信号
	output init_done			//初始化完成信号
);

reg [20:0] us_cnt;			//us计数器 上电延时等待
reg us_cnt_clr;				//计数器清零信号
parameter RST_NUM = 10;		//1000_000 //等待1s
//状态说明
//复位状态 初始化写命令状态 oled开写命令状态 oled显示清零写命令状态 oled显示清零写数据状态
//等待初始化写命令完成 等待oled开写命令完成 等待清零写命令完成 等待清零写数据完成
parameter Rst=0,Init=1,OledOn=2,ClearCmd=3,ClearData=4,WaitInit=5,WaitOn=6,WaitClearCmd=7,WaitClearData=8,Done=9;

reg[3:0] state,next_state;//状态机的当前状态和下一个状态


	
reg [7:0] init_cmd[27:0];	//初始化命令存储
reg [4:0] init_cmd_cnt;		//初始化命令计数

reg [7:0] oled_on_cmd[2:0];//oled开命令存储
reg [1:0] oled_on_cmd_cnt;	//oled开命令计数

reg [7:0] clear_cmd[24:0];	//清零命令存储
reg [4:0] clear_cmd_cnt;	//清零命令计数

reg [10:0] clear_data_cnt;	//清零写数据计数


//初始化命令
//这个初始化的点更密集
initial begin	
	init_cmd[0] = 8'hAE;				init_cmd[1] = 8'hD5;				init_cmd[2] = 8'h80;				init_cmd[3] = 8'hA8;
	init_cmd[4] = 8'h3F;				init_cmd[5] = 8'hD3;				init_cmd[6] = 8'h00;				init_cmd[7] = 8'h40;
	init_cmd[8] = 8'h8D;				init_cmd[9] = 8'h10|8'h04;		init_cmd[10] = 8'h20;			init_cmd[11] = 8'h02;
	init_cmd[12] = 8'hA0|8'h01;	init_cmd[13] = 8'hC0;			init_cmd[14] = 8'hDA;			init_cmd[15] = 8'h02|8'h10;
	init_cmd[16] = 8'h81;			init_cmd[17] = 8'hCF;			init_cmd[18] = 8'hD9;			init_cmd[19] = 8'hF1;
	init_cmd[20] = 8'hDB;			init_cmd[21] = 8'h40;			init_cmd[22] = 8'hA4|8'h00;	init_cmd[23] = 8'hA6|8'h00;
	init_cmd[24] = 8'hAE|8'h01;
end

/*
//初始化命令
//这个初始化出来的点比较稀疏
//应该是分辨率的设置不同把（猜测）
initial begin
	init_cmd[0] = 8'hAE;	init_cmd[1] = 8'h00;	init_cmd[2] = 8'h10;	init_cmd[3] = 8'h00;
	init_cmd[4] = 8'hB0;	init_cmd[5] = 8'h81;	init_cmd[6] = 8'hFF;	init_cmd[7] = 8'hA1;
	init_cmd[8] = 8'hA6;	init_cmd[9] = 8'hA8;	init_cmd[10] = 8'h1F;init_cmd[11] = 8'hC8;
	init_cmd[12] = 8'hD3;init_cmd[13] = 8'h00;init_cmd[14] = 8'hD5;init_cmd[15] = 8'h80;
	init_cmd[16] = 8'hD9;init_cmd[17] = 8'h1f;init_cmd[18] = 8'hD9;init_cmd[19] = 8'hF1;
	init_cmd[20] = 8'hDA;init_cmd[21] = 8'h00;init_cmd[22] = 8'hDB;init_cmd[23] = 8'h40;
end
*/

//oled开命令
initial begin
	oled_on_cmd[0] = 8'h8D;oled_on_cmd[1] = 8'h14;oled_on_cmd[2] = 8'hAF;
end

//oled清零命令
//也就是设置页地址，设置显示的低地址和设置显示的高地址
initial begin
	clear_cmd[0] = 8'hB0;clear_cmd[1] = 8'h00;clear_cmd[2] = 8'h10;//第0页
	clear_cmd[3] = 8'hB1;clear_cmd[4] = 8'h00;clear_cmd[5] = 8'h10;//第1页
	clear_cmd[6] = 8'hB2;clear_cmd[7] = 8'h00;clear_cmd[8] = 8'h10;//第2页
	clear_cmd[9] = 8'hB3;clear_cmd[10] = 8'h00;clear_cmd[11] = 8'h10;//第3页
	clear_cmd[12] = 8'hB4;clear_cmd[13] = 8'h00;clear_cmd[14] = 8'h10;//第4页
	clear_cmd[15] = 8'hB5;clear_cmd[16] = 8'h00;clear_cmd[17] = 8'h10;//第5页
	clear_cmd[18] = 8'hB6;clear_cmd[19] = 8'h00;clear_cmd[20] = 8'h10;//第6页
	clear_cmd[21] = 8'hB7;clear_cmd[22] = 8'h00;clear_cmd[23] = 8'h10;//第7页
end


//1微秒计数器
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        us_cnt <= 21'd0;
    else if (us_cnt_clr)
        us_cnt <= 21'd0;
    else 
        us_cnt <= us_cnt + 1'b1;
end 

//有一个故事告诉我们 always(*)别乱用（心酸）
//容易出问题。。。虽然也不知道为什么
//别什么东西都挤一起啊 赋值什么的还是和状态转换分开
//放进时序电路里面
//但是状态转换的下一个状态也不能放进时序电路里面
//会造成当前状态到下一个状态延迟一个时钟周期，时序可能就比较乱
always @(*) begin
	if(!rst_n) begin
		next_state = Rst;
	end
	else begin
		case(state)
			//复位等待状态
			//等待上电复位
			Rst: 
				next_state = us_cnt > RST_NUM ? Init : Rst;
			
			//初始化状态
			Init: 
				next_state = WaitInit;	//进入等待写命令完成的状态
			
			//等待初始化命令写完成状态
			//到达这个状态时cmd cnt才加到1，所以要大一个值判断
			//是否25个命令写完成 写完成进入下一个状态
			//否则是否spi写完成 spi写完成继续写下一个命令 否则就继续等待spi写完成
			//记得加&&write_done等待最后一次写完
			WaitInit: 
				next_state = (init_cmd_cnt == 5'd25&&write_done) ? OledOn : (write_done ? Init : WaitInit);	
				
							
			
			//oled开写命令状态
			OledOn: 
				next_state = WaitOn;
			
			//等待oled开写命令完成状态
			//判断命令是否写完 写完进入下一个状态
			//否则 再判断是否spi写完成 写完成继续写下一个数据
			WaitOn: 
				next_state = (oled_on_cmd_cnt == 2'd3&&write_done) ? ClearCmd : (write_done ? OledOn : WaitOn);	
			
			//清零写命令状态
			ClearCmd: 
				next_state = WaitClearCmd;

			
			//等待清零写命令状态			
			//每次写三个命令 所以对3取余数
			//这里0会造成进入这个状态就跳转了
			WaitClearCmd: 
				next_state = (clear_cmd_cnt % 2'd3 == 0 && write_done) ? ClearData : (write_done ? ClearCmd : WaitClearCmd);
				
			
			//清零写数据状态
			ClearData:
				next_state = WaitClearData;
			
			//等待清零写数据
			//1页需要写128个数据，写完7页就是1024个数据
			//写完1页，也就是每写完128个数据就要写一次命令，所以要对128取余，然后进入写命令的状态
			//其中0是不会对状态造成干扰的，因为进入这个状态的时候计数器已经加过1了
			WaitClearData: 
				next_state = (clear_data_cnt == 11'd1024&&write_done) ? Done : (clear_data_cnt % 11'd128 == 0&&write_done ? ClearCmd : (write_done ? ClearData : WaitClearData));
			
			//完成状态
			Done: 
				next_state = Done;

			default: 
				next_state = Rst;
				
		endcase
	end
end

//这个切忌不能写入上面的组合逻辑中
//会造成Latch
//至于原因，，我也不知道
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		oled_rst <= 1'b0;
		us_cnt_clr <= 1'b1;
		oled_dc <= 1'b1;
		data <= 8'h10;
		ena_write <= 1'b0;
	end
	else begin
		case(state)
			//复位等待状态
			Rst:begin
					oled_rst <= 1'b0;
					us_cnt_clr <= 1'b0;
			end
			
			//初始化状态
			Init:begin
				oled_rst <= 1'b1;
				us_cnt_clr <= 1'b1;	//清零计数器
				ena_write <= 1'b1;			//写使能
				oled_dc <= 1'b0;			//写命令
				data <= init_cmd[init_cmd_cnt];//写数据赋值
			end
			
			//等待初始化命令写完成状态
			WaitInit: begin
				ena_write <= 1'b0;			//写失能		
			end
			
			//oled开写命令状态
			OledOn:begin
				ena_write <= 1'b1;			//写使能
				oled_dc <= 1'b0;			//写命令
				data <= oled_on_cmd[oled_on_cmd_cnt];	
			end
			
			//等待oled开写命令完成状态
			WaitOn:begin
				ena_write <= 1'b0;			//写失能
			end
			
			//清零写命令状态
			ClearCmd:begin
				ena_write <= 1'b1;
				oled_dc <= 1'b0;
				data <= clear_cmd[clear_cmd_cnt];
			end
			
			//等待清零写命令状态
			WaitClearCmd:begin
				ena_write <= 1'b0;
			end
			
			//清零写数据状态
			ClearData:begin
				ena_write <= 1'b1;
				oled_dc <= 1'b1;
				data <= 8'h00;
			end
			
			//等待清零写数据
			WaitClearData:begin
				ena_write <= 1'b0;
			end
		endcase
	end
end

//状态转换
always @(posedge clk,negedge rst_n) begin
	if(!rst_n)	
		state <= Rst;
	else
		state <= next_state;
end

//计数器计数
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		init_cmd_cnt <= 5'd0;
		oled_on_cmd_cnt <= 4'd0;
		clear_cmd_cnt <=3'd0;
		clear_data_cnt <= 11'd0;
	end
	else begin
		case(state)
			Init:			init_cmd_cnt <= init_cmd_cnt + 1'b1;
			OledOn:		oled_on_cmd_cnt <= oled_on_cmd_cnt + 1'b1;
			ClearCmd:	clear_cmd_cnt <= clear_cmd_cnt + 1'b1;
			ClearData:	clear_data_cnt <= clear_data_cnt + 1'b1;
			default:begin
				init_cmd_cnt <= init_cmd_cnt;
				oled_on_cmd_cnt <= oled_on_cmd_cnt;
				clear_cmd_cnt <= clear_cmd_cnt;
				clear_data_cnt <= clear_data_cnt;
			end
		endcase
	end
end

assign init_done = (state == Done);


endmodule