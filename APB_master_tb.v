`timescale 1ns/1ns
 
module APB_MASTER_TB ();

/**********************************************************
*                Parameters and I/O signals                *
***********************************************************/
parameter DATA_WIDTH = 'd32,  ADDRESS_WIDTH = 'd32, STRB_WIDTH = 'd4, SLAVE_NUM = 'd2;

reg                          PCLK;      
reg                          PRESETn;    
reg  [ADDRESS_WIDTH - 1:0]   APB_writeAddress;
reg  [ADDRESS_WIDTH - 1:0]   APB_readAddress; 
reg  [DATA_WIDTH-1:0]        APB_writeData;          
reg                          READ1_WRITE0;   
reg  [STRB_WIDTH-1:0]        IN_STRB;    
reg                          TRANSFER_FLAG;
reg  [SLAVE_NUM - 1: 0]      Slave_Select;

reg  [DATA_WIDTH-1:0]        PRDATA;    
reg                          PREADY;     
reg                          PSLVERR;  

                             
wire   [DATA_WIDTH - 1:0]      APB_readData;
wire                           OUT_SLVERR;
  
wire   [ADDRESS_WIDTH - 1:0]   PADDR;      
wire   [DATA_WIDTH - 1:0]      PWDATA;     
wire   [STRB_WIDTH - 1:0]      PSTRB;      
wire   					                   PSEL1;  
wire   					                   PSEL2; 
wire                           PWRITE;     
wire                           PENABLE;    
   

/**********************************************************
*                     DUT instantiation                   *
***********************************************************/
 APB_MASTER DUT (
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

/**********************************************************
*                     CLOCK GENERATOR                     *
***********************************************************/
 always #5 PCLK = ~ PCLK;
 
/**********************************************************
*                  TestBench Initialization               *
***********************************************************/
task TB_INIT();
begin
	# 10
	PCLK = 'b0;
	PRESETn = 'b1;
	PSLVERR = 'b0;
	TRANSFER_FLAG = 'b0;
	PREADY = 'b0;
	Slave_Select = 'b00;
    APB_readAddress = 'd0;
    APB_writeAddress = 'd1;
	APB_writeData = 'd0;
	IN_STRB = 'b0101;
	READ1_WRITE0 = 'b0;
	PRDATA = 'b0;
end 
endtask

/**********************************************************
*                     TestBench Reset                     *
***********************************************************/
task TB_RESET();
begin
	PRESETn = 'b1;	
	#10 	
	PRESETn = 'b0;	
	#10 	
	PRESETn = 'b1;	
end 
endtask

/**********************************************************
*                   TestBench Main Block                  *
***********************************************************/
initial
begin
	
    $display("===================== Write operation with no wait states =====================");
	TB_INIT();
	TB_RESET();
    Write_NO_Wait();

	$display("===================== Read operation with no wait states =====================");
	TB_INIT();
	TB_RESET();
    Read_NO_Wait();

    $display("===================== Write operation with wait states =====================");
	TB_INIT();
	TB_RESET();
    Write_With_Wait();

    $display("===================== Read operation with wait states =====================");
	TB_INIT();
	TB_RESET();
    Read_With_Wait();

  	#10
	$finish;
end

/**********************************************************
*             Write Operation with No wait states         *
***********************************************************/
task Write_NO_Wait(); 
begin
	/************** First write operation **************/
    #10
  	TRANSFER_FLAG = 'b1;
  	Slave_Select = 'b01;
	APB_writeAddress = 32'h4CD3;              
	APB_writeData = 'd98;
	READ1_WRITE0 = 'b0;
	PREADY = 'b0;

    #15
    $display("************ First write operation test ************");
    if (PSEL1 == 1 && PADDR == APB_writeAddress && PWDATA == APB_writeData)
       $display(" First Setup process DONE ");	
	else
       $display(" Error in First Setup process ");

	#5
	PREADY = 'b1;

	/************** Second write operation **************/
	#10
	Slave_Select = 'b10;
	APB_writeAddress = 32'hB6B9;         
	APB_writeData = 'd105;
	PREADY = 'b0;
	
	#5
    if (PENABLE == 1'b0)
       $display(" First write operation DONE ");	
	else
       $display(" Error in First write operation ");	
  
	#5
	$display("************ Second write operation test ************");
    if (PSEL2 == 1 && PADDR == APB_writeAddress && PWDATA == APB_writeData)
       $display(" Second Setup process DONE ");	
	else
       $display(" Error in Second Setup process ");
	   
	PREADY = 'b1;
	TRANSFER_FLAG = 'b0;
	#10
	PREADY = 'b0;
	
	#5
    if (PENABLE == 1'b0)
       $display(" Second write operation DONE ");	
	else
       $display(" Error in Second write operation ");	
    
	#15
	$display("************ No other write operations test ************");
	if (PENABLE == 1'b0)
       $display("Master return to IDLE state ");	
	else
       $display("Error in Master operation ");
end
endtask

/**********************************************************
*               Write Operation with wait states          *
***********************************************************/
task Write_With_Wait();
begin
	/************** First write operation **************/
  	#10
  	TRANSFER_FLAG = 'b1;
  	Slave_Select = 'b01;
	APB_writeAddress = 32'h4CD3;  
	APB_writeData = 'd98;
	READ1_WRITE0 = 'b0;
	PREADY = 'b0;

    #15
    $display("************ First write operation test ************");
    if (PSEL1 == 1 && PADDR == APB_writeAddress && PWDATA == APB_writeData)
       $display(" First Setup process DONE ");	
	else
       $display(" Error in First Setup process ");	
	
	#20
	if (PENABLE == 1'b1)
       $display(" Master in waiting state ");	
	else
       $display("Error: Master didn't wait");	

	#5
	PREADY = 'b1;

	/************** Second write operation **************/
	#10
	Slave_Select = 'b10;
	APB_writeAddress = 32'hB6B9;          
	APB_writeData = 'd105;
	PREADY = 'b0;
	
	#5
    if (PENABLE == 1'b0)
       $display(" First write operation DONE ");	
	else
       $display(" Error in First write operation ");	
  
	#5
	$display("************ Second write operation test ************");
    if (PSEL2 == 1 && PADDR == APB_writeAddress && PWDATA == APB_writeData)
       $display(" Second Setup process DONE ");	
	else
       $display(" Error in Second Setup process ");
	
	#20
	if (PENABLE == 1'b1)
       $display(" Master in waiting state ");	
	else
       $display(" Error: Master didn't wait ");	
       
	PREADY = 'b1;
	TRANSFER_FLAG = 'b0;
	#10
	PREADY = 'b0;
	
	#5
    if (PENABLE == 1'b0)
       $display(" Second write operation DONE ");	
	else
       $display(" Error in Second write operation ");	
    
	#15
	$display("************ No other write operations needed test ************");
	if (PENABLE == 1'b0)
       $display(" Master return to IDLE state ");	
	else
       $display(" Error in Master operation ");
end
endtask

/**********************************************************
*             READ Operation with No wait states          *
***********************************************************/
task Read_NO_Wait();
begin
	/************** First read operation **************/
    #10
    TRANSFER_FLAG = 'b1;
    Slave_Select = 'b01;
	APB_readAddress = 32'hBAB8;
	READ1_WRITE0 = 'b1;
	PREADY = 'b0;

    #15
    $display("************ First read operation test ************");
    if (PSEL1 == 1 && PADDR == APB_readAddress)
       $display(" First Setup process DONE ");	
	else
       $display(" Error in First Setup process ");

	#5
	PREADY = 'b1;
	PRDATA = 'd98;

  	/************** Second write operation **************/
	#10
	Slave_Select = 'b10;
	APB_readAddress = 32'h4CD3;          
	PREADY = 'b0;

	#5
	if (APB_readData == PRDATA && PENABLE == 1'b0)
       $display(" First read operation DONE ");	
	else
       $display(" Error in First read operation ");	

	#5 
	$display("************ Second read operation test ************");
    if (PSEL2 == 1 && PADDR == APB_readAddress)
       $display(" Second Setup process DONE ");	
	else
       $display(" Error in Second Setup process ");		
	   
	PREADY = 'b1;
	PRDATA = 'd150;
	#5
	TRANSFER_FLAG = 'b0;
    #5
	PREADY = 'b0;

	#5
    if (APB_readData == PRDATA && PENABLE == 1'b0)
       $display(" Second read operation DONE ");	
	else
       $display(" Error in Second read operation ");	
   
	#25
	$display("************ No other read operations test ************");
	if (PENABLE == 1'b0)
       $display(" Master return to IDLE state ");	
	else
       $display(" Error in Master operation ");
end
endtask

/**********************************************************
*             READ Operation with wait states             *
***********************************************************/
task Read_With_Wait();
begin
	/************** First read operation **************/
    #10
    Slave_Select = 'b01;
    TRANSFER_FLAG = 'b1;
	APB_readAddress = 32'hBAB8;             
	READ1_WRITE0 = 'b1;
	PREADY = 'b0;

    #15
    $display("************ First read operation test ************");
    if (PSEL1 == 1 && PADDR == APB_readAddress)
       $display(" First Setup process DONE ");	
	else
       $display(" Error in First Setup process ");

	#25
	if (PENABLE == 1'b1)
       $display(" Master is waiting ");	
	else
       $display(" Error: Master didn't wait ");	
	
	PREADY = 'b1;
	PRDATA = 'd98;
    
  	/************** Second write operation **************/
	#10
	Slave_Select = 'b10;
	APB_readAddress = 32'hB6BD3;          
	PREADY = 'b0;
	
	#5
	if (APB_readData == PRDATA && PENABLE == 1'b0)
       $display(" First read operation DONE ");	
	else
       $display(" Error in First read operation ");	
	
	#5 
	$display("************ Second read operation test ************");
    if (PSEL2 == 1 && PADDR == APB_readAddress)
       $display(" Second Setup process DONE ");	
	else
       $display(" Error in Second Setup process ");		
	   
	#25
	if (PENABLE == 1'b1)
       $display(" Master is waiting ");	
	else
       $display(" Error: Master didn't wait ");	
	   
	PREADY = 'b1;
	PRDATA = 'd90;
	#5
	TRANSFER_FLAG = 'b0;
    #5
	PREADY = 'b0;

	#5
    if (APB_readData == PRDATA && PENABLE == 1'b0)
       $display(" Second read operation DONE ");	
	else
       $display(" Error in Second read operation ");	
  
	#25
	$display("************ No other read operations test ************");
	if (PENABLE == 1'b0)
       $display(" Master return to IDLE state ");	
	else
       $display(" Error in Master operation ");
end
endtask
endmodule