
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

reg [9:0] start_line;
reg [9:0] end_line;

reg [11:0] adc_curr;
reg [11:0] adc_curr_d;

reg [8:0] start_h;
reg [8:0] end_h;

reg[8:0] left_edge_3v3 = 159;
reg[8:0] limit_3v3 = 208;
reg[8:0] pervolt_3v3 = 63;

reg[8:0] left_edge_audio = 149;
reg[8:0] limit_audio = 230;

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
		
			adc_curr   <= adc_value;
			adc_curr_d <= adc_curr;
			
			hc <= 0;
			if(vc == (scandouble ? 523 : 261)) begin 
				vc <= 0;
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
	
	if (hc == 2) begin
		if (range == 0) begin
			limit			<= limit_3v3;
			left_edge	<= left_edge_3v3;
		end else begin
			limit			<= limit_audio;
			left_edge	<= left_edge_audio;
		end
	end

	if (hc == 3) begin
		if (adc_curr > adc_curr_d) begin
		
			if (adc_curr_d[11:4] > limit_3v3)
				start_h <= limit_3v3 + left_edge_3v3;
			else
				start_h <= adc_curr_d[11:4] + left_edge_3v3;

			if (adc_curr[11:4] > limit_3v3)
				end_h   <= limit_3v3 + left_edge_3v3;
			else
				end_h   <= adc_curr[11:4] + left_edge_3v3;

		end
		else begin
			if (adc_curr[11:4] > limit_3v3)
				start_h <= limit_3v3 +left_edge_3v3;
			else
				start_h <= adc_curr[11:4]   + left_edge_3v3;
				
			if (adc_curr_d[11:4] > limit_3v3)
				end_h   <= limit_3v3 + left_edge_3v3;
			else
				end_h   <= adc_curr_d[11:4] + left_edge_3v3;

		end
	end

	if (range == 0) begin				// Scale of 3.3V
	
		if (hc == left_edge_3v3) begin
			video_r <= 8'b1111_1111;
			video_g <= 8'b1111_1111;
			video_b <= 8'b0000_0000;
		end

		if ((hc == left_edge_3v3 + pervolt_3v3) || (hc == left_edge_3v3 + (pervolt_3v3 << 1)) ||		// Green gradations at each volt
			 (hc == left_edge_3v3 + (pervolt_3v3 << 1) + pervolt_3v3))
		begin
			video_r <= 8'b0000_0000;
			video_g <= 8'b0011_1111;
			video_b <= 8'b0000_0000;
		end
		
		if (vc & 2) begin
			if ((hc == left_edge_3v3 + (pervolt_3v3 >> 1)) ||
			    (hc == left_edge_3v3 + pervolt_3v3 + (pervolt_3v3 >> 1)) ||
				 (hc == left_edge_3v3 + (pervolt_3v3 << 1) + (pervolt_3v3 >> 1)) )		// dotted line at each half-volt
			begin
				video_r <= 8'b0000_0000;
				video_g <= 8'b0001_1111;
				video_b <= 8'b0000_0000;
			end
		end
		
		if (hc == left_edge_3v3 + limit_3v3) begin	// 3.3V range
			video_r <= 8'b1111_1111;
			video_g <= 8'b1111_1111;
			video_b <= 8'b0000_0000;
		end

		if ((hc >= start_h) && (hc <= end_h)) begin	// draw the voltage measurement in white
			video_r <= 8'b1111_1111;
			video_g <= 8'b1111_1111;
			video_b <= 8'b1111_1111;
		end
	end


	if (hc == 590) HSync <= 0;
end


endmodule
