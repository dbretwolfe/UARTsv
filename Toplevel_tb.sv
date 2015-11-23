`timescale 1ns/1ps

//module UARTsv #(
//	parameter SYSCLK_RATE = 100000000,
//	parameter BAUD_RATE = 9600,
//	parameter DATA_BITS = 8,
//	parameter PARITY_BIT = 1,
//	parameter STOP_BITS = 2,
//	parameter FIFO_SIZE = 8
//)
//(
//	input logic SysClk,
//	input logic Rst,
//	input logic Rx,
//	input logic CTS,
//	input logic [DATA_BITS-1:0] Tx_Data,
//	input logic Transmit_Start,
//	input logic BIST_Start,
//	output logic [DATA_BITS-1:0] Rx_Data,
//	output logic Data_Rdy,
//	output logic [2:0] Rx_Error,
//	output logic BIST_Busy,
//	output logic Tx,
//	output logic RTS
//	
//);

module Toplevel_tb ();
	parameter SYSCLK_RATE = 9600;
	parameter BAUD_RATE = 9600;
	parameter DATA_BITS = 8;
	parameter PARITY_BIT = 1;
	parameter STOP_BITS = 2;
	parameter FIFO_SIZE = 8;

	localparam CLOCK_DELAY = 9600/SYSCLK_RATE;

	logic SysClk = 0, Rst, Rx, CTS, Transmit_Start, BIST_Start, Data_Rdy, BIST_Busy, BIST_Error, Tx, RTS;
	logic [DATA_BITS-1:0] Tx_Data;
	logic [DATA_BITS-1:0] Rx_Data;
	logic [2:0] Rx_Error;
	
	always begin
		#CLOCK_DELAY SysClk = ~SysClk;
	end

	UARTsv #(.SYSCLK_RATE(SYSCLK_RATE),
		.BAUD_RATE(BAUD_RATE),
		.PARITY_BIT(PARITY_BIT),
		.STOP_BITS(STOP_BITS),
		.FIFO_SIZE(FIFO_SIZE))
	UART (.SysClk,
		.Rst,
		.Rx,
		.CTS,
		.Tx_Data,
		.Transmit_Start,
		.BIST_Start,
		.Rx_Data,
		.Data_Rdy,
		.Rx_Error,
		.BIST_Busy,
		.BIST_Error,
		.Tx,
		.RTS);

	initial begin
		Rst = '1;
		#CLOCK_DELAY Rst = '0;
		Tx_Data = 8'hAA;
		#2 Transmit_Start = 1;
		#4 Transmit_Start = 0;
	end
	
endmodule
