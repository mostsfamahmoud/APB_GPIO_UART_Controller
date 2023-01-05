module GPIO  #(
 parameter PDATA_SIZE = 32  //must be a multiple of 8
 
)
(
  input                         PRESETn,
                                PCLK,
  input                         PSEL,
  input                         PENABLE,
  input      [31:0]             PADDR,
  input                         PWRITE,
  input      [PDATA_SIZE/8-1:0] PSTRB,
  input      [PDATA_SIZE  -1:0] PWDATA,
  output reg [PDATA_SIZE  -1:0] PRDATA,
  output                        PREADY,
  output                        PSLVERR,

  input      [PDATA_SIZE  -1:0] gpio_i,
  output reg [PDATA_SIZE  -1:0] gpio_o,
  output reg                    gpio_oe
);
  
  
  /****************************Constants******************************/
  

  localparam PADDR_SIZE = 32;


  localparam MODE      = 0,
             DIRECTION = 1,
             OUTPUT    = 2,
             INPUT     = 3;
 
  /*number of synchronisation flipflop stages on GPIO inputs*/
  localparam INPUT_STAGES = 2;


  /***************************** Variables***************************/
  

  /*Control registers*/
  reg [PDATA_SIZE-1:0] mode_reg,
                       dir_reg,
                       out_reg,
                       in_reg;
     
  /*Input register, to prevent metastability*/
  reg [PDATA_SIZE-1:0] input_regs [INPUT_STAGES:0];


  /***************************** Functions***************************/

  /*Is this a valid read access?*/
 integer n =0;
 function automatic is_read(input  PSEL, input  PENABLE, input  PWRITE);
   is_read=(PSEL & PENABLE & (~PWRITE));
 endfunction

 function automatic is_write(input PSEL, input  PENABLE, input PWRITE); 
   is_write=(PSEL & PENABLE & PWRITE);
 endfunction


  /*Is this a valid write to address ?*/
  function automatic is_write_to_adr(input [PADDR_SIZE-1:0] address);
    is_write_to_adr = (is_write(PSEL, PENABLE, PWRITE) & (PADDR == address));
  endfunction 

  /*What data is written?*/
  function automatic [PDATA_SIZE-1:0] get_write_value (input [PDATA_SIZE-1:0] orig_val);
    
    for ( n=0; n < PDATA_SIZE/8; n=n+1)begin
       get_write_value[n*8 +: 8] = PSTRB[n] ? PWDATA[n*8 +: 8] : orig_val[n*8 +: 8];
     end
  endfunction 

  /*Clear bits on write*/
  function automatic [PDATA_SIZE-1:0] get_clearonwrite_value (input [PDATA_SIZE-1:0] orig_val);
    for ( n=0; n < PDATA_SIZE/8; n=n+1)begin
       get_clearonwrite_value[n*8 +: 8] = PSTRB[n] ? orig_val[n*8 +: 8] & ~PWDATA[n*8 +: 8] : orig_val[n*8 +: 8];
     end
  endfunction 

  /************************ Module Body****************************/

  /* APB accesses*/

  assign PREADY  = 1'b1; //always ready
  assign PSLVERR = 1'b0; //Never an error


  /* APB Writes*/
  
  //APB write to Mode register
  always @(posedge PCLK,negedge PRESETn) begin
    if      (!PRESETn              ) mode_reg <= {PDATA_SIZE{1'b0}};
    else if ( is_write_to_adr(MODE)) mode_reg <= get_write_value(mode_reg);
  end

  //APB write to Direction register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                   ) dir_reg <= {PDATA_SIZE{1'b0}};
    else if ( is_write_to_adr(DIRECTION)) dir_reg <= get_write_value(dir_reg);


  //APB write to Output register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                  ) out_reg <= {PDATA_SIZE{1'b0}};
    else if ( is_write_to_adr(OUTPUT) || is_write_to_adr(INPUT )  ) out_reg <= get_write_value(out_reg);



  /* APB Reads */
  always @(posedge PCLK)
    case (PADDR)
      MODE     : PRDATA <= mode_reg;
      DIRECTION: PRDATA <= dir_reg;
      OUTPUT   : PRDATA <= out_reg;
      INPUT    : PRDATA <= in_reg;
      default  : PRDATA <= {PDATA_SIZE{1'b0}};
    endcase


  /* Internals*/
    
  always @(posedge PCLK)
    for (n=0; n<INPUT_STAGES; n=n+1)begin
       if (n==0) input_regs[n] <= gpio_i;
       else      input_regs[n] <= input_regs[n-1];
    end

  always @(posedge PCLK)
    in_reg <= input_regs[INPUT_STAGES-1];


 
  always @(posedge PCLK)
    for (n=0; n<PDATA_SIZE; n=n+1)begin
      gpio_o[n] <= mode_reg[n] ? 1'b0 : out_reg[n];
    end

  always @(posedge PCLK)
  
    for ( n=0; n<PDATA_SIZE; n=n+1)begin
      gpio_oe <= dir_reg[n] & ~(mode_reg[n] ? out_reg[n] : 1'b0);
  end


 
endmodule
