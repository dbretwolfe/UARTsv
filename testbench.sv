module TestBench;
parameter integer DATA_BITS = 8;
reg Clk, Rst, BIST_Start, Data_Rdy_Out,RTS, Tx_Busy;
reg [DATA_BITS-1:0]Tx_Data_In;
logic [DATA_BITS-1:0]Rx_Data_Out;
logic BIST_Error;
wire BIST_Mode, BIST_Tx_Start_Out, BIST_Busy;


parameter TRUE   = 1'b1;
parameter FALSE  = 1'b0;
parameter CLOCK_CYCLE  = 20ns;
parameter CLOCK_WIDTH  = CLOCK_CYCLE/2;
parameter IDLE_CLOCKS  = 2;

bit Visited[string];			// keep track of visited states

BIST_FSM BFSM(Clk, Rst, BIST_Start, Tx_Data_In, Data_Rdy_Out, Rx_Data_Out, RTS, Tx_Busy, BIST_Mode, BIST_Tx_Start_Out, BIST_Error, BIST_Busy );

//
// set up monitor
//

initial
begin
$display("                Time , BIST_Start, Data_Rdy_Out, Rx_Data_Out,BIST_Mode,BIST_Tx_Start_Out,BIST_Error,	BIST_Busy, State\n");
$monitor($time, "  %b     %b          %b   %b   %b  %b   %b  %s", BIST_Start, Data_Rdy_Out, Rx_Data_Out, BIST_Mode,BIST_Tx_Start_Out,BIST_Error,	BIST_Busy,BFSM.State.name);
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

@(negedge Clk); {BIST_Start, Data_Rdy_Out,RTS, Tx_Busy, Tx_Data_In, Rx_Data_Out} = {2'b10, 2'b10, 8'b00000000, 8'b00000000};   //   Next clock MORE THAN ONE INPUT CANNOT TRANSITION TO START OF BIST
repeat (4) @(negedge Clk);


@(negedge Clk); {BIST_Start, Data_Rdy_Out,RTS, Tx_Busy, Tx_Data_In, Rx_Data_Out} = {2'b10,2'b11, 8'b00000000, 8'b00000000};   //   Next clock JUST ONE INPUT CAN TRANSITION TO START OF BIST
repeat (4) @(negedge Clk);

@(negedge Clk); {BIST_Start, Data_Rdy_Out,RTS, Tx_Busy, Tx_Data_In, Rx_Data_Out} = {2'b11, 2'b10, 8'b00000000, 8'b00000000};   //   Next clock MORE THAN ONE INPUT CANNOT TRANSITION TO START OF BIST
repeat (4) @(negedge Clk);

@(negedge Clk); {BIST_Start, Data_Rdy_Out,RTS, Tx_Busy, Tx_Data_In, Rx_Data_Out} = {2'b10, 2'b10, 8'b00000000, 8'b00110000};   //  Next clock
repeat (4) @(negedge Clk);

@(negedge Clk); {BIST_Start, Data_Rdy_Out,RTS, Tx_Busy, Tx_Data_In, Rx_Data_Out} = {2'b10, 2'b11, 8'b00000000, 8'b00110000};   //  Next clock
repeat (4) @(negedge Clk); 

@(negedge Clk); {BIST_Start, Data_Rdy_Out,RTS, Tx_Busy, Tx_Data_In, Rx_Data_Out} = {2'b11, 2'b10, 8'b00000000, 8'b00000000};   //  Next clock
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

endmodule

