`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2025 17:19:43
// Design Name: 
// Module Name: snake_update
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: can be optimized a lot then again who cares
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module snake_update(
    input clk,
    input snake_clk,
    input reset_n,
    input left,
    input right,
    input up,
    input down,
    input [10:0] countx,
    input [9:0]  county,
    input eaten,
	input displayarea,
	
    output reg  snakehead,
    output wire snakebody,
    output reg [5:0] size
    );
  
    
    

   
    reg[9:0] snake_body_x[49:0];
    reg[9:0] snake_body_y[49:0];
    reg[9:0] head_next_x;
    reg[9:0] head_next_y;
    
    reg [49:1] snakebody_arr;
    
    integer count1, count2, count3;
    
    reg [2:0] direction;
    reg [2:0] next_direction;
    

    
    
    reg found;  
    
    parameter IDLE= 0, RIGHT= 1,LEFT=2,UP=3,DOWN=4;
    
  
    
//State Update   and head update
    always@(posedge snake_clk or posedge reset_n)
    begin
		if (reset_n)
			begin
			direction<=IDLE;
		end
		else    
			begin
				direction<= next_direction;
		end
    end
        
        
//Next State Calculation
     always@(*)
     begin
            case(direction)
                 IDLE:
                     begin
                         if(left) 
                             next_direction= LEFT;
                         else if(right)
                             next_direction= RIGHT;    
                         else if(down)
                             next_direction= DOWN;
                         else if (up)
                             next_direction= UP;
                         else  
                             next_direction=IDLE;            
                     end    
                 LEFT:
                     begin
                         if(left) 
                             next_direction= LEFT;
                         else if(right)
                             next_direction= LEFT;    
                         else if(down)
                             next_direction= DOWN;
                         else if (down)
                             next_direction= UP;
                         else  
                             next_direction=LEFT;
                     end  
                 RIGHT:
                     begin
                         if(left) 
                             next_direction= RIGHT;
                         else if(right)
                             next_direction= RIGHT;    
                         else if(down)
                             next_direction= DOWN;
                         else if (up)
                             next_direction= UP;
                         else  
                             next_direction=RIGHT;
                     end  
                 UP:
                     begin
                         if(left) 
                             next_direction= LEFT;
                         else if(right)
                             next_direction= RIGHT;    
                         else if(down)
                             next_direction= UP;
                         else if (up)
                             next_direction= UP;
                         else  
                             next_direction=UP;
                     end  

                 DOWN:
                     begin
                         if(left) 
                             next_direction= LEFT;
                         else if(right)
                             next_direction= RIGHT;    
                         else if(down)
                             next_direction= DOWN;
                         else if (up)
                             next_direction= DOWN;
                         else  
                             next_direction=DOWN;
                     end 
                     
                 default:  
                         next_direction=IDLE;
            endcase
    end         
    
//update snake body for next frame       
	always @(posedge snake_clk or posedge reset_n) begin
		if (reset_n) begin
			for (count3 = 1; count3< 50; count3 = count3 + 1) begin
				snake_body_x[count3] = 10'd820;
				snake_body_y[count3] = 10'd630;    //illegals
			end
			snake_body_x[0] = 10'd200;
		    snake_body_y[0] = 10'd200;
		end 
		
		else if (|direction) begin
			for (count1 = 49; count1 > 0; count1 = count1 - 1) begin
				snake_body_x[count1] = snake_body_x[count1 - 1];
				snake_body_y[count1] = snake_body_y[count1 - 1];
			end

			case(direction)
				IDLE: begin
				   snake_body_x[0] = 10'd200;
				   snake_body_y[0] = 10'd200;
				end
				LEFT:  snake_body_x[0] = (snake_body_x[0]!=0)   ? snake_body_x[1] - 10 : 800;
				RIGHT: snake_body_x[0] = (snake_body_x[0]!=800) ? snake_body_x[1] + 10 :  0;
				UP:    snake_body_y[0] = (snake_body_y[0]!=0)   ? snake_body_y[1] - 10 : 600;
				DOWN:  snake_body_y[0] = (snake_body_y[0]!=600) ? snake_body_y[1] + 10 :  0;
				default: begin
					snake_body_x[0] = 10'd200;
					snake_body_y[0] = 10'd200;
				end
			endcase
		end
	end
	
	
        
    always@(posedge clk)
        begin
            snakehead = (countx>=snake_body_x[0])&&(countx<snake_body_x[0]+10)&&
            (county>=snake_body_y[0])&(county<snake_body_y[0]+10);
        end
        
    always@(posedge clk)
        begin
            		
            for(count2 = 1; count2 < 50; count2 = count2 + 1)
                    begin				
                        snakebody_arr[count2] <= ((countx >=snake_body_x[count2] 
                        && countx < snake_body_x[count2]+10) 
                        && (county >= snake_body_y[count2] 
                        && county < snake_body_y[count2]+10)) && (count2<size);
                    end                     
        end
    
    assign snakebody = |snakebody_arr;
        
   //update size       
   always@(posedge clk or posedge reset_n)  begin   
           if (reset_n) size<=1;
           else if (eaten) size<=size+1;
           else size<=size;
    end  




endmodule
