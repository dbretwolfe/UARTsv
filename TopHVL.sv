`define DEBUG

module TopHVL;

logic result = 0, testsFailed = 0;
logic [2:0] Err;
int numTestsFailed = 0;

task automatic CheckResult(input logic result, ref logic testsFailed, ref int numTestsFailed);
	if (result) begin
		testsFailed = 1;
		numTestsFailed += 1;
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
			$display("Failed to produce Rx parity error! err = %h", Err);
	`endif
	
	TopHDL.TestIf.SendData_FrameError(result, Err);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx frame error! err = %h", Err);
	`endif
	
	TopHDL.TestIf.SendData_BreakError(result, Err);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx break error! err = %h", Err);
	`endif
	
	if (!testsFailed)
		$display("All tests have passed!");
	$display("Results: Num failed = %d", numTestsFailed);
	$finish;
end

endmodule