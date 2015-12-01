interface UART_IFace;

	parameter SYSCLK_RATE = 100000000;
	parameter BAUD_RATE = 9600;
	parameter DATA_BITS = 8;
	parameter PARITY_BIT = 1;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;

	//pragma attribute UART_IFace partition_interface_xif 
	logic 					SysClk;
	logic 					Rst;
	logic 					Rx;
	logic 					CTS;
	logic 					Tx;
	logic 					RTS;
	logic 					BIST_Start;
	logic [DATA_BITS-1:0] 	Tx_Data;
	logic 					Transmit_Start;
	logic					Tx_Busy;
	logic [DATA_BITS-1:0] 	Data_Out;
	logic 					Data_Rdy;
	logic [2:0] 			Rx_Error;
	logic 					BIST_Busy;
	logic 					BIST_Error;
	logic 					Read_Done;		// Input to FIFO to cycle new data onto output
	logic					FIFO_Empty;		// Output from FIFO - no data
	logic					FIFO_Full; 		// Output from FIFO - 
	logic					FIFO_Overflow;		// Output from FIFO

	task automatic WriteData(logic [DATA_BITS-1:0] WriteBuf); //pragma tbx xtf
		while (Tx_Busy)	// Wait until the current transmission is finished, if any
			@(posedge SysClk);
		Tx_Data = WriteBuf;	// Set the transmit data reg
		@(negedge SysClk);	// On the next negative clock edge,
		Transmit_Start = '1;	// assert transmit start.
		@(negedge Tx);
		Transmit_Start = '0;	// Hold transmit start until the start bit is set on Tx.  The 
					// transmission should now be started.
	endtask

	task automatic ReadData(ref logic [DATA_BITS-1:0] ReadBuf); //pragma tbx xtf
		while (FIFO_Empty)// Make sure the fifo is not empty
			@(posedge SysClk);
		@(posedge SysClk);
		Read_Done = '1;		// Strobe the Read_Done input to tell the FIFO to cycle
		@(posedge SysClk);
		Read_Done = '0;		// in new data.
		ReadBuf = Data_Out; 	// Copy the data from the FIFO output
	endtask
	
	task automatic Start_BIST(); //pragma tbx xtf
		BIST_Start = '1;
		while(!BIST_Busy)
			@(posedge SysClk);
		BIST_Start = '0;
	endtask
	
	//***************************************************
	//	Testbench tasks
	//
	//  Return the test results to the HVL module
	//***************************************************
	
	// This task sends a single valid data packet to the UART.  It uses the data
	// input and the UART parameters to calculate parity, 
	task automatic SendData(input logic [DATA_BITS-1:0] Buf); //pragma tbx xtf
		logic Parity = 0;
		logic [TX_BITS-1:0] Tx_Packet;
		
		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end
		Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
	endtask
	
	// This task calls the write data task in the interface, and then captures
	// the output on the Tx net.  If the packet is sent incorrectly, the task
	// will set the test failed flag and increment the number of test failed counter.
	task automatic CheckTransmit(input logic [DATA_BITS-1:0] Buf); //pragma tbx xtf
		logic [TX_BITS -1:0] TestCapture;
		logic [TX_BITS -1:0] ExpectedPacket;
		logic Parity = 0;
		
		// Wait until the transmitter is free
		while(TestIf.Tx_Busy)
			@(posedge SysClk);
		
		// Calculate the parity bit and assemble the expected packet
		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end
		ExpectedPacket = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
		
		@(negedge Clk);		// Wait until the negative slow clock edge to start the transmit
		TestIf.WriteData(Buf);
		// The WriteData task finishes when it sees the start bit
		for (int i = TX_BITS -1; i >= 0; i = i -1) begin
			@(negedge Clk);	// Check the Tx values on the negative clock edge to avoid the transition
			TestCapture[i] = TestIf.Tx;
		end
		// Finally, compare the captured transmit data with the sent data
		if (TestCapture !== ExpectedPacket) begin
					
		end
	endtask
	
	task automatic Fill_FIFO(); //pragma tbx xtf
		
		logic [DATA_BITS-1:0] Buf = 0;

		for( int i = 0 ; i < FIFO_DEPTH; i++) begin
			SendData(i);
			repeat(8)
				@(posedge Clk);
		end
		for( int j = 0 ; j < FIFO_DEPTH; j++) begin
			TestIf.ReadData(Buf);
			if (Buf !== j) begin
				
			end
		end
	endtask
	
	// This task starts the BIST process, which changes the internal wiring of the UART module
	// so that the Transmitter sends directly to the receivers.  The transmitter gets it's data
	// from the BIST module, which has a parameterized test sequence.  The receiver then sends
	// the received data back to the BIST instead of to the FIFO, and the BIST compares the
	// received data to the sent data.  If the received data does not match the sent data, the
	// bist should assert it's error bit.  This test fails either if the BIST does not assert it's
	// error bit when it should, or if it asserts the error bit when it should not.
	task automatic BIST_Check(); //pragma tbx xtf
		TestIf.Start_BIST();
		while(TestIf.BIST_Busy)
			@(posedge SysClk);
		if (TestUART.SelfTest.BIST_Tx_Data_Out == TestUART.SelfTest.Rx_Data_Out) begin
			if (TestIf.BIST_Error == 1) begin
				
			end
		end
		else begin
			if (TestIf.BIST_Error == 0) begin
				
			end
		end
	endtask
	
	// Simple task to perform a system wide reset
	task automatic DoReset(); //pragma tbx xtf
		Rst = '1;
		@(posedge SysClk);
		Rst = '0;
	endtask
			
	);
endinterface
