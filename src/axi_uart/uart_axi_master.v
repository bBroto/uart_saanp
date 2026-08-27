`timescale 1ns / 1ps

module uart_axi_master (
    input wire          clk,
    input wire          rst_n,

    // UART RX 
    input wire [7:0]    rx_data,
    input wire          rx_valid,

    // AXI4-Lite Master ----- write only
    output reg [31:0]   M_AXI_AWADDR,
    output reg          M_AXI_AWVALID,
    input wire          M_AXI_AWREADY,

    output reg [31:0]   M_AXI_WDATA,
    output wire [3:0]   M_AXI_WSTRB,
    output reg          M_AXI_WVALID,
    input wire          M_AXI_WREADY,

    input wire [1:0]    M_AXI_BRESP,
    input wire          M_AXI_BVALID,
    output reg          M_AXI_BREADY
);

    // hardcoded write strobe all 1, 32-bit word
    assign M_AXI_WSTRB = 4'b1111;

    // FSM 
    localparam IDLE      = 4'd0;
    localparam GET_D3    = 4'd1;
    localparam GET_D2    = 4'd2;
    localparam GET_D1    = 4'd3;
    localparam GET_D0    = 4'd4;
    localparam AXI_AW    = 4'd5;
    localparam AXI_B     = 4'd6;

    reg [3:0] state;
    
    // internal registers
    reg [31:0] addr_reg;
    reg [31:0] data_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            state         <= IDLE;
            M_AXI_AWADDR  <= 32'd0;
            M_AXI_AWVALID <= 1'b0;
            M_AXI_WDATA   <= 32'd0;
            M_AXI_WVALID  <= 1'b0;
            M_AXI_BREADY  <= 1'b0;
            addr_reg      <= 32'd0;
            data_reg      <= 32'd0;
        end else begin
            case (state)
                IDLE: begin
                    M_AXI_BREADY <= 1'b0; // clear
                    if (rx_valid) begin
                        addr_reg <= {24'd0, rx_data}; //zero padding 8  
                        state <= GET_D3;
                    end
                end

                GET_D3: begin
                    if (rx_valid) begin
                        data_reg[31:24] <= rx_data;
                        state <= GET_D2;
                    end
                end

                GET_D2: begin
                    if (rx_valid) begin
                        data_reg[23:16] <= rx_data;
                        state <= GET_D1;
                    end
                end

                GET_D1: begin
                    if (rx_valid) begin
                        data_reg[15:8] <= rx_data;
                        state <= GET_D0;
                    end
                end

                GET_D0: begin
                    if (rx_valid) begin
                        data_reg[7:0] <= rx_data;
                        // assemble for AXI 
                        M_AXI_AWADDR  <= addr_reg;
                        M_AXI_WDATA   <= {data_reg[31:8], rx_data};
                        M_AXI_AWVALID <= 1'b1;
                        M_AXI_WVALID  <= 1'b1;
                        state <= AXI_AW;
                    end
                end

               AXI_AW: begin
                    // independently clear VALID as slave accepts data and addr
                    if (M_AXI_AWREADY && M_AXI_AWVALID) begin
                        M_AXI_AWVALID <= 1'b0;
                    end
                    
                    if (M_AXI_WREADY && M_AXI_WVALID) begin
                        M_AXI_WVALID <= 1'b0;
                    end

                    // once BOTH accepted valids low
                    if ((M_AXI_AWREADY || !M_AXI_AWVALID) && (M_AXI_WREADY || !M_AXI_WVALID)) begin
                        M_AXI_BREADY <= 1'b1;
                        state <= AXI_B;
                    end
                end

                // AXI_W not needed

                AXI_B: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        M_AXI_BREADY <= 1'b0; // acknowledge 
                        state <= IDLE;        // complete
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule