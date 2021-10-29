`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    input       [5:0]              int_in        ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    // tlbp_search
    output [              7:0] s0_asid,
    output [              7:0] s1_asid,
    input [               3:0] s1_index, 
    input                      s1_found,
    // tlb_read
    output[               3:0] r_index,     
    input [              18:0] r_vpn2,     
    input [               7:0] r_asid,     
    input                      r_g,     
    input [              19:0] r_pfn0,     
    input [               2:0] r_c0,     
    input                      r_d0,     
    input                      r_v0,     
    input [              19:0] r_pfn1,     
    input [               2:0] r_c1,     
    input                      r_d1,     
    input                      r_v1 ,
    // tlb_write
    output                       tlb_we,     
    output  [               3:0] w_index,     
    output  [              18:0] w_vpn2,     
    output  [               7:0] w_asid,     
    output                       w_g,     
    output  [              19:0] w_pfn0,     
    output  [               2:0] w_c0,     
    output                       w_d0, 
    output                       w_v0,     
    output  [              19:0] w_pfn1,     
    output  [               2:0] w_c1,     
    output                       w_d1,     
    output                       w_v1, 
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    // to ds
    output [`MS_FORWARD_BUS_WD -1:0] ms_forward_bus,
    // exception
    output [`MS_TO_FS_BUS_WD -1:0] ms_to_fs_bus,
    output [`MS_TO_ES_BUS_WD -1:0]  ms_to_es_bus,
    //from mul
    input  [63:0]                  mul_product,
    //from data-sram
    input data_sram_data_ok,
    input  [31:0] data_sram_rdata 
);

reg         ms_valid;
wire        ms_ready_go;
reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire        ms_res_from_mem;
wire [3:0]  ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_final_result;
wire [31:0] ms_result;
wire [31:0] ms_pc;
wire        ms_is_mul;
wire        ms_is_div;
wire        ms_is_mt;
wire        ms_is_mf;
wire        ms_is_hi;
wire [31:0] mem_result;
wire [63:0] ms_div_result;
wire        ms_is_byte;
wire        ms_is_hw;
wire        ms_is_word;
wire        ms_is_wl;
wire        ms_is_wr;
wire        ms_is_load_u;
wire        ms_mem_we;

wire    ms_ext;
wire    ms_bd;
wire [4:0] ms_excode;
wire   ms_mfc0;
wire   ms_mtc0;
wire   ms_eret;
wire [7:0]  c0_addr;
wire reflush;

wire ms_refill;
wire inst_tlbp;    
wire inst_tlbwi;   
wire inst_tlbr;  
wire [31:0] ms_badvaddr;
assign ms_badvaddr = ms_result;

assign {ms_refill      ,  //171
        inst_tlbp      ,  //170
        inst_tlbwi     ,  //169
        inst_tlbr      ,  //168
        ms_mem_we      ,  //167
        ms_ext         ,  //166
        ms_bd          ,  //165
        ms_excode      ,  //160:164
        ms_mfc0        ,  //159
        ms_mtc0        ,  //158
        ms_eret        ,  //157
        c0_addr        ,  //149:156
        ms_is_byte     ,  //148
        ms_is_hw       ,  //147
        ms_is_word     ,  //146
        ms_is_wl       ,  //145
        ms_is_wr       ,  //144
        ms_is_load_u   ,  //143
        ms_div_result  ,  //142:79
        ms_is_mul      ,  //78
        ms_is_div      ,  //77
        ms_is_mt       ,  //76
        ms_is_mf       ,  //75
        ms_is_hi       ,  //74
        ms_res_from_mem,  //73
        ms_gr_we       ,  //72:69
        ms_dest        ,  //68:64
        ms_result      ,  //63:32
        ms_pc             //31:0
       } = es_to_ms_bus_r;

assign ms_to_ws_bus = {ms_gr_we       ,  //72:69
                       ms_dest        ,  //68:64
                       ms_final_result,  //63:32
                       ms_pc             //31:0
                      };

reg refetch;
wire ms_need_refetch;
// Notice that MEM stage will never block by WB stage.
assign ms_need_refetch = ms_valid && (inst_tlbr|inst_tlbwi);
always @(posedge clk) begin
    if(reset | reflush) 
        refetch <= 1'd0;
    else if(ms_need_refetch) 
        refetch <= 1'd1;
end

reg [31:0] hi;
reg [31:0] lo;
always @(posedge clk) begin
    if(ms_is_div && ms_valid && ~reflush && ~ms_ext) begin 
        hi <= ms_div_result[31:0];
        lo <= ms_div_result[63:32];
    end 
    else if(ms_is_mul && ms_valid && ~reflush && ~ms_ext) begin 
        hi <= mul_product[63:32];
        lo <= mul_product[31:0];
    end 
    else if(ms_is_mt & ms_is_hi && ms_valid && ~reflush && ~ms_ext)
         hi <= ms_result[31:0];
    else if(ms_is_mt & ~ms_is_hi && ms_valid && ~reflush && ~ms_ext)
         lo <= ms_result[31:0];
end
wire [31:0] mf_result;
assign mf_result = ms_is_hi ? hi : lo;
wire ext_int;

wire [3:0] ms_forward_valid;
wire       ms_data_not_gen;
assign     ms_data_not_gen = ~ms_ready_go;
assign ms_forward_valid = {4{ms_valid}} & ms_gr_we;
assign ms_forward_bus = {ext_int         ,  //43
                         reflush         ,  //42
                         ms_data_not_gen ,  //41
                         ms_forward_valid,  //37:40
                         ms_dest,           //36:32
                         ms_final_result    //31:0
                        };

assign ms_ready_go    = ~(ms_res_from_mem&~data_sram_data_ok);
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go && ~reflush;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if(reflush)
        ms_valid <= 1'd0;
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  = es_to_ms_bus;
    end
end

// load data decoder
wire [3:0] vaddr;
wire [7:0] byte_0;
wire [7:0] byte_1;
wire [7:0] byte_2;
wire [7:0] byte_3;
wire [31:0] lwl_data;
wire [31:0] lwr_data;
assign vaddr[0] = ms_result[1:0] == 2'b00;
assign vaddr[1] = ms_result[1:0] == 2'b01;
assign vaddr[2] = ms_result[1:0] == 2'b10;
assign vaddr[3] = ms_result[1:0] == 2'b11;
assign byte_0 =   ({8{vaddr[0]}} & data_sram_rdata[7:0])
                | ({8{vaddr[1]}} & data_sram_rdata[15:8])
                | ({8{vaddr[2]}} & data_sram_rdata[23:16])
                | ({8{vaddr[3]}} & data_sram_rdata[31:24]);
assign byte_1 =   ({8{vaddr[0]}} & data_sram_rdata[15:8])
                | ({8{vaddr[1]}} & data_sram_rdata[23:16])
                | ({8{vaddr[2]}} & data_sram_rdata[31:24]);
assign byte_2 =   ({8{vaddr[0]}} & data_sram_rdata[23:16])
                | ({8{vaddr[1]}} & data_sram_rdata[31:24]);
assign byte_3 =   ({8{vaddr[0]}} & data_sram_rdata[31:24]);
assign lwl_data = ({32{vaddr[0]}} & {data_sram_rdata[7:0], 24'd0})
                | ({32{vaddr[1]}} & {data_sram_rdata[15:0], 16'd0})
                | ({32{vaddr[2]}} & {data_sram_rdata[23:0], 8'd0})
                | ({32{vaddr[3]}} & data_sram_rdata);
assign lwr_data = ({32{vaddr[0]}} & data_sram_rdata)
                | ({32{vaddr[1]}} & {8'b0, data_sram_rdata[31:8]})
                | ({32{vaddr[2]}} & {16'b0, data_sram_rdata[31:16]})
                | ({32{vaddr[3]}} & {24'b0, data_sram_rdata[31:24]});
assign mem_result =   ({32{ms_is_byte&~ms_is_load_u}} & {{24{byte_0[7]}}, byte_0})
                    | ({32{ms_is_hw&~ms_is_load_u}} & {{16{byte_1[7]}}, byte_1, byte_0})
                    | ({32{ms_is_word}} & {byte_3, byte_2, byte_1, byte_0})
                    | ({32{ms_is_byte&ms_is_load_u}} & {24'd0, byte_0})
                    | ({32{ms_is_hw&ms_is_load_u}} & {16'd0, byte_1, byte_0})
                    | ({32{ms_is_wl}} & lwl_data)
                    | ({32{ms_is_wr}} & lwr_data);



// -----------cp0--------------
wire [5:0] ext_int_in;
wire mtc0_we;
wire [31:0] c0_wdata;
wire count_eq_compare;

assign c0_wdata = ms_result;
assign mtc0_we = ms_valid && ms_mtc0 && !ms_ext;
assign ext_int_in = int_in;

//status
wire [31:0] c0_status;

reg [7:0] c0_status_im;
always @(posedge clk) begin
    if(reset)
        c0_status_im <= 8'd0;
    else if(mtc0_we && c0_addr == `CR_STATUS)
        c0_status_im <= c0_wdata[15:8];
end

reg c0_status_exl;
always @(posedge clk) begin
    if(reset)
        c0_status_exl <= 1'd0;
    else if(ms_ext && ms_valid)
        c0_status_exl <= 1'd1;
    else if(ms_eret && ms_valid)
        c0_status_exl <= 1'd0;
    else if(mtc0_we && c0_addr == `CR_STATUS)
        c0_status_exl <= c0_wdata[1];
end

reg c0_status_ie;
always @(posedge clk) begin
    if(reset)
        c0_status_ie <= 1'd0;
    else if(mtc0_we && c0_addr == `CR_STATUS)
        c0_status_ie <= c0_wdata[0];
end
assign c0_status = {9'd0,1'd1,6'd0,c0_status_im,6'd0,c0_status_exl,c0_status_ie};

//cause
wire [31:0] c0_cause;
reg c0_cause_bd;
always @(posedge clk) begin
    if(reset) 
        c0_cause_bd <= 1'd1;
    else if(ms_ext && !c0_status_exl && ms_valid)
        c0_cause_bd <= ms_bd;
end
reg c0_cause_ti;
always @(posedge clk) begin
    if(reset)
        c0_cause_ti <= 1'd0;
    else if(mtc0_we && c0_addr == `CR_COMPARE)
        c0_cause_ti <= 1'd0;
    else if(count_eq_compare)
        c0_cause_ti <= 1'd1;
end
reg [7:0] c0_cause_ip;
always @(posedge clk) begin
    if(reset)
        c0_cause_ip[7:0] <= 8'd0;
    else begin 
        c0_cause_ip[7] <= ext_int_in[5] | c0_cause_ti;
        c0_cause_ip[6:2] <= ext_int_in[4:0];
        if(mtc0_we && c0_addr == `CR_CAUSE)
            c0_cause_ip[1:0] <= c0_wdata[9:8];
    end
end

reg [4:0] c0_cause_excode;
always @(posedge clk) begin
    if(reset)
        c0_cause_excode <= 5'd0;
    else if(ms_ext && ms_valid)
        c0_cause_excode <= ms_excode;
end
assign c0_cause = {c0_cause_bd, c0_cause_ti, 14'd0, c0_cause_ip, 1'd0, c0_cause_excode, 2'd0};

//epc
reg[31:0] c0_epc;
always @(posedge clk) begin
    if(ms_ext && !c0_status_exl && ms_valid)
        c0_epc <= ms_bd ? ms_pc - 3'd4 : ms_pc;
    else if(mtc0_we && c0_addr == `CR_EPC)
        c0_epc <= c0_wdata;
end

//badvaddr
reg [31:0] c0_badvaddr;
always @(posedge clk) begin
    if(ms_ext && ms_valid && ms_excode == 5'h04||ms_excode == 5'h05||ms_excode==5'h01||ms_excode==5'h02||ms_excode==5'h03)
        c0_badvaddr <= ms_badvaddr;
end

//count 
reg tick;
reg [31:0] c0_count;
always @(posedge clk) begin
    if(reset) 
        tick <= 1'd0;
    else if(mtc0_we && c0_addr == `CR_COUNT)
        tick <= 1'd0;
    else 
        tick <= ~tick;
    if(mtc0_we && c0_addr == `CR_COUNT)
        c0_count <= c0_wdata;
    else if(tick)
        c0_count <= c0_count + 1'd1;
end

//compare
reg [31:0] c0_compare;
always @(posedge clk) begin
    if(reset)
        c0_compare <= 32'd0;
    else if(mtc0_we && c0_addr == `CR_COMPARE)
        c0_compare <= c0_wdata;
end

//entryhi
wire [31:0] c0_entryhi;
reg [18:0] c0_entryhi_vpn2;
reg  [7:0] c0_entryhi_asid;
assign c0_entryhi = {c0_entryhi_vpn2,5'd0,c0_entryhi_asid};
always @(posedge clk) begin
    if(mtc0_we && c0_addr == `CR_ENTRYHI) begin
        c0_entryhi_vpn2 <= c0_wdata[31:13];
        c0_entryhi_asid <= c0_wdata[7:0];
    end
    else if(inst_tlbr && ~ms_ext && ms_valid) begin
        c0_entryhi_vpn2 <= r_vpn2;
        c0_entryhi_asid <= r_asid;
    end
    else if((ms_excode==5'h01||ms_excode==5'h02||ms_excode==5'h03)&&ms_ext && ms_valid)
        c0_entryhi_vpn2<= ms_badvaddr[31:13];
end

//entrylo0
wire [31:0] c0_entrylo0;
reg  [19:0] c0_entrylo0_pfn;
reg  [5:0] c0_entrylo0_C_D_V_G;
assign c0_entrylo0 = {6'd0,c0_entrylo0_pfn,c0_entrylo0_C_D_V_G};
always @(posedge clk) begin
    if(mtc0_we && c0_addr == `CR_ENTRYLO0) begin
        c0_entrylo0_pfn <= c0_wdata[25:6];
        c0_entrylo0_C_D_V_G <= c0_wdata[5:0];
    end
    else if(inst_tlbr && ~ms_ext && ms_valid) begin
        c0_entrylo0_pfn <= r_pfn0;
        c0_entrylo0_C_D_V_G <= {r_c0,r_d0,r_v0,r_g};
    end
end 

//entrylo1
wire [31:0] c0_entrylo1;
reg  [19:0] c0_entrylo1_pfn;
reg  [5:0] c0_entrylo1_C_D_V_G;
assign c0_entrylo1 = {6'd0,c0_entrylo1_pfn,c0_entrylo1_C_D_V_G};
always @(posedge clk) begin
    if(mtc0_we && c0_addr == `CR_ENTRYLO1) begin
        c0_entrylo1_pfn <= c0_wdata[25:6];
        c0_entrylo1_C_D_V_G <= c0_wdata[5:0];
    end
    else if(inst_tlbr && ~ms_ext && ms_valid) begin
        c0_entrylo1_pfn <= r_pfn1;
        c0_entrylo1_C_D_V_G <= {r_c1,r_d1,r_v1,r_g};
    end
end 

//index
wire [31:0]c0_index;
reg        c0_index_p;
reg  [3:0] c0_index_index;

assign c0_index = {c0_index_p,27'd0,c0_index_index};
always@(posedge clk) begin
    if(reset) 
        c0_index_p <= 1'b0;
    else if(mtc0_we && c0_addr == `CR_INDEX) 
        c0_index_index <= c0_wdata[3:0];
    else if(inst_tlbp && ~s1_found && ~ms_ext && ms_valid) 
        c0_index_p <= 1'd1;
    else if(inst_tlbp && s1_found && ~ms_ext && ms_valid) begin
        c0_index_p <= 1'd0;
        c0_index_index <= s1_index;
    end
end

// tlb search
assign s0_asid = c0_entryhi_asid;
assign s1_asid = c0_entryhi_asid;
// tlb read
assign r_index = c0_index_index;
// tlb_write
assign tlb_we = inst_tlbwi && ms_valid && ~ms_ext;
assign w_index = c0_index_index;
assign w_vpn2 = c0_entryhi_vpn2;
assign w_asid = c0_entryhi_asid;
assign w_g = c0_entrylo0_C_D_V_G[0] & c0_entrylo1_C_D_V_G[0];
assign w_pfn0 = c0_entrylo0_pfn;
assign w_c0 = c0_entrylo0_C_D_V_G[5:3];
assign w_d0 = c0_entrylo0_C_D_V_G[2];
assign w_v0 = c0_entrylo0_C_D_V_G[1];
assign w_pfn1 = c0_entrylo1_pfn;
assign w_c1 = c0_entrylo1_C_D_V_G[5:3];
assign w_d1 = c0_entrylo1_C_D_V_G[2];
assign w_v1 = c0_entrylo1_C_D_V_G[1];

//read
wire [31:0] c0_rdata;
assign c0_rdata = {32{c0_addr == `CR_STATUS}} & c0_status
                | {32{c0_addr == `CR_CAUSE}} & c0_cause
                | {32{c0_addr == `CR_EPC}} & c0_epc
                | {32{c0_addr == `CR_BADVADDR}} & c0_badvaddr
                | {32{c0_addr == `CR_COMPARE}} & c0_compare
                | {32{c0_addr == `CR_ENTRYHI}} & c0_entryhi
                | {32{c0_addr == `CR_ENTRYLO0}} & c0_entrylo0
                | {32{c0_addr == `CR_ENTRYLO1}} & c0_entrylo1
                | {32{c0_addr == `CR_INDEX}} & c0_index
                | {32{c0_addr == `CR_COUNT}} & c0_count;

assign ms_final_result = ~(ms_res_from_mem | ms_is_mf | ms_mfc0) ? ms_result:
                          {32{ms_res_from_mem}} & mem_result
                        | {32{ms_is_mf}}        & mf_result 
                        | {32{ms_mfc0}}         & c0_rdata;

//int
assign count_eq_compare = c0_compare == c0_count;
assign ext_int = ~c0_status_exl && c0_status_ie &&
                 c0_status_im[0] & c0_cause_ip[0]
               | c0_status_im[1] & c0_cause_ip[1]
               | c0_status_im[2] & c0_cause_ip[2]
               | c0_status_im[3] & c0_cause_ip[3]
               | c0_status_im[4] & c0_cause_ip[4]
               | c0_status_im[5] & c0_cause_ip[5]
               | c0_status_im[6] & c0_cause_ip[6]
               | c0_status_im[7] & c0_cause_ip[7];

// cancel
wire [31:0] ext_pc;
assign reflush = ms_valid & (ms_ext | ms_eret | refetch);

//Note: Remains to eliminate bits of wires between 2 stages, to improve WNS slack.
assign ms_to_es_bus = {
    ms_need_refetch ,  //54
    c0_entryhi_vpn2, // 53:35
    inst_tlbp & ms_valid, //34
    reflush,         //33
    ms_res_from_mem & ms_valid, //32
    ms_result        //31:0
};
assign ms_to_fs_bus = {
    reflush ,   //32       
    ext_pc      //31:0
};
assign ext_pc = refetch ? ms_pc :
                ms_ext  ? (ms_refill ? 32'hbfc00200 : 32'hbfc00380)
                        : c0_epc    ; //eret

endmodule