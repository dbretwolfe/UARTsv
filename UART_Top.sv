module UARTsv(UART_IFace UARTIf);

	localparam SYSCLK_RATE = UARTIf.SYSCLK_RATE;
	localparam BAUD_RATE = UARTIf.BAUD_RATE;
	localparam DATA_BITS = UARTIf.DATA_BITS;
	localparam STOP_BITS = UARTIf.STOP_BITS;
	localparam FIFO_WIDTH = UARTIf.FIFO_WIDTH;
	
	
	//Internal nets and variables
	wire [DATA_BITS-1:0]	Rx_Data_Out;
	wire 			Rx_In;
	wire			Transmit_Start_In;
	wire			Data_Rdy_Out;		// Output from the Rx FSM indicating valid data output
	wire [DATA_BITS-1:0]	BIST_Tx_Data_Out;	// Output from the BIST module, muxed with Tx_Data
	wire 			BIST_Tx_Start_Out;	// Output from the BIST module, muxed with Transmit_Start
	wire			BIST_Mode;		// Control signal to the mux/demux, from BIST
	wire 			Clk;			// Clock generated from the timing module
	wire			Tx_Out;			// Output from transmitter
	
	//Mux assignments
								    // otherwise from the top module port.
	assign Transmit_Start_In = BIST_Mode ? BIST_Tx_Start_Out : UARTIf.Transmit_Start; //Likewise, the Tx FSM will get its transmit start command
								    // from the BIST module, otherwise from the top module port.
	assign Rx_In = BIST_Mode ? Tx_Out : UARTIf.Rx;		// If BIST is active, the Rx FSM gets it's serial data input from the serial output of the Tx FSM,
							// otherwise the Rx FSM gets its data from the top module port
	assign UARTIf.Tx = BIST_Mode ? 1'b1 : Tx_Out;
	assign UARTIf.Data_Rdy = Data_Rdy_Out;
	assign UARTIf.Clk = Clk;
	
	//*********************************************
	//
	//		Modules
	//
	//  Timing Generator
	//  Receiver
	//  Transmitter
	//  Built-in Self Test
	//  FIFO
	//
	//*********************************************
	Timing_Gen #(
		.SYSCLK_RATE(SYSCLK_RATE),
		.BAUD_RATE(BAUD_RATE)
		)
	BaudGen (
		.SysClk(UARTIf.SysClk),
		.Rst(UARTIf.Rst),
		.Clk
		);

	RX_FSM #(
		.STOP_BITS(STOP_BITS),
		.DATA_BITS(DATA_BITS),
		.SYSCLOCK_FREQ(SYSCLK_RATE),
		.BAUDRATE(BAUD_RATE)
		)
	Receiver (
		.Clk(UARTIf.SysClk),
		.Rst(UARTIf.Rst),
		.Rx_In,			// Input from de-mux
		.RTS(UARTIf.RTS),			// Output to module port
		.Data_Rdy_Out,		// Output to mux
		.Rx_Data_Out,		// Output to module port and BIST FSM
		.Rx_Error(UARTIf.Rx_Error)
	);

	TX_FSM #(
		.STOP_BITS(STOP_BITS),
		.DATA_BITS(DATA_BITS)
		)
	Transmitter (
		.Clk,
		.Rst(UARTIf.Rst),
		.Tx_Data_In(UARTIf.Tx_Data),		// Input from de-mux - either from BIST or top module port
		.Transmit_Start_In,	// Input from de-mux - either from BIST or top module port
		.CTS(UARTIf.CTS),			// Input from module port
		.Tx(Tx_Out),			// Output to module port
		.Tx_Busy(UARTIf.Tx_Busy)
	);

	BIST_FSM #(
		.DATA_BITS(DATA_BITS)
		)
	SelfTest (
		.Clk,
		.Rst(UARTIf.Rst),
		.BIST_Start(UARTIf.BIST_Start),		// Input from module port
		.Tx_Data_In(UARTIf.Tx_Data),
		.Data_Rdy_Out,		// Input from Rx FSM
		.Rx_Data_Out,		// Input from Rx FSM
		.RTS(UARTIf.RTS),
		.Tx_Busy(UARTIf.Tx_Busy),
		.BIST_Mode,		// Output to mux/demux
		.BIST_Tx_Start_Out,	// Output to the Tx FSM input mux
		.BIST_Error(UARTIf.BIST_Error),
		.BIST_Busy(UARTIf.BIST_Busy)
	);

	//*********************************************
	//
	//		FIFO MODULE INSTANTIATION
	//
	//  
	//
	//*********************************************
	
	FIFO #(
		.DATA_BITS(DATA_BITS),
		.FIFO_WIDTH(FIFO_WIDTH)
		)
	RX_FIFO(
		.clk(UARTIf.SysClk),
		.rst(UARTIf.Rst),
		.Rx_Data(Rx_Data_Out),
		.Data_Rdy(Data_Rdy_Out),  		//	To write data to FIFO 
		.Pop_Data(UARTIf.Pop_Data), 		// 	To read data from FIFO
		.BIST_Mode,
		.FIFO_Empty(UARTIf.FIFO_Empty), 
		.FIFO_Full(UARTIf.FIFO_Full), 
		.FIFO_Overflow(UARTIf.FIFO_Overflow), 
		.Data_Out(UARTIf.Data_Out)
	);	
endmodule