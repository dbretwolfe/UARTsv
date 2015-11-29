//
// behavioral model BIST FSM
//

module BIST_FSM#(parameter integer DATA_BITS = 8,
				 parameter integer BIST_DATA = 8'b10101010
				)
				(
				input 	logic	Clk,
				input 	logic	Rst,
				input 	logic	BIST_Start,
				input 	logic	Data_Rdy_Out,
				input 	logic [DATA_BITS-1:0]Rx_Data_Out,
				input	logic	RTS,
				input	logic	Tx_Busy,
				output 	logic BIST_Mode,
				output 	logic [DATA_BITS-1:0]BIST_Tx_Data_Out,
				output 	logic BIST_Tx_Start_Out,
				output  logic BIST_Error,
				output 	logic BIST_Busy);

//input Clk, Rst, BIST_Start, Data_Rdy_Out, [7:0]Rx_Data_Out;
//output BIST_Mode, [7:0]Tx_Data, BIST_Tx_Start_Out, [2:0]BIST_Error, BIST_Busy;
//reg BIST_Mode, BIST_Tx_Data_Out[DATA_BITS-1:0], BIST_Tx_Start_Out, [2:0]BIST_Error, BIST_Busy;

parameter ON  = 1'b1;
parameter OFF = 1'b0;

// define states using same names and state assignments as state diagram and table
// Using one-hot method, we have one bit per state

typedef enum logic [4:0] {
	READY  		= 5'b00001,
	BIST_ACTIVE	= 5'b00010,
	BIST_INIT 	= 5'b00100,
	BIST_LOOP 	= 5'b01000,
	BIST_DONE  	= 5'b10000} FSMState;
	
FSMState State, NextState;


//
// Update state or reset on every + clock edge
//

always_ff @(posedge Clk or posedge Rst)
begin
if (Rst)
	State <= READY;
else
	State <= NextState;
end

//
// Next state generation logic
//

always_comb
begin
unique case (State)
	READY:
		begin
		if (BIST_Start && !Data_Rdy_Out && RTS && !Tx_Busy)
			NextState = BIST_ACTIVE;
		else
			NextState = READY;
		end

	BIST_ACTIVE:
		begin
			NextState = BIST_INIT;
		end
	
	BIST_INIT:
		begin
			if (Tx_Busy)
				NextState = BIST_LOOP;
			else
				NextState = BIST_INIT;
		end

	BIST_LOOP:
		begin
		if (Data_Rdy_Out)
			NextState = BIST_DONE;
		else
			NextState = BIST_LOOP;
		end

	BIST_DONE:
		begin
			NextState = READY;
		end

endcase
end


//
// Outputs depend only upon state (Moore machine)
//

always_comb
begin

unique case (State)
	READY:
		begin
		BIST_Mode = 0;
		BIST_Tx_Data_Out[DATA_BITS-1:0] = 8'b00000000;
		BIST_Tx_Start_Out = 0;
		BIST_Busy = 0;
		BIST_Error =0;
		end

	BIST_ACTIVE:
		begin
		BIST_Mode = 1;
		BIST_Tx_Data_Out = BIST_DATA;
		BIST_Tx_Start_Out = 0;
		BIST_Busy = 1;
		BIST_Error = 0;
		end

	BIST_INIT:
		begin
		BIST_Mode = 1;
		BIST_Tx_Data_Out= BIST_DATA;
		BIST_Tx_Start_Out = 1;
		BIST_Busy = 1;
		BIST_Error = 0;
		end
	
	BIST_LOOP:
		begin
		BIST_Mode = 1;
		BIST_Tx_Data_Out= BIST_DATA;
		BIST_Tx_Start_Out = 0;
		BIST_Busy = 1;
		BIST_Error = 0;
		end

	BIST_DONE:
		begin
		if (BIST_Tx_Data_Out != Rx_Data_Out) BIST_Error = 1;
		
		BIST_Mode = 0;
		BIST_Tx_Data_Out[DATA_BITS-1:0] = 8'b00000000;
		BIST_Tx_Start_Out = 0;
		BIST_Busy = 0;
		end

endcase
end

endmodule

