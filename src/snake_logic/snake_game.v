`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  BlahBlah Incorporation
// Engineer: Hitabrata Das
// 
// Create Date: 27.06.2025 23:13:26
// Design Name: 
// Module Name: snake_game
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


module snake_game(
    input clk,
    input reset_n,
    input left,
    input right,
    input up,
    input down,
	
    output vsync,
    output hsync,
    output reg[11:0] data
	
	//new interface signals
	input [11:0] snake_color;
    input [11:0] food_color;
    input [11:0] bg_color;
    input [23:0] speed_div;
	
	
    );
    
    
     wire [10:0] countx;
     wire [9:0]  county;
    
     wire snake_clk;
     wire [5:0]size;
    
    //Flags
     wire eaten;
     wire food;
     wire snakehead;
     wire snakebody;
     wire displayarea;
     wire not_IDLE;
    
    //sync button
    
    reg[1:0] left_b;
    reg[1:0] right_b;
    reg[1:0] up_b;
    reg[1:0] down_b;
    
    assign displayarea = (countx>0 && countx<=800)
                    	    && (county>0 && county<=600);
    

   assign eaten= snakehead && food;
    

    vga_drive vga(
        clk,
        reset_n,
        hsync,
        vsync,
        countx,
        county);
    
    random_food fruit( 
        clk,
        reset_n,
        eaten,
        countx,
        county,
        food);
		  
		  
        
    snake_update updates(
        clk,
        snake_clk,
        reset_n,
        left_b[1],
        right_b[1],
        up_b[1],
        down_b[1],
        countx,
        county,
        eaten,
        snakehead,
        snakebody,
        size,
        displayarea
        );
    
    clk_div  sclk(
        .clk(clk),
        .reset_n(reset_n),
        .speed_div(speed_div), // updated for axi
        .snake_clk(snake_clk)
    );
    
    always@ (posedge snake_clk)
    begin
        left_b[0]<=left;
        right_b[0]<=right;
        up_b[0]<=up;
        down_b[0]<=down;
        
        left_b[1]<= left_b[0];
        right_b[1]<= right_b[0];
        up_b[1]<= up_b[0];
        down_b[1]<= down_b[0];           
    end
    
    always@ (posedge clk)
    begin
        if (displayarea && size>49)
             data<=12'h00F;//blue game over hardcoded
        else if(displayarea && (snakehead ||snakebody)) 
             data<= snake_color; //red snake default
        else if(displayarea && food) 
             data<= food_color; //green food default
        else if (displayarea)
             data<= bg_color; //yellow background default
        else
             data<=12'h000;		  
    end
	
    
    
endmodule
