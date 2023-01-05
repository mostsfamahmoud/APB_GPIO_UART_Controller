module UART_RX
  #(parameter CLKS_PER_BIT)
  (
   input                 in_Reset,
   input                 in_Clk,
   input                 in_RX_Serial,
   output reg            out_RX_DV,        //RX Data Valid for one cycle
   output reg [7:0]      out_RX_Byte
   );
   
  localparam IDLE       = 3'b000;
  localparam RX_START   = 3'b001;
  localparam RX_DATA    = 3'b010;
  localparam RX_STOP    = 3'b011;
  localparam CLEAN      = 3'b100;
  
  reg [$clog2(CLKS_PER_BIT)-1:0] reg_Clk_Count;
  reg [2:0] reg_IndexBit; //8 bits total
  reg [2:0] reg_Main_State;
  
  
  // Purpose: Control RX state machine
  always @(posedge in_Clk or negedge in_Reset)
  begin
    if (~in_Reset)
    begin
      reg_Main_State <= 3'b000;
      out_RX_DV   <= 1'b0;
    end
    else
    begin
      case (reg_Main_State)
      IDLE :
        begin
          out_RX_DV       <= 1'b0;
          reg_Clk_Count <= 0;
          reg_IndexBit   <= 0;
          
          if (in_RX_Serial == 1'b0)          // Start bit detected
            reg_Main_State <= RX_START;
          else
            reg_Main_State <= IDLE;
        end
      
      // Check middle of start bit to make sure it's still low
      RX_START :
        begin
          if (reg_Clk_Count == (CLKS_PER_BIT-1)/2)
          begin
            if (in_RX_Serial == 1'b0)
            begin
              reg_Clk_Count <= 0;  // reset counter, found the middle
              reg_Main_State     <= RX_DATA;
            end
            else
              reg_Main_State <= IDLE;
          end
          else
          begin
            reg_Clk_Count <= reg_Clk_Count + 1;
            reg_Main_State     <= RX_START;
          end
        end // case: RX_START
      
      
      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      RX_DATA :
        begin
          if (reg_Clk_Count < CLKS_PER_BIT-1)
          begin
            reg_Clk_Count <= reg_Clk_Count + 1;
            reg_Main_State     <= RX_DATA;
          end
          else
          begin
            reg_Clk_Count          <= 0;
            out_RX_Byte[reg_IndexBit] <= in_RX_Serial;
            
            // Check if we have received all bits
            if (reg_IndexBit < 7)
            begin
              reg_IndexBit <= reg_IndexBit + 1;
              reg_Main_State   <= RX_DATA;
            end
            else
            begin
              reg_IndexBit <= 0;
              reg_Main_State   <= RX_STOP;
            end
          end
        end // case: RX_DATA
      
      
      // Receive Stop bit.  Stop bit = 1
      RX_STOP :
        begin
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (reg_Clk_Count < CLKS_PER_BIT-1)
          begin
            reg_Clk_Count <= reg_Clk_Count + 1;
            reg_Main_State     <= RX_STOP;
          end
          else
          begin
            out_RX_DV       <= 1'b1;
            reg_Clk_Count <= 0;
            reg_Main_State     <= CLEAN;
          end
        end // case: RX_STOP
      
      
      // Stay here 1 clock
      CLEAN :
        begin
          reg_Main_State <= IDLE;
          out_RX_DV   <= 1'b0;
        end
      
      
      default :
        reg_Main_State <= IDLE;
      
    endcase
    end // else: !if(~in_Reset)
  end // always @ (posedge in_Clk or negedge in_Reset)
  
endmodule
