interface UART_IFace;

	parameter SYSCLK_RATE = 100000000;
	parameter BAUD_RATE = 9600;
	parameter DATA_BITS = 8;
	parameter PARITY_BIT = 1;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;
	
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);

	//pragma attribute UART_IFace partition_interface_xif 
	logic 					SysClk;
	logic					Clk;
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
	
	//**************************************
	//
	//	Internal Tasks
	//
	//**************************************
	
	/* Can only use from HVL side
	// Write a data packet
	task automatic WriteData(logic [DATA_BITS-1:0] WriteBuf); //pragma tbx xtf
		@(posedge Clk);
		while (Tx_Busy)	// Wait until the current transmission is finished, if any
			@(posedge Clk);
		Tx_Data = WriteBuf;	// Set the transmit data reg
		@(negedge Clk);	// On the next negative clock edge,
		Transmit_Start = '1;	// assert transmit start.
		@(negedge Tx);
		Transmit_Start = '0;	// Hold transmit start until the start bit is set on Tx.  The 
					// transmission should now be started.
	endtask
	*/
	
	
	// Read a data packet from the FIFO
	task automatic ReadData(output logic [DATA_BITS-1:0] ReadBuf); //pragma tbx xtf
		@(posedge Clk);
		while (FIFO_Empty)// Make sure the fifo is not empty
			@(posedge Clk);
		@(posedge Clk);
		Read_Done = '1;		// Strobe the Read_Done input to tell the FIFO to cycle
		@(posedge Clk);
		Read_Done = '0;		// in new data.
		ReadBuf = Data_Out; 	// Copy the data from the FIFO output
	endtask
	
	
	/*
	// Start the BIST process
	task automatic Start_BIST(logic [DATA_BITS-1:0] TestData); //pragma tbx xtf
		@(posedge Clk);
		while (Tx_Busy)
			@(posedge Clk);
		Tx_Data = TestData;
		@(posedge Clk);
		BIST_Start = '1;
		while(!BIST_Busy)
			@(posedge Clk);
		BIST_Start = '0;
	endtask
	*/
	
		//***************************************************
	//	Testbench tasks
	//
	//  Return the test results to the HVL module
	//***************************************************
	

	// This task sends a single valid data packet to the UART.  It uses the data
	// input and the UART parameters to calculate parity, 
	task SendData(input logic [DATA_BITS-1:0] Buf); //pragma tbx xtf
		logic Parity;
		logic [TX_BITS-1:0] Tx_Packet;
		
		@(posedge Clk);
		while(!RTS)
			@(posedge Clk);
		
		Parity = 0;
		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end
		Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
		Rx = '1;
	endtask

	
	// This task calls the write data task in the interface, and then captures
	// the output on the Tx net.  If the packet is sent incorrectly, the task
	// will set the test failed flag and increment the number of test failed counter.
	task CheckTransmit(input logic [DATA_BITS-1:0] Buf, output logic Result, output logic [DATA_BITS-1:0] Capture); //pragma tbx xtf
		logic [TX_BITS -1:0] TestCapture;
		logic [TX_BITS -1:0] ExpectedPacket;
		logic Parity;
		
		@(posedge Clk);
		// Wait until the transmitter is free
		while(Tx_Busy)
			@(posedge Clk);
		
		// Calculate the parity bit and assemble the expected packet
		Parity = 0;
		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end
		ExpectedPacket = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
		
		@(posedge Clk);		// Wait until the negative slow clock edge to start the transmit

		while (Tx_Busy)	// Wait until the current transmission is finished, if any
			@(posedge Clk);
		Tx_Data = Buf;	// Set the transmit data reg
		@(posedge Clk);	// On the next negative clock edge,
		Transmit_Start = '1;	// assert transmit start.
		while (!Tx_Busy)	// Wait until the current transmission is finished, if any
			@(posedge Clk);
		Transmit_Start = '0;	// Hold transmit start until the start bit is set on Tx.  The 
					// transmission should now be started.
					
		// The WriteData task finishes when it sees the start bit
		for (int i = TX_BITS -1; i >= 0; i = i -1) begin
			TestCapture[i] = Tx;
			@(posedge Clk);
		end
		// Finally, compare the captured transmit data with the sent data
		if (TestCapture !== ExpectedPacket)
			Result = 1;
		else
			Result = 0;
	endtask
	
	// This task completely fills the FIFO, and then reads out the
	// data.  If the read data does not match the written data,
	// the task reports a failure.
	task Fill_FIFO(output logic Result); //pragma tbx xtf
		logic Parity;
		logic [TX_BITS-1:0] Tx_Packet;
		logic [DATA_BITS-1:0] Buf;
		
		@(posedge Clk);
		for( int i = 0 ; i < FIFO_DEPTH; i++) begin
			
			Parity = 0;
			Tx_Packet = 0;
			Buf = i;
			
			@(posedge Clk);
			while(!RTS)
				@(posedge Clk);
				
			for (int i = '0; i < DATA_BITS; i = i + 1) begin
				Parity = Buf[i] ^ Parity;
			end
			Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
			for (int i = TX_BITS-1; i >=0; i--) begin
				Rx = Tx_Packet[i];
				@(posedge Clk);
			end
			Rx = '1;
			
			repeat(8)
				@(posedge Clk);
				
		end
		for( int j = 0 ; j < FIFO_DEPTH; j++) begin
			while (FIFO_Empty)// Make sure the fifo is not empty
				@(posedge Clk);
			@(posedge Clk);
			Read_Done = '1;		// Strobe the Read_Done input to tell the FIFO to cycle
			@(posedge Clk);
			Read_Done = '0;		// in new data.			
			if (Data_Out !== j)
				Result = 1;
			else
				Result = 0;
		end
	endtask
	
	// This task verifies that the FIFO_Full signal is being asserted
	// when the FIFO is half full plus one entry, as per the FIFO spec.
	// If the FIFO_Full signal is NOT asserted, the task reports failure.
	task FIFO_Full_Check(output logic Result); //pragma tbx xtf
		logic Parity;
		logic [TX_BITS-1:0] Tx_Packet;
		logic [DATA_BITS-1:0] Buf;
		
		@(posedge Clk);
		for( int i = 0 ; i < (FIFO_DEPTH>>1); i++) begin
			
			Parity = 0;
			Tx_Packet = 0;
			Buf = i;
			
			@(posedge Clk);
			while(!RTS)
				@(posedge Clk);
				
			for (int i = '0; i < DATA_BITS; i = i + 1) begin
				Parity = Buf[i] ^ Parity;
			end
			Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
			for (int i = TX_BITS-1; i >=0; i--) begin
				Rx = Tx_Packet[i];
				@(posedge Clk);
			end
			Rx = '1;
			
			repeat(8)
				@(posedge Clk);
				
		end
		if (!FIFO_Full)
			Result = 1;
		else
			Result = 0;
			
		for( int j = 0 ; j < (FIFO_DEPTH>>1); j++) begin
			@(posedge Clk);
		while (FIFO_Empty)// Make sure the fifo is not empty
			@(posedge Clk);
		Read_Done = '1;		// Strobe the Read_Done input to tell the FIFO to cycle
		@(posedge Clk);
		Read_Done = '0;		// in new data.
		end
	endtask
	
	// This task verifies that the FIFO_Overflow signal is being asserted
	// when the FIFO is half full plus one entry, as per the FIFO spec.
	// If the FIFO_Overflow signal is NOT asserted, the task reports failure.
	task FIFO_Overflow_Check(output logic Result); //pragma tbx xtf
		logic Parity;
		logic [TX_BITS-1:0] Tx_Packet;
		logic [DATA_BITS-1:0] Buf;
		
		@(posedge Clk);
		for( int i = 0 ; i <FIFO_DEPTH; i++) begin
			
			Parity = 0;
			Tx_Packet = 0;
			Buf = i;
			
			@(posedge Clk);
			while(!RTS)
				@(posedge Clk);
				
			for (int i = '0; i < DATA_BITS; i = i + 1) begin
				Parity = Buf[i] ^ Parity;
			end
			Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
			for (int i = TX_BITS-1; i >=0; i--) begin
				Rx = Tx_Packet[i];
				@(posedge Clk);
			end
			Rx = '1;
			
			repeat(8)
				@(posedge Clk);
			
		end
		if (!FIFO_Overflow)
			Result = 1;
		else
			Result = 0;
			
		for( int j = 0 ; j < FIFO_DEPTH; j++) begin
			while (FIFO_Empty)// Make sure the fifo is not empty
				@(posedge Clk);
			@(posedge Clk);
			Read_Done = '1;		// Strobe the Read_Done input to tell the FIFO to cycle
			@(posedge Clk);
			Read_Done = '0;		// in new data.
		end
	endtask
	
	// This task starts the BIST process, which changes the internal wiring of the UART module
	// so that the Transmitter sends directly to the receivers.  The transmitter gets it's data
	// from the BIST module, which has a parameterized test sequence.  The receiver then sends
	// the received data back to the BIST instead of to the FIFO, and the BIST compares the
	// received data to the sent data.  If the received data does not match the sent data, the
	// bist should assert it's error bit.  This test fails either if the BIST does not assert it's
	// error bit when it should, or if it asserts the error bit when it should not.
	task BIST_Check(input logic [DATA_BITS-1:0] TestData, output logic Result); //pragma tbx xtf
		@(posedge Clk);
		
		while (Tx_Busy)
			@(posedge Clk);
		Tx_Data = TestData;
		@(posedge Clk);
		BIST_Start = '1;
		while(!BIST_Busy)
			@(posedge Clk);
		BIST_Start = '0;
		while(BIST_Busy)
			@(posedge Clk);
			
		if (TestUART.SelfTest.Tx_Data_In == TestUART.SelfTest.Rx_Data_Out) begin
			if (BIST_Error == 1) // False positive case
				Result = 1;
			else
				Result = 0;
		end
		else begin
			if (BIST_Error == 0) // False negative case
				Result = 1;
			else
				Result = 0;
		end
	endtask
	
	 // Check Parity Rx error
	task SendData_ParityError(output logic Result, output logic [2:0] Err); //pragma tbx xtf
		logic Parity;
		logic [DATA_BITS-1:0] Buf;
		logic [TX_BITS-1:0] Tx_Packet;
		
		@(posedge Clk);
		while(!RTS)
			@(posedge Clk);
			
		Buf = 8'hAA;
		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end

		Tx_Packet = {1'b0, Buf, (!Parity), {STOP_BITS{1'b1}}};

		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
		Rx = '1;
		@(posedge Clk);
		@(posedge Clk);
		if (!Rx_Error[1])
			Result = 1;
		else
			Result = 0;
		Err = Rx_Error;
	endtask

	// Check Frame Rx error
	task SendData_FrameError(output logic Result, output logic [2:0] Err); //pragma tbx xtf
		logic Parity;
		logic [DATA_BITS-1:0] Buf;
		logic [TX_BITS-1:0] Tx_Packet;
		
		@(posedge Clk);
		while(!RTS)
			@(posedge Clk);
		
		Buf = 8'hAA;
		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end

		Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b0}}};

		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
		Rx = '1;
		@(posedge Clk);
		@(posedge Clk);
		if (!Rx_Error[2])
			Result = 1;
		else
			Result = 0;
		Err = Rx_Error;
	endtask

	// Check Break Rx error
	task SendData_BreakError(output logic Result, output logic [2:0] Err); //pragma tbx xtf
		logic [TX_BITS-1:0] Tx_Packet;
		
		@(posedge Clk);
		while(!RTS)
			@(posedge Clk);
		Tx_Packet = '0;
		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
		Rx = '1;
		@(posedge Clk);
		@(posedge Clk);
		if (!Rx_Error[0])
			Result = 1;
		else
			Result = 0;
		Err = Rx_Error;
	endtask

	// Simple task to perform a system wide reset
	task DoReset(); //pragma tbx xtf
		@(posedge SysClk);
		Rst = '1;
		@(posedge SysClk);
		Rst = '0;
	endtask
	
	// Wait for 8 baud clock cycles
	task wait8();
		@(posedge Clk);
		repeat(7)
			@(posedge Clk);
	endtask
			
endinterface
