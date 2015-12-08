`define DEBUG

module TopHVL;

logic result = 0, testsFailed = 0;
logic [2:0] Err;
int numTestsFailed = 0;

// Class to generate a FIFO's worth of random data
class RandomBulk;
	randc logic [TopHDL.FIFO_DEPTH-1:0][TopHDL.DATA_BITS-1:0] data;
endclass

// Class to generate a single packet of random data
class RandomSingle;
	randc logic [TopHDL.DATA_BITS-1:0] data;
endclass

task automatic CheckResult(input logic result, ref logic testsFailed, ref int numTestsFailed);
	if (result) begin
		testsFailed = 1;
		numTestsFailed += 1;
	end
endtask

task automatic RandomTransmit(input int numTransmits, ref logic testsFailed, ref int numTestsFailed);
	RandomSingle dataPacket;
	logic result;
	
	dataPacket = new();
	for (int i = 0; i <numTransmits; i++) begin
		if (dataPacket.randomize()) begin
			TopHDL.TestIf.CheckTransmit(dataPacket.data, result);
			CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
			`ifdef DEBUG
				if (result)
					$display("Random transmit check failed!");
			`endif
		end
		else begin
			`ifdef DEBUG
				$display("Randomize single failed!");
			`endif
		end	
	end
endtask

initial begin
	$display("Starting tests");
	TopHDL.TestIf.DoReset();	// First, we have to reset to put the system into a known state
	TopHDL.TestIf.CTS = '1;		// Since there is no receiving device, we can tie CTS high.
	
	// The first two directed tasks check sending all zeroes and all ones.
	TopHDL.TestIf.CheckTransmit(8'h00, result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Transmit check failed!");
	`endif
	
	TopHDL.TestIf.CheckTransmit(8'hFF, result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Transmit check failed!");
	`endif
	
	// The next task fills the FIFO completely, reads the FIFO data, and compares the received
	// data to the sent data.
	TopHDL.TestIf.Fill_FIFO(result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Fill FIFO task failed!");
	`endif
	$display("Wptr = %d", TopHDL.TestUART.fifo_initialize.WPtr);
	
	TopHDL.TestIf.Fill_FIFO(result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Fill FIFO task failed!");
	`endif
	$display("Wptr = %d", TopHDL.TestUART.fifo_initialize.WPtr);
	
	TopHDL.TestIf.FIFO_Full_Check(result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce FIFO_Full signal!");
	`endif
	$display("Wptr = %d", TopHDL.TestUART.fifo_initialize.WPtr);
	
	TopHDL.TestIf.FIFO_Overflow_Check(result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce FIFO_Overflow signal! Wptr = %d", TopHDL.TestUART.fifo_initialize.WPtr);
	`endif
	
	//This task exercises the BIST system.  
	TopHDL.TestIf.BIST_Check(8'h00, result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("BIST check failed!");
	`endif
	
	TopHDL.TestIf.BIST_Check(8'hFF, result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("BIST check failed!");
	`endif
	
	// The following 3 tasks stimulate all of the possible Rx error signals.
	TopHDL.TestIf.SendData_ParityError(result, Err);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx parity error! err = %h State = %s", Err, TopHDL.TestUART.Receiver.State);
			
	`endif
	TopHDL.TestIf.wait8();
	
	TopHDL.TestIf.SendData_FrameError(result, Err);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx frame error! err = %h State = %s", Err, TopHDL.TestUART.Receiver.State);
	`endif
	TopHDL.TestIf.wait8();
	
	TopHDL.TestIf.SendData_BreakError(result, Err);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx break error! err = %h State = %s", Err, TopHDL.TestUART.Receiver.State);
	`endif
	TopHDL.TestIf.wait8();
	
	RandomTransmit(100, testsFailed, numTestsFailed);
	
	if (!testsFailed)
		$display("All tests have passed!");
	$display("Results: Num failed = %d", numTestsFailed);
	$finish;
end

endmodule