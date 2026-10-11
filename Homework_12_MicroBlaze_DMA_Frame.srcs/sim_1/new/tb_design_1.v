`timescale 1ns / 1ps

module tb_design_1;

    // ------------------------------------------------------------
    // DUT inputs
    // ------------------------------------------------------------

    reg        CLK_IN1_D_0_clk_p = 1'b0;
    reg        CLK_IN1_D_0_clk_n = 1'b1;

    reg [0:0]  GPIO_0_tri_i      = 1'b0;

    reg        ext_clk_0          = 1'b0;
    reg [7:0]  ext_data_0         = 8'd0;
    reg        ext_valid_0        = 1'b0;

    reg        ext_reset_in_0     = 1'b0;
    reg        ext_resetn_0       = 1'b0;


    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    design_1_wrapper dut (
        .CLK_IN1_D_0_clk_n (CLK_IN1_D_0_clk_n),
        .CLK_IN1_D_0_clk_p (CLK_IN1_D_0_clk_p),

        .GPIO_0_tri_i      (GPIO_0_tri_i),

        .ext_clk_0         (ext_clk_0),
        .ext_data_0        (ext_data_0),
        .ext_reset_in_0    (ext_reset_in_0),
        .ext_resetn_0      (ext_resetn_0),
        .ext_valid_0       (ext_valid_0)
    );


    // ------------------------------------------------------------
    // 100 MHz differential system clock
    // ------------------------------------------------------------

    always #5 begin
        CLK_IN1_D_0_clk_p = ~CLK_IN1_D_0_clk_p;
        CLK_IN1_D_0_clk_n = ~CLK_IN1_D_0_clk_n;
    end


    // ------------------------------------------------------------
    // External data clock: 25 MHz
    // Period = 40 ns
    // ------------------------------------------------------------

    always #20 ext_clk_0 = ~ext_clk_0;


    // ------------------------------------------------------------
    // Send one 320 x 200 frame
    // 64000 pixels, 8 bits per pixel
    // ------------------------------------------------------------

    task send_frame;
        integer i;
        begin

            for (i = 0; i < 64000; i = i + 1) begin
                @(negedge ext_clk_0);

                ext_valid_0 = 1'b1;

                // Simple test pattern:
                // 00, 01, 02 ... FF, 00, 01 ...
                ext_data_0 = i[7:0];
            end

            @(negedge ext_clk_0);

            ext_valid_0 = 1'b0;
            ext_data_0  = 8'd0;
        end
    endtask


    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------

    initial begin

        GPIO_0_tri_i  = 1'b0;

        ext_data_0    = 8'd0;
        ext_valid_0   = 1'b0;

        // Hold both reset domains in reset
        ext_reset_in_0 = 1'b0;
        ext_resetn_0   = 1'b0;

        #500;

        // Release resets
        ext_reset_in_0 = 1'b1;
        ext_resetn_0   = 1'b1;

        // Give MicroBlaze enough time to boot and initialize
        #500000;
        
        // Press button for 100 us
        GPIO_0_tri_i = 1'b1;
        
        #100000;
        
        GPIO_0_tri_i = 1'b0;
        
        // Give MicroBlaze time to configure DMA
        // and generate START
        #500000;

        // --------------------------------------------------------
        // Send frame
        // --------------------------------------------------------

        send_frame();

        // Wait after complete frame
        #50000;

        $finish;
    end

endmodule