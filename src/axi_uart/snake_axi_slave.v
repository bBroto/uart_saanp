`timescale 1ns / 1ps

//adapted from somewhere 

module snake_axi_slave (
    input wire          S_AXI_ACLK,
    input wire          S_AXI_ARESETN,

    //write address channel
    input wire [31:0]   S_AXI_AWADDR,
    input wire          S_AXI_AWVALID,
    output wire         S_AXI_AWREADY,

    // write data channel
    input wire [31:0]   S_AXI_WDATA,
    input wire [3:0]    S_AXI_WSTRB,
    input wire          S_AXI_WVALID,
    output wire         S_AXI_WREADY,

    // w response channel
    output wire [1:0]   S_AXI_BRESP,
    output wire         S_AXI_BVALID,
    input wire          S_AXI_BREADY,

    // r addr channel
    input wire [31:0]   S_AXI_ARADDR,
    input wire          S_AXI_ARVALID,
    output wire         S_AXI_ARREADY,

    // r data channnel
    output wire [31:0]  S_AXI_RDATA,
    output wire [1:0]   S_AXI_RRESP,
    output wire         S_AXI_RVALID,
    input wire          S_AXI_RREADY,

    // snake config reg
    output wire [11:0]  snake_color,
    output wire [11:0]  food_color,
    output wire [11:0]  bg_color,
    output wire [23:0]  speed_div,
    
    // snake control reg
    output wire         game_up,
    output wire         game_down,
    output wire         game_left,
    output wire         game_right
);

    // internal reg
    reg [31:0] slv_reg0;  // 0x00: Colors
    reg [31:0] slv_reg1;  // 0x04: Background
    reg [31:0] slv_reg2;  // 0x08: Speed
    reg [31:0] slv_reg3;  // 0x0C: Controls

    // handshake 
    reg axi_awready;
    reg axi_wready;
    reg axi_bvalid;
    reg axi_arready;
    reg axi_rvalid;
    reg [31:0] axi_rdata;

    // output axi
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = 2'b00; 
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = 2'b00; 
    assign S_AXI_RVALID  = axi_rvalid;

    // output snake config
    assign snake_color = slv_reg0[11:0];
    assign food_color  = slv_reg0[23:12];
    assign bg_color    = slv_reg1[11:0];
    assign speed_div   = slv_reg2[23:0];
    
    // output snake control
    assign game_up     = slv_reg3[0];
    assign game_down   = slv_reg3[1];
    assign game_left   = slv_reg3[2];
    assign game_right  = slv_reg3[3];

    // write logic
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            
            //dafault
            slv_reg0 <= {8'h00, 12'h0F0, 12'hF00}; 
            slv_reg1 <= {20'h00000, 12'hFF0};      
            slv_reg2 <= {8'h00, 24'd4_000_000};    
            slv_reg3 <= 32'h0000_0000; 
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
                axi_awready <= 1'b1;
            else
                axi_awready <= 1'b0;

            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
                axi_wready <= 1'b1;
            else
                axi_wready <= 1'b0;

            // reg w 
            if (axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID) begin
                case (S_AXI_AWADDR[3:2]) //addr decode
                    2'b00: slv_reg0 <= S_AXI_WDATA;
                    2'b01: slv_reg1 <= S_AXI_WDATA;
                    2'b10: slv_reg2 <= S_AXI_WDATA;
                    2'b11: slv_reg3 <= S_AXI_WDATA; 
                    default: ; 
                endcase
            end

            if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && ~axi_bvalid)
                axi_bvalid <= 1'b1;
            else if (S_AXI_BREADY && axi_bvalid)
                axi_bvalid <= 1'b0;
        end
    end

    // read //not used here
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rdata   <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID)
                axi_arready <= 1'b1;
            else
                axi_arready <= 1'b0;

            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                case (S_AXI_ARADDR[3:2])
                    2'b00: axi_rdata <= slv_reg0;
                    2'b01: axi_rdata <= slv_reg1;
                    2'b10: axi_rdata <= slv_reg2;
                    2'b11: axi_rdata <= slv_reg3; 
                    default: axi_rdata <= 32'b0;
                endcase
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

endmodule