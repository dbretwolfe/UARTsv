module RX_FSM  #(parameter DATA_BITS = 8, 
				 parameter STOP_BITS = 2,
				 parameter SYSCLOCK_FREQ = 100000,
				 parameter BAUDRATE = 9600)
				(input Rx_In,
                input Clk,
                input Rst,
                output logic RTS,
                output logic Data_Rdy_Out,
                output logic [DATA_BITS-1:0] Rx_Data_Out,
                output logic [2:0] Rx_Error); 
    
    // This constant is a factor of the number of clock cycles per baud rate - when
    // the baud pulse counter counts to this number, 1/16th of a baud clock has elapsed.
    localparam BAUD_PULSE_COUNT = (SYSCLOCK_FREQ / (16*BAUDRATE));
    localparam NUM_RX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);
    
    /*************************************************************
     *
     *  Types and variables
     *
     *************************************************************/
    
    typedef enum integer {READY, RECEIVING, OUTPUT, CALC_ERROR, RESET} rx_states_t;
    
    // General variables
    logic rx_gate;
    logic [NUM_RX_BITS-1:0] rx_buffer;
    rx_states_t current_state, next_state;
	logic Parity_Reg;
	integer i;
    
    // Variables for the start bit detector
    logic start_detected;
    
    // Variables for the baud pulse generator   
    logic baud_pulse;
    integer baud_pulse_counter;
    
    // Variables for sample pulse generator
    logic sample_pulse;
    integer sample_pulse_counter;
    
    // Variables for bit counter
    logic bit_count_done;
	logic sample_reset;
    integer bit_counter;
    
    /*************************************************************
     *
     *  Internal signal generation logic
     *
     *************************************************************/
    
    // Start bit detector - start_detected is high when the RX line goes low
    // for the first time while the receiver is in the READY state
    always_ff @(posedge Clk or posedge Rst) begin
        if (Rst) begin
            start_detected <= 0;
        end
        else begin
            if (!Rx_In && current_state == READY) begin
                start_detected <= 1;
            end
            else begin
                start_detected <= 0;
            end
        end
    end
    
    // Baud pulse generator - generates a pulse at 16X the baud rate
    always_ff @(posedge Clk or posedge Rst) begin
        if (Rst) begin
            baud_pulse <= 0;
            baud_pulse_counter <= 0;
        end
        else begin
            if (rx_gate) begin
                if (baud_pulse_counter == BAUD_PULSE_COUNT-1) begin
                    baud_pulse <= 1;
                    baud_pulse_counter <= 0;
                end
                else begin
                    baud_pulse <= 0;
                    baud_pulse_counter <= baud_pulse_counter + 1;
                end
            end
            else begin
                baud_pulse <= 0;
                baud_pulse_counter <= 0;
            end
        end
    end
    
    // Sample pulse generator - generates a pulse halfway through each
    // baud clock, to sample in the middle of each bit.  This rejects
    // noise on the bit transition.  This counter is clocked by the
    // baud pulse signal.
    always_ff @(posedge Clk or posedge Rst) begin
        if (Rst) begin
            sample_pulse <= 0;
            sample_pulse_counter <= 0;
        end
        else begin
            if (rx_gate) begin
				if (baud_pulse) begin
					if (sample_pulse_counter == 7) begin                     // When the counter is at 7, it is halfway through the incoming bit
						sample_pulse <= 1;                                  // The sample pulse signal is asserted for one cycle
						sample_pulse_counter <= sample_pulse_counter + 1;
					end
					else if (sample_pulse_counter == 15) begin
						sample_pulse <= 0;
						sample_pulse_counter <= 0;
					end
					else begin
						sample_pulse <= 0;
						sample_pulse_counter <= sample_pulse_counter + 1;
					end
				end
            end
            else begin
                sample_pulse <= 0;
                sample_pulse_counter <= 0;
            end
        end
    end
    
    // Sampler and bit counter.  This module is clocked by the sample
    // pulse signal.  Whenever sample pulse goes high, another bit is
    // latched into the receive buffer.  Once all the bits have been
    // latched in, the bit_count_done is asserted until rx_gate is
    // deasserted.  As long as rx_gate remains high, the rx_buffer
    // keeps its value.
    always_ff @(posedge sample_pulse or posedge Rst or posedge sample_reset) begin
        if (Rst or sample_reset) begin
            bit_count_done <= 0;
            bit_counter <= NUM_RX_BITS;
            rx_buffer <= 0;
        end
        else begin
            if (rx_gate) begin
                if (sample_pulse) begin
                    if (bit_counter == 0) begin
                        bit_count_done <= 1;
                        bit_counter <= 0;
                        rx_buffer <= rx_buffer;
                    end
                    else begin
                        bit_count_done <= 0;
                        rx_buffer[bit_counter-1] <= Rx_In;
                        bit_counter <= bit_counter - 1;
                    end
                end
            end
            else begin
                bit_count_done <= 0;
                bit_counter <= NUM_RX_BITS;
                rx_buffer <= 0;
            end
        end
    end
    
    /*************************************************************
     *
     *  State machine logic
     *
     *************************************************************/
     
     // State transition logic
     always_ff @(posedge Clk) begin
        current_state = next_state;
     end
     
     // Next state logic
     always_comb begin
        if(Rst) begin
            next_state = READY;
        end
        else begin
            case (current_state)
                READY: begin
                    if (start_detected) begin       // Once a start pulse is detected, move to the
                        next_state = RECEIVING;     // receiving state.
                    end
                    else begin
                        next_state = READY;
                    end
                end
                RECEIVING: begin
                    if (bit_count_done) begin       // Receiving transitions to output once all the
                        next_state = OUTPUT;        // bits have been latched into the rx buffer.
                    end
                    else begin
                        next_state = RECEIVING;
                    end
                end
                OUTPUT: begin                       // Output takes one clock cycle to copy data from
                    next_state = CALC_ERROR;        // the rx buffer to the module output.
                end
                CALC_ERROR: begin                   // Calc error takes a clock cycle to generate the error
                    next_state = RESET;             // bits.
                end
                RESET: begin                        // Once the data is copied, reset deasserts rx_gate,
                    next_state = READY;             // which resets all of the signal generator blocks.
                end
            endcase
        end
     end
     
     // State output logic
     always_comb begin
        if(Rst) begin
             rx_gate = 0;
             Data_Rdy_Out = 0;
			 Rx_Error = 0;
             Rx_Data_Out = 0;
             RTS = 0;
			 Parity_Reg = 0;
			 sample_reset = 0;
        end
        else begin
            case (current_state)
                READY: begin
                    rx_gate = 1'b0;                 // While idle, rx_gate is kept low,
                    Data_Rdy_Out = 1'b0;            // data ready is low because the data is stale,
					Rx_Error = Rx_Error;
                    Rx_Data_Out = Rx_Data_Out;      // the current output is held over,
                    RTS = 1'b1;                     // and ready to send is asserted.
					Parity_Reg = 0;
					sample_reset = 0;
                end
                RECEIVING: begin
                    rx_gate = 1'b1;                 // Once a start bit is detected, rx_gate is asserted.
                    Data_Rdy_Out = 1'b0;
					Rx_Error = Rx_Error;
                    Rx_Data_Out = Rx_Data_Out;
                    RTS = 0;                        // At the same time, ready to send is deasserted, since
                                                    // the receiver is now busy.
					Parity_Reg = 0;
					sample_reset = 0;
                end
                OUTPUT: begin
                    rx_gate = 1'b1;
                    Data_Rdy_Out = 1'b0;
					for (i = STOP_BITS+1; i < STOP_BITS+DATA_BITS+1; i = i + 1) begin
                        Parity_Reg = rx_buffer[i] ^ Parity_Reg;
                    end
                    Rx_Data_Out = rx_buffer[(NUM_RX_BITS-2)-:DATA_BITS];    // The rx data goes onto the output one clock
                    RTS = 0;                                                // before the data ready signal is asserted,
					sample_reset = 0;
                end                                                         // so that the FIFO does not grab invalid data.
                CALC_ERROR: begin
                    rx_gate = 1'b1;                    // rx gate is deasserted, which resets all of the signal generation blocks
                    Data_Rdy_Out = 1'b0;            // Data ready is asserted, which causes the FIFO to push the new data.
                    if (rx_buffer == '0) begin			// Line break error - line stays low after start bit
                        Rx_Error[0] = 1'b1;
                    end
                    if(rx_buffer[STOP_BITS] != Parity_Reg) begin    // Parity error - parity bit doesn't match calculated parity
                        Rx_Error[1] = 1'b1;
                    end
                    if (rx_buffer[STOP_BITS-1:0] != '1) begin        // Frame error - stop bits not present
                        Rx_Error[2] = 1'b1;
                    end
                    Rx_Data_Out = Rx_Data_Out;
                    RTS = 0;                        // RTS does not go high until the next clock in the READY state.
                    Parity_Reg = Parity_Reg;
					sample_reset = 0;
                end                                           
                RESET: begin
                    rx_gate = 0;                    // rx gate is deasserted, which resets all of the signal generation blocks
                    Data_Rdy_Out = 1'b1;            // Data ready is asserted, which causes the FIFO to push the new data.	
					Rx_Error = Rx_Error;
                    Rx_Data_Out = Rx_Data_Out;
                    RTS = 0;                        // RTS does not go high until the next clock in the READY state.
					Parity_Reg = Parity_Reg;
					sample_reset = 1;
                end
            endcase
        end
     end

endmodule