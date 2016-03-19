/************************************************
/
/	System Verilog UART with Built in Self Test
/
/************************************************

SystemVerilog Files:

	TopHVL - HVL testbench partition, calls all of the XRTL tasks in the interface.
		modified for this course to add more debug information.
	TopHDL - HDL testbench partition, instantiates the interface and DUT, clock block.
		
	UARTIf_HDL - XRTL interface, contains all of the internal RTL and external XRTL tasks,
		contains the pin level interface to the DUT.  Modified for this course - tasks
		were re-written to accomodate new HDL, and to fix errors in compilation.

	UART_Top - The DUT - Instantiates all of the following modules.  Modified from the previous
				course to reflect new port list, and to allow connection multiple
				DUT instantiations in null-modem configuration.

	Timing_Gen - Turns the system clock into a divided baud clock for the clocked modules in the DUT.
		     Modified for this class to fix bugs in the baud clock generation.

	TX_FSM - Transmitter

	RX_FSM - Receiver - completely re-written for this class, so works completely asynchronously

	BIST - Built in self-test module - modified for this class, now synchronous with

	FIFO - Completely re-written for this class.  New FIFO makes use of synchronous logic and
		fixed several bugs from the previous version.

Emulation:
	
	Un-define "DEBUG" to turn off failure messages.
	
	Puresim: Enter "make" in the command line
	
	Veloce: Enter "make MODE=veloce" in command line
	
Project Contributions:

Devin: New HDL, modifications to XTRL test tasks, HVL testbench
Jonathan: SVA assertions, Makefile debug
Randon: Debug of HDL, emulation flow, Makefile, emulation errors
	
