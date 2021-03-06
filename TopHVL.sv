`define DEBUG

module TopHVL;

parameter numRandomTransmits = 1000;
parameter numRandomReceives = 500;

logic result = 0, testsFailed = 0;
logic [2:0] Err;
int numTestsFailed = 0;
int numTests = 0;
logic [TopHDL.DATA_BITS-1:0] rdBuf;
logic [TopHDL.TX_BITS-1:0] cap;

// Class to generate a FIFO's worth of random data
class RandomBulk;
	randc logic [TopHDL.FIFO_DEPTH-1:0][TopHDL.DATA_BITS-1:0] data;
	rand int numSends;
	constraint c1 { numSends < TopHDL.FIFO_DEPTH;} 
	constraint c2 { numSends > 0;} 
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
	numTests += 1;
endtask

// This task randomly generates 
task automatic RandomTransmit(input int numTransmits, ref logic testsFailed, ref int numTestsFailed);
	RandomSingle dataPacket;
	logic result;
	
	dataPacket = new();
	for (int i = 0; i <numTransmits; i++) begin
		if (dataPacket.randomize()) begin
			TopHDL.TestIf.CheckTransmit(dataPacket.data, result, cap);
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
			testsFailed = 0;
		end
	end
endtask

task automatic RandomFill(input int numFills, ref logic testsFailed, ref int numTestsFailed);
	RandomBulk dataArray;
	logic [TopHDL.TestIf.DATA_BITS-1:0] Buf = 0;
	logic Result;
	dataArray = new();
	for (int k = 0; k < numFills; k ++) begin
		if (dataArray.randomize()) begin
			for( int i = 0 ; i < dataArray.numSends; i++) begin
				TopHDL.TestIf.SendData(dataArray.data[i]);
				TopHDL.TestIf.wait8();
				//$display("WPtr = %d, RPtr = %d, Empty = %b", TopHDL.TestUART.fifo_initialize.WPtr, TopHDL.TestUART.fifo_initialize.RPtr, TopHDL.TestIf.FIFO_Empty);
			end
			for( int j = 0 ; j < dataArray.numSends; j++) begin
				TopHDL.TestIf.ReadData(Buf);
				//$display("WPtr = %d, RPtr = %d, Empty = %b", TopHDL.TestUART.fifo_initialize.WPtr, TopHDL.TestUART.fifo_initialize.RPtr, TopHDL.TestIf.FIFO_Empty);
				if (Buf !== dataArray.data[j]) begin
					Result = 1;
					`ifdef DEBUG
						$display("Random fill failed! Data read = %h, Expected %h", Buf, dataArray.data[j]);
					`endif
				end
				else
					Result = 0;
				TopHDL.TestIf.wait8();
			end
		end
		else begin
			`ifdef DEBUG
				$display("Randomize array failed!");
			`endif
			testsFailed = 0;
		end
		numTests += 1;
	end
	CheckResult(.result(Result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
endtask

initial begin
	$display("Starting tests");
	TopHDL.TestIf.DoReset();	// First, we have to reset to put the system into a known state
	TopHDL.TestIf.CTS = '1;		// Since there is no receiving device, we can tie CTS high.
	TopHDL.TestIf.Rx = '1;		// Rx should start high
	
	`ifdef DEBUG
		$display("Transmit checks starting");
	`endif
	// The first two directed tasks check sending all zeroes and all ones.
	TopHDL.TestIf.CheckTransmit('0, result, cap);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Transmit check failed! Captured data: %b", cap);
	`endif
	
	TopHDL.TestIf.CheckTransmit({TopHDL.DATA_BITS{1'b1}}, result, cap);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Transmit check failed! Captured data: %b", cap);
	`endif
	
	`ifdef DEBUG
		$display("FIFO empty check starting");
	`endif
	// Now, we check the FIFO output to make sure it is zero
	if (TopHDL.TestIf.Data_Out) begin
		CheckResult(.result(1), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed)); // Test failed if data is non-zero
		`ifdef DEBUG
			$display("Null FIFO data check failed!");
		`endif
	end
	
	`ifdef DEBUG
		$display("FIFO signal checks starting");
	`endif
	// The next task fills the FIFO completely, reads the FIFO data, and compares the received
	// data to the sent data.
	TopHDL.TestIf.Fill_FIFO(result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result) begin
			$display("Fill FIFO task failed!");
			$display("Wptr = %d", TopHDL.TestUART.fifo_initialize.WPtr);
		end
	`endif
	
	TopHDL.TestIf.FIFO_Full_Check(result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result) begin
			$display("Failed to produce FIFO_Full signal!");
			$display("Wptr = %d, FIFO_Full = %b", TopHDL.TestUART.fifo_initialize.WPtr, TopHDL.TestIf.FIFO_Full);
		end
	`endif
	
	
	TopHDL.TestIf.FIFO_Overflow_Check(result);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result) begin
			$display("Failed to produce FIFO_OverFlow signal!");
			$display("Wptr = %d", TopHDL.TestUART.fifo_initialize.WPtr);
		end
	`endif
	
	`ifdef DEBUG
		$display("BIST checks starting");
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
	
	`ifdef DEBUG
		$display("RX error checks starting, ignore assertions until random checks");
	`endif
	// The following 3 tasks stimulate all of the possible Rx error signals.
	TopHDL.TestIf.SendData_ParityError(result, Err);
	CheckResult(.result(result), .testsFailed(testsFailed), .numTestsFailed(numTestsFailed));
	`ifdef DEBUG
		if (result)
			$display("Failed to produce Rx parity error! err = %h State = %s, Parity = %b, Expected = %b", Err, TopHDL.TestUART.Receiver.State, TopHDL.TestUART.Receiver.Parity_Bit[6], TopHDL.TestUART.Receiver.Reg_Parity);		
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
	
	`ifdef DEBUG
		$display("Random checks starting");
	`endif
	// Finally, the randomized tasks for transmit and receive
	RandomTransmit(numRandomTransmits, testsFailed, numTestsFailed);
	
	RandomFill(numRandomReceives, testsFailed, numTestsFailed);
	
	if (!testsFailed)
		$display("All tests have passed!");
	$display("Results: Number of tests: %d Number failed = %d", numTests, numTestsFailed);
	$finish;
end

endmodule