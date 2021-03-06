module FIFO # (parameter DATA_BITS = 8,	parameter FIFO_DEPTH = 4)
		(input logic Rst,
		input logic [DATA_BITS-1:0] Rx_Data,
		input logic Data_Rdy, 
		input logic Read_Done,
		input logic BIST_Mode,
		output logic FIFO_Empty, 
		output logic FIFO_Full, 
		output logic FIFO_Overflow,
		output logic [DATA_BITS-1:0] Data_Out);		

integer WPtr, RPtr, i, j;

logic [FIFO_DEPTH-1:0][DATA_BITS-1:0] FIFO_Array;

always@(posedge Data_Rdy or posedge Rst or posedge Read_Done )
		
		if (Rst) begin
			FIFO_Empty = 1;
			Data_Out = '0;
			WPtr = '0;
			RPtr = '0;
			FIFO_Full = 0;
			FIFO_Overflow = 0;
			FIFO_Array = '0;
		end
		
		else if (Read_Done)	begin
			if (WPtr > 0) begin
				Data_Out = FIFO_Array[RPtr];
				WPtr = WPtr-1;
				FIFO_Overflow =0;
				for (int i = 0; i< FIFO_DEPTH-1; i = i+1)
					FIFO_Array[i] = FIFO_Array[i+1];
				FIFO_Array[FIFO_DEPTH-1] = 0;
			end
		end	
		
		else if(Data_Rdy && !BIST_Mode)begin	
		if (WPtr < FIFO_DEPTH)
		begin
			FIFO_Array[WPtr] = Rx_Data;
			WPtr = WPtr+1;
			FIFO_Empty = 0;
		end	
	

		if(WPtr == (FIFO_DEPTH - 1)) FIFO_Overflow = 1;
		else if(WPtr == 0) FIFO_Empty = 1;
		else if(WPtr >= (FIFO_DEPTH >> 1)) FIFO_Full = 1;
		else FIFO_Full = 0;
		
	end
endmodule
