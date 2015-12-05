module TopHVL;

bit result = 0, testsFailed = 0;
int numTestsFailed = 0;


initial begin
	$display("Starting tests");
	TopHDL.TestIf.TestPkg.DoReset();
	TopHDL.TestIf.CTS = '1;
	
	TopHDL.TestIf.TestPkg.CheckTransmit(8'hAB, result);
	if (result) begin
		testsFailed = 1;
		numTestsFailed += 1;
		$display("Transmit check failed!");
	end
	if (!testsFailed)
		$display("All tests have passed!");
	$display("Results: Num failed = %d", numTestsFailed);
	$finish;
end

endmodule