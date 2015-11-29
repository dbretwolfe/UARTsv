module FIFO # (parameter DATA_BITS = 8,	parameter FIFO_DEPTH = 4)
		(input logic Rst,
		input logic [DATA_BITS-1:0] Rx_Data,
		input logic Data_Rdy, 
		input logic Read_Done,
		output logic FIFO_Empty, 
		output logic FIFO_Full, 
		output logic FIFO_Overflow,
		output logic [DATA_BITS-1:0] Data_Out);		

int WPtr, RPtr, i, j;

logic [DATA_BITS-1:0] FIFO_Array [FIFO_DEPTH-1:0];

always@(posedge Data_Rdy or posedge Rst)
	if (WPtr < FIFO_DEPTH)
	begin
		FIFO_Array[WPtr] = Rx_Data;
		WPtr = WPtr+1;
		FIFO_Empty = 0;
	end
always@(posedge Read_Done or posedge Rst)
begin
	if (Rst) begin
		Data_Out = '0;
		WPtr = '0;
		FIFO_Overflow = 0;
		for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
			for (j = 0; j < DATA_BITS; j = j + 1) begin
				FIFO_Array[i][j] = '0;
			end
		end
	end
	else begin
		Data_Out <= FIFO_Array[RPtr];
		WPtr = WPtr-1;
		FIFO_Overflow =0;
		for (int i = 0; i< FIFO_DEPTH-1; i = i+1)
			FIFO_Array[i] = FIFO_Array[i+1];
		FIFO_Array[FIFO_DEPTH-1] = 0;
	end
end

always@(WPtr or posedge Rst)
begin
	if (Rst) begin
		FIFO_Empty = 1;
	end
	else if(WPtr == FIFO_DEPTH) FIFO_Overflow = 1;
		else if(WPtr == 0) FIFO_Empty = 1;
end

always@(WPtr or posedge Rst)
begin
	if (Rst) begin
		FIFO_Full = 0;
	end
	else if(WPtr == 0.75 * FIFO_DEPTH) FIFO_Full = 1;
		else FIFO_Full = 0;
end

endmodule