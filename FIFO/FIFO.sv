module FIFO # (parameter DATA_BITS = 8,	parameter FIFO_DEPTH = 4)
		(input logic [DATA_BITS-1:0] Rx_Data,
		input logic Data_Rdy, 
		input logic Read_Done,
		output logic FIFO_Empty, 
		output logic FIFO_Full, 
		output logic FIFO_Overflow,
		output logic [DATA_BITS-1:0] Data_Out);

int WPtr, RPtr = 0;

logic [DATA_BITS-1:0] FIFO_Array [FIFO_DEPTH-1:0];

always@(posedge Data_Rdy)
	if (WPtr < FIFO_DEPTH)
	begin
		FIFO_Array[WPtr] = Rx_Data;
		WPtr = WPtr+1;
		FIFO_Empty = 0;
	end
always@(posedge Read_Done)
begin
	Data_Out <= FIFO_Array[RPtr];
	WPtr = WPtr-1;
	FIFO_Overflow =0;
	for (int i = 0; i< FIFO_DEPTH-1; i = i+1)
		FIFO_Array[i] = FIFO_Array[i+1];
	FIFO_Array[FIFO_DEPTH-1] = 0;
end

always@(WPtr)
begin
	if(WPtr == FIFO_DEPTH) FIFO_Overflow = 1;
		else if(WPtr == 0) FIFO_Empty = 1;
end

always@(WPtr)
begin
	if(WPtr == 0.75 * FIFO_DEPTH) FIFO_Full = 1;
		else FIFO_Full = 0;
end

endmodule