`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 19:37:44
// Design Name: 
// Module Name: vga_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vga_drive(
    clk,
    reset_n,
    hsync,
    vsync,
    hsync_cnt,
    vsync_cnt
    );

    input clk;
    input reset_n;

    output hsync;
    output vsync;
    output reg [10:0] hsync_cnt;
    output reg [9:0]vsync_cnt;

    reg hsync;
    reg vsync;
    
     
    wire [10:0]hsync_cnt_nxt;
    wire [9:0]vsync_cnt_nxt;
    wire adv_vsync;
    wire reset_vysnc;
    
    //precalculate next value for counting
    assign hsync_cnt_nxt= hsync_cnt +1;
    assign vsync_cnt_nxt= vsync_cnt +1;
    
    //Decide weather to advance vsync
    assign adv_vsync= (hsync_cnt_nxt==11'd1040);
    assign reset_vsync= (hsync_cnt_nxt==11'd1040)&(vsync_cnt_nxt==10'd666);
    
    
    //h_sync Starts
    always@(posedge clk or posedge reset_n)
    begin 
		if (reset_n==1'b1)
		begin
			hsync_cnt<=11'd0;
			hsync<=1;
		end  
			
		 else if (hsync_cnt_nxt==11'd1040)//count over
		 begin
			hsync_cnt<=11'd0;
			hsync<=1;
		end
		  
		else if (hsync_cnt_nxt==11'd856 || hsync_cnt_nxt==11'd976)//sync pulse
		begin
			hsync_cnt<=hsync_cnt_nxt;
			hsync<= ~hsync;
		end
		  
		else 
		begin
			hsync_cnt<=hsync_cnt_nxt;
			hsync<=hsync;
		end  
    end
    //hysnc ends
    
    //vsync starts
    always@(posedge clk or posedge reset_n)
    begin 
        if (reset_n==1'b1)
        begin
            vsync_cnt<=10'd0;
            vsync<=1;
        end  
        
        else if (reset_vsync==1'b1)//count over
        begin
            vsync_cnt<=10'd0;
            vsync<=1;
        end
      
        else if ((vsync_cnt_nxt==11'd637 || vsync_cnt_nxt==11'd643) & adv_vsync==1'b1)//sync pulse
        begin
            vsync_cnt<=vsync_cnt_nxt;
            vsync<= ~vsync;
        end
      
        else if (adv_vsync==1'b1)
        begin
           vsync_cnt<=vsync_cnt_nxt;
           vsync<=vsync;
        end  
      
      else 
      begin
           vsync_cnt<=vsync_cnt;
           vsync<=vsync;
      end  
    end
    

endmodule

