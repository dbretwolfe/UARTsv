module RX_FSM_TB;

parameter DATA_BITS = 8;

logic Rx_In, Clk, Rst; 
logic RTS;
logic Data_Rdy_Out;
logic [DATA_BITS-1:0] Rx_Data_Out;
logic [2:0] Rx_Error;

RX_FSM R1(.Rx_In, .Clk, .Rst, .RTS, .Data_Rdy_Out, .Rx_Data_Out, .Rx_Error);

initial begin
 Clk = 0; 
end
always
 #5  Clk =  ! Clk;

initial
begin
    
Rx_In = 1'b1;
// Test input with parity error - Parity Error 
#20 Rx_In = 1'b0; // Start
#10 Rx_In = 1'b0; // Data and parity
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b1; //Parity
#10 Rx_In = 1'b1;
// Test input without any error 
#50 Rx_In = 1'b0; // Start
#10 Rx_In = 1'b1; // Data and Parity
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b1; // Stop 
#10 Rx_In = 1'b1;

// Test input with stop bit error - Framing error 
#40 Rx_In = 1'b0; // Start
#10 Rx_In = 1'b1; // Data and Parity
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0; // Stop 

#10 Rx_In = 1'b1; 

// Test input with Rx low for a duration of character and stop bit not detected - Break error 
#40 Rx_In = 1'b0; // Start
#10 Rx_In = 1'b0; // Data and Parity
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0; // Stop 

#10 Rx_In = 1'b1; 

// Test input with Break error and parity error
#40 Rx_In = 1'b0; // Start
#10 Rx_In = 1'b0; // Data and Parity
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b0;
#10 Rx_In = 1'b1;
#10 Rx_In = 1'b0; // Stop 


#60 Rx_In = 1'b1;
#40 Rx_In = 1'b0;

end
endmodule
