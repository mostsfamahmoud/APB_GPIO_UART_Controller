`timescale 1ns/1ns

module APB_interface_tb ;

parameter DATA_WIDTH = 'd32,  ADDRESS_WIDTH = 'd32, STRB_WIDTH = 'd4, PDATA_SIZE = 'd32, SLAVES_NUM = 'd2 ;

reg                        PRESETn ;
reg                        PCLK ;
reg                        READ1_WRITE0 ;
reg                        TRANSFER_FLAG ;
reg  [ADDRESS_WIDTH - 1:0] APB_writeAddress ;
reg  [ADDRESS_WIDTH - 1:0] APB_readAddress ;
reg  [DATA_WIDTH - 1:0]    APB_writeData ;   
reg  [STRB_WIDTH - 1:0]    IN_STRB ;
reg                        in_RX_Serial ;
reg  [PDATA_SIZE  -1:0]    gpio_i ;
reg  [SLAVES_NUM - 1: 0]   Slave_Select;

wire [DATA_WIDTH - 1:0]    APB_readData ;
wire                       out_TX_Serial ;
wire [PDATA_SIZE  -1:0]    gpio_o ;
wire                       gpio_oe ; 
integer i; 
APB_Protcol A1 (
  .PRESETn(PRESETn),
  .PCLK(PCLK),
  .READ1_WRITE0(READ1_WRITE0),
  .TRANSFER_FLAG(TRANSFER_FLAG),
  .APB_writeAddress(APB_writeAddress),
  .APB_readAddress(APB_readAddress),
  .APB_writeData(APB_writeData),
  .IN_STRB(IN_STRB),
  .Slave_Select(Slave_Select),
  .in_RX_Serial(in_RX_Serial),
  .gpio_i(gpio_i),
  .APB_readData(APB_readData),
  .out_TX_Serial(out_TX_Serial),
  .gpio_o(gpio_o),
  .gpio_oe(gpio_oe)
);


// Clock generator
always #2500 PCLK = ~PCLK;

initial begin

       /* Initial Values */
        PCLK = 1'b0;
        READ1_WRITE0 = 1'b0;
        TRANSFER_FLAG = 1'b0;
        PRESETn = 1'b0;
        APB_writeAddress = 32'h00000000;
        APB_readAddress = 32'h00000000;
        APB_writeData = 32'h00000000;
        IN_STRB = 'b1111;
        in_RX_Serial = 'b0;
        gpio_i = 'b0;
        Slave_Select = 'b00;
        #30;
                
    
        // ++++++++++++++++++++++++++++++++ GPIO ++++++++++++++++++++++++++++++++
        
        PRESETn = 1'b1;
        Slave_Select = 2'b01;
        TRANSFER_FLAG = 1'b1;
        // Write a value to the slave peripheral's memory
        READ1_WRITE0 = 1'b0;
        APB_writeAddress = 32'hABDC6398;        // address --> 1010_1011_1101_1100_0110_0011_1001_1000
        APB_writeData = 'd150;
        #30 

        // Read a value from the slave peripheral's memory
        READ1_WRITE0 = 1'b1;
        APB_readAddress = 32'h8936CDBA;       // address --> 1000_1001_0011_0110_1100_1101_1011_1010
        #30; 

        READ1_WRITE0 = 1'b0;
        APB_writeAddress = 32'h10;        // address --> 1010_1011_1101_1100_0110_0011_1001_1000
        APB_writeData = 'd250;
        #30 

        READ1_WRITE0 = 1'b1;
        APB_readAddress = 32'h12345678;       // address --> 0001_0010_0011_0100_0101_0110_0111_1000
        #30; 

        Slave_Select = 2'b00;
        #30
        


        // ++++++++++++++++++++++++++++++++ UART test ++++++++++++++++++++++++++++++++
 
    PRESETn = 1'b1;
    Slave_Select = 2'b10;
    TRANSFER_FLAG = 1'b1;
   READ1_WRITE0 = 1'b0;
@(posedge PCLK);
    APB_writeAddress = 32'h4;
    APB_writeData = 32'h55;

    APB_writeAddress = 32'h0;
    APB_writeData = 32'h1;

    APB_writeAddress = 32'h8;
    APB_writeData = 32'h3333;
    #30000
            
    #100
     READ1_WRITE0 = 1'b1;
    #30
       in_RX_Serial = 0; // start bit
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 1; // stop bit
        #104166
        READ1_WRITE0 = 1'b1;
        in_RX_Serial = 0; // start bit
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 0;
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 1;
        #104166
        in_RX_Serial = 1;
        #104166
        READ1_WRITE0 = 1'b1;

 
      $finish();
    end



  

endmodule  