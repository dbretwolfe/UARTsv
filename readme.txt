/************************************************
/
/	System Verilog UART with Built in Self Test
/
/************************************************

Files:

Emulation Files:

	TopHVL - HVL testbench partition, calls all of the XRTL tasks in the interface
	TopHDL - HDL testbench partition, instantiates the interface and DUT, clock block
	UARTIf_HDL - XRTL interface, contains all of the internal RTL and external XRTL tasks,
					contains the pin level interface to the DUT

Simulation Files:
	Toplevel_Tb - Original top level testbench, to be run in questa.  Not partitioned, will not emulate
	UARTIf - Original interface, to be run in questa.  Same conditions.

Common Files:

	UART_Top - The DUT - instantiates all of the following modules
	Timing_Gen - Turns the system clock into a divided baud clock for the clocked modules in the DUT
	TX_FSM - Transmitter
	RX_FSM - Receiver
	BIST - Built in self-test module
	FIFO

Other:

	I also included the original module level testbenches, but, again, I cannot verify that they
	work correctly after the changes made to the common modules for emulation.
	
Transcripts:
	
	transcript - Veloce run
		The project files analyze and compile correctly, but during the compile_velsyn_0 task, the FIFO produces
		the error
		
		"The state element TopHDL.TestUART.fifo_initialize.rtlcreg_WPtr_X appears to be in a combinational cycle"
		
		for each bit X of WPtr.  WPtr is the write pointer for the FIFO, and veloce will not allow it to be either
		used inside a combinational block, or to be evaluated as part of any logical declaration, such as
		"if(WPtr-Rptr == 0) FIFO_Empty = 1".  This is absolutely disabling for this project, because without checking
		the position of the write pointer the FIFO cannot function.  We have tried multiple solutions to this problem,
		but as of the project deadline nothing has worked.  I believe this to be the only error in the project, as
		the FIFO block is the last to be analyzed and no other blocks produce errors during compilation or synthesis.
	
	transcript.puresim - Puresim run
		The project runs perfectly in puresim.  The assertion related error messages are due to error
		injection - the HVL testbench deliberately sends bad packets to the DUT to tickle the Receiver
		error messages.
	
Simulation:
	The simulation only files may no longer work in Questa due to incremental changes to the common module during
the emulation process.  The sim files can be loaded into questa, compiled together, and run by simulating Toplevel_Tb.

Emulation:
	
	Un-define "DEBUG" to turn off failure messages.
	
	Puresim: Enter "make" in the command line
	
	Veloce: Enter "make MODE=veloce" in command line
	
Project Contributions:


Simulation testbench, HVL/HDL testbench, Interfaces, DUT top module, Tx FSM, Timing gen, Emulation - Devin Wolfe
Receiver - Goutham Konidala
BIST - Nikhil Marda
FIFO - Goutham and Nikhil, synchronous changes by Devin
Assertions - All
Project presentation - Nikhil Marda
Test tasks - All
	
