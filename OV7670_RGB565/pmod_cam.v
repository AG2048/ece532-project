`timescale 1ns / 1ps

module pmod_cam (
    input                   pclk,
    input                   vsync,
    input                   href,
    input       [7:0]       din,
    output reg  [23:0]      tdata,       // 16-bit pixel data for BRAM
    output                  tvalid,
    output                  tlast,
    output reg              pclk_out,
    
    // new signals added
    
    output reset,
    output pwdn,
    output [3:0]tkeep,
    output [0:0]tuser,
    input tready

);

    reg reset;
    assign pwdn = 1'b0;    
    assign tkeep = 4'b1111;
    assign tuser = 4'b0001;
    
    reg cnt;
    reg r_href;
    reg we, r_we;

    initial begin
        reset = 1'b0;
    end

    assign tlast = ({href, r_href} == 2'b01) ? 1'b1 : 1'b0;
    assign tvalid = ({we, r_we} == 2'b10) ? 1'b1 : 1'b0;
    
    
    always @(posedge pclk)
    begin 
      r_href <= href;
      r_we <= we;
      if (reset == 0) begin
        reset = 1'b1;
      end
      if (vsync == 1)
      begin
        cnt <= 'd0;
        we <= 1'b0;
      end
      else
      begin
        // While reading a line, output the RGB value once we have received all
        // colour channels
        if (href == 1'b1)
        begin
          if (cnt == 'd1)
          begin
            cnt <= 'd0;
            we <= 1'b1;
          end
          else
          begin
            cnt <= cnt + 'd1;
            we <= 1'b0;
          end
        end
        else
        begin
          we<=0;
        end 
        case (cnt)
          0 : begin
            tdata[23: 16] <= {din[7:3], 3'b0}; //r
            tdata[7:5] <= {din[2:0]}; // g first half
          end
          1 : begin
            tdata[4:0] <= {din[7:5], 2'h0}; // g second half
            tdata[15:8] <= {din[4:0], 3'b0}; // b
          end
        endcase
      end
    end
endmodule