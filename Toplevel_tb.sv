`timescale 1ns/1ps

module Toplevel_tb ();
	parameter SYSCLK_RATE = 4;
	parameter BAUD_RATE = 1;
	parameter DATA_BITS = 8;
	parameter PARITY_BIT = 1;
	parameter STOP_BITS = 2;
	parameter FIFO_DEPTH = 8;

	localparam CLOCK_DELAY = 5;
	localparam TX_BITS = (1 + DATA_BITS + PARITY_BIT + STOP_BITS);

	logic SysClk = 0, Rst = 0, Rx = 1, CTS = 0, Data_Rdy, BIST_Busy, BIST_Error, Tx, RTS;
	logic [DATA_BITS-1:0] 	Rx_Data;
	logic [2:0] 			Rx_Error;
	logic					Clk;
	logic					RetVal;
	logic					FIFO_Empty;
	
	UART_IFace    #(.SYSCLK_RATE(SYSCLK_RATE),
					.BAUD_RATE(BAUD_RATE),
					.DATA_BITS(DATA_BITS),
					.PARITY_BIT(PARITY_BIT),
					.STOP_BITS(STOP_BITS),
					.FIFO_DEPTH(FIFO_DEPTH)
				)
	TestIf (.SysClk(SysClk),
			.Rst(Rst),
			.Tx(Tx),
			.Rx(Rx),
			.CTS(CTS),
			.RTS(RTS));
	
	Timing_Gen #(
		.SYSCLK_RATE(SYSCLK_RATE),
		.BAUD_RATE(BAUD_RATE)
		)
	BaudGen (
		.SysClk,
		.Rst,
		.Clk
		);
		
	task automatic SendData(input logic [DATA_BITS-1:0] Buf);
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

	always begin
		#CLOCK_DELAY SysClk = ~SysClk;
	end

	UARTsv TestUART(TestIf.full);

	initial begin
		Rst = '1;
		@(posedge SysClk);
		Rst = '0;
		CTS = '1;
		@(posedge SysClk);
		fork begin
			TestIf.WriteData(8'hBB);
			SendData(8'hAA);
			TestIf.ReadData(Rx_Data);
		end
		join
		TestIf.Start_BIST();
	end
	
endmodule
