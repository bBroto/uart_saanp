`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// adapted from HDLfor beginners--stacey
//////////////////////////////////////////////////////////////////////////////////

module uart_rx
  #(
    parameter CLKRATE = 50000000,
    parameter BAUD = 115200,
    parameter WORD_LENGTH = 8
    )
   (
    input 		    clk,
    input 		    rst,
    input 		    UART_RX,
    output [WORD_LENGTH-1:0] rx_data,
    output 		    rx_data_valid
    );

   // internal signals
   reg                    uart_rx_P  = 1'b0;
   reg                    uart_rx_PP = 1'b0;
   reg                    uart_rx_iD = 1'b0;
   wire                   uart_rx_i;
   reg [WORD_LENGTH-1:0]  rx_data_i;
   reg                    rx_data_ready_i;
   reg                    parity_check;

   // resolve metastability by 2 flop synch.
   always @(posedge clk)
    begin
        if(rst) begin
            uart_rx_P  <= 1'b0;
            uart_rx_PP <= 1'b0;
        end
        else begin
               uart_rx_P  <= UART_RX;
               uart_rx_PP <= uart_rx_P;
               uart_rx_iD <= uart_rx_PP;
        end
    end
    assign uart_rx_i = uart_rx_PP;
///////////////////////////////////////////////////////////////////////////////////////////////////


   // Define our states
   localparam IDLE   =3'b000,
              START  =3'b001, 
              DATA   =3'b010, 
              PARITY =3'b011, 
              STOP   =3'b100;


   reg[2:0] current_state = IDLE;
   reg[2:0] next_state    = IDLE;
	
   function integer clog2;
	   input integer value;
		begin
		   value=value-1;
			for (clog2=0;value>0;clog2=clog2+1)
			   value= value>>1;
		end
	endfunction

   // counter parameters
   // count the baud
   localparam BAUD_COUNTER_MAX = CLKRATE/BAUD;
   localparam BAUD_COUNTER_SIZE = clog2(BAUD_COUNTER_MAX);
   // count the data
   localparam DATA_COUNTER_MAX = WORD_LENGTH;
   localparam DATA_COUNTER_SIZE = clog2(DATA_COUNTER_MAX);

   reg [BAUD_COUNTER_SIZE-1:0] uart_baud_counter;
   reg [DATA_COUNTER_SIZE-1:0] uart_data_counter;
   wire                         uart_baud_done;
   wire                         uart_baud_half;
   wire                         uart_data_done;

////////////////////////////////clock management/////////////////////////
   // UART Baud Clock
   always @(posedge clk)
     begin
	if(rst) begin
           uart_baud_counter <= 0;
	end
	else begin
           // Reset at state transition
           if (uart_baud_done || current_state != next_state) begin
              uart_baud_counter <= 0;

           end
           else begin
              uart_baud_counter <= uart_baud_counter + 'd1;

           end
	end
     end

   // baud clock is done
   assign uart_baud_done = (uart_baud_counter ==  BAUD_COUNTER_MAX-1)     ? 1'b1 : 1'b0;
   assign uart_baud_half = (uart_baud_counter == (BAUD_COUNTER_MAX/2)-1) ? 1'b1 : 1'b0;

   // data counting and shifting
   always @(posedge clk)
    begin
        if(rst) begin
            uart_data_counter <= 0;
        end

        else if(current_state != next_state) begin     //doesnt matter which state but will work for start to data as well quite elegant
                uart_data_counter <= 0;
        end

        // note uart_baud_done is clk enable
        else if (uart_baud_done ) begin
                uart_data_counter <= uart_data_counter + 'd1;
        end
    end
  
   // uart_data_done indicates all bits are transmitted
   assign uart_data_done = (uart_data_counter == DATA_COUNTER_MAX-1) ? 1'b1 : 1'b0;


////////////////////////////////////////////////////////////////////////////////////


   wire start_bit_detected;
   assign start_bit_detected = (current_state==IDLE) && (uart_rx_iD && (~uart_rx_i)); 

   // State Machine
   always @(*)
     begin
        case (current_state)
          IDLE   :
            begin
               if (start_bit_detected) begin
                  next_state = START;

               end
               else begin
                  next_state = current_state;

               end
            end
          START  :
            begin
               if (uart_baud_half) begin
                  if (uart_rx_i == 1'b0) begin
                    next_state = DATA;
                  end
                  else next_state = IDLE;
               end
               else begin
                  next_state = current_state;
               end
            end
          DATA   :
            begin
               if (uart_data_done & uart_baud_done) begin
                  next_state = PARITY;

               end
               else begin
                  next_state = current_state;

               end
            end
          PARITY :
            begin
               if (uart_baud_done) begin
                  next_state = STOP;
               end
               else begin
                  next_state = current_state;

               end
            end
          STOP   :
            begin
               if (uart_baud_done) begin
                  next_state = IDLE;
               end
               else begin
                  next_state = current_state;

               end
            end
          default:
            next_state = current_state;
        endcase
     end


   always @(posedge clk)
   begin
      if(rst) begin
            current_state <= IDLE;
      end
      else begin
            current_state <= next_state;
      end
   end

    // store rx_data_i when valid for use later
   always @(posedge clk)
   begin
      if(rst) begin
            rx_data_i       <= 0;
            parity_check    <= 1'b0;
            rx_data_ready_i <= 1'b0;
      end
      else begin
            // default
            rx_data_ready_i <= 1'b0; 
            
            if(current_state==START) begin
                  parity_check <= 0;
            end
            else if ((current_state == DATA) && uart_baud_done) begin
                  rx_data_i    <= {uart_rx_i, rx_data_i[WORD_LENGTH-1:1]};
                  parity_check <= parity_check ^ uart_rx_i;
            end
            else if ((current_state == PARITY) && uart_baud_done) begin
                  parity_check <= parity_check ^ uart_rx_i;
            end
            else if ((current_state == STOP) && uart_baud_done) begin
                  rx_data_ready_i <= parity_check && uart_rx_i;
            end
      end
   end
   
   assign rx_data_valid = rx_data_ready_i;
   assign rx_data = rx_data_i;

  
endmodule