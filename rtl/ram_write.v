/***************************************
该模块用来向ram中写入显示的数据
地址0~127：第7页
地址128~255：第6页
地址256~383：第5页
地址384~511：第4页
地址512~639：第3页
地址640~767：第2页
地址768~895：第1页
地址896~1023：第0页
****************************************/
module ram_write(
	input clk,							//时钟信号
	input rst_n,						//按键复位信号
	input en_ram_wr,					//模块开始写信号
	output reg wren,					//ram写使能
	output reg [9:0] wraddress,	//ram写地址
	output reg [7:0] data			//写到ram的数据
);

//状态说明
//等待模块使能 写数据 完成
parameter ClearRAM=0,WaitInit=1,WriteData=2,Done=3;
reg[2:0] state,next_state;
reg [7:0] zm[383:0];//写进ram的静态数据
reg [8:0] cnt_zm;//数据计数器

//字模数据初始化 字号大小16
initial begin
	zm[0]=8'h07;zm[1]=8'hF0;zm[2]=8'h08;zm[3]=8'h08;
	zm[4]=8'h10;zm[5]=8'h04;zm[6]=8'h10;zm[7]=8'h04;
	zm[8]=8'h10;zm[9]=8'h04;zm[10]=8'h08;zm[11]=8'h08;
	zm[12]=8'h07;zm[13]=8'hF0;zm[14]=8'h00;zm[15]=8'h00;//"O",0
	
	zm[16]=8'h10;zm[17]=8'h04;zm[18]=8'h1F;zm[19]=8'hFC;
	zm[20]=8'h10;zm[21]=8'h04;zm[22]=8'h00;zm[23]=8'h04;
	zm[24]=8'h00;zm[25]=8'h04;zm[26]=8'h00;zm[27]=8'h04;
	zm[28]=8'h00;zm[29]=8'h0C;zm[30]=8'h00;zm[31]=8'h00;//"L",1
	
	zm[32]=8'h10;zm[33]=8'h04;zm[34]=8'h1F;zm[35]=8'hFC;
	zm[36]=8'h11;zm[37]=8'h04;zm[38]=8'h11;zm[39]=8'h04;
	zm[40]=8'h17;zm[41]=8'hC4;zm[42]=8'h10;zm[43]=8'h04;
	zm[44]=8'h08;zm[45]=8'h18;zm[46]=8'h00;zm[47]=8'h00;//"E",2
	
	zm[48]=8'h10;zm[49]=8'h04;zm[50]=8'h1F;zm[51]=8'hFC;
	zm[52]=8'h10;zm[53]=8'h04;zm[54]=8'h10;zm[55]=8'h04;
	zm[56]=8'h10;zm[57]=8'h04;zm[58]=8'h08;zm[59]=8'h08;
	zm[60]=8'h07;zm[61]=8'hF0;zm[62]=8'h00;zm[63]=8'h00;//"D",3
	
	zm[64]=8'h00;zm[65]=8'h02;zm[66]=8'h00;zm[67]=8'h42;
	zm[68]=8'h00;zm[69]=8'h22;zm[70]=8'h7F;zm[71]=8'h1A;
	zm[72]=8'h49;zm[73]=8'h02;zm[74]=8'h49;zm[75]=8'hFE;
	zm[76]=8'h49;zm[77]=8'h02;zm[78]=8'h49;zm[79]=8'h02;
	zm[80]=8'h49;zm[81]=8'h02;zm[82]=8'h49;zm[83]=8'hFE;
	zm[84]=8'h49;zm[85]=8'h02;zm[86]=8'h7F;zm[87]=8'h0A;
	zm[88]=8'h00;zm[89]=8'h12;zm[90]=8'h00;zm[91]=8'h62;
	zm[92]=8'h00;zm[93]=8'h02;zm[94]=8'h00;zm[95]=8'h00;//"显",4
	
	zm[96]=8'h02;zm[97]=8'h04;zm[98]=8'h02;zm[99]=8'h08;
	zm[100]=8'h42;zm[101]=8'h10;zm[102]=8'h42;zm[103]=8'h60;
	zm[104]=8'h42;zm[105]=8'h00;zm[106]=8'h42;zm[107]=8'h02;
	zm[108]=8'h42;zm[109]=8'h01;zm[110]=8'h43;zm[111]=8'hFE;
	zm[112]=8'h42;zm[113]=8'h00;zm[114]=8'h42;zm[115]=8'h00;
	zm[116]=8'h42;zm[117]=8'h00;zm[118]=8'h42;zm[119]=8'h40;
	zm[120]=8'h42;zm[121]=8'h20;zm[122]=8'h02;zm[123]=8'h10;
	zm[124]=8'h02;zm[125]=8'h0C;zm[126]=8'h00;zm[127]=8'h00;//"示",5
	
	zm[128]=8'h10;zm[129]=8'h04;zm[130]=8'h1F;zm[131]=8'hFC;
	zm[132]=8'h11;zm[133]=8'h04;zm[134]=8'h11;zm[135]=8'h04;
	zm[136]=8'h11;zm[137]=8'h04;zm[138]=8'h0E;zm[139]=8'h88;
	zm[140]=8'h00;zm[141]=8'h70;zm[142]=8'h00;zm[143]=8'h00;//"B",6
	
	zm[144]=8'h01;zm[145]=8'h00;zm[146]=8'h01;zm[147]=8'h81;
	zm[148]=8'h01;zm[149]=8'h61;zm[150]=8'h00;zm[151]=8'h1E;
	zm[152]=8'h00;zm[153]=8'h18;zm[154]=8'h01;zm[155]=8'h60;
	zm[156]=8'h01;zm[157]=8'h80;zm[158]=8'h01;zm[159]=8'h00;//"y",7
	
	zm[160]=8'h20;zm[161]=8'h80;zm[162]=8'h28;zm[163]=8'h91;
	zm[164]=8'h35;zm[165]=8'h11;zm[166]=8'hE2;zm[167]=8'h12;
	zm[168]=8'h25;zm[169]=8'h14;zm[170]=8'h28;zm[171]=8'h98;
	zm[172]=8'h30;zm[173]=8'h70;zm[174]=8'h00;zm[175]=8'h90;
	zm[176]=8'h38;zm[177]=8'h90;zm[178]=8'h25;zm[179]=8'h12;
	zm[180]=8'h22;zm[181]=8'h11;zm[182]=8'h25;zm[183]=8'h12;
	zm[184]=8'h29;zm[185]=8'h1C;zm[186]=8'h30;zm[187]=8'h80;
	zm[188]=8'h00;zm[189]=8'h80;zm[190]=8'h00;zm[191]=8'h00;//"努",8
	
	zm[192]=8'h00;zm[193]=8'h00;zm[194]=8'h08;zm[195]=8'h01;
	zm[196]=8'h08;zm[197]=8'h02;zm[198]=8'h08;zm[199]=8'h04;
	zm[200]=8'h08;zm[201]=8'h18;zm[202]=8'h08;zm[203]=8'h60;
	zm[204]=8'hFF;zm[205]=8'h80;zm[206]=8'h08;zm[207]=8'h00;
	zm[208]=8'h08;zm[209]=8'h04;zm[210]=8'h08;zm[211]=8'h02;
	zm[212]=8'h08;zm[213]=8'h01;zm[214]=8'h08;zm[215]=8'h02;
	zm[216]=8'h0F;zm[217]=8'hFC;zm[218]=8'h00;zm[219]=8'h00;
	zm[220]=8'h00;zm[221]=8'h00;zm[222]=8'h00;zm[223]=8'h00;//"力",9
	
	zm[224]=8'h00;zm[225]=8'h00;zm[226]=8'h1F;zm[227]=8'hFF;
	zm[228]=8'h10;zm[229]=8'h00;zm[230]=8'h10;zm[231]=8'h00;
	zm[232]=8'h30;zm[233]=8'h00;zm[234]=8'h53;zm[235]=8'hF8;
	zm[236]=8'h92;zm[237]=8'h10;zm[238]=8'h12;zm[239]=8'h10;
	zm[240]=8'h12;zm[241]=8'h10;zm[242]=8'h13;zm[243]=8'hF8;
	zm[244]=8'h10;zm[245]=8'h00;zm[246]=8'h10;zm[247]=8'h02;
	zm[248]=8'h10;zm[249]=8'h01;zm[250]=8'h1F;zm[251]=8'hFE;
	zm[252]=8'h00;zm[253]=8'h00;zm[254]=8'h00;zm[255]=8'h00;//"向",10
	
	zm[256]=8'h10;zm[257]=8'h00;zm[258]=8'h10;zm[259]=8'h00;
	zm[260]=8'h17;zm[261]=8'hFF;zm[262]=8'h94;zm[263]=8'h90;
	zm[264]=8'h74;zm[265]=8'h92;zm[266]=8'h14;zm[267]=8'h91;
	zm[268]=8'h17;zm[269]=8'hFE;zm[270]=8'h10;zm[271]=8'h00;
	zm[272]=8'h10;zm[273]=8'h00;zm[274]=8'h13;zm[275]=8'hF0;
	zm[276]=8'h30;zm[277]=8'h02;zm[278]=8'hD0;zm[279]=8'h01;
	zm[280]=8'h17;zm[281]=8'hFE;zm[282]=8'h10;zm[283]=8'h00;
	zm[284]=8'h10;zm[285]=8'h00;zm[286]=8'h00;zm[287]=8'h00;//"前",11
	
	zm[288]=8'h00;zm[289]=8'h00;zm[290]=8'h1F;zm[291]=8'hFE;
	zm[292]=8'h30;zm[293]=8'h84;zm[294]=8'hD0;zm[295]=8'h84;
	zm[296]=8'h10;zm[297]=8'h84;zm[298]=8'h10;zm[299]=8'h84;
	zm[300]=8'h1F;zm[301]=8'hFE;zm[302]=8'h02;zm[303]=8'h00;
	zm[304]=8'h0C;zm[305]=8'h00;zm[306]=8'hF1;zm[307]=8'h00;
	zm[308]=8'h10;zm[309]=8'hC2;zm[310]=8'h10;zm[311]=8'h01;
	zm[312]=8'h10;zm[313]=8'h02;zm[314]=8'h1F;zm[315]=8'hFC;
	zm[316]=8'h00;zm[317]=8'h00;zm[318]=8'h00;zm[319]=8'h00;//"的",12
	
	zm[320]=8'h00;zm[321]=8'h10;zm[322]=8'h00;zm[323]=8'h20;
	zm[324]=8'h00;zm[325]=8'hC0;zm[326]=8'h07;zm[327]=8'h00;
	zm[328]=8'h00;zm[329]=8'h00;zm[330]=8'h00;zm[331]=8'h02;
	zm[332]=8'h00;zm[333]=8'h01;zm[334]=8'hFF;zm[335]=8'hFE;
	zm[336]=8'h00;zm[337]=8'h00;zm[338]=8'h00;zm[339]=8'h00;
	zm[340]=8'h00;zm[341]=8'h00;zm[342]=8'h04;zm[343]=8'h00;
	zm[344]=8'h02;zm[345]=8'h00;zm[346]=8'h01;zm[347]=8'h80;
	zm[348]=8'h00;zm[349]=8'h70;zm[350]=8'h00;zm[351]=8'h00;//"小",13
	
	zm[352]=8'h08;zm[353]=8'h80;zm[354]=8'h11;zm[355]=8'h00;
	zm[356]=8'h23;zm[357]=8'hFF;zm[358]=8'hCC;zm[359]=8'h00;
	zm[360]=8'h00;zm[361]=8'h04;zm[362]=8'h04;zm[363]=8'h88;
	zm[364]=8'h08;zm[365]=8'hB0;zm[366]=8'h14;zm[367]=8'h82;
	zm[368]=8'h24;zm[369]=8'h81;zm[370]=8'hC7;zm[371]=8'hFE;
	zm[372]=8'h24;zm[373]=8'h80;zm[374]=8'h14;zm[375]=8'hA0;
	zm[376]=8'h08;zm[377]=8'h90;zm[378]=8'h04;zm[379]=8'h8C;
	zm[380]=8'h04;zm[381]=8'h00;zm[382]=8'h00;zm[383]=8'h00;//"徐",14

end

//下一个状态确认
always @(*) begin
	if(!rst_n)
		next_state = ClearRAM;
	else begin
		case(state)
			ClearRAM: next_state = (wraddress == 10'd1023) ? WaitInit : ClearRAM;
			//等待模块使能
			WaitInit: next_state = en_ram_wr ? WriteData : WaitInit;
			//写数据
			WriteData: next_state = (cnt_zm==9'd383) ? Done : WriteData;
			//数据写完成
			Done: next_state = Done;
		endcase
	end
end

//每一个状态的逻辑变量赋值
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		wren <= 1'b0;			//写使能信号复位
		data <= 8'd0;			//数据值复位
	end
	else begin
		case(state)
			ClearRAM:begin
				wren <= 1'b1;			//写使能信号拉高 复位ram
				data <= 8'd0;			//数据值复位
			end
			WaitInit:begin
				wren <= 1'b0;	//等待模块使能状态 信号复位
				data <= 8'd0;
			end
			
			WriteData:begin
				wren <= 1'b1;	//写使能信号拉高
				data <= zm[cnt_zm];//写到ram中的数据赋值
			end
			Done:begin
				wren <= 1'b0;
				data <= 8'd0;
			end	
		endcase
	end

end

//数据计数器计数
always @(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
		cnt_zm <= 9'd0;//计数值复位
		wraddress <= 10'd0;
	end
	else begin
		case(cnt_zm)
			9'd126: cnt_zm <= 9'd1;		//第1页写完毕 转到第2页
			9'd127: cnt_zm <= 9'd128;	//第2页写完毕 转到第3页
			9'd158: cnt_zm <= 9'd129;	//第3页写完毕 转到第4页
			9'd159: cnt_zm <= 9'd160;	//第4页写完毕 转到第5页
			9'd382: cnt_zm <= 9'd161;	//第5页写完毕 转到第6页
			default:
				if(state == WriteData)	//写数据状态下，计数器自增，加2是因为一个字模的高度为16，它本页的下一个数据应该在和当前数据间隔着一个
					cnt_zm <= cnt_zm + 2'd2;
				else
					cnt_zm <= cnt_zm;		//其他状态保持不变
		endcase
		
		//页数说明：主要看你想把字体显示在哪一行
		case(cnt_zm)
			9'd1: wraddress<=10'd128+24;		//进入第2页，地址重新赋值，加入偏移量，显示靠中间位置
			9'd128: wraddress<=10'd256+48;	//进入第3页
			9'd129: wraddress<=10'd384+48;	//进入第4页
			9'd160: wraddress<=10'd512;		//进入第5页
			9'd161: wraddress<=10'd640;		//进入第6页
			default:begin
				case(state)
					ClearRAM: wraddress <= wraddress + 1'b1;//增加地址 复位RAM
					WaitInit: wraddress <= 10'd0+23;//地址复位，加入偏移量23，使得显示靠中间位置
					WriteData: wraddress <= wraddress + 1'b1;
					default: wraddress <= wraddress;		//其他状态下地址保持不变
				endcase					
			end
		endcase
	end
end

//状态转换
always @(posedge clk,negedge rst_n) begin
	if(!rst_n)
		state <= ClearRAM;
	else
		state <= next_state;
end

endmodule
