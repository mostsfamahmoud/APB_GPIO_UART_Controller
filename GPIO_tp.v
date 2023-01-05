`timescale 1ns / 1ps

module apb_gpio_tb;

  //inputs
  reg                         PRESETn;
  reg                         PCLK;
  reg                         PSEL;
  reg                         PENABLE;
  reg      [31:0]             PADDR;
  reg                         PWRITE;
  reg      [3:0]              PSTRB;
  reg      [31:0]             PWDATA;
  reg      [31:0]             gpio_i;
  wire                        gpio_oe;
  wire      [31:0]             gpio_o;
  
  //outputs
  wire      [31:0]             PRDATA;
  wire                        PREADY;
  wire                        PSLVERR;
  
  //instantiate DUT
  GPIO uut (
    .PRESETn(PRESETn),
    .PCLK(PCLK),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PSTRB(PSTRB),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
    .gpio_i(gpio_i),
    .gpio_o(gpio_o),
    .gpio_oe(gpio_oe)
  );
  
  //initialize inputs
  initial begin
    PRESETn = 1;
    PCLK = 0;
    PSEL = 0;
    PENABLE = 0;
    PADDR = 0;
    PWRITE = 0;
    PSTRB = 0;
    PWDATA = 0;
    gpio_i = 0;
  end
  
  //clock generator
  always begin
    #5 PCLK = ~PCLK;
  end
  
  //test cases
  initial begin
    
    //reset the DUT
    PRESETn = 0;
    #5;
    PRESETn = 1;
    
    //test case 1: write to mode register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h0;
    PWRITE = 1;
    PSTRB = 4'b1111;
    PWDATA = 32'hA301200F;
    #5;
    
    //test case 2: read from mode register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h0;
    PWRITE = 0;
    PSTRB = 4'b0000;
    PWDATA = 0;
    #5;
    
    //test case 3: write to direction register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h1;
    PWRITE = 1;
    PSTRB = 4'b1111;
    PWDATA = 32'hA03400FF;
    #5
    //test case 4: read from direction register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h1;
    PWRITE = 0;
    PSTRB = 4'b0000;
    PWDATA = 0;
    #5;
    
    //test case 5: write to output register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h2;
    PWRITE = 1;
    PSTRB = 4'b1111;
    PWDATA = 32'h0070240F;
    #5;
    
    //test case 6: read from output register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h2;
    PWRITE = 0;
    PSTRB = 4'b0000;
    PWDATA = 0;
    #5;
    
    //test case 7: read from input register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h3;
    PWRITE = 0;
    PSTRB = 4'b0000;
    PWDATA = 0;
    #5;
    
    //test case 8: write to input register (should have no effect)
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h3;
    PWRITE = 1;
    PSTRB = 4'b1111;
    PWDATA = 32'hA030F00F;
    #5;
    
    //test case 9: read from input register
    PSEL = 1;
    PENABLE = 1;
    PADDR = 4'h3;
    PWRITE = 0;
    PSTRB = 4'b0000;
    PWDATA = 0;
    #5;


    #10
	  $finish;
    
  end
  
endmodule
