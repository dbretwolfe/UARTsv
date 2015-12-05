module TestBench;
parameter integer DATA_BITS = 8;
reg Clk, Rst, BIST_Start, Data_Rdy;
logic [DATA_BITS-1:0]Rx_Data_Out;
logic BIST_Error;
wire BIST_Mode, BIST_Tx_Start_Out, BIST_Busy;
logic [DATA_BITS-1:0]BIST_Tx_Data_Out;

parameter TRUE   = 1'b1;
parameter FALSE  = 1'b0;
parameter CLOCK_CYCLE  = 20ns;
parameter CLOCK_WIDTH  = CLOCK_CYCLE/2;
parameter IDLE_CLOCKS  = 2;

bit Visited[string];			// keep track of visited states

BIST_FSM BFSM(Clk, Rst, BIST_Start, Data_Rdy, Rx_Data_Out, BIST_Mode, BIST_Error, BIST_Tx_Data_Out, BIST_Tx_Start_Out, BIST_Busy );

//
// set up monitor
//

initial
begin
$display("                Time , BIST_Start, Data_Rdy, Rx_Data_Out, BIST_Tx_Data_Out, State\n");
$monitor($time, "  %b     %b       %b     %b  %s", BIST_Start, Data_Rdy, Rx_Data_Out, BIST_Tx_Data_Out, BFSM.State.name);
end


//
// Create free running clock
//

initial
begin
Clk = FALSE;
forever #CLOCK_WIDTH Clk = ~Clk;
end


//
// Generate Rst signal for two cycles
//

initial
begin
Rst = TRUE;
repeat (IDLE_CLOCKS) @(negedge Clk);
Rst = FALSE;
end


//
// Keep track of states visited
//

always @(negedge Clk)
begin
Visited[BFSM.State.name] = 1;
end


//
// Generate stimulus after waiting for reset
//

initial
begin

@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'b11, 8'b00000000};   //   Next clock MORE THAN ONE INPUT CANNOT TRANSITION TO START OF BIST
repeat (4) @(negedge Clk);


@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'b10, 8'b00000000};   //   Next clock JUST ONE INPUT CAN TRANSITION TO START OF BIST
repeat (4) @(negedge Clk);

@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'b10, 8'b00000000};   //   Next clock MORE THAN ONE INPUT CANNOT TRANSITION TO START OF BIST
repeat (4) @(negedge Clk);

@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'b01, 8'b00000000};   //  Next clock
repeat (4) @(negedge Clk);

@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'bx1, 8'b00000000};   //  Next clock
repeat (4) @(negedge Clk); // checking if the assertion for all valid inputs is working or no

@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'b11, 8'b00000000};   //  Next clock
repeat (4) @(negedge Clk); // more than one input enabled

BFSM.State = BFSM.State.first;
forever
  begin
  if (!Visited.exists(BFSM.State.name))
  	$display("Never entered state %s\n",BFSM.State.name);
  if (BFSM.State == BFSM.State.last) break;
  BFSM.State = BFSM.State.next;
  end

$stop;
end

// checking for valid inputs 

property state_validinputs_p;
@(posedge Clk)
($fell(Rst)) |-> $isunknown({Rst, BIST_Start, Data_Rdy, Rx_Data_Out}) == 0; 
endproperty

// Checking valid outputs once everything is reset

property state_validoutputs_p;
@(posedge Clk)
($fell(Rst)) |-> $isunknown({BIST_Mode, BIST_Error, BIST_Tx_Data_Out, BIST_Tx_Start_Out, BIST_Busy}) == 0; 
endproperty


// Checking not more than one input

//property state_notmorethanoneput_p;
//@(posedge Clk)
//($fell(Rst)) |-> $onehot({BIST_Start, Data_Rdy}) == 1; 
//endproperty



state_validinputs_a: assert property(state_validinputs_p); 
state_validoutputs_a: assert property(state_validoutputs_p);
//state_notmorethanoneput_a: assert property(state_notmorethanoneput_p);

endmodule

