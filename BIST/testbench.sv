module TestBench;

reg Clk, Rst, BIST_Start, Data_Rdy;
bit [7:0]Rx_Data_Out;
bit BIST_Error;
wire BIST_Mode, BIST_Tx_Start_Out, BIST_Busy;
bit [7:0]BIST_Tx_Data_Out;

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

@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'b10, 8'b00000000};   //   Next clock
repeat (4) @(negedge Clk);

@(negedge Clk); {BIST_Start, Data_Rdy, Rx_Data_Out} = {2'b01, 8'b00000000};   //  Next clock
repeat (4) @(negedge Clk);



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

/*  sequence state_transitions_s;
(State == READY) ##1
((State == BIST_ACTIVE)||(State == BIST_LOOP )||(State == BIST_DONE))
endsequence
 
property state_transitions_p;
@(posedge Clk)
($fell(Rst) |-> state_transitions_s)
endproperty

state_transitions_a: assert property(state_transitions_p);  */


//ap_A2B: assert property(@(posedge Clk) 
//$past(state)==A && !c |-> state==A; //

endmodule

