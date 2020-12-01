
module adctest
(
	input         clk,
	input         reset,
	
//	input         pal,
	input         scandouble,

	input  [7:0] max_val,
	input  [7:0] min_val,

	output reg    ce_pix,

	output reg    HBlank,
	output reg    HSync,
	output reg    VBlank,
	output reg    VSync,

	output reg [7:0] video_r,
	output reg [7:0] video_g,
	output reg [7:0] video_b
);

reg   [9:0] hc;
reg   [9:0] vc;
//reg   [9:0] vvc;
//reg  [63:0] rnd_reg;

//wire  [5:0] rnd_c = {rnd_reg[0],rnd_reg[1],rnd_reg[2],rnd_reg[2],rnd_reg[2],rnd_reg[2]};
//wire [63:0] rnd;

// lfsr random(rnd);

reg  big_gradation;
reg  small_gradation;
reg  disp_red;
reg  disp_white;

reg [9:0] start_line;
reg [9:0] end_line;


always @(posedge clk) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		hc <= 0;
		vc <= 0;
	end
	else if(ce_pix) begin
		if(hc == 637) begin
			hc <= 0;
			if(vc == (scandouble ? 523 : 261)) begin 
				vc <= 0;
//				vvc <= vvc + 9'd6;
			end else begin
				vc <= vc + 1'd1;
			end
		end else begin
			hc <= hc + 1'd1;
		end

//		rnd_reg <= rnd;
	end
end

always @(posedge clk) begin
	if (hc == 529)
		HBlank <= 1;
	else if (hc == 0)
		HBlank <= 0;

	if (hc == 544) begin
		HSync <= 1;

		if(vc == (scandouble ? 490 : 245)) VSync <= 1;
			else if (vc == (scandouble ? 496 : 248)) VSync <= 0;

		if(vc == (scandouble ? 480 : 240)) VBlank <= 1;
			else if (vc == 0) VBlank <= 0;
	end

	if (hc == 0) begin
		big_gradation <= 1'b0;
		small_gradation <= 1'b0;
		disp_red <= 1'b0;
		disp_white <= 1'b0;

		start_line <= { 2'b0, ~max_val[7:0] } + 9'd114;
		end_line   <= { 2'b0, ~min_val[7:0] } + 9'd114;
	end
	
	if (hc == 1) begin															// set the flags for the line

		if(vc == (scandouble ? 112 : 56)) big_gradation <= 1'b1;			// 100%
		if(vc == (scandouble ? 144 : 72)) small_gradation <= 1'b1;		// 87.5%
		if(vc == (scandouble ? 176 : 88)) small_gradation <= 1'b1;		// 75%
		if(vc == (scandouble ? 208 : 104)) small_gradation <= 1'b1;		// 62.5%
		if	(vc == (scandouble ? 240 : 120)) big_gradation <= 1'b1;		// 50%
		if(vc == (scandouble ? 272 : 136)) small_gradation <= 1'b1;		// 37.5%
		if(vc == (scandouble ? 304 : 152)) small_gradation <= 1'b1;		// 25%
		if(vc == (scandouble ? 336 : 168)) small_gradation <= 1'b1;		// 12.5%
		if(vc == (scandouble ? 368 : 184)) big_gradation <= 1'b1;		// 0%
		
	end
	
	if (hc == 2) begin
//		if (scandouble == 1) begin
//			if ((vc > start_line) && (vc < end_line)) begin
//				if (vc < 164)
//					disp_red <= 1'b1;
//				else 
//					disp_white <= 1'b1;
//			end
//		else
			if ( (vc >= (start_line >> 1) ) && (vc < (end_line >> 1) ) ) begin
				if (vc < 82)
					disp_red <= 1'b1;
				else 
					disp_white <= 1'b1;
			end
//		end
	end

   if ( (hc > 80) && (hc < 100) && (big_gradation == 1) ) begin
//		if (scandouble == 1'b0) begin
			video_r <= 8'b1111_1111;
			video_g <= 8'b1111_1111;
//		end
		video_b <= 8'b1111_1111;
	end

   else if ( (hc > 95) && (hc < 100) && (small_gradation == 1) ) begin
		video_r <= 8'b1111_1111;
		video_g <= 8'b1111_1111;
		video_b <= 8'b1111_1111;
	end

   else if ( (hc > 150) && (hc < 250) && (disp_red == 1) ) begin
		video_r <= 8'b1111_1111;
	end

   else if ( (hc > 150) && (hc < 250) && (disp_white == 1) ) begin
		video_r <= 8'b1111_1111;
		video_g <= 8'b1111_1111;
		video_b <= 8'b1111_1111;
	end
	
   else if ( vc == start_line ) begin
		video_r <= 8'b1111_1111;
		video_g <= 8'b0000_0000;
		video_b <= 8'b0000_0000;
	end

   else if ( vc == end_line ) begin
		video_r <= 8'b0000_0000;
		video_g <= 8'b1111_1111;
		video_b <= 8'b0000_0000;
	end

	else begin
		video_r <= 8'b0000_0000;
		video_g <= 8'b0000_0000;
		video_b <= 8'b0000_0000;
	end

	if (hc == 590) HSync <= 0;
end

//reg  [7:0] cos_out;
//wire [5:0] cos_g = cos_out[7:3]+6'd32;
//cos cos(vvc + {vc>>scandouble, 2'b00}, cos_out);

// assign video_r = (cos_g >= rnd_c) ? {cos_g - rnd_c, 2'b00} : 8'd0;

endmodule
