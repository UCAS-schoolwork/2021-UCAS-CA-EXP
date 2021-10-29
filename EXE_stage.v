`include "mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ds
    output [`ES_FORWARD_BUS_WD -1:0] es_forward_bus,
    // from ms
    input  [`MS_TO_ES_BUS_WD -1:0]  ms_to_es_bus,
    // mul interface
    output        mul_is_signed  ,
    output [31:0] mul_A          ,
    output [31:0] mul_B          ,
    // tlb search 1
    output  [              18:0] s1_vpn2,     
    output                       s1_odd_page,         
    input                        s1_found,          
    input [              19:0]   s1_pfn,     
    input [               2:0]   s1_c,     
    input                        s1_d,     
    input                        s1_v, 
    // data sram interface
    output data_sram_req    ,
    output data_sram_wr     ,
    output  [1:0] data_sram_size   ,
    output  [3:0] data_sram_wstrb ,
    output  [31:0] data_sram_addr   ,
    input   data_sram_addr_ok,
    output  [31:0] data_sram_wdata 
);

reg         es_valid      ;
wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [11:0] es_alu_op     ;
wire        es_load_op    ;
wire        es_src1_is_sa ;  
wire        es_src1_is_pc ;
wire        es_src2_is_imm; 
wire        es_src2_is_8  ;
wire [3:0]  es_gr_we      ;
wire        es_mem_we     ;
wire [ 4:0] es_dest       ;
wire [15:0] es_imm        ;
wire [31:0] es_rs_value   ;
wire [31:0] es_rt_value   ;
wire [31:0] es_pc         ;
wire        es_is_unsigned;
wire        es_is_mul     ;
wire        es_is_div     ;
wire        es_is_mt      ;
wire        es_is_mf      ;
wire        es_is_hi      ;
wire [63:0] es_div_result ;
wire [31:0] es_final_result;
wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_result ;
wire        es_is_byte;
wire        es_is_hw;
wire        es_is_word;
wire        es_is_wl;
wire        es_is_wr;
wire        es_is_load_u;
wire  [3:0] new_gr_we;

wire    div;
wire    ds_ext;
wire    es_ext;
wire    es_ext_n;
wire    es_bd;
wire   [4:0] es_excode;
wire   [4:0] ds_excode;
wire    es_mfc0;
wire    es_mtc0;
wire    es_eret;
wire [7:0] es_cp0_addr;
wire    exam_overflow;
wire    alu_overflow;
wire    ext_adel;
wire    ext_ades;
wire    ext_overflow;

wire    ext_tlb;
wire    tlb_refill_s;
wire    tlb_refill_l;
wire    tlb_invalid_s;
wire    tlb_invalid_l;
wire    tlb_modified;

wire    reflush;
wire    ms_is_load;
wire [31:0] ms_addr;
wire [31:0] es_badvaddr;

wire ds_refill;
wire es_refill;
wire inst_tlbp;    
wire inst_tlbwi;   
wire inst_tlbr;   
wire ms_tlbp;
wire [18:0] ms_vpn2;
wire ms_need_refetch;

assign {
    ms_need_refetch,
    ms_vpn2,
    ms_tlbp,
    reflush,
    ms_is_load,
    ms_addr
} = ms_to_es_bus;

reg     req_done;
assign  es_ext_n = ext_adel | ext_ades | ext_overflow;
assign  es_ext = es_ext_n | ds_ext | ext_tlb;
assign  es_refill = ds_refill | tlb_refill_l | tlb_refill_s;

// These new exts should be exclusive
assign  es_excode = ds_ext ? ds_excode :
                    {5{ext_adel}} & 5'h04
                |   {5{ext_ades}} & 5'h05
                |   {5{ext_overflow}} & 5'h0c
                |   {5{tlb_refill_l|tlb_invalid_l}} & 5'h02
                |   {5{tlb_refill_s|tlb_invalid_s}} & 5'h03
                |   {5{tlb_modified}} & 5'h01;

assign {ds_refill      ,  //173
        inst_tlbp      ,  //172
        inst_tlbwi     ,  //171
        inst_tlbr      ,  //170
        exam_overflow  ,  //169
        ds_ext         ,  //168
        es_bd          ,  //167
        ds_excode      ,  //162:166
        es_mfc0        ,  //161
        es_mtc0        ,  //160
        es_eret        ,  //159
        es_cp0_addr    ,  //151:158
        es_is_byte     ,  //150
        es_is_hw       ,  //149
        es_is_word     ,  //148
        es_is_wl       ,  //147
        es_is_wr       ,  //146
        es_is_load_u   ,  //145
        es_is_mul      ,  //144
        es_is_div      ,  //143
        es_is_mt       ,  //142
        es_is_mf       ,  //141
        es_is_hi       ,  //140
        es_alu_op      ,  //139:128
        es_load_op     ,  //127
        es_is_unsigned ,  //126
        es_src1_is_sa  ,  //125
        es_src1_is_pc  ,  //124
        es_src2_is_imm ,  //123
        es_src2_is_8   ,  //122
        es_gr_we       ,  //121:118
        es_mem_we      ,  //117:117
        es_dest        ,  //116:112
        es_imm         ,  //111:96
        es_rs_value    ,  //95 :64
        es_rt_value    ,  //63 :32
        es_pc             //31 :0
       } = ds_to_es_bus_r;

assign mul_A = es_rs_value;
assign mul_B = es_rt_value;
assign mul_is_signed = ~es_is_unsigned;

assign es_to_ms_bus = {es_refill      ,  //171
                       inst_tlbp      ,  //170
                       inst_tlbwi     ,  //169
                       inst_tlbr      ,  //168
                       es_mem_we      ,  //167
                       es_ext         ,  //166
                       es_bd          ,  //165
                       es_excode      ,  //160:164
                       es_mfc0        ,  //159
                       es_mtc0        ,  //158
                       es_eret        ,  //157
                       es_cp0_addr    ,  //149:156
                       es_is_byte     ,  //148
                       es_is_hw       ,  //147
                       es_is_word     ,  //146
                       es_is_wl       ,  //145
                       es_is_wr       ,  //144
                       es_is_load_u   ,  //143
                       es_div_result  ,  //142:79
                       es_is_mul      ,  //78
                       div            ,  //77
                       es_is_mt       ,  //76
                       es_is_mf       ,  //75
                       es_is_hi       ,  //74
                       es_load_op     ,  //73
                       new_gr_we      ,  //72:69
                       es_dest        ,  //68:64
                       es_final_result,  //63:32
                       es_pc             //31:0
                      };

wire [3:0] es_forward_valid;
//assign es_forward_valid = {4{es_valid}} & new_gr_we & {4{~ds_ext}}; //unnecessary to forward new_gr_we for lwl/lwr
assign es_forward_valid = {4{es_valid}} & es_gr_we;
wire ds_may_block;
assign ds_may_block = (es_load_op | es_is_mf | es_mfc0) & es_valid;
// should not forward es_final_result!!
assign es_forward_bus = {ds_may_block,      //41
                         es_forward_valid,  //40:37
                         es_dest,           //36:32
                         es_alu_result     //31:0
                        };

reg refetch;
wire es_need_refetch;
assign es_need_refetch = es_valid && (inst_tlbr|inst_tlbwi);
always @(posedge clk) begin
    if(reset | reflush)
         refetch <= 1'd0;
    else if(es_need_refetch || ms_need_refetch)
        refetch <= 1'd1;
end


wire complete;
assign es_ready_go    = ~(div&~complete) && ~((es_load_op|es_mem_we) & ~(data_sram_addr_ok&data_sram_req | req_done)) 
                         || es_ext || refetch;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset) begin
        es_valid <= 1'b0;
    end
    else if(reflush)
        es_valid <= 1'd0;
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

wire [31:0] alu_imm;
assign alu_imm = es_is_unsigned ? {16'd0, es_imm[15:0]} : {{16{es_imm[15]}}, es_imm[15:0]};
assign es_alu_src1 = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                     es_src1_is_pc  ? es_pc[31:0] :
                                      es_rs_value;
assign es_alu_src2 = es_src2_is_imm ? alu_imm : 
                     es_src2_is_8   ? 32'd8 :
                                      es_rt_value;

alu u_alu(
    .alu_op     (es_alu_op    ),
    .alu_src1   (es_alu_src1  ),
    .alu_src2   (es_alu_src2  ),
    .alu_result (es_alu_result),
    .alu_overflow (alu_overflow)
    );
assign ext_overflow = exam_overflow & alu_overflow;
//data_ram input
wire  [3:0] vaddr;
wire  [31:0] swr_data;
wire  [31:0] swl_data;
wire  mem_we;
wire  [31:0] paddr;
wire  unmap;
wire  [31:0] ms_vaddr;
assign ms_vaddr = {es_alu_result[31:2], {2{~es_is_wl}}&es_alu_result[1:0]};
assign unmap = es_alu_result[31:30]==2'b10;
assign s1_vpn2 = ms_tlbp ? ms_vpn2 : es_alu_result[31:13];
assign s1_odd_page = es_alu_result[12];
assign paddr = {unmap ? es_alu_result[31:12] : s1_pfn, es_alu_result[11:2], {2{~es_is_wl}}&es_alu_result[1:0]};

assign mem_we = es_mem_we && es_valid & ~es_ext & ~reflush;

assign new_gr_we = ~(es_load_op & (es_is_wl | es_is_wr)) ? es_gr_we :
                   {4{es_is_wl}} & {1'd1,vaddr[1]|vaddr[2]|vaddr[3],vaddr[2]|vaddr[3],vaddr[3]}
                 | {4{es_is_wr}} & {vaddr[0],vaddr[0]|vaddr[1],vaddr[0]|vaddr[1]|vaddr[2],1'd1};
assign vaddr[0] = es_alu_result[1:0] == 2'b00;
assign vaddr[1] = es_alu_result[1:0] == 2'b01;
assign vaddr[2] = es_alu_result[1:0] == 2'b10;
assign vaddr[3] = es_alu_result[1:0] == 2'b11;
assign data_sram_wstrb[0] = mem_we & es_valid && (vaddr[0] || es_is_wl);
assign data_sram_wstrb[1] = mem_we & es_valid && (es_is_byte && vaddr[1] || es_is_hw && vaddr[0] || es_is_word || es_is_wl && ~vaddr[0] || es_is_wr && (vaddr[0] | vaddr[1]));
assign data_sram_wstrb[2] = mem_we & es_valid && (es_is_byte && vaddr[2] || es_is_hw && vaddr[2] || es_is_word || (vaddr[2] | vaddr[3]) && es_is_wl || es_is_wr && ~vaddr[3]);
assign data_sram_wstrb[3] = mem_we & es_valid && (es_is_byte && vaddr[3] || es_is_hw && vaddr[2] || es_is_word || es_is_wl && vaddr[3] || es_is_wr);
assign swr_data = ({32{vaddr[0]}} & es_rt_value)
                | ({32{vaddr[1]}} & {es_rt_value[23:0], 8'd0})
                | ({32{vaddr[2]}} & {es_rt_value[15:0], 16'd0})
                | ({32{vaddr[3]}} & {es_rt_value[7:0], 24'd0});
assign swl_data = ({32{vaddr[0]}} & {24'd0, es_rt_value[31:24]})
                | ({32{vaddr[1]}} & {16'd0, es_rt_value[31:16]})
                | ({32{vaddr[2]}} & {8'd0, es_rt_value[31:8]})
                | ({32{vaddr[3]}} & es_rt_value);

// WARNING: Work only when ext does not occur at MEM stage, 
// or should consider unfinished request when reflushing.
always @(posedge clk) begin 
    if(reset) 
        req_done <= 1'd0;
    else if(es_ready_go && ms_allowin)
        req_done <= 1'd0;
    else if(data_sram_req && data_sram_addr_ok)
        req_done <= 1'd1;
end
assign data_sram_req = (es_load_op | (es_mem_we & ~(ms_is_load && ~ms_allowin && ms_addr[31:2] == es_alu_result[31:2])))
                       && ~req_done &&es_valid&&~es_ext&&~reflush&&~reset&&~(~unmap&ms_tlbp)&&~refetch;
assign data_sram_wr = es_mem_we;
assign data_sram_size = {2{es_is_word | es_is_wl & (vaddr[2]|vaddr[3])|es_is_wr &(vaddr[0]|vaddr[1])}} & 2'd2
                      | {2{es_is_hw | es_is_wl & vaddr[1] | es_is_wr & vaddr[2]}} & 2'd1 
                      | {2{es_is_byte | es_is_wl & vaddr[0] | es_is_wr & vaddr[3]}} & 2'd0;
    
assign data_sram_addr  = paddr;
assign data_sram_wdata = ({32{es_is_byte}} & {4{es_rt_value[7:0]}})
					   | ({32{es_is_hw}} & {2{es_rt_value[15:0]}})
					   | ({32{es_is_word}} & es_rt_value)
					   | ({32{es_is_wl}} & swl_data)
					   | ({32{es_is_wr}} & swr_data);


wire addr_err;
assign addr_err = es_is_word & ~vaddr[0] 
                ||es_is_hw   & (vaddr[1] | vaddr[3]);
assign ext_adel = es_load_op & addr_err;
assign ext_ades = es_mem_we  & addr_err;
assign tlb_refill_s = ~unmap & ~s1_found & es_mem_we & ~ds_ext & ~es_ext_n;
assign tlb_refill_l = ~unmap & ~s1_found & es_load_op & ~ds_ext & ~es_ext_n;
assign tlb_invalid_s = ~unmap & s1_found & ~s1_v & es_mem_we & ~ds_ext & ~es_ext_n;
assign tlb_invalid_l = ~unmap & s1_found & ~s1_v & es_load_op & ~ds_ext & ~es_ext_n;
assign tlb_modified = ~unmap & s1_found & s1_v & ~s1_d & es_mem_we & ~ds_ext & ~es_ext_n;
assign ext_tlb = (tlb_refill_s | tlb_refill_l | tlb_invalid_s | tlb_invalid_l | tlb_modified) & ~ms_tlbp;

// div interface
wire [31:0] rem;
wire [31:0] S_out;
wire resetn;
wire div_is_signed;
assign div = es_is_div & es_valid;
assign resetn = ~reset;
assign div_is_signed = ~es_is_unsigned;
assign es_div_result = {S_out,rem};
div32 u_div(
    .clk(clk),
    .resetn(resetn),
    .div(div),
    .is_signed(div_is_signed),
    .Ain(es_rs_value),
    .Bin(es_rt_value),
    .complete(complete),
    .rem(rem),
    .S_out(S_out)
);

assign es_badvaddr = ds_ext ? es_pc : ms_vaddr;
assign      es_final_result = es_ext ? es_badvaddr : 
                              es_is_mt ? es_rs_value : 
                              es_mtc0 ? es_rt_value :
                              es_alu_result;
                              
endmodule
