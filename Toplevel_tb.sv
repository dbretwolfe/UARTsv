`timescale 1ns/1ps

`define DEBUG
`define DEBUG_DONE

module Toplevel_tb ();
	parameter SYSCLK_RATE = 4;
	parameter BAUD_RATE = 1;
	parameter DATA_BITS = 8;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;

	localparam CLOCK_DELAY = 5;
	localparam TX_BITS = (1 + DATA_BITS + 1 + STOP_BITS);

	logic SysClk = 0, Rst = 0, Rx = 1, CTS = 0, Data_Rdy, BIST_Busy, BIST_Error, Tx, RTS;
	logic [DATA_BITS-1:0] 	Rx_Data;
	logic [2:0] 			Rx_Error;
	logic					Clk;
	logic					FIFO_Empty;
	logic					Tests_Failed = 0;
	int						Num_Tests_Failed = 0;
	
	UART_IFace    #(.SYSCLK_RATE(SYSCLK_RATE),
					.BAUD_RATE(BAUD_RATE),
					.DATA_BITS(DATA_BITS),
					.STOP_BITS(STOP_BITS),
					.FIFO_DEPTH(FIFO_DEPTH)
				)
	TestIf();
	
	Timing_Gen #(
		.SYSCLK_RATE(SYSCLK_RATE),
		.BAUD_RATE(BAUD_RATE)
		)
	BaudGen (
		.SysClk,
		.Rst,
		.Clk
		);
	
	UARTsv TestUART(TestIf);
	
	// This task sends a single valid data packet to the UART.  It uses the data
	// input and the UART parameters to calculate parity, 
	task automatic SendData(input logic [DATA_BITS-1:0] Buf);
		logic Parity = 0;
		logic [TX_BITS-1:0] Tx_Packet;
		
		`ifdef DEBUG
			$display("Send Data called with: %h ", Buf);
		`endif
		
		for (int i = '0; i < DATA_BITS; i = i + 1) begin
			Parity = Buf[i] ^ Parity;
		end
		Tx_Packet = {1'b0, Buf, Parity, {STOP_BITS{1'b1}}};
		`ifdef DEBUG
			$display("Send Data packet: %h ", Tx_Packet);
		`endif
		for (int i = TX_BITS-1; i >=0; i--) begin
			Rx = Tx_Packet[i];
			@(posedge Clk);
		end
	endtask
	
	// This task calls the write data task in the interface, and then captures
	// the output on the Tx net.  If the packet is sent incorrectly, the task
	// will set the test failed flag and increment the number of test failed counter.
	task automatic CheckTransmit(input logic [DATA_BITS-1:0] Buf);
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
			`ifdef DEBUG
				$display("Transmit failed! Expected Data: %h  Captured Data: %h", ExpectedPacket, TestCapture);
			`endif
			Tests_Failed = 1;
			Num_Tests_Failed = Num_Tests_Failed +1;			
		end
		`ifdef DEBUG_DONE
			$display("Transmit test done");
		`endif
	endtask
	
	task automatic Fill_FIFO();
		
		logic [DATA_BITS-1:0] Buf = 0;

		for( int i = 0 ; i < FIFO_DEPTH; i++) begin
			SendData(i);
			repeat(8)
				@(posedge Clk);
		end
		for( int j = 0 ; j < FIFO_DEPTH; j++) begin
			TestIf.ReadData(Buf);
			if (Buf !== j) begin
				Tests_Failed = 1;
				Num_Tests_Failed = Num_Tests_Failed + 1;
				`ifdef DEBUG_DONE
					$display("Receive/FIFO test failed!  Sent data: %h	Received data: %h", j, Buf);
				`endif
			end
		end
		`ifdef DEBUG_DONE
			$display("Receive/FIFO test done");
		`endif
	endtask
	
	// This task starts the BIST process, which changes the internal wiring of the UART module
	// so that the Transmitter sends directly to the receivers.  The transmitter gets it's data
	// from the BIST module, which has a parameterized test sequence.  The receiver then sends
	// the received data back to the BIST instead of to the FIFO, and the BIST compares the
	// received data to the sent data.  If the received data does not match the sent data, the
	// bist should assert it's error bit.  This test fails either if the BIST does not assert it's
	// error bit when it should, or if it asserts the error bit when it should not.
	/*
	task automatic BIST_Check();
		TestIf.Start_BIST();
		while(TestIf.BIST_Busy)
			@(posedge SysClk);
		if (TestUART.SelfTest.BIST_Tx_Data_Out == TestUART.SelfTest.Rx_Data_Out) begin
			if (TestIf.BIST_Error == 1) begin
				`ifdef DEBUG
					$display ("BIST test failed: Error flag was set on success");
				`endif
				Tests_Failed = 1;
				Num_Tests_Failed = Num_Tests_Failed +1;
			end
		end
		else begin
			if (TestIf.BIST_Error == 0) begin
				`ifdef DEBUG
					$display ("BIST test failed: Error flag was not set on fail");
				`endif
				Tests_Failed = 1;
				Num_Tests_Failed = Num_Tests_Failed +1;
			end
		end
		`ifdef DEBUG_DONE
			$display("BIST test done");
		`endif
	endtask
	*/
	
	// Simple task to perform a system wide reset
	task automatic DoReset();
		TestIf.Rst = '1;
		@(posedge SysClk);
		TestIf.Rst = '0;
	endtask
		
	always begin
		#CLOCK_DELAY SysClk = ~SysClk;
	end

	initial begin
		DoReset();
		CTS = '1;
		@(posedge SysClk);
		/*
		TestIf.WriteData(8'hBB);
		SendData(8'hAA);
		TestIf.ReadData(Rx_Data);
		CheckTransmit(8'hAB);
		BIST_Check;
		*/
		Fill_FIFO;
		Fill_FIFO;
		$finish;
	end
	
endmodule
