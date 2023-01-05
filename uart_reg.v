module UART
#(
	parameter DATA_WIDTH = 'd32,  ADDRESS_WIDTH = 'd32
)
(
	 input                 	      PWRITE,
	 input                 	      PSEL,
	 input                 	      PENABLE,
	 input                 	      PCLK,
	 input			              PRESETn,
	 input                        in_RX_Serial,
	 input [DATA_WIDTH - 1:0]     PWDATA,
	 input [ADDRESS_WIDTH -1 :0]  PADDR,

	 output reg [DATA_WIDTH - 1:0]  PRDATA,
	 output 		                PSLVERR, 
	 output      	     	        PREADY,
	 output			                out_RXNE,
         output                          wire_TX_Active,
	 output                         out_TX_Serial
 );

wire TXE, RXNE; // TXT : Transmit data register empty, RXNE : Read data register not empty

  // Testbench uses a 200 kHZ clock
  // Want to interface to 115200 baud UART

  // 200000 / 115200 = 2 Clocks Per Bit.
 localparam c_CLOCK_PERIOD_NS = 5000;
  localparam c_CLKS_PER_BIT    = 2;

/*
 localparam c_CLOCK_PERIOD_NS = 10;
  localparam c_CLKS_PER_BIT    = 868;
*/
reg [31:00] status = 32'h00; // read only
reg [07:00] TDR;    //Trasmit Data Register
reg [07:00] RDR;    //Receive Data Register

wire write	= PSEL & PENABLE & PWRITE;
wire read 	= PSEL & ~PWRITE;

wire wire_RX_DV;
wire [07:00] wire_RX_Byte;

//wire wire_TX_Active;
wire wire_Tx_Finish;

reg busy = 1'b0;
assign PSLVERR = 1'b0;


assign TXE = status[7] & status[0] & !busy;
assign out_RXNE = status[5];
assign PREADY = (PADDR[03:00] == 4'h4) ? !busy : 1'b1;

always@(posedge PCLK or negedge PRESETn) begin
	if(!PRESETn) begin
		TDR		<= 0;
		RDR		<= 0;
		PRDATA 	<= 0;
	end
	else begin
		if(write) begin
			case(PADDR[3:0])
			4'h0 : status[0] 	<= PWDATA[0];
			4'h4 : begin
					TDR 		<= PWDATA[7:0];
					status[7]	<= 1'b1;
			end
			// 4'hc : CPB 	<= PWDATA;
			endcase
		end
		if(read) begin
			case(PADDR[3:0])
			4'h0 : PRDATA 	<= status;
			4'h4 : PRDATA 	<= {24'h0, TDR};
			4'h8 : 
			begin
				PRDATA 	<= {24'h0, RDR};
				status[5] 	<= 1'b0;
			end
			// 4'hc : PRDATA 	<= CPB;
			default : PRDATA <= 0;
			endcase
		end
		else
			PRDATA 		<= 0;
	end
	if(TXE) begin
		status[7] 	<= 1'b0;
		busy 		<= 1'b1;
	end
end

always@(posedge wire_RX_DV) begin
		status[5] 	<= 1'b1;
		RDR 		<= wire_RX_Byte;
end

always@(posedge wire_Tx_Finish) begin
		busy		<= 1'b0;
end

UART_RX #(
	.CLKS_PER_BIT(c_CLKS_PER_BIT)
) 
UART_RX_Inst( 
	.in_Reset(PRESETn),
    .in_Clk(PCLK),
    .in_RX_Serial(in_RX_Serial),
    .out_RX_DV(wire_RX_DV),
    .out_RX_Byte(wire_RX_Byte)
);
	 
UART_TX #(
	.CLKS_PER_BIT(c_CLKS_PER_BIT)
) 
UART_TX_Inst(
    .in_Reset(PRESETn),
	.in_Clk(PCLK),
    .in_TX_EN(TXE),
    .in_TX_Byte(TDR),
    .out_TX_Active(wire_TX_Active),
    .out_TX_Serial(out_TX_Serial),
    .out_TX_Finish(wire_Tx_Finish)
);

// Keeps the UART Receive input high (default) when
// UART transmitter is not active
//assign in_RX_Serial = wire_TX_Active ? out_TX_Serial : 1'b1;


endmodule