`timescale 1ns/1ns

module APB_Protcol 
#(
    parameter DATA_WIDTH = 'd32,  ADDRESS_WIDTH = 'd32,
                STRB_WIDTH = 'd4, SLAVES_NUM = 'd2, PDATA_SIZE = 'd32
) 
(
    input wire                       PRESETn,
    input wire                       PCLK,
    input wire                       READ1_WRITE0,
    input wire                       TRANSFER_FLAG,
    input wire [ADDRESS_WIDTH - 1:0] APB_writeAddress,
	input wire [ADDRESS_WIDTH - 1:0] APB_readAddress,
	input wire [DATA_WIDTH - 1:0]    APB_writeData,   
	input wire [STRB_WIDTH - 1:0]    IN_STRB,
    input wire [SLAVES_NUM - 1: 0]   Slave_Select,
    input wire [PDATA_SIZE  -1:0]    gpio_i,
    input wire                       in_RX_Serial,

	output wire [DATA_WIDTH - 1:0]    APB_readData,
    output wire                       out_TX_Serial,
    output wire [PDATA_SIZE  -1:0]    gpio_o,
    output wire     gpio_oe    
//output wire out_RXNE
);

wire out_RXNE;
wire                        wire_TX_Active;
wire   [DATA_WIDTH - 1:0]   PRDATA;
wire   [DATA_WIDTH - 1:0]   PRDATA1;
wire   [DATA_WIDTH - 1:0]   PRDATA2;

wire                        PREADY;
wire                        PREADY1;
wire                        PREADY2;

wire                        PSLVERR;
wire   					    PSEL1;  
wire   					    PSEL2;  

wire   [ADDRESS_WIDTH - 1:0]   PADDR;      
wire   [DATA_WIDTH-1:0]    PWDATA;     
wire   [STRB_WIDTH-1:0]    PSTRB;      
  
wire                       PWRITE;     
wire                       PENABLE;    
wire                       OUT_SLVERR; 




assign  in_RX_Serial = ( PREADY2 && wire_TX_Active )? out_TX_Serial : 1'b1;
assign PREADY = (Slave_Select == 'b10) ? PREADY2 : ((Slave_Select == 'b01)? PREADY1: 'b00);
assign PRDATA = READ1_WRITE0 ? ((Slave_Select == 'b10) ? PRDATA2 :((Slave_Select == 'b01)? PRDATA1: 32'dx)) : 32'dx;


/*
/**********************************************************
*                     DUT instantiation                   *
***********************************************************/
APB_MASTER APB 
(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .APB_readAddress(APB_readAddress),
    .APB_writeAddress(APB_writeAddress),
    .APB_writeData(APB_writeData),
    .PRDATA(PRDATA),
    .READ1_WRITE0(READ1_WRITE0),
    .TRANSFER_FLAG(TRANSFER_FLAG),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
    .IN_STRB(IN_STRB),
    .Slave_Select(Slave_Select),

    .PSTRB(PSTRB),
    .OUT_SLVERR(OUT_SLVERR),
    .APB_readData(APB_readData),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL1(PSEL1),
    .PSEL2(PSEL2)
 );

GPIO gpio 
(
    .PRESETn(PRESETn),
    .PCLK(PCLK),
    .PSEL(PSEL1),
    .PENABLE(PENABLE),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PSTRB(PSTRB),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA1),
    .PREADY(PREADY1),
    .PSLVERR(PSLVERR),
    .gpio_i(gpio_i),
    .gpio_o(gpio_o),
    .gpio_oe(gpio_oe)
);
UART uart
(
.wire_TX_Active(wire_TX_Active),
	.PCLK(PCLK),
    .PRESETn(PRESETn),
	.PADDR(PADDR),
	.PWRITE(PWRITE),
	.PSEL(PSEL2),
	.PENABLE(PENABLE),
	.PWDATA(PWDATA),
	.PRDATA(PRDATA2),
	.PREADY(PREADY2),
    .out_RXNE(out_RXNE),
    .out_TX_Serial(out_TX_Serial),
    .in_RX_Serial(in_RX_Serial),
  .PSLVERR(PSLVERR)
);

endmodule