module Timing_tb ();

logic SysClk = 0, Rst, Clk;

always begin
	#5nsSysClk = ~SysClk;
end

Timing_Gen #(.SYSCLK_RATE(9600),
		.BAUD_RATE(9600))
	Timing_Mod
	(.SysClk,
	.Rst,
	.Clk);

initial begin
	Rst = '1;
	#10 Rst = '0;
end

endmodule