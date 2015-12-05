`define DEBUG

module TopHVL;

bit result = 0, testsFailed = 0;
int numTestsFailed = 0;

task CheckResult(input logic result, ref logic testsFailed, ref logic numTestsFailed);
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
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("Transmit check failed!");
		end
	`endif
	
	TopHDL.TestIf.CheckTransmit(8'hFF, result);
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("Transmit check failed!");
		end
	`endif
	
	// The next task fills the FIFO completely, reads the FIFO data, and compares the received
	// data to the sent data.
	TopHDL.TestIf.Fill_FIFO(result);
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("Fill FIFO task failed!");
		end
	`endif
	
	//This task exercises the BIST system.  
	TopHDL.TestIf.BIST_Check(8'h00, result);
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("BIST check failed!");
		end
	`endif
	
	TopHDL.TestIf.BIST_Check(8'hFF, result);
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("BIST check failed!");
		end
	`endif
	
	// The following 3 tasks stimulate all of the possible Rx error signals.
	TopHDL.TestIf.SendData_ParityError(result);
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx parity error!");
		end
	`endif
	
	TopHDL.TestIf.SendData_FrameError(result);
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx frame error!");
		end
	`endif
	
	TopHDL.TestIf.SendData_BreakError(result);
	CheckResult(.result, .testsFailed, .numTestsFailed);
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx break error!");
		end
	`endif
	
	if (!testsFailed)
		$display("All tests have passed!");
	$display("Results: Num failed = %d", numTestsFailed);
	$finish;
end

endmodule