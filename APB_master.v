`timescale 1ns/1ns

module APB_MASTER
#(
	parameter DATA_WIDTH = 'd32,  ADDRESS_WIDTH = 'd32, STRB_WIDTH = 'd4, SLAVE_NUM = 'd2
)
(
    /* APB Control Signals */
    input wire                       PRESETn,
    input wire                       PCLK,
    input wire                       READ1_WRITE0,
    input wire                       TRANSFER_FLAG,
    input wire                       PREADY,
	input wire                       PSLVERR,
    input wire [ADDRESS_WIDTH - 1:0] APB_writeAddress,
	input wire [ADDRESS_WIDTH - 1:0] APB_readAddress,
	input wire [DATA_WIDTH - 1:0]    APB_writeData,   
	input wire [DATA_WIDTH - 1:0]    PRDATA,
	input wire [STRB_WIDTH - 1:0]    IN_STRB,
	input wire [SLAVE_NUM - 1: 0]    Slave_Select,


	output reg                       PENABLE,
    output reg                       PWRITE,
	output reg                       OUT_SLVERR,
	output reg                       PSEL1,
	output reg                       PSEL2,
	output reg [ADDRESS_WIDTH -1 :0] PADDR,
	output reg [DATA_WIDTH - 1:0]    PWDATA,
	output reg [DATA_WIDTH - 1:0]    APB_readData,
    output reg [STRB_WIDTH - 1:0]    PSTRB
);
    
/*************** States Encoding **************/
localparam IDLE = 2'b00, SETUP = 2'b01, ACCESS = 2'b11;
   
reg [1:0] state, nextState;

/*************** States Transitions **************/
always @(posedge PCLK or negedge PRESETn)
begin
	if(!PRESETn)
		state <= IDLE;
	else
		state <= nextState; 
end

/**************** Next State Logic **************/
always @(*)
begin
	if(!PRESETn)
	  nextState = IDLE;
	else
        begin
	        case(state)
		        IDLE: 
                    begin 
		                if(!TRANSFER_FLAG)
	        	            nextState = IDLE;
	                    else
			                nextState = SETUP;
	                end
	       	    SETUP:   
                    begin
                        if (TRANSFER_FLAG)
                            nextState = ACCESS;
                        else
                            nextState = SETUP;
		            end
	       	    ACCESS: 
		            begin
			            if(TRANSFER_FLAG && !PSLVERR)
			            begin
				            if(PREADY)
                                nextState = SETUP;
				            else 
                                nextState = ACCESS;
		                end
		                else 
                            nextState = IDLE;
			        end
                default: 
					nextState = IDLE;
            endcase
        end
end

always @(posedge PCLK, negedge PRESETn)
begin
	if(!PRESETn)
       begin
         	PENABLE       <= 1'b0 ;
         	PADDR         <=  'b0 ;
         	PWDATA        <=  'b0 ;
         	PWRITE        <= 1'b0 ;
			PSTRB         <=  'b0 ;
         	APB_readData  <=  'b0 ;
         	OUT_SLVERR    <= 1'b0 ;
       end
	else
        begin
            PWRITE = ~READ1_WRITE0;
	        case(nextState)
		        IDLE: 
	                PENABLE = 1'b0;
	       	    SETUP:   
                    begin
			            PENABLE <= 1'b0;
			            if(READ1_WRITE0)
						begin
							PSTRB <= 'b0;  
	                        PADDR <= APB_readAddress;
						end
			            else 
                        begin
                            PSTRB  <= IN_STRB;   
                            PADDR  <= APB_writeAddress;
				            PWDATA <= APB_writeData;
                        end
		            end
	       	    ACCESS: 
		            begin 
                        if((PSEL1) || (PSEL2))
		                    PENABLE = 1'b1;

						if(PREADY)
				        begin
							OUT_SLVERR <= PSLVERR;
					        if(READ1_WRITE0)
                                APB_readData = PRDATA; 
			            end
			        end
                default:
					PENABLE <= 1'b0;
            endcase
        end
end


/**************** Address Decoding ****************/
always @(posedge PCLK or negedge PRESETn or Slave_Select) 
begin
    if ((!PRESETn) || (nextState == IDLE))
	begin
     	PSEL1 = 0;
		PSEL2 = 0;
	end
    else
    begin
		case(Slave_Select)
		2'b01:
		begin
			PSEL1 = 1;
			PSEL2 = 0;
		end
		2'b10:
		begin
			PSEL1 = 0;
			PSEL2 = 1;
		end
		default:
		begin
			PSEL1 = 0;
			PSEL2 = 0;
		end
		endcase
    end
end

endmodule
