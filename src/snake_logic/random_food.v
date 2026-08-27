
///outputs a food signal when high food drawn 

module random_food( 
    input vga_clk,
    input reset_n,
    input eaten,
    input [10:0] countx,
    input [9:0] county,
    output wire food    
);
 
    reg [9:0] food_x;
    reg [9:0] food_y;
    reg [9:0] rand_x = 10'd150;
    reg [9:0] rand_y = 10'd200;

    // pseudo random (simple can be improved if necessary)
    always @(posedge vga_clk) begin
        rand_x <= rand_x + 10;
        rand_y <= rand_y + 30;
    end 
 
    // update food when eaten
    always @(posedge vga_clk or posedge reset_n) begin
        if (reset_n)
            food_x <= 30;
        else if (eaten) begin
            if (rand_x >= 780)       food_x <= 430;
            else if (rand_x <= 20)   food_x <= 180; 
            else                     food_x <= rand_x + 20; 
        end
        else food_x<=food_x;
    end    

    always @(posedge vga_clk or posedge reset_n) begin
        if (reset_n)
            food_y <= 20;
        else if (eaten) begin
            if (rand_y >= 580)       food_y <= 80;
            else if (rand_y <= 20)   food_y <= 180; 
            else                     food_y <= rand_y + 20;
        end
        else food_y<=food_y;
    end    
    
  

    // comb logic to set food pixel
    
      assign  food = (countx > food_x) && (countx <=food_x + 10) &&
               (county > food_y) && (county <= food_y + 10);
   

endmodule