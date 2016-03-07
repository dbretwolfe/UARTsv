//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2016 02:58:56 PM
// Design Name: 
// Module Name: FIFO
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIFO # (parameter DATA_BITS = 8,	parameter FIFO_WIDTH = 4)
		(input logic rst,
		input logic [DATA_BITS-1:0] Rx_Data,
		input logic Data_Rdy, 
		input logic Pop_Data,
		input logic BIST_Mode,
		output logic FIFO_Empty, 
		output logic FIFO_Full, 
		output logic FIFO_Overflow,
		output logic [DATA_BITS-1:0] Data_Out);
		
		localparam FIFO_ENTRIES = 2**FIFO_WIDTH;
		
		logic [DATA_BITS-1:0] FIFO_Array [FIFO_ENTRIES-1:0];     // Array of 2^FIFO_DEPTH number of DATA_BITS wide elements
		logic [FIFO_WIDTH-1:0] readPointer, writePointer;
		integer numEntries;
		
        always @ (posedge Data_Rdy or posedge Pop_Data or posedge rst) begin
            if (rst) begin
                readPointer <= 0;
                writePointer <= 0;
                numEntries <= 0;
                FIFO_Empty <= 1'b1;
                FIFO_Full <= 1'b0;
                FIFO_Overflow <= 1'b0;
                Data_Out <= '0;
            end
            else begin
                if (!BIST_Mode) begin
                    if (Data_Rdy && !Pop_Data) begin                           // There is new data for the FIFO
                        if (numEntries < FIFO_ENTRIES) begin                   // If there is still space in the FIFO
                            FIFO_Array[writePointer] <= Rx_Data;               // Write data to the FIFO array
                            writePointer <= writePointer + 1;                  // Increment the write pointer
                            numEntries <= numEntries + 1;                      // Increment the number of entries
                            FIFO_Empty <= 1'b0;                                // Data has been written, so the FIFO is not empty
                            if ((numEntries + 1) >= (FIFO_ENTRIES >> 1)) begin   // If the fifo is at least 1/2 full
                                FIFO_Full <= 1'b1;                             // Set the full flag
                            end
                            if ((numEntries + 1) == FIFO_ENTRIES) begin          // If the write pointer has caught up to the read pointer,
                                FIFO_Overflow <= 1'b1;                         // then set the overflow flag
                            end
                        end
                        else begin                                             // Otherwise nothing changes
                            writePointer <= writePointer;
                            numEntries <= numEntries;
                            FIFO_Empty <= FIFO_Empty;
                            FIFO_Full <= FIFO_Full;
                            FIFO_Overflow <= FIFO_Overflow;
                        end
                        // These outputs are not changes in this part of the block
                        readPointer <= readPointer;
                        Data_Out <= Data_Out;
						$display("Numentries  in push = %d, readptr = %d", numEntries, writePointer);
                    end // Write to FIFO
                    
                    else if (Pop_Data && !Data_Rdy) begin                                   // Data needs to be popped out of the FIFO
                        if (numEntries > 0) begin                               // If there is still data in the FIFO
                            Data_Out <= FIFO_Array[readPointer];                // put the next data onto the output
                            readPointer <= readPointer + 1;
                            numEntries <= numEntries - 1;
                            if ((numEntries - 1) == 0) begin                    // Check to see if the FIFO will be empty
                                FIFO_Empty <= 1'b1;                             // If so, set the empty flag
                            end                   
                            if ((numEntries - 1) < (FIFO_ENTRIES >> 1)) begin     // If the fifo is less than 1/2 full, clear the full flag
                                FIFO_Full <= 1'b0;
                            end
                            FIFO_Overflow <= 1'b0;                              // Data has been read, so the FIFO cannot be overflowing
                        end
                        else begin                                              // Otherwise nothing changes
                            readPointer <= readPointer;
                            numEntries <= numEntries;
                            FIFO_Empty <= FIFO_Empty;
                            FIFO_Full <= FIFO_Full;
                            FIFO_Overflow <= FIFO_Overflow;
                            Data_Out <= Data_Out;
                        end
                        // The write pointer never changes in this part of the block
                        writePointer <= writePointer;
						$display("Numentries in pop= %d, readptr = %d", numEntries, readPointer);
                    end // Read from FIFO
                end // Not BIST Mode
                else begin                                                  // Bist mode is active, don't do anything
                    readPointer <= readPointer;
                    writePointer <= writePointer;
                    numEntries <= numEntries;
                    FIFO_Empty <= FIFO_Empty;
                    FIFO_Full <= FIFO_Full;
                    FIFO_Overflow <= FIFO_Overflow;
                    Data_Out <= Data_Out;
                end
            end
        end

endmodule
