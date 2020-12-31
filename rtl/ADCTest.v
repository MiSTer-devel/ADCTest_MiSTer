
module adctest
(
	input         clk,
	input         reset,
	
	input         scandouble,

	input  [11:0] adc_value,
	input         range,

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


// For audio line level, this is AC coupling; we must determine 'swing' from average value
// samples are taken at the beginning of each scanline (adc_val[n]), and
// a running total is kept in adc_total - which is 256 times the average amount
// The average is snapshotted once per frame (vsync), but can honestly be taken at any time

integer ii=0;
reg [11:0] adc_val[0:255];
reg [20:0] adc_total = 0;
reg [11:0] adc_avg;



// For the 3.3V scale, we remove 4 bits of precision from the value
// this gives us a range of 208 pix/3.3V, or ~63 pix per volt
// Note: the raw reading is roughly in millivolts

reg [8:0] left_edge_3v3 = 159;
reg [8:0] limit_3v3 = 208;
reg [8:0] pervolt_3v3 = 63;

reg [8:0] start_h_3v3;
reg [8:0] end_h_3v3;


// line level for consumer equipment is 0.894V peak-to-peak; for this reduced scale,
// we will only drop 2 bits of precision, but will constantly need to determine
// average value in order to center the image in the scale

reg [8:0] left_edge_audio = 106;
reg [8:0] red_zone_l_audio = 152;
reg [8:0] red_zone_r_audio = 378;
reg [8:0] limit_audio = 318;
reg [8:0] half_limit_audio = 159;

reg [9:0] start_h_line;
reg [9:0] end_h_line;



reg[8:0] left_edge;
reg[8:0] limit;



always @(posedge clk) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		hc <= 0;
		vc <= 0;
	end
	else if(ce_pix) begin
		if(hc == 637) begin
		
			adc_val[0] <= adc_value;
			adc_total  <= adc_total - adc_val[255] + adc_value;

			for (ii=0; ii<255; ii=ii+1)
				adc_val[ii+1] <= adc_val[ii];
			
			hc <= 0;
			if(vc == (scandouble ? 523 : 261)) begin
				vc <= 0;
				adc_avg <= adc_total[19:8];			// grab average value once per VSYNC
			end else begin
				vc <= vc + 1'd1;
			end
		end else begin
			hc <= hc + 1'd1;
		end

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


	video_r <= 0;
	video_g <= 0;
	video_b <= 0;

	if (hc == 2) begin								// beginning of scanline: determine range
		if (range == 0) begin
			limit			<= limit_3v3;
			left_edge	<= left_edge_3v3;
		end else begin
			limit			<= limit_audio;
			left_edge	<= left_edge_audio;
		end
	end

	if (hc == 3) begin								// next pixel: determine start/end values for this line
	
		// we're going to draw a horizontal line from old value to new value
		// first find which is the leftmost dot
		//
		// Do the calculations for the 3.3V scale here

		if (adc_val[0] > adc_val[1]) begin		
		
			if (adc_val[1][11:4] > limit_3v3)
				start_h_3v3 <= limit_3v3        + left_edge_3v3;
			else
				start_h_3v3 <= adc_val[1][11:4] + left_edge_3v3;

				
			if (adc_val[0][11:4] > limit_3v3)
				end_h_3v3   <= limit_3v3        + left_edge_3v3;
			else
				end_h_3v3   <= adc_val[0][11:4] + left_edge_3v3;

		end else begin

			if (adc_val[0][11:4] > limit_3v3)
				start_h_3v3 <= limit_3v3 +left_edge_3v3;
			else
				start_h_3v3 <= adc_val[0][11:4] + left_edge_3v3;

			if (adc_val[1][11:4] > limit_3v3)
				end_h_3v3   <= limit_3v3        + left_edge_3v3;
			else
				end_h_3v3   <= adc_val[1][11:4] + left_edge_3v3;
		end
		
		// Now, do the calculations for the line level
		
		if (adc_val[0] > adc_avg) begin
			if (adc_val[0][11:2] - adc_avg[11:2] > half_limit_audio)
				start_h_line <= limit_audio + left_edge_audio;
			else
				start_h_line <= left_edge_audio + adc_val[0][11:2] - adc_avg[11:2] + half_limit_audio;
				
		end else begin
		
			if (adc_avg[11:2] - adc_val[0][11:2] > half_limit_audio)
				start_h_line <= left_edge_audio;
			else
				start_h_line <= left_edge_audio + adc_val[0][11:2] - adc_avg[11:2] + half_limit_audio;
		end

		if (adc_val[1] > adc_avg) begin
			if (adc_val[1][11:2] - adc_avg[11:2] > half_limit_audio)
				end_h_line <= limit_audio + left_edge_audio;
			else
				end_h_line <= left_edge_audio + adc_val[1][11:2] - adc_avg[11:2] + half_limit_audio;
				
		end else begin
		
			if (adc_avg[11:2] - adc_val[1][11:2] > half_limit_audio)
				end_h_line <= left_edge_audio;
			else
				end_h_line <= left_edge_audio + adc_val[1][11:2] - adc_avg[11:2] + half_limit_audio;
		end

	end
	
	if (hc == 4) begin						// now to get the order correct, check if they are correct

		if (start_h_line > end_h_line) begin
			end_h_line		<= start_h_line;
			start_h_line	<= end_h_line;
		end
	end


	if (range == 0) begin				// Scale of 3.3V
	
		if ((hc == left_edge_3v3 + pervolt_3v3) ||
			 (hc == left_edge_3v3 + (pervolt_3v3 << 1)) ||
			 (hc == left_edge_3v3 + (pervolt_3v3 << 1) + pervolt_3v3))							// Green gradations at each volt
		begin
			video_r <= 8'b0000_0000;
			video_g <= 8'b0011_1111;
			video_b <= 8'b0000_0000;
		end
		
		if (vc & 2) begin
			if ((hc == left_edge_3v3 + (pervolt_3v3 >> 1)) ||
			    (hc == left_edge_3v3 + pervolt_3v3 + (pervolt_3v3 >> 1)) ||
				 (hc == left_edge_3v3 + (pervolt_3v3 << 1) + (pervolt_3v3 >> 1)) )			// dotted line at each half-volt
			begin
				video_r <= 8'b0000_0000;
				video_g <= 8'b0001_1111;
				video_b <= 8'b0000_0000;
			end
		end

		if (hc == (left_edge_3v3 + adc_avg[11:4])) begin
			video_r <= 8'b0111_1111;
			video_g <= 8'b0000_0000;
			video_b <= 8'b0000_0000;
		end

		if ((hc >= start_h_3v3) && (hc <= end_h_3v3)) begin										// draw the voltage measurement in white
			video_r <= 8'b1111_1111;
			video_g <= 8'b1111_1111;
			video_b <= 8'b1111_1111;
		end
		
	end else begin
	
		if ((vc & 2) && (hc == left_edge + (limit >> 1)) ) begin									// halfway point - dotted line
			video_r <= 8'b0000_0000;
			video_g <= 8'b0011_1111;
			video_b <= 8'b0000_0000;
		end

		if ((hc >= left_edge_audio) && (hc <= red_zone_l_audio)) begin							// shaded left red zone
			video_r <= 8'b0001_1111;
			video_g <= 8'b0000_0000;
			video_b <= 8'b0000_0000;
		end

		if ((hc >= red_zone_r_audio) && (hc <= (left_edge_audio + limit_audio))) begin	// shaded right red zone
			video_r <= 8'b0001_1111;
			video_g <= 8'b0000_0000;
			video_b <= 8'b0000_0000;
		end

		if ((hc >= start_h_line) && (hc <= end_h_line) && (hc <= red_zone_l_audio)) begin		// draw wave within the left red zone
			video_r <= 8'b1111_1111;
			video_g <= 8'b0000_0000;
			video_b <= 8'b0000_0000;
		end

		if ((hc >= start_h_line) && (hc <= end_h_line) && (hc >= red_zone_r_audio)) begin		// draw wave within the right red zone
			video_r <= 8'b1111_1111;
			video_g <= 8'b0000_0000;
			video_b <= 8'b0000_0000;
		end

		if ((hc >= start_h_line) && (hc <= end_h_line) &&
			 (hc >= red_zone_l_audio) && (hc <= red_zone_r_audio))										// draw wave within the middle white zone
		begin
			video_r <= 8'b1111_1111;
			video_g <= 8'b1111_1111;
			video_b <= 8'b1111_1111;
		end


	end

	if (hc == left_edge) begin				// left edge marker
		video_r <= 8'b1111_1111;
		video_g <= 8'b1111_1111;
		video_b <= 8'b0000_0000;
	end

	if (hc == left_edge + limit) begin	// right edge marker
		video_r <= 8'b1111_1111;
		video_g <= 8'b1111_1111;
		video_b <= 8'b0000_0000;
	end


	if (hc == 590) HSync <= 0;
end


endmodule
