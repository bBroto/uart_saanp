`timescale 1ns / 1ps

module system_top(
    input wire          clk,          // 50 mhz 
    input wire          rst_n,        // active low
    input wire          UART_RX,      // uart serial
    output wire         hsync,        
    output wire         vsync,       
    output wire [11:0]  data          // VGA RGB 
);

    // internal uart to axi master
    wire [7:0] rx_data;
    wire       rx_valid;

    // internal axi4 lite wires
    wire [31:0] axi_awaddr;
    wire        axi_awvalid;
    wire        axi_awready;
    wire [31:0] axi_wdata;
    wire [3:0]  axi_wstrb;
    wire        axi_wvalid;
    wire        axi_wready;
    wire [1:0]  axi_bresp;
    wire        axi_bvalid;
    wire        axi_bready;
    wire [31:0] axi_araddr;
    wire        axi_arvalid;
    wire        axi_arready;
    wire [31:0] axi_rdata;
    wire [1:0]  axi_rresp;
    wire        axi_rvalid;
    wire        axi_rready;

    // axi read not used
    assign axi_araddr  = 32'd0;
    assign axi_arvalid = 1'b0;
    assign axi_rready  = 1'b0;

    //axi slave to snake 
    wire [11:0] snake_color;
    wire [11:0] food_color;
    wire [11:0] bg_color;
    wire [23:0] speed_div;
    wire        game_up;
    wire        game_down;
    wire        game_left;
    wire        game_right;

    // uart rx
    uart_rx #(
        .CLKRATE(50000000),
        .BAUD(115200),
        .WORD_LENGTH(8)
    ) u_uart_rx (
        .clk(clk),
        .rst(~rst_n),
        .UART_RX(UART_RX),
        .rx_data(rx_data),
        .rx_data_valid(rx_valid)
    );

    // uart to axi 
    uart_axi_master u_uart_axi_master (
        .clk(clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .M_AXI_AWADDR(axi_awaddr),
        .M_AXI_AWVALID(axi_awvalid),
        .M_AXI_AWREADY(axi_awready),
        .M_AXI_WDATA(axi_wdata),
        .M_AXI_WSTRB(axi_wstrb),
        .M_AXI_WVALID(axi_wvalid),
        .M_AXI_WREADY(axi_wready),
        .M_AXI_BRESP(axi_bresp),
        .M_AXI_BVALID(axi_bvalid),
        .M_AXI_BREADY(axi_bready)
    );

    // axi lite reg interface
    snake_axi_slave u_snake_axi_slave (
        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(axi_awaddr),
        .S_AXI_AWVALID(axi_awvalid),
        .S_AXI_AWREADY(axi_awready),
        .S_AXI_WDATA(axi_wdata),
        .S_AXI_WSTRB(axi_wstrb),
        .S_AXI_WVALID(axi_wvalid),
        .S_AXI_WREADY(axi_wready),
        .S_AXI_BRESP(axi_bresp),
        .S_AXI_BVALID(axi_bvalid),
        .S_AXI_BREADY(axi_bready),
        .S_AXI_ARADDR(axi_araddr),
        .S_AXI_ARVALID(axi_arvalid),
        .S_AXI_ARREADY(axi_arready),
        .S_AXI_RDATA(axi_rdata),
        .S_AXI_RRESP(axi_rresp),
        .S_AXI_RVALID(axi_rvalid),
        .S_AXI_RREADY(axi_rready),
        .snake_color(snake_color),
        .food_color(food_color),
        .bg_color(bg_color),
        .speed_div(speed_div),
        .game_up(game_up),
        .game_down(game_down),
        .game_left(game_left),
        .game_right(game_right)
    );

    //snake logic
    snake_game u_snake_game (
        .clk(clk),
        .reset_n(rst_n),
        .left(game_left),
        .right(game_right),
        .up(game_up),
        .down(game_down),
        .vsync(vsync),
        .hsync(hsync),
        .data(data)
    );

endmodule