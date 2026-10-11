module frame_rx_axis #(
    parameter FRAME_WIDTH  = 320,
    parameter FRAME_HEIGHT = 200
)(
    // External input clock domain
    input  wire        ext_clk,
    input  wire        ext_resetn,

    input  wire [7:0]  ext_data,
    input  wire        ext_valid,

    // Start capture
    input  wire        start,

    // AXI4-Stream clock domain
    input  wire        m_axis_aclk,
    input  wire        m_axis_aresetn,

    // AXI4-Stream output
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    localparam FRAME_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;
    localparam FRAME_WORDS  = FRAME_PIXELS / 4;


    // ============================================================
    // START synchronization into ext_clk domain
    // ============================================================

    reg start_sync1;
    reg start_sync2;
    reg start_sync2_d;

    wire start_pulse;

    assign start_pulse = start_sync2 & ~start_sync2_d;

    always @(posedge ext_clk or negedge ext_resetn) begin
        if (!ext_resetn) begin
            start_sync1   <= 1'b0;
            start_sync2   <= 1'b0;
            start_sync2_d <= 1'b0;
        end else begin
            start_sync1   <= start;
            start_sync2   <= start_sync1;
            start_sync2_d <= start_sync2;
        end
    end


    // ============================================================
    // Frame capture logic
    // ============================================================

    reg        capture_active;
    reg [31:0] pixel_count;

    wire fifo_full;
    wire fifo_wr_en;

    assign fifo_wr_en =
        capture_active &&
        ext_valid &&
        !fifo_full;

    always @(posedge ext_clk or negedge ext_resetn) begin
        if (!ext_resetn) begin
            capture_active <= 1'b0;
            pixel_count    <= 32'd0;
        end else begin

            // Start new frame
            if (start_pulse) begin
                capture_active <= 1'b1;
                pixel_count    <= 32'd0;
            end

            // Count only bytes actually written into FIFO
            if (fifo_wr_en) begin
                if (pixel_count == FRAME_PIXELS - 1) begin
                    capture_active <= 1'b0;
                    pixel_count    <= 32'd0;
                end else begin
                    pixel_count <= pixel_count + 1'b1;
                end
            end
        end
    end


    // ============================================================
    // Asynchronous FIFO
    //
    // Write side:  8 bit
    // Read side:  32 bit
    // ============================================================

    wire [31:0] fifo_dout;
    wire        fifo_empty;
    wire        fifo_rd_en;

    frame_fifo frame_fifo_inst (
        .rst    (~ext_resetn),

        .wr_clk (ext_clk),
        .rd_clk (m_axis_aclk),

        .din    (ext_data),
        .wr_en  (fifo_wr_en),

        .rd_en  (fifo_rd_en),
        .dout   (fifo_dout),

        .full   (fifo_full),
        .empty  (fifo_empty)
    );


    // ============================================================
    // AXI4-Stream output
    // ============================================================

    reg [31:0] word_count;

    assign m_axis_tdata  = fifo_dout;
    assign m_axis_tvalid = !fifo_empty;

    assign m_axis_tlast =
        (!fifo_empty) &&
        (word_count == FRAME_WORDS - 1);

    assign fifo_rd_en =
        m_axis_tvalid &&
        m_axis_tready;


    // Count only successfully transferred AXI words
    always @(posedge m_axis_aclk or negedge m_axis_aresetn) begin
        if (!m_axis_aresetn) begin
            word_count <= 32'd0;
        end else begin

            if (m_axis_tvalid && m_axis_tready) begin
                if (word_count == FRAME_WORDS - 1)
                    word_count <= 32'd0;
                else
                    word_count <= word_count + 1'b1;
            end
        end
    end

endmodule