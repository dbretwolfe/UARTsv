module TX_FSM #(parameter integer STOP_BITS = 2,
				parameter integer DATA_BITS = 8)
		
				(input logic Clk,
				input logic Rst,
				input logic [DATA_BITS-1:0] Tx_Data_In,
				input logic Transmit_Start_In,
				input logic CTS,
				output logic Tx,
				output logic Tx_Busy);

	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);

	typedef enum logic [1:0] {IDLE = 2'b00, START = 2'b01, LOOP = 2'b10} tx_states_t;
	
	tx_states_t current_state, next_state;

	integer Tx_Counter, i;
	logic Tx_Done;
	logic [TX_BITS-1:0] Tx_Packet;
	logic Parity;
	logic Tx_Gate;
	
	// State transition block
	always_ff @ (posedge Clk or posedge Rst) begin
		if (Rst)
			current_state <= IDLE;
		else
			current_state <= next_state;
	end
	
	// Next state block
	always_comb begin
		if (Rst)
			next_state = IDLE;
		else begin
			unique case (current_state)
				IDLE:	begin
						if (Transmit_Start_In)
							next_state = START;
						else
							next_state = current_state;
					end
				START:	begin
						if (CTS)
							next_state = LOOP;
						else
							next_state = current_state;
					end
				LOOP:	begin
						if (Tx_Done)
							next_state = IDLE;
						else
							next_state = current_state;
					end
			endcase
		end
	end

	// Output logic block
	always_comb begin
		if (Rst) begin
			Tx_Gate = '0;
			Parity = '0;
			Tx_Packet = '0;
			Tx_Busy = '0;
		end
		else begin
			a1: assert 
			unique case (current_state)
				IDLE:	begin
						Tx_Gate = '0;
						Parity = '0;		
						Tx_Packet = '0;
						Tx_Busy = '0;
					end
				START:	begin
						Tx_Gate = '0;
						Tx_Busy = '1;
						for (i = '0; i < DATA_BITS; i = i + 1) begin
							Parity = Tx_Data_In[i] ^ Parity;
						end
						Tx_Packet = {1'b0, Tx_Data_In, Parity, {STOP_BITS{1'b1}}};
					end
				LOOP:	begin
						Tx_Gate = '1;
						Parity = Parity;
						Tx_Packet = Tx_Packet;
						Tx_Busy = '1;
					end
			endcase
		end
	end
	
	// Gated transmit block - necessary to separate the FSM output logic and the
	// clocked transmit output logic.  To have a transmit loop, the logic needs 
	// to be clocked, because the FSM output logic block only triggers on state change
	// or reset.
	always_ff @ (posedge Clk or posedge Rst) begin
		if (Rst) begin
			Tx_Counter <= TX_BITS - 1;
			Tx <= '1;
			Tx_Done <= '0;
		end
		else begin
			if (Tx_Gate) begin
				if (Tx_Counter === '0 && !Tx_Done) begin	//I.E, the counter only just hit zero this clock
					Tx <= Tx_Packet[Tx_Counter];
					Tx_Done <= '1;
					Tx_Counter <= Tx_Counter;
				end
				else if (Tx_Done) begin
					Tx <= '1;
					Tx_Done <= '1;
					Tx_Counter <= Tx_Counter;
				end
				else begin
					Tx <= Tx_Packet[Tx_Counter];
					Tx_Done <= '0;
					Tx_Counter <= Tx_Counter - 1;
				end
			end
			else begin
				Tx_Counter <= TX_BITS - 1;
				Tx <= '1;
				Tx_Done <= 0;
			end
		end
	end
	
	// Concurrent assertion to check the default values of being reset
	property Reset_Valid;
	@(posedge Clk)
		($rose(Rst))	|-> $isunknown ({Tx, Tx_Busy}) == 0  ;	
	endproperty
	
	property Busy_State;
	@(posedge Clk)
		(!Tx_Busy)		|-> Tx == '1;
	endproperty
	
	assert_Reset_Valid: assert property(Reset_Valid);
	
	assert_Busy_State: assert property(Busy_State);
	
endmodule
		