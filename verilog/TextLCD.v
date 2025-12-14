module TextLCD (
    input           clk,
    input           rst_n,
    input  [15:0]   noteup_bit0,
    input  [15:0]   noteup_bit1,
    input  [15:0]   notedown_bit0,
    input  [15:0]   notedown_bit1,

    output          LCD_E,           //1602使能引脚，1时读取信息，1->0（下降沿）执行命令  
    output   reg       LCD_RS,          //1602数据——H/命令——L  选择端  
    output   reg       LCD_RW,          //1602写——L/读——H  选择端  
    output  reg [7:0]    LCD_DATA,        //1602数据传输端口  
    output          LCD_ON
);
`define FPS 50
`define TAP "O"
`define HOLD_START "<"
`define HOLD_MIDDLE "{"+96

wire [1:0]note_up[15:0];
wire [1:0]note_down[15:0];
reg [7:0]ascii_up[15:0];
reg [7:0]ascii_down[15:0];

genvar i;
generate
    for(i=0;i<16;i=i+1)begin:generate_case0
        assign note_up[i]={noteup_bit1[i],noteup_bit0[i]};
        assign note_down[i]={notedown_bit1[i],notedown_bit0[i]};
        //  assign note_up[i]=2'd1;
        //  assign note_down[i]=2'd2;
    end
endgenerate

genvar j;
generate
    for(j=0;j<16;j=j+1)begin:generate_case1
        always  @(*)begin
            case(note_up[j])
                2'd0: 
                    ascii_up[j]=" ";
                2'd1: 
                    ascii_up[j]=`TAP;
                2'd2:
                    ascii_up[j]=`HOLD_START;
                2'd3 :
                    ascii_up[j]=`HOLD_MIDDLE;
                default:
                    ascii_up[j]=" ";
            endcase 
        end
    end
endgenerate

genvar k;
generate
    for(k=0;k<16;k=k+1)begin:generate_case2
        always  @(*)begin
            case(note_down[k])
                2'd0: 
                    ascii_down[k]=" ";
                2'd1: 
                    ascii_down[k]=`TAP;
                2'd2:
                    ascii_down[k]=`HOLD_START;
                2'd3 :
                    ascii_down[k]=`HOLD_MIDDLE;
                default:
                    ascii_down[k]=" ";
            endcase 
        end
    end
endgenerate


reg [31:0] count;  
reg clk_div1;       //500个clk的周期，20ns*500=10us  
reg clk_div2;       //1000个，20us  
reg [31:0] count1;   //250个clk_div2的周期，20us*250=5000u=5ms  
reg clk_buf;  
//******************  
//-----分频模块-----  
//******************  
assign LCD_ON=1'b1;

always @(posedge clk or negedge rst_n)  
begin  
    if(!rst_n)    //rst=0  
        count<=0;  
    else  
        begin  
            if(count<`FPS*2)        //2500  
                begin  
                    clk_div1<=0;  
                    count<=count+1'b1;  
                end  
            else if(count>=`FPS*4)        //5000  
                count<=0;  
            else  
                begin  
                    clk_div1<=1;  
                    count<=count+1'b1;  
                end               
        end  
end  


always @(posedge clk_div1 or negedge rst_n)  
begin  
    if(!rst_n)  
        clk_div2<=0;  
    else  
        clk_div2<=~clk_div2;  
end  
always @(posedge clk_div2 or negedge rst_n)     
begin  
    if(!rst_n)    //rst=0  
        begin  
            count1<=0;  
            clk_buf<=0;      //  
        end  
    else  
        begin  
            if(count1<`FPS)       //2500  
                begin  
                    clk_buf<=0;  
                    count1<=count1+1'b1;  
                end  
            else if(count1>=`FPS*2)       //5000  
                count1<=0;  
            else  
                begin  
                    clk_buf<=1;  
                    count1<=count1+1'b1;  
                end               
        end  
end  
assign LCD_E=clk_buf;  
  
//**********************  
//-----显示控制模块-----  
//**********************  
reg [4:0] state;        //当前状态寄存器  ,10个状态  
reg [5:0] address;      //地址的位置，0~31,  

parameter     
        IDLE             = 4'd0,    //空闲   
        CLEAR            = 4'd1,  
        SET_FUNCTION     = 4'd2,    //工作方式设置指令    
        SWITCH_MODE      = 4'd3,     //开关控制指令    
        SET_MODE         = 4'd4,    //输入方式设置    
        SET_DDRAM1       = 4'd5,    //设定第一行DDRAM地址指令    
        WRITE_RAM1       = 4'd6,    //向第一行写入的数码    
        SET_DDRAM2       = 4'd7,    //设定第2行DDRAM地址指令    
        WRITE_RAM2       = 4'd8,    //向第2行写入的数码    
        SHIFT            = 4'd9,    //设定显示屏或光标移动方向指令  
        STOP             = 4'd10;  
              
reg [7:0] Data_First [15:0];  
reg [7:0] Data_Second [15:0];  
 always @(*) begin
 
        Data_First[0] = ascii_up[0];  
        Data_First[1] = ascii_up[1];  
        Data_First[2] = ascii_up[2];  
        Data_First[3] =  ascii_up[3];  
        Data_First[4] =  ascii_up[4];  
        Data_First[5] =  ascii_up[5];  
        Data_First[6] =  ascii_up[6];
        Data_First[7] =  ascii_up[7];   
        Data_First[8] =  ascii_up[8];   
        Data_First[9] =  ascii_up[9];   
        Data_First[10]=  ascii_up[10];  
        Data_First[11]=  ascii_up[11];  
        Data_First[12]=  ascii_up[12];  
        Data_First[13]=  ascii_up[13];  
        Data_First[14]=  ascii_up[14];  
        Data_First[15]= ascii_up[15];  
          
        Data_Second[0] =  ascii_down[0]; 
        Data_Second[1] =   ascii_down[1];   
        Data_Second[2] =   ascii_down[2];   
        Data_Second[3] =   ascii_down[3];  
        Data_Second[4] =   ascii_down[4];  
        Data_Second[5] =   ascii_down[5];  
        Data_Second[6] =   ascii_down[6];   
        Data_Second[7] =   ascii_down[7];   
        Data_Second[8] =   ascii_down[8];  
        Data_Second[9] =   ascii_down[9];  
        Data_Second[10]=   ascii_down[10];
        Data_Second[11]=   ascii_down[11];   
        Data_Second[12]=  ascii_down[12];     
        Data_Second[13]=   ascii_down[13];  
        Data_Second[14]=   ascii_down[14];     
        Data_Second[15]=  ascii_down[15];  
 end
//-----状态控制-----  
always @(posedge clk_buf or negedge rst_n)        // clk_div1 clk_buf  
begin  
    if(!rst_n)  
        begin  
            state<=IDLE;  
            address<=6'd0;  
            LCD_DATA<=8'b0000_0000;  
            LCD_RS<=0;  
            LCD_RW<=0;  
        end  
    else  
        begin  
            case(state)  
                IDLE:       //空闲状态  
                            begin  
                                LCD_DATA<=8'bzzzz_zzzz;      //8'bzzzz_zzzz  
                                state<=CLEAR;  
                            end  
                CLEAR:      //清屏指令  
                                begin  
                                    LCD_RS<=0;  
                                    LCD_RW<=0;  
                                    LCD_DATA<=8'b0000_0001;  //指令  
                                    state<=SET_FUNCTION;                           
                                end  
                SET_FUNCTION:       //工作方式设置  
                                begin  
                                    LCD_RS<=0;  
                                    LCD_RW<=0;  
                                    LCD_DATA<=8'b0011_1100;      //38h  
                                    //第4位DL：0=数据总线为4位；1=数据总线为8位★★★  
                                    //第3位N：0=显示1行；1=显示2行★★★    
                                    //第2位F：0=5×7点阵/每字符；1=5×10点阵/每字符★★★  
                                    state<=SWITCH_MODE;        
                                end  
                SWITCH_MODE:        //显示开关控制指令  
                                begin  
                                    LCD_RS<=0;  
                                    LCD_RW<=0;  
                                    LCD_DATA<=8'b0000_1111;      //0Fh  
                                    //第2位D：0=显示功能关；1=显示功能开★★★  
                                    //第1位C：0=无光标；1=有光标★★★    
                                    //第0位B：1=光标闪烁； 0=光标不闪烁★★★  
                                    state<=SET_MODE;  
                                end  
                SET_MODE:       //设定显示屏或光标移动方向指令    
                                begin  
                                    LCD_RS<=0;  
                                    LCD_RW<=0;  
                                    LCD_DATA<=8'b0000_0110;  //06h  
                                    //第1位N：0=读或者写一个字符后，地址指针-1，光标-1  
                                    //        1=读或者写一个字符后，地址指针+1，光标+1★★★  
                                    //第0位S：0=当写一个字符，整屏显示不移动★★★  
                                    //        1=当写一个字符，整屏显示左移（N=1）或者右移（N=0）,以得到光标不移动而屏幕移动的效果  
                                    state<=SHIFT;   
                                end               
                SHIFT:      //设定显示屏或光标移动方向指令    
                                begin  
                                    LCD_RS<=0;  
                                    LCD_RW<=0;  
                                    LCD_DATA<=8'b0001_0100;    
                                    //第3位S/C；第2位R/L  
                                    //     S/C   R/L     设定情况    
                                    //      0      0      光标左移1格，且地址指针值减1    
                                    //      0      1      光标右移1格，且地址指针值加1  ★★★  
                                    //      1      0      显示器上字符全部左移一格，但光标不动    
                                    //      1      1      显示器上字符全部右移一格，但光标不动  
                                    state<=SET_DDRAM1;   
                                end  
                SET_DDRAM1:     //设定第一行DDRAM地址指令  
                                begin    
                                    LCD_RS<=0;  
                                    LCD_RW<=0;  
                              
                //-----写入第一行显示起始地址：-----   
                //  1   2  3  4   5   6   7  8  9  10  11  12  13  14  15  16  
                // 00  01 02  03  04  05 06 07 08  09  0A  0B  0C  0D  0E  0F   第一行  
                                    LCD_DATA<=8'h80+8'd0; //第一行第1个位置   
                                      
                                    address<=2'd0;  
                                    state<=WRITE_RAM1;   
//                                  Data_First_Buf<=Data_First;    
                                end  
                WRITE_RAM1:     //向第一行写入的数码  
                                begin  
                                    if(address<=15)          //表示写第一行  
                                        begin  
                                            LCD_RS<=1;  
                                            LCD_RW<=0;  
                                            LCD_DATA<=Data_First[address];  
//                                          Data_First_Buf<=(Data_First_Buf<<8);   //左移  
                                            address<=address+1'b1;  
                                            state<=WRITE_RAM1;  
                                        end  
                                    else  
                                        begin  
                                            LCD_RS<=0;  
                                            LCD_RW<=0;  
                                            LCD_DATA<=8'h80+address;  
                                            state<=SET_DDRAM2;  
                                        end  
                                end  
                SET_DDRAM2:     //设定第2行DDRAM地址指令  
                                begin    
                                    LCD_RS<=0;  
                                    LCD_RW<=0;  
                              
                //-----写入第2行显示起始地址：-----   
                //  1   2  3  4   5   6   7  8  9  10  11  12  13  14  15  16  
                // 40  41 42  43  44  45 46 47 48  49  4A  4B  4C  4D  4E  4F   第二行  
                                    LCD_DATA<=8'hC0+8'd0; //第2行第1个位置    
                              
                                    state<=WRITE_RAM2;   
//                                  Data_Second_Buf<=Data_Second;    
                                    address<=6'd0;  
                                end  
                WRITE_RAM2:     //向第2行写入的数码  
                            begin  
                                if(address<=15)          //表示写第一行  
                                        begin  
                                            LCD_RS<=1;  
                                            LCD_RW<=0;  
                                            LCD_DATA<=Data_Second[address];  
//                                          Data_Second_Buf<=(Data_Second_Buf<<8);   
                                            address<=address+1'b1;  
                                            state<=WRITE_RAM2;  
                                        end  
                                    else  
                                        begin  
                                            LCD_RS<=0;  
                                            LCD_RW<=0;  
                                            LCD_DATA<=8'hC0+address;  
                                            state<=STOP;  
                                        end  
                            end  
                STOP:         
                            begin  
                                            state<=CLEAR;  
                                            address<=6'd0;  
                                            LCD_RW<=1;  
                            end  
                default:  
                            state<=CLEAR;  
            endcase               
        end  
end  
      
endmodule 

