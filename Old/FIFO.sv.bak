module FIFO(Rx_Data, Data_Rdy, Read_Done, FIFO_Empty, FIFO_Full, FIFO_Overflow, Data_Out);

parameter DATA_BITS = 8;
parameter FIFO_DEPTH = 4;

input [DATA_BITS-1:0] Rx_Data;
input Data_Rdy, Read_Done;
output logic FIFO_Empty, FIFO_Full, FIFO_Overflow;
output logic [DATA_BITS-1:0] Data_Out;

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