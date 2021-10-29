module axi_bridge(
    input         clk   ,
    input         reset ,

    output [3 :0] arid   ,
    output [31:0] araddr ,
    output [7 :0] arlen  ,
    output [2 :0] arsize ,
    output [1 :0] arburst,
    output [1 :0] arlock ,
    output [3 :0] arcache,
    output [2 :0] arprot ,
    output        arvalid,
    input         arready,

    input [3 :0] rid    ,
    input [31:0] rdata  ,
    input [1 :0] rresp  ,
    input        rlast  ,
    input        rvalid ,
    output       rready ,

    output [3 :0] awid   ,
    output [31:0] awaddr ,
    output [7 :0] awlen  ,
    output [2 :0] awsize ,
    output [1 :0] awburst,
    output [1 :0] awlock ,
    output [3 :0] awcache,
    output [2 :0] awprot ,
    output        awvalid,
    input         awready,

    output [3 :0] wid    ,
    output [31:0] wdata  ,
    output [3 :0] wstrb  ,
    output        wlast  ,
    output        wvalid ,
    input         wready ,

    input [3 :0] bid    ,
    input [1 :0] bresp  ,
    input        bvalid ,
    output       bready ,

    // inst ram
    input inst_sram_req  ,
    //input inst_sram_wr    ,
    //input [1:0] inst_sram_size   ,
    //input [3:0] inst_sram_wstrb  ,
    input [31:0] inst_sram_addr   ,
    //input [31:0] inst_sram_wdata  ,
    output inst_sram_addr_ok,
    output inst_sram_data_ok,
    output [31:0] inst_sram_rdata  ,

    // data ram
    input data_sram_req    ,
    input data_sram_wr     ,
    input  [1:0] data_sram_size   ,
    input  [3:0] data_sram_wstrb ,
    input  [31:0] data_sram_addr   ,
    input  [31:0] data_sram_wdata ,
    output data_sram_addr_ok,
    output data_sram_data_ok,
    output  [31:0] data_sram_rdata 
);

localparam  ID_INST = 4'd0, 
            ID_DATA = 4'd1;

// ar
wire   data_sram_raddr_ok;
wire   data_sram_waddr_ok;

assign arlen = 8'd0;
assign arburst = 2'b01;
assign arlock = 2'd0;
assign arcache = 4'd0;
assign arprot = 3'd0;

wire inst_arreq;
wire data_arreq;

wire cpu_arreq;
wire [31:0] cpu_araddr;
wire [2:0] cpu_arsize;
wire [3:0] cpu_arid;

reg ar_req;
reg [31:0] araddr_r;
reg [2:0]  arsize_r;
reg [3:0]  arid_r;

assign inst_arreq = inst_sram_req & inst_sram_addr_ok;
assign data_arreq = data_sram_req & ~data_sram_wr & data_sram_raddr_ok;
assign cpu_arreq  = inst_arreq | data_arreq;
assign cpu_araddr = data_arreq ? data_sram_addr : inst_sram_addr;
assign cpu_arsize = data_arreq ? {1'd0,data_sram_size} : 3'd2;
assign cpu_arid   = data_arreq ? ID_DATA : ID_INST;

assign araddr = ar_req ? araddr_r : cpu_araddr;
assign arsize = ar_req ? arsize_r : cpu_arsize;
assign arid   = ar_req ? arid_r   : cpu_arid;

always @(posedge clk) begin
    if(reset) 
        ar_req <= 1'd0;
    else if(~ar_req & cpu_arreq & ~arready) begin 
        ar_req   <= 1'd1;
        araddr_r <= cpu_araddr;
        arsize_r <= cpu_arsize;
        arid_r   <= cpu_arid  ;
    end
    else if(ar_req & arready) 
        ar_req <= 1'd0;
end

assign arvalid = ar_req | cpu_arreq;

// r
assign rready = 1'd1;
assign inst_sram_data_ok = rvalid && rid == ID_INST;
assign data_sram_data_ok = rvalid && rid == ID_DATA;
assign inst_sram_rdata   = rdata;
assign data_sram_rdata   = rdata;

//aw && w 
assign awid = ID_DATA;
assign awlen = 8'd0;
assign awburst = 2'b01;
assign awlock = 2'd0;
assign awcache = 4'd0;
assign awprot = 3'd0;
assign wid = ID_DATA;
assign wlast = 1'd1;

wire data_awreq;
reg  aw_req;
reg  w_write;

reg [31:0] awaddr_r;
reg [2:0]  awsize_r;
reg [3:0]  wstrb_r;
reg [31:0] wdata_r;

assign data_awreq = data_sram_req & data_sram_wr & data_sram_waddr_ok;

assign awaddr = aw_req ? awaddr_r : data_sram_addr;
assign awsize = aw_req ? awsize_r : {1'd0,data_sram_size};
assign wstrb = w_write ? wstrb_r  : data_sram_wstrb  ;
assign wdata = w_write ? wdata_r  : data_sram_wdata  ;

always @(posedge clk) begin
    if(reset) 
        aw_req <= 1'd0;
    else if(~aw_req & data_awreq & ~awready) begin
        aw_req   <= 1'd1;
        awaddr_r <= data_sram_addr;
        awsize_r   <= {1'd0,data_sram_size};
    end
    else if(aw_req & awready) 
        aw_req <= 1'd0;
end

assign awvalid = data_awreq | aw_req;

always @(posedge clk) begin
    if(reset) 
        w_write <= 1'd0;
    else if(~w_write & data_awreq & ~wready) begin 
        w_write <= 1'd1;
        wstrb_r <= data_sram_wstrb;
        wdata_r <= data_sram_wdata;
    end
    else if(w_write & wready) 
        w_write <= 1'd0;
end

assign wvalid = data_awreq | w_write;

// b
assign bready = 1'd1;
reg w_not_finish;
always @(posedge clk) begin
    if(reset) 
        w_not_finish <= 1'd0;
    else if(~w_not_finish & data_awreq) 
        w_not_finish <= 1'd1;
    else if(w_not_finish & bvalid & ~data_awreq)
        w_not_finish <= 1'd0;
end

assign data_sram_waddr_ok = bvalid | ~w_not_finish;

// a very rough hazard detect
wire data_hazard;
wire inst_hazard;
assign data_hazard = data_sram_addr[31:2] == awaddr_r[31:2];
assign inst_hazard = 1'd0;
//assign inst_hazard = inst_sram_addr[31:2] == awaddr_r[31:2];
//assign inst_sram_addr_ok = ~ar_req & ~(inst_hazard & w_not_finish & ~bvalid) & ~data_arreq;
assign inst_sram_addr_ok = ~ar_req & ~data_arreq;
assign data_sram_raddr_ok = ~ar_req & ~(data_hazard & w_not_finish & ~bvalid);
assign data_sram_addr_ok = data_sram_wr ? data_sram_waddr_ok : data_sram_raddr_ok;

endmodule