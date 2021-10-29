module cache( 
    input         clk_g,
    input         resetn, 
    input         valid,
    input         op,
    input  [ 7:0] index, 
    input  [19:0] tag, 
    input  [ 3:0] offset, 
    input  [ 3:0] wstrb,
    input  [31:0] wdata,

    output        addr_ok,
    output        data_ok,
    output [31:0] rdata,
    
    output        rd_req,
    output [ 2:0] rd_type,
    output [31:0] rd_addr,
    input         rd_rdy,
    input         ret_valid,
    input         ret_last,
    input  [31:0] ret_data,
    
    output        wr_req,
    output [ 2:0] wr_type,
    output [31:0] wr_addr,
    output [ 3:0] wr_wstrb,
    output [127:0]wr_data,       
    input         wr_rdy
);  

// Not supported to expend now, remains to be improved
localparam WAYNUM = 2;

wire clk;
assign clk = clk_g;
reg [7:0] rst_count;
reg reseting;

localparam  IDLE    = 5'b1,
            LOOKUP  = 5'b10,
            MISS    = 5'b100,
            REPLACE = 5'b1000,
            REFILL  = 5'b10000;

wire is_hit;
wire need_replace;

reg  [4:0] current_state;
reg  [4:0] next_state;

always @(*) begin
    case(current_state)
        IDLE:   if(valid && addr_ok)
                    next_state = LOOKUP;
                else 
                    next_state = IDLE;
        LOOKUP: if(~is_hit && need_replace)
                    next_state = MISS;
                else if(~is_hit && ~need_replace)
                    next_state = REPLACE;
                else if(is_hit && valid && addr_ok)
                    next_state = LOOKUP;
                else 
                    next_state = IDLE;
        MISS:   if(wr_rdy) 
                    next_state = REPLACE;
                else 
                    next_state = MISS;
        REPLACE:if(rd_rdy)
                    next_state = REFILL;
                else 
                    next_state = REPLACE;
        REFILL: if(ret_last && ret_valid) begin 
                    if(addr_ok && valid)
                        next_state = LOOKUP;
                    else 
                        next_state = IDLE;
                end
                else 
                    next_state = REFILL;
        default:    next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    if(~resetn) 
        current_state <= IDLE;
    else if(~reseting)
        current_state <= next_state;
end

reg        op_r;
reg [7:0]  index_r;
reg [19:0] tag_r;
reg [3:0]  offset_r;
reg [3:0]  wstrb_r;
reg [31:0] wdata_r;

always @(posedge clk) begin
    if(addr_ok && valid) begin
        op_r     <= op;
        index_r  <= index;
        tag_r    <= tag;
        offset_r <= offset;
        wstrb_r  <= wstrb;
        wdata_r  <= wdata;
    end
end

wire [WAYNUM-1:0] r_v;
wire [19:0] r_tag [WAYNUM-1:0];
wire w_v;
wire [19:0] w_tag;
wire [127:0] r_data [WAYNUM-1:0];
wire [31:0] w_data;
wire [7:0] tagv_set;
wire [7:0] data_set [3:0];
wire [WAYNUM-1:0] tagv_we;
wire [15:0] data_we [WAYNUM-1:0];

wire [WAYNUM-1:0] replace_way;
wire [WAYNUM-1:0] hit;
reg  [255:0] dirty [WAYNUM-1:0];

always @(posedge clk) begin
    if(current_state==LOOKUP && ~op_r && ~is_hit) 
        dirty[replace_way][index_r] <= 1'd0;
    else if(current_state==LOOKUP && op_r) begin
        if(hit[0])
            dirty[0][index_r] <= 1'd1;
        else if(hit[1])
            dirty[1][index_r] <= 1'd1;
        else 
            dirty[replace_way][index_r] <= 1'd1;
    end
end

genvar i;
generate for (i=0;i<WAYNUM;i=i+1) begin: ram_gen
    ram_tagv u_ram_tagv(.addra(tagv_set), .clka(clk), .dina({w_tag,w_v}), .douta({r_tag[i],r_v[i]}), .wea(tagv_we[i]));
    ram_data u_ram_data0(.addra(data_set[0]), .clka(clk), .dina(w_data), .douta(r_data[i][0+:32]), .wea(data_we[i][0+:4]));
    ram_data u_ram_data1(.addra(data_set[1]), .clka(clk), .dina(w_data), .douta(r_data[i][32+:32]), .wea(data_we[i][4+:4]));
    ram_data u_ram_data2(.addra(data_set[2]), .clka(clk), .dina(w_data), .douta(r_data[i][64+:32]), .wea(data_we[i][8+:4]));
    ram_data u_ram_data3(.addra(data_set[3]), .clka(clk), .dina(w_data), .douta(r_data[i][96+:32]), .wea(data_we[i][12+:4]));
end endgenerate

reg [15:0] lfsr;
always @(posedge clk) begin
    if(~resetn)
        lfsr <= 16'h9BCD;  
    else if(current_state == REFILL && ret_last && ret_valid)
        lfsr <= {lfsr[14:0],~(lfsr[3]^lfsr[12]^lfsr[14]^lfsr[15])};
end

assign replace_way = lfsr[0];
assign need_replace = ~is_hit && dirty[replace_way][offset_r] && r_v[replace_way];
assign is_hit = hit[0] || hit[1];

assign tagv_set = reseting ? rst_count : addr_ok ? index : index_r;
assign data_set[0] = addr_ok && ~(current_state==LOOKUP&&op_r&&offset_r[3:2]==2'd0) ? index : index_r;
assign data_set[1] = addr_ok && ~(current_state==LOOKUP&&op_r&&offset_r[3:2]==2'd1) ? index : index_r;
assign data_set[2] = addr_ok && ~(current_state==LOOKUP&&op_r&&offset_r[3:2]==2'd2) ? index : index_r;
assign data_set[3] = addr_ok && ~(current_state==LOOKUP&&op_r&&offset_r[3:2]==2'd3 || current_state==REFILL) ? index : index_r;

reg [1:0] counter;
always @(posedge clk) begin
    if(current_state == LOOKUP)
        counter <= 2'd0;
    else if(current_state==REFILL && ret_valid) 
        counter <= counter + 2'd1;
end

wire [15:0] cpu_wstrb;
assign cpu_wstrb = {{4{offset_r[3:2]==2'd3}} & wstrb_r,{4{offset_r[3:2]==2'd2}} & wstrb_r,
                    {4{offset_r[3:2]==2'd1}} & wstrb_r,{4{offset_r[3:2]==2'd0}} & wstrb_r};
wire [15:0] refill_wstrb;
assign refill_wstrb = {{4{counter==2'd3}},{4{counter==2'd2}},{4{counter==2'd1}},{4{counter==2'd0}}};
wire [31:0] refill_data;
wire [31:0] strbit;
assign strbit = {{8{wstrb_r[3]}},{8{wstrb_r[2]}},{8{wstrb_r[1]}},{8{wstrb_r[0]}}};
assign refill_data = offset_r[3:2]!=counter ? ret_data : wdata_r & strbit | ret_data & ~strbit;
wire [127:0] hit_block;
assign hit_block = hit[0] ? r_data[0] : r_data[1];
wire [31:0] hit_data;
assign hit_data = {32{offset_r==2'd3}} & hit_block[96+:32] | {32{offset_r==2'd2}} & hit_block[64+:32] 
                | {32{offset_r==2'd1}} & hit_block[32+:32] | {32{offset_r==2'd0}} & hit_block[0+:32];

generate for (i=0;i<WAYNUM;i=i+1) begin: wire_gen
    assign hit[i] = r_v[i] && r_tag[i]==tag_r;
    assign tagv_we[i] = current_state==REPLACE && rd_rdy && replace_way==i || reseting;
    assign data_we[i] = {16{current_state==LOOKUP&&hit[i]&&op_r}} & cpu_wstrb
                      | {16{current_state==REFILL && replace_way==i && ret_valid}} & refill_wstrb;
end endgenerate

wire [127:0] replace_data;
wire [19:0] replace_tag;
assign replace_data = r_data[replace_way];
assign replace_tag  = r_tag[replace_way];

// not support uncache access yet
assign wr_req = current_state == MISS;
assign wr_type = 3'b100;
assign wr_addr = {replace_tag,index_r,4'd0};
assign wr_wstrb = 4'hf;
assign wr_data = replace_data;

assign rd_req = current_state == REPLACE;
assign rd_type = 3'b100;
assign rd_addr = {tag_r, index_r, 4'd0};

assign w_v = ~reseting;
assign w_tag = tag_r;
assign w_data = current_state==REFILL ? refill_data : wdata_r;

assign rdata = current_state == LOOKUP ? hit_data : ret_data;
assign addr_ok = (current_state == IDLE || current_state == LOOKUP && is_hit && ~(op_r && offset[3:2]==offset_r[3:2])
                || current_state == REFILL && ret_valid && ret_last && offset[3:2]!=2'd3) && ~reseting;
assign data_ok = current_state == LOOKUP && (op_r | is_hit)
              || current_state == REFILL && ~op_r && ret_valid && counter == offset_r[3:2];

//reset
always @(posedge clk) begin
    if(~resetn) 
        rst_count <= 8'd0;
    else 
        rst_count <= rst_count + 1'd1;
end

always @(posedge clk) begin
    if(~resetn) 
        reseting <= 1'd1;
    else if(rst_count == 8'd255)
        reseting <= 1'd0;
end


endmodule