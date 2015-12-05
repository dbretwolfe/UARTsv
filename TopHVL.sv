`define DEBUG

module TopHVL;

bit result = 0, testsFailed = 0;
int numTestsFailed = 0;


initial begin
	$display("Starting tests");
	TopHDL.TestIf.DoReset();	// First, we have to reset to put the system into a known state
	TopHDL.TestIf.CTS = '1;		// Since there is no receiving device, we can tie CTS high.
	
	// The first two directed tasks check sending all zeroes and all ones.
	TopHDL.TestIf.CheckTransmit(8'h00, result);
	if (result) begin
		testsFailed = 1;
		numTestsFailed += 1;
		`ifdef DEBUG
			$display("Transmit check failed!");
		`endif
	end
	
	TopHDL.TestIf.CheckTransmit(8'hFF, result);
	if (result) begin
		testsFailed = 1;
		numTestsFailed += 1;
		`ifdef DEBUG
			$display("Transmit check failed!");
		`endif
	end
	
	// The next task fills the FIFO completely, reads the FIFO data, and compares the received
	// data to the sent data.
	TopHDL.TestIf.Fill_FIFO(result);
	if (result) begin
		testsFailed = 1;
		numTestsFailed += 1;
		`ifdef DEBUG
			$display("Fill FIFO task failed!");
		`endif
	end
	
	if (!testsFailed)
		$display("All tests have passed!");
	$display("Results: Num failed = %d", numTestsFailed);
	$finish;
end

endmodule