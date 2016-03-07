interface UART_IFace;

	parameter SYSCLK_RATE = 100000000;
	parameter BAUD_RATE = 9600;
	parameter DATA_BITS = 8;
	parameter PARITY_BIT = 1;
	parameter STOP_BITS = 2;
	parameter FIFO_WIDTH = 8;
	
	localparam FIFO_ENTRIES = 2**FIFO_WIDTH;
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);

//////////////////    Assertion Block     ////////////////////
//assert range of SysCLK_Rate
//assert (SYSCLK_RATE > 3) else $error("SYSCLK_RATE is not in bounds");  
//assert (SYSCLK_RATE<200000000) else $error("SYSCLK_RATE is not in bounds");  
//assert range of Baud_Rate  
//assert ((BAUD_RATE > 0) && (BAUD_RATE<7000000)) else $error("BAUD_RATE is not in bounds");  
//assert range of Data Bits  
//assert ((DATA_BITS > 0) && (DATA_BITS<9)) else $error("DATA_BITS is not in bounds");  
//assert range of Stop_bits  
//assert ((STOP_BITS > 0) && (STOP_BITS<3)) else $error("STOP_BITS is not in bounds");  
//assert range of FIFO_Depth  
//assert ((FIFO_DEPTH > 0) && (FIFO_DEPTH<17)) else $error("FIFO_DEPTH is not in bounds");  
//Assert critical relationships Baud rate, sysCLK_Rate, clock delay(below)  

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
	logic 					Pop_Data;		// Input to FIFO to cycle new data onto output
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
		@(posedge Clk);
	endtask
	*/
	
	
	// Read a data packet from the FIFO
	task ReadData(output logic [DATA_BITS-1:0] ReadBuf); //pragma tbx xtf
		@(posedge Clk);
		Pop_Data = '1;		// Strobe the Pop_Data input to tell the FIFO to cycle
		@(posedge Clk);
		Pop_Data = '0;		// in new data.
		ReadBuf = Data_Out; 	// Copy the data from the FIFO output
		@(posedge Clk);
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
		@(posedge Clk);
		Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
		@(posedge Clk);
		$display("Tx packet = %b", Tx_Packet);
		for (int i = TX_BITS-1; i >=0; i--) begin
			@(posedge Clk);
			Rx = Tx_Packet[i];
		end
		Rx = '1;
		@(posedge Clk);
	endtask

	
	// This task calls the write data task in the interface, and then captures
	// the output on the Tx net.  If the packet is sent incorrectly, the task
	// will set the test failed flag and increment the number of test failed counter.
	task CheckTransmit(input logic [DATA_BITS-1:0] Buf, output logic Result, output logic [TX_BITS-1:0] Capture); //pragma tbx xtf
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
		@(posedge Clk);		
		// The WriteData task finishes when it sees the start bit
		for (int i = TX_BITS -1; i >= 0; i = i -1) begin
			@(posedge Clk);
			TestCapture[i] = Tx;		
		end
		// Finally, compare the captured transmit data with the sent data
		if (TestCapture !== ExpectedPacket)
			Result = 1;
		else
			Result = 0;
		Capture = TestCapture;
	endtask
	
	// This task fills the FIFO, and then reads out the
	// data.  If the read data does not match the written data,
	// the task reports a failure.
	task Fill_FIFO(input integer num_entries, output logic Result); //pragma tbx xtf
		logic [DATA_BITS-1:0] buffer, i;
		@(posedge Clk);
		buffer = 0;
		Result = 0;
		for (i = 0; i < num_entries; i++) begin
			@(posedge Clk);
			$display("Pushing %b", i);
			logic Parity;
			logic [TX_BITS-1:0] Tx_Packet;
			
			@(posedge Clk);
			while(!RTS)
				@(posedge Clk);
			
			Parity = 0;
			for (int i = '0; i < DATA_BITS; i = i + 1) begin
				Parity = Buf[i] ^ Parity;
			end
			@(posedge Clk);
			Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
			@(posedge Clk);
			$display("Tx packet = %b", Tx_Packet);
			for (int i = TX_BITS-1; i >=0; i--) begin
				@(posedge Clk);
				Rx = Tx_Packet[i];
			end
			Rx = '1;
		end
		@(posedge Clk);
		for (i = 0; i < num_entries; i++) begin
			@(posedge Clk);
			Pop_Data = '1;		// Strobe the Pop_Data input to tell the FIFO to cycle
			@(posedge Clk);
			Pop_Data = '0;		// in new data.
			ReadBuf = Data_Out; 	// Copy the data from the FIFO output
			@(posedge Clk);
			$display("Read buffer = %b", buffer);
			if (buffer != i) begin
				Result = 1;
			end
			else begin
				Result = Result;
			end
		end
	endtask
	
	// This task verifies that the FIFO_Full signal is being asserted
	// when the FIFO is half full plus one entry, as per the FIFO spec.
	// If the FIFO_Full signal is NOT asserted, the task reports failure.
	task FIFO_Full_Check(output logic Result); //pragma tbx xtf
		Result = 1;
	endtask
	
	// This task verifies that the FIFO_Overflow signal is being asserted
	// when the FIFO is half full plus one entry, as per the FIFO spec.
	// If the FIFO_Overflow signal is NOT asserted, the task reports failure.
	task FIFO_Overflow_Check(output logic Result); //pragma tbx xtf
		Result = 1;
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
		Parity = 0;
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
		if (!Rx_Error[1]) begin
			Result = 1;
			@(posedge Clk);
			Pop_Data = '1;		// Strobe the Pop_Data input to tell the FIFO to cycle
			@(posedge Clk);
			Pop_Data = '0;		// in new data.
		end
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
		if (!Rx_Error[2]) begin
			Result = 1;
			@(posedge Clk);
			Pop_Data = '1;		// Strobe the Pop_Data input to tell the FIFO to cycle
			@(posedge Clk);
			Pop_Data = '0;		// in new data.
		end
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
		if (!Rx_Error[0]) begin
			Result = 1;
			@(posedge Clk);
			Pop_Data = '1;		// Strobe the Pop_Data input to tell the FIFO to cycle
			@(posedge Clk);
			Pop_Data = '0;		// in new data.
		end
		else
			Result = 0;
		Err = Rx_Error;
	endtask

	// Simple task to perform a system wide reset
	task DoReset(); //pragma tbx xtf
		@(posedge SysClk);
		Rst = '1;
		CTS = '1;
		Rx = '1;
		Pop_Data = '0;
		BIST_Start = '0;
		@(posedge SysClk);
		Rst = '0;
		wait8();
		wait8();
	endtask
	
	// Wait for 8 baud clock cycles
	task wait8(); //pragma tbx xtf
		@(posedge Clk);
		repeat(7)
			@(posedge Clk);
	endtask
			
endinterface
