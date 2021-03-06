package TestTasks;

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
	task automatic CheckTransmit(input logic [DATA_BITS-1:0] Buf, output logic Result); //pragma tbx xtf
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
		if (TestCapture !== ExpectedPacket)
			Result = 1;
		else
			Result = 0;
	endtask
	
	task automatic Fill_FIFO(output logic Result); //pragma tbx xtf
		
		logic [DATA_BITS-1:0] Buf = 0;

		for( int i = 0 ; i < FIFO_DEPTH; i++) begin
			SendData(i);
			repeat(8)
				@(posedge Clk);
		end
		for( int j = 0 ; j < FIFO_DEPTH; j++) begin
			TestIf.ReadData(Buf);
			if (Buf !== j)
				Result = 1;
			else
				Result = 0;
		end
	endtask
	
	// This task starts the BIST process, which changes the internal wiring of the UART module
	// so that the Transmitter sends directly to the receivers.  The transmitter gets it's data
	// from the BIST module, which has a parameterized test sequence.  The receiver then sends
	// the received data back to the BIST instead of to the FIFO, and the BIST compares the
	// received data to the sent data.  If the received data does not match the sent data, the
	// bist should assert it's error bit.  This test fails either if the BIST does not assert it's
	// error bit when it should, or if it asserts the error bit when it should not.
	task automatic BIST_Check(output logic Result); //pragma tbx xtf
		TestIf.Start_BIST();
		while(TestIf.BIST_Busy)
			@(posedge SysClk);
		if (TestUART.SelfTest.BIST_Tx_Data_Out == TestUART.SelfTest.Rx_Data_Out) begin
			if (TestIf.BIST_Error == 1) // False positive case
				Result = 1;
			else
				Result = 0;
		end
		else begin
			if (TestIf.BIST_Error == 0) // False negative case
				Result = 1;
			else
				Result = 0;
		end
	endtask
	
	 // Check Parity Rx error
	task automatic SendData_ParityError(output logic Result); //pragma tbx xtf
		logic Parity = 0;
		logic [DATA_BITS-1:0] Buf = 8'hAA;
		logic [TX_BITS-1:0] Tx_Packet;

		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end

		Tx_Packet = {1'b0, Buf, (!Parity), {STOP_BITS{1'b1}}};

		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
		@(posedge Clk);
		if (!Rx_Error[1])
			Result = 1;
		else
			Result = 0;
	endtask

	// Check Frame Rx error
	task automatic SendData_FrameError(output logic Result); //pragma tbx xtf
		logic Parity = 0;
		logic [DATA_BITS-1:0] Buf = 8'hAA;
		logic [TX_BITS-1:0] Tx_Packet;

		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end

		Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b0}}};

		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
		@(posedge Clk);
			if (!Rx_Error[2])
				Result = 1;
			else
				Result = 0;
	endtask

	// Check Break Rx error
	task automatic SendData_BreakError(output logic Result); //pragma tbx xtf
		logic [TX_BITS-1:0] Tx_Packet = '0;
		
		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
		@(posedge Clk);
			if (!Rx_Error[0])
				Result = 1;
			else
				Result = 0;
	endtask


	
	// Simple task to perform a system wide reset
	task automatic DoReset(); //pragma tbx xtf
		Rst = '1;
		@(posedge SysClk);
		Rst = '0;
	endtask
endpackage