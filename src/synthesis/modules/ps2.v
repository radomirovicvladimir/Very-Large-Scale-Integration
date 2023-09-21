module ps2 (
    input PS2_KBCLK,
    input PS2_KBDAT,
    input rst_n,
    input CLOCK_50,
    output [15:0] display
);

    localparam START = 1'b0;
    localparam STOP = 1'b1;
    localparam startState = 2'b00;
    localparam dataState = 2'b01;
    localparam parityState = 2'b10;
    localparam stopState = 2'b11;

    reg[1:0] stateReg, stateNext;


    reg [15:0] displayReg, displayNext;
	 reg [15:0] tempDispReg, tempDispNext;
    reg [7:0] dataReg, dataNext;
    reg [3:0] countReg, countNext;
    reg parityReg, parityNext;
    reg flagErrorReg, flagErrorNext;
    reg flagE0Reg, flagE0Next;
    reg flagF0Reg, flagF0Next; 
	 
	 assign display = displayReg;


    always @(posedge CLOCK_50, negedge rst_n) begin
        if (!rst_n) begin
				stateReg <= 2'd0;
				displayReg <= 16'd0;
				tempDispReg <= 16'd0;
				dataReg <= 8'd0;
				countReg <= 4'd0;
				parityReg <= 1'd0;
				flagErrorReg <= 1'd0;
				flagE0Reg <= 1'd0;
				flagF0Reg <= 1'd0;
        end else begin
				stateReg <= stateNext;
				displayReg <= displayNext;
				tempDispReg <= tempDispNext;
				dataReg <= dataNext;
				countReg <= countNext;
				parityReg <= parityNext;
				flagErrorReg <= flagErrorNext;
				flagE0Reg <= flagE0Next;
				flagF0Reg <= flagF0Next;
        end
    end

    always @(negedge PS2_KBCLK) begin
        	stateNext = stateReg;
			displayNext = displayReg;
			tempDispNext = tempDispReg;
			dataNext = dataReg;
			countNext = countReg;
			parityNext = parityReg;
			flagErrorNext = flagErrorReg;
			flagE0Next = flagE0Reg;
			flagF0Next = flagF0Reg;
			
         case (stateReg)
            startState: begin 
				
               if (PS2_KBDAT == START) begin
                  flagErrorNext = 1'b0;
                  countNext = 4'd8;
                  dataNext = 8'd0;
                  stateNext = dataState;
						
						//ovo ovde nam sluzi da prikazemo samo 1B ako je make code 1B
						if(dataReg != 8'hE0 && dataReg != 8'hF0) begin
							tempDispNext = 16'd0;
						end

                  if( dataReg == 8'hF0) begin
                     flagF0Next = 1'b1;
                  end else begin
                     flagF0Next = 1'b0;
                  end
                end
					 
            end

            dataState: begin
				
               dataNext = (dataReg >> 1'b1) | ({PS2_KBDAT,{7{1'b0}}}); 

               if(countReg == 4'd8) begin
                  parityNext = PS2_KBDAT;
               end else begin
                  parityNext = parityReg ^ PS2_KBDAT;
               end     

               if(countReg > 4'd1) begin
                  countNext = countReg - 4'd1; 
               end else begin
                  stateNext = parityState;
               end
					
            end
            
            parityState: begin
				
               if(parityReg ^ PS2_KBDAT) begin
                  //ispravno
                  flagErrorNext = 1'b0;
               end else begin
                  //neispravno
                  flagErrorNext = 1'b1;
               end
               stateNext = stopState;
					
            end

            stopState: begin
				
               if(PS2_KBDAT == STOP && flagErrorReg == 1'b0) begin
						
						tempDispNext = (tempDispReg<<8) | dataReg;
						if( flagE0Reg == 1'b0 || dataReg == 8'hE0) begin
							flagE0Next = 1'b1;
						end else begin
							displayNext = tempDispNext;
							flagErrorNext = 1'b0;
						end
						
						if(flagF0Reg == 1'b1) begin
							displayNext = {8'hF0,dataReg};
						end
               end else begin
						//greska parity ili stop bit
                  displayNext = 16'hFFFF;
               end
               stateNext = startState;
            
				end
				
        endcase
    end

endmodule

