`include "mycpu.h"

module id_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          es_allowin    ,
    output                         ds_allowin    ,
    //from fs
    input                          fs_to_ds_valid,
    input  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus  ,
    //to es
    output                         ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to fs
    output [`BR_BUS_WD       -1:0] br_bus        ,
    //forward bus
    input [`ES_FORWARD_BUS_WD -1:0] es_forward_bus,
    input [`MS_FORWARD_BUS_WD -1:0] ms_forward_bus,
    input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus
);

reg     ds_valid;
wire    reflush ;
wire    ds_ext;
wire    ds_bd;

always @(posedge clk) begin
    if (reset) begin
        ds_valid <= 1'b0;
    end
    else if(reflush)
        ds_valid <= 1'd0;
    else if (ds_allowin) begin
        ds_valid <= fs_to_ds_valid;
    end
end


wire        ds_ready_go;

wire [31                 :0] fs_pc;
reg  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;
assign fs_pc = fs_to_ds_bus[31:0];

wire        br_taken;
wire [31:0] br_target;

wire [11:0] alu_op;
wire        load_op;
wire        is_unsigned;
wire        src1_is_sa;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_8;
wire [3:0]  gr_we;
wire        mem_we;
wire [ 4:0] dest;
wire [15:0] imm;
wire [31:0] rs_value;
wire [31:0] rt_value;

wire [ 5:0] op;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [25:0] jidx;
wire [63:0] op_d;
wire [31:0] rs_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [63:0] func_d;

wire        inst_addu;
wire        inst_subu;
wire        inst_slt;
wire        inst_sltu;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_nor;
wire        inst_sll;
wire        inst_srl;
wire        inst_sra;
wire        inst_addiu;
wire        inst_lui;
wire        inst_lw;
wire        inst_sw;
wire        inst_beq;
wire        inst_bne;
wire        inst_jal;
wire        inst_jr;

wire        inst_add;
wire        inst_addi;
wire        inst_sub;
wire        inst_slti;
wire        inst_sltiu;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sllv;
wire        inst_srlv;
wire        inst_srav;
wire        inst_mult;
wire        inst_multu;
wire        inst_div;
wire        inst_divu;
wire        inst_mfhi;
wire        inst_mflo;
wire        inst_mthi;
wire        inst_mtlo;

wire        inst_bgez;
wire        inst_bgtz;
wire        inst_blez;
wire        inst_bltz;
wire        inst_j;
wire        inst_bltzal;
wire        inst_bgezal;
wire        inst_jalr;
wire        inst_lb;
wire        inst_lbu;
wire        inst_lh;
wire        inst_lhu;
wire        inst_lwl;
wire        inst_lwr;
wire        inst_sb;
wire        inst_sh;
wire        inst_swl;
wire        inst_swr;

wire        inst_mfc0;  
wire        inst_mtc0;  
wire        inst_syscall;
wire        inst_eret;
wire        inst_break;
wire        reserve_inst;

wire        inst_tlbp;
wire        inst_tlbr;
wire        inst_tlbwi;

wire        dst_is_r31;  
wire        dst_is_rt;   
wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

wire        rs_eq_rt;
wire        br_valid;
wire        br_stall;
assign br_bus  = {
    br_valid, //34
    br_stall, //33
    br_taken, //32
    br_target //31:0
};

wire    is_mul;
wire    is_div;
wire    is_mt;
wire    is_mf;
wire    is_hi;
wire    is_byte;
wire    is_hw;
wire    is_word;
wire    is_wl;
wire    is_wr;
wire    is_load_u;

wire [31:0] ds_inst;
 wire [31:0] ds_pc  ;

wire       fs_ext;
wire       ds_ext_n;
wire [4:0] fs_excode;
wire [4:0] ds_excode;
wire [7:0] cp0_addr;
wire       ext_int;
wire       fs_refill;
wire       ds_refill;

assign ds_ext_n = inst_syscall || inst_break || reserve_inst || ext_int;
assign ds_ext   = ds_ext_n | fs_ext;
assign ds_refill = fs_refill & ~ext_int;
assign ds_excode = ext_int ? 5'h00 : 
                    fs_ext ? fs_excode :
                   {5{inst_syscall}} & 5'h08 
                  |{5{inst_break}}   & 5'h09
                  |{5{reserve_inst}} & 5'h0a;

assign cp0_addr = {rd, ds_inst[2:0]};


assign {fs_refill,//71
        fs_ext,   //70
        fs_excode,//69:65
        ds_bd  ,  //64
        ds_inst,  //63:32
        ds_pc     //31:0
       } = fs_to_ds_bus_r;

wire [3:0]  ws_fvalid ;
wire [ 4:0] ws_faddr  ;
wire [31:0] ws_fdata  ;
assign {ws_fvalid   ,   //40:37
        ws_faddr,       //36:32
        ws_fdata        //31:0
       } = ws_to_rf_bus;
wire        data_in_ms;
wire [3:0]  es_fvalid    ;
wire [ 4:0] es_faddr     ;
wire [31:0] es_fdata     ;
assign {data_in_ms,     //41
        es_fvalid,      //40:37
        es_faddr,       //36:32
        es_fdata        //31:0
       } = es_forward_bus;
wire [3:0]  ms_fvalid    ;
wire [ 4:0] ms_faddr     ;
wire [31:0] ms_fdata     ;
wire        ms_data_not_gen;
assign {ext_int,       //43
        reflush  ,     //42
        ms_data_not_gen,  //41
        ms_fvalid,     //40:37
        ms_faddr,      //36:32
        ms_fdata       //31:0
       } = ms_forward_bus;

assign ds_to_es_bus = {ds_refill    ,  //173
                       inst_tlbp    ,  //172
                       inst_tlbwi   ,  //171
                       inst_tlbr    ,  //170
                       exam_overflow,  //169
                       ds_ext       ,  //168
                       ds_bd        ,  //167
                       ds_excode    ,  //162:166
                       inst_mfc0    ,  //161
                       inst_mtc0    ,  //160
                       inst_eret    ,  //159
                       cp0_addr     ,  //151:158
                       is_byte      ,  //150
                       is_hw        ,  //149
                       is_word      ,  //148
                       is_wl        ,  //147
                       is_wr        ,  //146
                       is_load_u    ,  //145
                       is_mul       ,  //144
                       is_div       ,  //143
                       is_mt        ,  //142
                       is_mf        ,  //141
                       is_hi        ,  //140
                       alu_op       ,  //139:128
                       load_op      ,  //127
                       is_unsigned  ,  //126
                       src1_is_sa   ,  //125
                       src1_is_pc   ,  //124
                       src2_is_imm  ,  //123
                       src2_is_8    ,  //122
                       gr_we        ,  //121:118 
                       mem_we       ,  //117:117
                       dest         ,  //116:112
                       imm          ,  //111:96
                       rs_value     ,  //95 :64
                       rt_value     ,  //63 :32
                       ds_pc           //31 :0
                      };

wire es_hazard1;
wire es_hazard2;
wire ms_hazard1;
wire ms_hazard2;
assign ds_ready_go    = ~(   (es_hazard1 | es_hazard2) & data_in_ms 
                          || ~es_hazard1 & ms_hazard1  & ms_data_not_gen
                          || ~es_hazard2 & ms_hazard2  & ms_data_not_gen
                         ) || ds_ext;

assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go;
always @(posedge clk) begin
    if (fs_to_ds_valid && ds_allowin) begin
        fs_to_ds_bus_r <= fs_to_ds_bus;
    end
end

assign op   = ds_inst[31:26];
assign rs   = ds_inst[25:21];
assign rt   = ds_inst[20:16];
assign rd   = ds_inst[15:11];
assign sa   = ds_inst[10: 6];
assign func = ds_inst[ 5: 0];
assign imm  = ds_inst[15: 0];
assign jidx = ds_inst[25: 0];

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));


assign inst_add    = op_d[6'h00] & func_d[6'h20] & sa_d[5'h00];
assign inst_addu   = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];
assign inst_sub    = op_d[6'h00] & func_d[6'h22] & sa_d[5'h00];
assign inst_subu   = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];
assign inst_and    = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];
assign inst_or     = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];
assign inst_xor    = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];
assign inst_nor    = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];
assign inst_slt    = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];
assign inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];
assign inst_addi   = op_d[6'h08];
assign inst_addiu  = op_d[6'h09];
assign inst_slti   = op_d[6'h0a];
assign inst_sltiu  = op_d[6'h0b];
assign inst_andi   = op_d[6'h0c];
assign inst_ori    = op_d[6'h0d];
assign inst_xori   = op_d[6'h0e];
assign inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
assign inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
assign inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
assign inst_sllv   = op_d[6'h00] & func_d[6'h04] & sa_d[5'h00];
assign inst_srlv   = op_d[6'h00] & func_d[6'h06] & sa_d[5'h00];
assign inst_srav   = op_d[6'h00] & func_d[6'h07] & sa_d[5'h00]; 

assign inst_lui    = op_d[6'h0f] & rs_d[5'h00];
assign inst_lw     = op_d[6'h23];
assign inst_sw     = op_d[6'h2b];
assign inst_beq    = op_d[6'h04];
assign inst_bne    = op_d[6'h05];
assign inst_jal    = op_d[6'h03];
assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];

assign inst_mult   = op_d[6'h00] & func_d[6'h18] & rd_d[5'h00] & sa_d[5'h00];
assign inst_multu  = op_d[6'h00] & func_d[6'h19] & rd_d[5'h00] & sa_d[5'h00];
assign inst_div    = op_d[6'h00] & func_d[6'h1a] & rd_d[5'h00] & sa_d[5'h00];
assign inst_divu   = op_d[6'h00] & func_d[6'h1b] & rd_d[5'h00] & sa_d[5'h00];
assign inst_mfhi   = op_d[6'h00] & func_d[6'h10] & rt_d[5'h00] & rs_d[5'h00] & sa_d[5'h00];
assign inst_mflo   = op_d[6'h00] & func_d[6'h12] & rt_d[5'h00] & rs_d[5'h00] & sa_d[5'h00];
assign inst_mthi   = op_d[6'h00] & func_d[6'h11] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];
assign inst_mtlo   = op_d[6'h00] & func_d[6'h13] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];

assign inst_bgez   = op_d[6'h01] & rt_d[5'h01];
assign inst_bgtz   = op_d[6'h07] & rt_d[5'h00];
assign inst_blez   = op_d[6'h06] & rt_d[5'h00];
assign inst_bltz   = op_d[6'h01] & rt_d[5'h00];
assign inst_bltzal = op_d[6'h01] & rt_d[5'h10];
assign inst_bgezal = op_d[6'h01] & rt_d[5'h11];
assign inst_j      = op_d[6'h02];
assign inst_jalr   = op_d[6'h00] & func_d[6'h09] & rt_d[5'h00] & sa_d[5'h00];
assign inst_lb     = op_d[6'h20];
assign inst_lbu    = op_d[6'h24];
assign inst_lh     = op_d[6'h21];
assign inst_lhu    = op_d[6'h25];
assign inst_lwl    = op_d[6'h22];
assign inst_lwr    = op_d[6'h26];
assign inst_sb     = op_d[6'h28];
assign inst_sh     = op_d[6'h29];
assign inst_swl    = op_d[6'h2a];
assign inst_swr    = op_d[6'h2e];
assign inst_mfc0   = op_d[6'h10] & rs_d[5'h00] & sa_d[5'h00] & ds_inst[5:3] == 3'd0;
assign inst_mtc0   = op_d[6'h10] & rs_d[5'h04] & sa_d[5'h00] & ds_inst[5:3] == 3'd0;
assign inst_tlbp   = op_d[6'h10] & ds_inst[25] & (ds_inst[24:6] == 0) & func_d[6'h08];
assign inst_tlbr   = op_d[6'h10] & ds_inst[25] & (ds_inst[24:6] == 0) & func_d[6'h01];
assign inst_tlbwi  = op_d[6'h10] & ds_inst[25] & (ds_inst[24:6] == 0) & func_d[6'h02];

assign inst_syscall= op_d[6'h00] & func_d[6'h0c];
assign inst_eret   = op_d[6'h10] & func_d[6'h18] & rs_d[5'h10] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];
assign inst_break  = op_d[6'h00] & func_d[6'h0d];
assign reserve_inst = ~(inst_addu|inst_subu|inst_slt|inst_sltu|inst_and|inst_or|
inst_xor|inst_nor|inst_sll|inst_srl|inst_sra|inst_addiu|inst_lui|inst_lw|inst_sw|
inst_beq|inst_bne|inst_jal|inst_jr|inst_add|inst_addi|inst_sub|inst_slti|inst_sltiu|
inst_andi|inst_ori|inst_xori|inst_sllv|inst_srlv|inst_srav|inst_mult|inst_multu|
inst_div|inst_divu|inst_mfhi|inst_mflo|inst_mthi|inst_mtlo|inst_bgez|inst_bgtz|
inst_blez|inst_bltz|inst_j|inst_bltzal|inst_bgezal|inst_jalr|inst_lb|inst_lbu|
inst_lh|inst_lhu|inst_lwl|inst_lwr|inst_sb|inst_sh|inst_swl|inst_swr|inst_mfc0|
inst_mtc0|inst_syscall|inst_eret|inst_break|inst_tlbp|inst_tlbr|inst_tlbwi);

assign alu_op[ 0] = inst_add | inst_addi | inst_addu | inst_addiu | inst_lw | inst_sw | inst_jal
| inst_bltzal | inst_bgezal | inst_jalr | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lwl | inst_lwr | inst_sb | inst_sh | inst_swl | inst_swr;
assign alu_op[ 1] = inst_subu | inst_sub;
assign alu_op[ 2] = inst_slt | inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltiu;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_sll | inst_sllv;
assign alu_op[ 9] = inst_srl | inst_srlv;
assign alu_op[10] = inst_sra | inst_srav;
assign alu_op[11] = inst_lui;

assign is_unsigned  = inst_andi | inst_ori | inst_xori | inst_multu | inst_divu;
assign src1_is_sa   = inst_sll   | inst_srl | inst_sra;
assign src1_is_pc   = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;
assign src2_is_imm  = inst_addiu | inst_lui | inst_lw | inst_sw | inst_andi | inst_ori | inst_xori | inst_addi | inst_slti | inst_sltiu
| inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lwl | inst_lwr | inst_sb | inst_sh | inst_swl | inst_swr;
assign src2_is_8    = src1_is_pc;
assign load_op      = inst_lw | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lwl |inst_lwr;
assign dst_is_r31   = inst_jal | inst_bltzal | inst_bgezal;
assign dst_is_rt    = inst_addiu | inst_lui | inst_lw | inst_andi | inst_ori | inst_xori | inst_addi | inst_slti | inst_sltiu
| inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lwl | inst_lwr | inst_mfc0;
assign gr_we        = {4{~inst_sw & ~inst_beq & ~inst_bne & ~inst_jr & ~is_mul & ~is_div & ~is_mt
& ~inst_bgez & ~inst_bgtz & ~inst_blez & ~inst_bltz & ~inst_j & ~inst_sb & ~inst_sh & ~inst_swl & ~inst_swr
& ~inst_mtc0 & ~inst_syscall & ~inst_eret & ~inst_break & ~inst_tlbp & ~inst_tlbr & ~inst_tlbwi}};
assign mem_we       = inst_sw | inst_sb | inst_sh | inst_swl | inst_swr;

assign is_mul       = inst_mult | inst_multu;
assign is_div       = inst_div | inst_divu;
assign is_mt        = inst_mthi | inst_mtlo;
assign is_mf        = inst_mfhi | inst_mflo;
assign is_hi        = inst_mfhi | inst_mthi;
assign exam_overflow = inst_add | inst_addi | inst_sub;

assign is_byte      = inst_lb | inst_lbu | inst_sb;
assign is_hw        = inst_lh | inst_lhu | inst_sh;
assign is_word      = inst_lw | inst_sw;
assign is_wr        = inst_lwr | inst_swr;
assign is_wl        = inst_lwl | inst_swl;
assign is_load_u    = inst_lbu | inst_lhu;

assign dest         = dst_is_r31 ? 5'd31 :
                      dst_is_rt  ? rt    : 
                                   rd;

assign rf_raddr1 = rs;
assign rf_raddr2 = rt;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (ws_fvalid),
    .waddr  (ws_faddr ),
    .wdata  (ws_fdata )
    );

wire need_read_s;
wire need_read_t;
assign need_read_s = ~inst_j & ~inst_jal & ~src1_is_sa & ~inst_eret & ~inst_mfc0 & ~inst_syscall & ~inst_break & ~inst_tlbp & ~inst_tlbr & ~inst_tlbwi;
assign need_read_t = ~src2_is_8 & ~inst_j & ~dst_is_rt & ~inst_bgez & ~inst_eret & ~inst_syscall & ~inst_break & ~inst_tlbp & ~inst_tlbr & ~inst_tlbwi;
assign es_hazard1 = es_fvalid!=4'd0 && rf_raddr1 == es_faddr && rf_raddr1 != 5'd0 && need_read_s;
assign es_hazard2 = es_fvalid!=4'd0 && rf_raddr2 == es_faddr && rf_raddr2 != 5'd0 && need_read_t;
assign ms_hazard1 = ms_fvalid!=4'd0 && rf_raddr1 == ms_faddr && rf_raddr1 != 5'd0 && need_read_s;
assign ms_hazard2 = ms_fvalid!=4'd0 && rf_raddr2 == ms_faddr && rf_raddr2 != 5'd0 && need_read_t;

genvar fi;
generate for (fi=0;fi<4;fi=fi+1) begin: f_gen
assign rs_value[fi*8+7:fi*8] = es_fvalid[fi] && rf_raddr1 == es_faddr && rf_raddr1 != 5'd0 ? es_fdata[fi*8+7:fi*8] : 
                               ms_fvalid[fi] && rf_raddr1 == ms_faddr && rf_raddr1 != 5'd0 ? ms_fdata[fi*8+7:fi*8] : 
                               ws_fvalid[fi] && rf_raddr1 == ws_faddr && rf_raddr1 != 5'd0 ? ws_fdata[fi*8+7:fi*8] : 
                                                                                                                     rf_rdata1[fi*8+7:fi*8];
assign rt_value[fi*8+7:fi*8] = es_fvalid[fi] && rf_raddr2 == es_faddr && rf_raddr2 != 5'd0 ? es_fdata[fi*8+7:fi*8] : 
                               ms_fvalid[fi] && rf_raddr2 == ms_faddr && rf_raddr2 != 5'd0 ? ms_fdata[fi*8+7:fi*8] : 
                               ws_fvalid[fi] && rf_raddr2 == ws_faddr && rf_raddr2 != 5'd0 ? ws_fdata[fi*8+7:fi*8] : 
                                                                                                                     rf_rdata2[fi*8+7:fi*8];
end endgenerate

wire rs_gtz;
wire rs_gez;
wire [31:0] ds_pc_plus;
assign ds_pc_plus = ds_pc + 3'd4;
assign rs_gez = ~rs_value[31];
assign rs_gtz = rs_gez & ~(rs_value == 32'd0);
assign rs_eq_rt = (rs_value == rt_value);
assign br_taken = (   inst_beq  &&  rs_eq_rt
                   || inst_bne  && !rs_eq_rt
                   || inst_jal
                   || inst_jr
                   || inst_bgez | inst_bgezal && rs_gez
                   || inst_bgtz && rs_gtz
                   || inst_blez && ~rs_gtz
                   || inst_bltz | inst_bltzal && ~rs_gez
                   || inst_j
                   || inst_jalr
                  ) && ds_valid;
assign br_target = (inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_bltzal | inst_bgezal) ? (ds_pc_plus + {{14{imm[15]}}, imm[15:0], 2'b0}) :
                   (inst_jr | inst_jalr)              ? rs_value :
                  /*inst_jal*/              {ds_pc_plus[31:28], jidx[25:0], 2'b0};


assign br_valid = (inst_beq | inst_bne | inst_jal | inst_jr | inst_bgez | inst_bgtz
                   | inst_blez | inst_bltz | inst_j | inst_bltzal | inst_bgezal | inst_jalr
) && ds_valid;

assign br_stall = ~ds_ready_go;

endmodule
