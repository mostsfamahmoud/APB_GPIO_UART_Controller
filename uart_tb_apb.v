
`timescale 1ns/10ps

module uart_tb_apb;

reg   PCLK;
reg   PRESETn;
reg   [31:00] PADDR;
reg   PWRITE;
reg   PSEL;
reg   PENABLE;
reg   in_RX_Serial;
reg   [31:00] PWDATA;
wire  [31:00] PRDATA;
wire  PREADY;
wire  out_RXNE;
wire  out_TX_Serial;
wire wire_TX_Active;
reg [31:00] tmp_r;
always@(posedge PCLK or negedge PRESETn) begin
 in_RX_Serial <=  wire_TX_Active ? out_TX_Serial : 1'b1;
end
task Test0;
begin
    @(posedge PCLK);
    @(posedge PCLK);
    // APB_WRITE(32'h0, 32'h1111); 
    APB_WRITE(32'h4, 32'h55);       // tdr 0x55 8bit 
    APB_WRITE(32'h0, 32'h1);        // enable
    APB_WRITE(32'h8, 32'h3333);     // meaning nothing
    // APB_WRITE(32'hc, 32'h4444); 
    @(posedge out_RXNE);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);
    APB_READ(32'h4, tmp_r);
    $display("TDR reg \t %08x", tmp_r);
    APB_READ(32'h8, tmp_r);
    $display("RDR reg \t %08x", tmp_r);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);
    
    
    $display("write phase2");
    APB_WRITE(32'h4, 32'haa);       // tdr 0xaa 8bit 
    @(posedge out_RXNE);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);
    APB_READ(32'h4, tmp_r);
    $display("TDR reg \t %08x", tmp_r);
    APB_READ(32'h8, tmp_r);
    $display("RDR reg \t %08x", tmp_r);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);

    APB_WRITE(32'h0, 32'h0);        // enable
end
endtask

task Test1;
begin
    @(posedge PCLK);
    APB_WRITE(32'h0, 32'h1);        // enable
    APB_WRITE(32'h4, 32'h11);       // tdr 0x11 8bit 
    @(posedge out_RXNE);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);
    APB_READ(32'h4, tmp_r);
    $display("TDR reg \t %08x", tmp_r);
    APB_READ(32'h8, tmp_r);
    $display("RDR reg \t %08x", tmp_r);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);
    
    $display("write phase2");
    APB_WRITE(32'h4, 32'hff);       // tdr 0xff 8bit 
    @(posedge out_RXNE);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);
    APB_READ(32'h4, tmp_r);
    $display("TDR reg \t %08x", tmp_r);
    APB_READ(32'h8, tmp_r);
    $display("RDR reg \t %08x", tmp_r);
    APB_READ(32'h0, tmp_r);
    $display("status reg \t %08x", tmp_r);

    APB_WRITE(32'h0, 32'h0);        // enable
end
endtask

task APB_WRITE(input [31:00] addr, input [31:00] wdata);
begin
    @(posedge PCLK);
    PADDR   <= addr;
    PWDATA  <= wdata;
    PSEL    <= 1;
    PWRITE  <= 1;
    @(posedge PCLK);
    PENABLE <= 1;
    while(!PREADY)       @(posedge PCLK);
    @(posedge PCLK);
    PSEL    <= 0;
    PENABLE <= 0;
    end
endtask

task APB_READ(input [31:00] addr, output [31:00] rdata);
begin
    @(posedge PCLK);
    PADDR   <= addr;
    PSEL    <= 1;
    PWRITE  <= 0;
    @(posedge PCLK);
    PENABLE <= 1;
    while(!PREADY)        @(posedge PCLK);
    @(posedge PCLK);    
    rdata   = PRDATA;
    PSEL    <= 0;
    PENABLE <= 0;
    end
endtask

initial
 begin
  PRESETn = 0;
  PCLK = 0; 
  #10;
  PRESETn = 1;
end
always #2500 PCLK = ~ PCLK;


initial begin
  @(posedge PRESETn);
  $display("TEST0 CALL");
  Test0;
  $display("\nTEST1 CALL");
  Test1;
  $finish();
end

UART duv
(
	.PCLK(PCLK),
    .PRESETn(PRESETn),
	.PADDR(PADDR),
	.PWRITE(PWRITE),
	.PSEL(PSEL),
	.PENABLE(PENABLE),
	.PWDATA(PWDATA),
	.PRDATA(PRDATA),
	.PREADY(PREADY),
    .out_RXNE(out_RXNE),
    .out_TX_Serial(out_TX_Serial),
    .in_RX_Serial(in_RX_Serial),
  .PSLVERR(PSLVERR),
.wire_TX_Active(wire_TX_Active)
);

  
endmodule
