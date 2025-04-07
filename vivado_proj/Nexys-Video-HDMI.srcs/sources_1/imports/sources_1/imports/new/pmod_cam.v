`timescale 1ns / 1ps

module pmod_cam (
    input                   pclk,
    input                   vsync,
    input                   href,
    input       [7:0]       din,
    output reg  [23:0]      dout,       // 16-bit pixel data for BRAM
    output                  valid,
    output                  last,
    output reg              pclk_out

);

//reg [1:0] cnt;
//reg r_href;
//reg we, r_we;

//// Create a 'last' pulse on the falling edge of href
//assign last = ({href, r_href} == 2'b01) ? 1'b1 : 1'b0;
//// Create a 'valid' pulse on the rising edge of write enable
//assign valid = ({we, r_we} == 2'b10) ? 1'b1 : 1'b0;

//always @(posedge pclk)
//begin 
//  r_href <= href;
//  r_we <= we;

//  // Reset values on the end of a frame
//  if (vsync == 1)
//  begin
//    cnt <= 'd0;
//    we <= 1'b0;
//  end
//  else
//  begin
//    // While reading a line, output the RGB value once we have received all
//    // colour channels
//    if (href == 1'b1)
//    begin
//      if (cnt == 'd2)
//      begin
//        cnt <= 'd0;
//        we <= 1'b1;
//      end
//      else
//      begin
//        cnt <= cnt + 'd1;
//        we <= 1'b0;
//      end
//    end

//    // Update the pixel data according to our internal counter
//    case (cnt)
//      1 : begin
//        dout[23:16] <= 'hFF;   
//      end
//      0 : begin
//        dout[15: 8] <= 'hFF;
//      end
//      2 : begin
//        dout[ 7: 0] <= 'hFF;
//      end
//    endcase
//  end
//end


reg cnt;
reg r_href;
reg we, r_we;

// Create a 'last' pulse on the falling edge of href
assign last = ({href, r_href} == 2'b01) ? 1'b1 : 1'b0;
// Create a 'valid' pulse on the rising edge of write enable
assign valid = ({we, r_we} == 2'b10) ? 1'b1 : 1'b0;

always @(posedge pclk)
begin 
  r_href <= href;
  r_we <= we;

  // Reset values on the end of a frame
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

    // Update the pixel data according to our internal counter
    case (cnt)
      1 : begin
        dout[15:8] <= {din[3:0], 4'h0}; // b
        dout[7:0] <= {din[7:4], 4'b0}; // g
      end
      0 : begin
        dout[23: 16] <= {din[7:4], 4'b0}; //r
      end
    endcase
  end
end
  
  
  
  
//  reg cnt;
//reg r_href;
//reg we, r_we;

//// Create a 'last' pulse on the falling edge of href
//assign last = ({href, r_href} == 2'b01) ? 1'b1 : 1'b0;
//// Create a 'valid' pulse on the rising edge of write enable
//assign valid = ({we, r_we} == 2'b10) ? 1'b1 : 1'b0;

//always @(posedge pclk)
//begin 
//  r_href <= href;
//  r_we <= we;

//  // Reset values on the end of a frame
//  if (vsync == 1)
//  begin
//    cnt <= 'd0;
//    we <= 1'b0;
//  end
//  else
//  begin
//    // While reading a line, output the RGB value once we have received all
//    // colour channels
//    if (href == 1'b1)
//    begin
//      if (cnt == 'd1)
//      begin
//        cnt <= 'd0;
//        we <= 1'b1;
//      end
//      else
//      begin
//        cnt <= cnt + 'd1;
//        we <= 1'b0;
//      end
//    end else begin
//        we<=0;
//    end

//    // Update the pixel data according to our internal counter
//    case (cnt)
//      1 : begin
//        dout[15:8] <= {din[4:0], 3'h0}; // b
//        dout[4:0] <= {din[7:5], 2'b0}; // g
//      end
//      0 : begin
//        dout[23: 16] <= {din[7:3], 3'b0}; //r
//        dout[7:5] <= {din[2:0]}; // g

//      end
//    endcase
//  end
//end
  
  
  
  
  
  
  
  
  
  
  
  
    
//    always @ (negedge pclk)
//    begin
//        pclk_out = !pclk_out;
//    end



//reg [3:0] cnt;
//reg r_href;
//reg we, r_we;

//// Create a 'last' pulse on the falling edge of href
//assign last = ({href, r_href} == 2'b01) ? 1'b1 : 1'b0;
//// Create a 'valid' pulse on the rising edge of write enable
//assign valid = ({we, r_we} == 2'b10) ? 1'b1 : 1'b0;

//always @(posedge pclk)
//begin 
//  r_href <= href;
//  r_we <= we;

//  // Reset values on the end of a frame
//  if (vsync == 1)
//  begin
//    cnt <= 'd0;
//    we <= 1'b0;
//  end
//  else
//  begin
//    // While reading a line, output the RGB value once we have received all
//    // colour channels
//    if (href == 1'b1)
//    begin
//      if (cnt == 3 || cnt == 7 || cnt == 11)
//      begin
//        cnt <= cnt == 11 ? 0 : cnt + 1;
//        we <= 1;
//      end
////      else if (cnt == 2 || cnt == 6 || cnt == 10)
////      begin
////        cnt <= cnt == 11 ? 0 : cnt + 1;
////      end
//      else 
//      begin
//        cnt <= cnt + 'd1;
//        we <= 1'b0;
//      end
////      if (cnt_color == 'd2) begin
////        cnt_color<='d0;
////      end else begin
////        cnt_color <= cnt_color + 'd1;
////      end
//    end else begin
//        we <= 0;
//    end

//    // Update the pixel data according to our internal counter
//    case (cnt)
//      0 : begin
//        dout[23:16] <= {din[3:0],4'b0}; // r  
//      end
//      1 : begin
//        dout[15: 8] <= {din[3:0],4'b0}; //b
//        dout[7: 0] <= {din[7:4],4'b0}; //g
//      end
//      2 : begin
//        dout[31: 24] <= {din[3:0],4'b0}; // r
//      end
//      3: begin
//        dout[7:0] <= {din[3:0],4'b0}; 
//      end
//      4 : begin
//        dout[31:24] <= {din[3:0],4'b0};
//      end
//      5 : begin
//        dout[23: 16] <= {din[7:4],4'b0};
//      end
//      6 : begin
//        dout[15: 8] <= {din[3:0],4'b0}; 
//      end
//      7: begin
//        dout[7:0] <= {din[3:0],4'b0};
//      end
//      8 : begin
//        dout[31:24] <= din;   
//      end
//      9 : begin
//        dout[23: 16] <= 8'hFF;
//      end
//      10 : begin
//        dout[15: 8] <= 8'hFF;
//      end
//      11: begin
//        dout[7:0] <= 
//      end
      
//    endcase
//  end
//end

//always @(posedge fast_clk) begin
//    we <= 'b1111;
//end

endmodule

