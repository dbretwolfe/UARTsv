module UARTsv #(
	parameter SYSCLK_RATE = 100000000,
	parameter BAUD_RATE = 9600,
	parameter DATA_BITS = 8,
	parameter PARITY_BIT = 1,
	parameter STOP_BITS = 2,
	parameter FIFO_SIZE = 8
)
(
	input logic SysClk,
	input logic Rst,
	input logic Rx,
	input logic CTS,
	input logic [DATA_BITS-1:0] Tx_Data,
	input logic Transmit_Start,
	input logic BIST_Start,
	output logic [DATA_BITS-1:0] Rx_Data,
	output logic Data_Rdy,
	output logic [2:0] Rx_Error,
	output logic BIST_Busy,
	output logic BIST_Error,
	output logic Tx,
	output logic RTS
	
);
	
	//Internal nets and variables
	wire [DATA_BITS-1:0]	Rx_Data_Out;
	wire 			Rx_In;
	wire [DATA_BITS-1:0]	Tx_Data_In;
	wire			Transmit_Start_In;
	wire			Data_Rdy_Out;		// Output from the Rx FSM indicating valid data output
	wire [DATA_BITS-1:0]	BIST_Tx_Data_Out;	// Output from the BIST module, muxed with Tx_Data
	wire 			BIST_Tx_Start_Out;	// Output from the BIST module, muxed with Transmit_Start
	wire			BIST_Mode;		// Control signal to the mux/demux, from BIST
	wire 			Clk;			// Clock generated from the timing module
	
	//Mux assignments
	assign Tx_Data_In = BIST_Mode ? BIST_Tx_Data_Out : Tx_Data; // If BIST is active, the Tx FSM gets its parallel data input from the BIST module,
								    // otherwise from the top module port.
	assign Transmit_Start_In = BIST_Mode ? BIST_Tx_Start_Out : Transmit_Start; //Likewise, the Tx FSM will get its transmit start command
								    // from the BIST module, otherwise from the top module port.
	assign Rx_In = BIST_Mode ? Tx : Rx;		// If BIST is active, the Rx FSM gets it's serial data input from the serial output of the Tx FSM,
							// otherwise the Rx FSM gets its data from the top module port
	
	assign Rx_Data = Rx_Data_Out;			// The Rx_Data top module output gets the bits of the Rx FSM output
	assign Data_Rdy = Data_Rdy_Out;
	
	//*********************************************
	//
	//		Finite State Machines
	//
	//  Receiver
	//  Transmitter
	//  Built-in Self Test
	//
	//*********************************************
	Timing_Gen #(
		.SYSCLK_RATE(SYSCLK_RATE),
		.BAUD_RATE(BAUD_RATE)
		)
	BaudGen (
		.SysClk,
		.Rst,
		.Clk
		);

	RX_FSM #(
		.PARITY_BIT(PARITY_BIT),
		.STOP_BITS(STOP_BITS),
		.DATA_BITS(DATA_BITS)
		)
	Receiver (
		.Clk,
		.Rst,
		.Rx_In,			// Input from de-mux
		.RTS,			// Output to module port
		.Data_Rdy_Out,		// Output to mux
		.Rx_Data_Out,		// Output to module port and BIST FSM
		.Rx_Error
	);

	TX_FSM #(
		.PARITY_BIT(PARITY_BIT),
		.STOP_BITS(STOP_BITS),
		.DATA_BITS(DATA_BITS)
		)
	Transmitter (
		.Clk,
		.Rst,
		.Tx_Data_In,		// Input from de-mux - either from BIST or top module port
		.Transmit_Start_In,	// Input from de-mux - either from BIST or top module port
		.CTS,			// Input from module port
		.Tx			// Output to module port
	);

	BIST_FSM #(
		.DATA_BITS(DATA_BITS)
		)
	SelfTest (
		.Clk,
		.Rst,
		.BIST_Start,		// Input from module port
		.Data_Rdy_Out,		// Input from Rx FSM
		.Rx_Data_Out,		// Input from Rx FSM
		.BIST_Mode,		// Output to mux/demux
		.BIST_Tx_Data_Out,	// Output to the Tx FSM input mux
		.BIST_Tx_Start_Out,	// Output to the Tx FSM input mux
		.BIST_Error,
		.BIST_Busy
	);
	
	FIFO #(
		.DATA_BITS(DATA_BITS);
		.FIFO_DEPTH(FIFO_DEPTH);
		)
	fifo_initialize(
		.Rx_Data,
		.Data_Rdy, 
		.Read_Done, 
		.FIFO_Empty, 
		.FIFO_Full, 
		.FIFO_Overflow, 
		.Data_Out
	);	
endmodule