module FIFO_TB;

parameter DATA_BITS = 8;
parameter FIFO_DEPTH = 4;

logic [DATA_BITS-1:0] Rx_Data;
logic Data_Rdy, Read_Done;
logic FIFO_Empty, FIFO_Full, FIFO_Overflow;
logic [DATA_BITS-1:0] Data_Out;

FIFO F1(.Rx_Data, .Data_Rdy, .Read_Done, .FIFO_Empty, .FIFO_Full, .FIFO_Overflow, .Data_Out);

initial 
begin 
Data_Rdy = 0;
#10    
Data_Rdy = 1;
Rx_Data = 8'b00101001;
#5
Data_Rdy = 0;
#10    
Data_Rdy = 1;
Rx_Data = 8'b11111001;
#5
Data_Rdy = 0;
#10    Data_Rdy = 1;
Rx_Data = 8'b00000001;
#5
Data_Rdy = 0;
#10    Data_Rdy = 1;
Rx_Data = 8'b11101001;

#10 Read_Done = 1;

#5 Read_Done = 0;
#5 Read_Done = 1;

#5
Data_Rdy = 0;
#10    Data_Rdy = 1;
Rx_Data = 8'b10100101;


#5 Read_Done = 0;
#5 Read_Done = 1;

#5
Data_Rdy = 0;
#10    Data_Rdy = 1;
Rx_Data = 8'b11111111;


#5
Data_Rdy = 0;
#10    Data_Rdy = 1;
Rx_Data = 8'b10000011;

#5 Read_Done = 0;
#5 Read_Done = 1;

#5 Read_Done = 0;
#5 Read_Done = 1;

#5 Read_Done = 0;
#5 Read_Done = 1;

#5 Read_Done = 0;
#5 Read_Done = 1;


end
endmodule