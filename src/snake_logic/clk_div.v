`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 14:26:50
// Design Name: 
// Module Name: clk_div
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

module clk_div(
    input clk,           // 50 mhz sys clock
    input reset_n,
    input [23:0] speed_div; // input from AXI reg
    output reg snake_clk
);

    reg [23:0] counter;

    //parameter DIV_VALUE = 24'd4_000_000; //  ~3.125 Hz  //default

    always @(posedge clk or posedge reset_n) begin
        if (reset_n) begin
            counter <= 0;
            snake_clk <= 0;
        end else begin
            if (counter == speed_div) begin
                counter <= 0;
                snake_clk <= ~snake_clk;
            end 
			else begin
                counter <= counter + 1;
            end
        end
    end

endmodule