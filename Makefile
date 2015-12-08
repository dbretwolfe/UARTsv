#Sameer Ghewari, Portland State University, Feb 2015
#This makefile is for TBX BFM Example - Simple booth

#Specify the mode- could be either puresim or veloce
#Always make sure that everything works fine in puresim before changing to veloce

MODE ?= veloce

#make all does everything
all: work build run

#Create respective work libs and map them 
work:
	vlib work.$(MODE)
	vmap work work.$(MODE)
	
#Compile/synthesize the environment
build:
	vlog TopHVL.sv			#Compile the testbench 
ifeq ($(MODE),puresim)		#If mode is puresim, compile everything else
	vlog UARTIf_HDL.sv				#Compile the interface
	vlog UART_Top.sv					#Compile the UART DUT
	vlog TopHDL.sv				#Compule the HDL top 
	vlog Timing_Gen.sv
	vlog TX_FSM.sv
	vlog Receiver.sv
	vlog BIST.sv
	vlog FIFO.sv
	velhvl -sim $(MODE)
else						#else, synthesize!
	velanalyze -extract_hvl_info +define+QUESTA TopHVL.sv	#Analyze the HVL for external task calls in BFM 
	velanalyze UARTIf_HDL.sv			#Analyze the interface for synthesis
	velanalyze TopHDL.sv		#Analyze the HDL top for synthesis 
	velanalyze UART_Top.sv			#Analyze the UART DUT for synthesis
	velanalyze Timing_Gen.sv
	velanalyze TX_FSM.sv
	velanalyze Receiver.sv
	velanalyze BIST.sv
	velanalyze FIFO.sv
	velcomp -top TopHDL  	#Synthesize!
	velhvl -sim $(MODE) 
endif

run:
	vsim -c -do "run -all" TopHVL TopHDL	#Run all 
	cp transcript transcript.$(MODE)		#Record transcript 

norun:	#No run lets you control stepping etc. 
	vsim -c +tbxrun+norun TopHVL TopHDL -cpppath $(CPP_PATH)
	cp transcript transcript.$(MODE)

clean:
	rm -rf tbxbindings.h modelsim.ini transcript.veloce transcript.puresim work work.puresim work.veloce transcript *~ vsim.wlf *.log dgs.dbg dmslogdir veloce.med veloce.wave veloce.map velrunopts.ini edsenv 
	


