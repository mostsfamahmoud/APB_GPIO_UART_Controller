module UART_TX 
#(parameter CLKS_PER_BIT)
(
   input       in_Reset,
   input       in_Clk,
   input       in_TX_EN,         //TX Data Valid for one cycle
   input [7:0] in_TX_Byte, 
   output reg  out_TX_Active,
   output reg  out_TX_Serial,
   output reg  out_TX_Finish
);
 
  localparam IDLE         = 3'b000;
  localparam TX_START = 3'b001;
  localparam TX_DATA = 3'b010;
  localparam TX_STOP  = 3'b011;
  localparam CLEAN      = 3'b100;
  
  reg [2:0] reg_Main_State;
  reg [$clog2(CLKS_PER_BIT):0] reg_Clk_Count;
  reg [2:0] reg_IndexBit;
  reg [7:0] reg_TX_Data;

  // Purpose: Control TX state machine
  always @(posedge in_Clk or negedge in_Reset)
  begin
    if (~in_Reset)
    begin
      reg_Main_State <= 3'b000;
      out_TX_Finish <= 1'b0;
    end
    else
    begin
      case (reg_Main_State)
      IDLE :
        begin
          out_TX_Serial   <= 1'b1;         // Drive Line High for Idle
          out_TX_Finish     <= 1'b0;
          reg_Clk_Count <= 0;
          reg_IndexBit   <= 0;
          
          if (in_TX_EN == 1'b1)
          begin
            out_TX_Active <= 1'b1;
            reg_TX_Data   <= in_TX_Byte;
            reg_Main_State   <= TX_START;
          end
          else
            reg_Main_State <= IDLE;
        end // case: IDLE
      
      
      // Send out Start Bit. Start bit = 0
      TX_START :
        begin
          out_TX_Serial <= 1'b0;
          
          // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
          if (reg_Clk_Count < CLKS_PER_BIT-1)
          begin
            reg_Clk_Count <= reg_Clk_Count + 1;
            reg_Main_State     <= TX_START;
          end
          else
          begin
            reg_Clk_Count <= 0;
            reg_Main_State     <= TX_DATA;
          end
        end // case: TX_START
      
      
      // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
      TX_DATA :
        begin
          out_TX_Serial <= reg_TX_Data [reg_IndexBit];
          
          if (reg_Clk_Count < CLKS_PER_BIT-1)
          begin
            reg_Clk_Count <= reg_Clk_Count + 1;
            reg_Main_State     <= TX_DATA;
          end
          else
          begin
            reg_Clk_Count <= 0;
            
            // Check if we have sent out all bits
            if (reg_IndexBit < 7)
            begin
              reg_IndexBit <= reg_IndexBit + 1;
              reg_Main_State   <= TX_DATA;
            end
            else
            begin
              reg_IndexBit <= 0;
              reg_Main_State   <= TX_STOP;
            end
          end 
        end // case: TX_DATA
      
      
      // Send out Stop bit.  Stop bit = 1
      TX_STOP :
        begin
          out_TX_Serial <= 1'b1;
          
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (reg_Clk_Count < CLKS_PER_BIT-1)
          begin
            reg_Clk_Count <= reg_Clk_Count + 1;
            reg_Main_State     <= TX_STOP;
          end
          else
          begin
            out_TX_Finish     <= 1'b1;
            reg_Clk_Count <= 0;
            reg_Main_State     <= CLEAN;
            out_TX_Active   <= 1'b0;
          end 
        end // case: TX_STOP
      
      
      // Stay here 1 clock
      CLEAN :
        begin
          reg_Main_State <= IDLE;
        end
      
      
      default :
        reg_Main_State <= IDLE;
      
    endcase
    end // else: !if(~in_Reset)
  end // always @ (posedge in_Clk or negedge in_Reset)

  
endmodule