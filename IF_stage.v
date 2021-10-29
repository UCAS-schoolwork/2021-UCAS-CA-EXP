`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //allowin
     input                      ds_allowin     ,
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    //to ds
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    // from ms
    input [`MS_TO_FS_BUS_WD-1:0] ms_to_fs_bus ,
    // search port0
    output  [             18:0]s0_vpn2,
    output                     s0_odd_page,        
    input                      s0_found,         
    input [              19:0] s0_pfn,     
    input                      s0_v,
    // inst sram interface
    output inst_sram_req  ,
    //output inst_sram_wr    ,
    //output [1:0] inst_sram_size   ,
    //output [3:0] inst_sram_wstrb  ,
    output [31:0] inst_sram_addr   ,
    //output [31:0] inst_sram_wdata  ,
    input inst_sram_addr_ok,
    input inst_sram_data_ok,
    input [31:0] inst_sram_rdata  
);

 reg         fs_valid;
 wire        fs_ready_go;
 wire        fs_allowin;
wire        to_fs_valid;
 wire   pfs_ready_go;
 
wire [31:0] seq_pc;
 wire [31:0] nextpc;
 wire        pfs_ext;
 reg          fs_ext;
 wire         fs_bd;


reg [4:0]  fs_excode;
reg        fs_refill;
wire [4:0] pfs_excode;
 wire         br_taken;
wire [ 31:0] br_target;
 wire         br_valid;
 wire         br_stall;

wire   tlb_refill;

//ext
wire [31:0] fs_inst;
 reg  [31:0] fs_pc;
assign fs_to_ds_bus = {fs_refill, //71
                       fs_ext,    //70
                       fs_excode, //69:65
                       fs_bd   ,  //64
                       fs_inst ,  //63:32
                       fs_pc      //31:0
                       }; 

  // reflush_r means reflush or reflush_reg
wire reflush_r;
wire reflush;
wire [31:0] ext_pc;
reg ms_to_fs_bus_r_valid;
reg [`MS_TO_FS_BUS_WD-1:0] ms_to_fs_bus_r;
always @(posedge clk) begin
    if(reset)
        ms_to_fs_bus_r_valid <= 1'd0;
    else if(~ms_to_fs_bus_r_valid&(reflush)&~pfs_ready_go) begin
        ms_to_fs_bus_r_valid <= 1'd1;
        ms_to_fs_bus_r <= ms_to_fs_bus;
    end
    else if(ms_to_fs_bus_r_valid&pfs_ready_go)
        ms_to_fs_bus_r_valid <= 1'd0;
end
assign {
    reflush_r, //32
    ext_pc    //31:0
} = ms_to_fs_bus_r_valid ? ms_to_fs_bus_r : ms_to_fs_bus;
assign reflush = ms_to_fs_bus[32];

reg [`BR_BUS_WD-1:0] br_bus_r;
reg                  br_bus_r_valid;
reg                  bd_done;

// tlb
wire   [31:0] next_ppc;
wire   unmap;
assign unmap = nextpc[31:30]==2'b10;
assign s0_vpn2 = nextpc[31:13];
assign s0_odd_page = nextpc[12];
assign next_ppc = {unmap ? nextpc[31:12] : s0_pfn, nextpc[11:0]};

// pre-IF stage
// pre_IF valid == 1
reg    req_done;
assign pfs_ready_go = inst_sram_req & inst_sram_addr_ok || pfs_ext || req_done & ~reflush;
assign to_fs_valid  = pfs_ready_go;//~reset
assign seq_pc       = fs_pc + 3'h4;
assign nextpc       = reflush_r ? ext_pc :
                      br_taken&&(bd_done|fs_valid) ? br_target : seq_pc; 

//br_bus                    
always @(posedge clk) begin
    if(reset) 
        br_bus_r_valid <= 1'd0;
    else if(pfs_ready_go && bd_done && fs_allowin || reflush)
        br_bus_r_valid <= 1'd0;
    else if(br_bus[34] && ~(fs_valid & pfs_ready_go && fs_allowin)) begin //br_bus_valid
        br_bus_r_valid <= 1'd1;
        br_bus_r <= br_bus;
    end
end
always @(posedge clk) begin
    if(reset | reflush)
        bd_done <= 1'd0;
    else if(br_valid && ~bd_done && (fs_valid ^ fs_allowin & pfs_ready_go))
        bd_done <= 1'd1;
    else if(bd_done && pfs_ready_go && fs_allowin)
        bd_done <= 1'd0;
end

assign {
    br_valid, //34
    br_stall, //33
    br_taken, //32
    br_target //31:0
} = br_bus_r_valid ? br_bus_r : br_bus;


// IF stage
reg [31:0] inst_r;
reg        inst_r_valid;
reg [31:0] inst_r2;
reg        inst_r2_valid;
reg        abandon_one;
reg        abandon_two;
assign fs_ready_go    = (inst_sram_data_ok | inst_r_valid | fs_ext) && ~abandon_one;
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin || reflush_r;
assign fs_to_ds_valid =  fs_valid && fs_ready_go;
always @(posedge clk) begin
    if (reset) begin
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;
    end

    if (reset) begin
        fs_pc <= 32'hbfbffffc;  
    end
    else if (to_fs_valid && fs_allowin) begin
        fs_pc <= nextpc;
        fs_ext <= pfs_ext;
        fs_excode <= pfs_excode;
        fs_refill <= tlb_refill;
    end
end

always @(posedge clk) begin
    if(reset)  begin
        abandon_one <= 1'd0;
        abandon_two <= 1'd0;
    end
    else if(reflush) begin
        abandon_one <= fs_valid & ~fs_ready_go | req_done;
        abandon_two <= fs_valid & ~fs_ready_go & req_done;
    end
    else if(inst_sram_data_ok) begin
        abandon_one <= abandon_two;
        abandon_two <= 1'd0;
    end
end 

always @(posedge clk) begin
    if(reset | reflush)
        inst_r_valid <= 1'd0;
    else if(~inst_r_valid && inst_sram_data_ok && ~ds_allowin && ~abandon_one) begin
        inst_r_valid <= 1'd1;
        inst_r <= inst_sram_rdata;
    end
    else if(inst_r_valid && inst_sram_data_ok && ds_allowin) 
        inst_r <= inst_sram_rdata;
    else if(fs_ready_go && ds_allowin) begin
        inst_r_valid <= inst_r2_valid;
        inst_r <= inst_r2;
    end
end

always @(posedge clk) begin
    if(reset | reflush)
        inst_r2_valid <= 1'd0; 
    else if(inst_sram_data_ok && inst_r_valid && ~ds_allowin) begin
        inst_r2_valid <= 1'd1;
        inst_r2 <= inst_sram_rdata;
    end
    else if(fs_ready_go && ds_allowin)
        inst_r2_valid <= 1'd0;
end

// pfs_exception
wire   pfs_adel;
wire   tlb_invalid;
assign tlb_refill = ~unmap & ~s0_found & ~pfs_adel;
assign tlb_invalid = ~unmap & s0_found & ~s0_v & ~pfs_adel;
assign pfs_adel = nextpc[1:0]!=2'd0;
assign pfs_ext = pfs_adel | tlb_refill | tlb_invalid;
assign pfs_excode = pfs_adel ? 5'h04 : 5'h02;

assign fs_bd = br_valid;

//assign inst_sram_wdata = 32'd0;
//assign inst_sram_wr = 1'd0;
//assign inst_sram_size = 2'd2;
//assign inst_sram_wstrb = 4'd0;


always @(posedge clk) begin 
    if(reset) 
        req_done <= 1'd0;
    else if(pfs_ready_go && fs_allowin || reflush_r)
        req_done <= 1'd0;
    else if(inst_sram_req && inst_sram_addr_ok)
        req_done <= 1'd1;
end
assign inst_sram_req = (~req_done && ~(bd_done|fs_valid && br_stall && br_valid)||reflush_r) && ~pfs_ext && ~reset;
assign inst_sram_addr  = next_ppc;

assign fs_inst         = inst_r_valid ? inst_r : inst_sram_rdata;

endmodule
