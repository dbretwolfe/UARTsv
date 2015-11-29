
module RX_FSM (Rx_In, Clk, Rst, RTS, Data_Rdy_Out, Rx_Data_Out, Rx_Error); 

parameter DATA_BITS = 8; 
parameter STOP_BITS = 2;
parameter PARITY_BIT = 1;

input Rx_In;
input Clk; 
input Rst;
output logic RTS;
output logic Data_Rdy_Out;
output logic [DATA_BITS-1:0] Rx_Data_Out;
output logic [2:0] Rx_Error;

logic [DATA_BITS-1:0] Data_Reg = 0; 
logic [DATA_BITS-2:0]Parity_Bit =0;
logic [STOP_BITS-1:0] Reg_Stop = 0;
logic Reg_Parity =0;

int Count;
int Stop_Count;	

typedef enum logic[2:0] {Ready, Start_Bit, Rx_Wait, Parity, Stop_Bit, Rx_Done } Rx_States;

Rx_States State, Next_State ; 

always_ff @(posedge Clk)
begin 
	if(Rst) 
	State <= Ready;
	else 
	State <= Next_State;
end

always_comb
begin : set_Next_State

case(State)
	Ready: 	if(Rx_In == 0)
			Next_State =  Start_Bit;
		else
			Next_State = Ready;
	Start_Bit:
			Next_State =  Rx_Wait;
			
	Rx_Wait: 
		if (Count == DATA_BITS)
			begin
			Next_State = Parity;
			a1: assert (($countones(Data_Reg)%2) == Reg_Parity ); // Immediate assertion for Parity bit
			end
		else 	
			Next_State = Rx_Wait;
			
	Parity  : 	
			begin
			Next_State = Stop_Bit;
			
  	 		end
	Stop_Bit: 
		if(Stop_Count == STOP_BITS)
			begin
			Next_State = Rx_Done;	
			a2: assert ( Reg_Stop == '1) ; // Immediate assertion to check the Stop Bits 
			end
		else 	
			Next_State = Stop_Bit;
	Rx_Done: 	
			begin
			
			Next_State = Ready;
			end
endcase;
end : set_Next_State;

always_comb
begin: set_Outputs	

	RTS = 1'b0;
	Rx_Error[2] = 1'b0;
	Rx_Error[1] = 1'b0;
	Rx_Error[0] = 1'b0;
	Rx_Data_Out = 0;
	Data_Rdy_Out = 0;

case(State)
	Ready: 
		 	RTS = 1'b1;
			
	Rx_Done: 	begin
			// Break Error 
			if((Data_Reg == 0) & (Reg_Stop != '1)) Rx_Error[0] = 1'b1;
			
			// Parity Error 
			if(Parity_Bit[DATA_BITS-2] != Reg_Parity) Rx_Error[1] = 1'b1;
			
			// Framing Error 
			if(Reg_Stop != '1) Rx_Error[2] = 1'b1;
			
			// Data bits Output if there is no error in the data sent 
			if ( (Rx_Error[2] == 1'b1) | (Rx_Error[1] == 1'b1) |(Rx_Error[0] == 1'b1) | $isunknown(Data_Reg) | $isunknown(Reg_Stop))
				Rx_Data_Out = 0;
			else
				begin
				Rx_Data_Out = Data_Reg;	
				Data_Rdy_Out = 1;
				end
			end
endcase;
end : set_Outputs
 

always_ff @(posedge Clk)
begin 
if (State == Ready ) 
begin
	Count = 0;
	Stop_Count=0;
	Data_Reg =0 ;
	Parity_Bit = 0;
	Reg_Stop = 0;
end
else if (Next_State == Rx_Wait)
begin   
	Count = Count+1;
	Data_Reg = (Data_Reg << 1);
	Data_Reg = Data_Reg | Rx_In; 
end
else if (Next_State == Stop_Bit)
	begin
	Stop_Count = Stop_Count+1;
	Reg_Stop = (Reg_Stop <<1);
	Reg_Stop = Reg_Stop |Rx_In;
	end
else if (Next_State == Parity)
	begin
	Reg_Parity = Rx_In;	
	Parity_Bit[0] = (Data_Reg[1] ^ Data_Reg[0]);
	for (int i = 0; i<DATA_BITS-2; i++)
		begin Parity_Bit[i+1] = (Data_Reg[i+2] ^ Parity_Bit[i]); end
	end
end

property Data_Valid;
@(posedge Clk)
	$isunknown(Data_Reg)== 0 ;
endproperty

property Reset_Valid;
@(posedge Clk)
	($rose(Rst))	|-> $isunknown ({RTS, Data_Rdy_Out, Rx_Data_Out, Rx_Error}) == 0  ;	
endproperty

property Done;
@(posedge Clk)
	State == Rx_Done |=> RTS ;
endproperty

assert_Data_Valid : assert property(Data_Valid);
 
assert_Reset_Valid: assert property(Reset_Valid);

aseert_Done : assert property(Done);

endmodule
