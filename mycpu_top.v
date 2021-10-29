module mycpu_top(
    input [5:0]   int,
    input         aclk,
    input         aresetn,
    
    output [3 :0] arid  ,
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
    
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);


wire   reset;
assign reset = ~aresetn;

wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0] br_bus;
wire [`ES_FORWARD_BUS_WD -1:0] es_forward_bus;
wire [`MS_FORWARD_BUS_WD -1:0] ms_forward_bus;
wire [`MS_TO_FS_BUS_WD -1:0]   ms_to_fs_bus;
wire [`MS_TO_ES_BUS_WD -1:0]   ms_to_es_bus;

wire mul_is_signed;
wire [31:0] mul_A;
wire [31:0] mul_B;
wire [63:0] mul_product;

// inst ram
wire inst_sram_req  ;
//wire inst_sram_wr    ;
//wire [1:0] inst_sram_size   ;
//wire [3:0] inst_sram_wstrb  ;
wire [31:0] inst_sram_addr   ;
//wire [31:0] inst_sram_wdata  ;
wire inst_sram_addr_ok;
wire inst_sram_data_ok;
wire [31:0] inst_sram_rdata  ;
// data ram
wire data_sram_req    ;
wire data_sram_wr     ;
wire  [1:0] data_sram_size   ;
wire  [3:0] data_sram_wstrb ;
wire  [31:0] data_sram_addr   ;
wire  [31:0] data_sram_wdata ;
wire data_sram_addr_ok;
wire data_sram_data_ok;
wire  [31:0] data_sram_rdata ;
//tlb
wire  [              18:0] s0_vpn2;
wire                       s0_odd_page;     
wire  [               7:0] s0_asid;     
wire                       s0_found;     
wire                 [3:0] s0_index;     
wire  [              19:0] s0_pfn;     
wire  [               2:0] s0_c;     
wire                       s0_d;     
wire                       s0_v; 
wire  [              18:0] s1_vpn2;     
wire                       s1_odd_page;     
wire  [               7:0] s1_asid;     
wire                       s1_found;     
wire  [               3:0] s1_index;     
wire  [              19:0] s1_pfn;     
wire  [               2:0] s1_c;     
wire                       s1_d;     
wire                       s1_v; 
wire                       tlb_we;     
wire  [               3:0] w_index;     
wire  [              18:0] w_vpn2;     
wire  [               7:0] w_asid;     
wire                       w_g;     
wire  [              19:0] w_pfn0;     
wire  [               2:0] w_c0;     
wire                       w_d0; 
wire                       w_v0;     
wire  [              19:0] w_pfn1;     
wire  [               2:0] w_c1;     
wire                       w_d1;     
wire                       w_v1;     
wire  [               3:0] r_index;     
wire  [              18:0] r_vpn2;     
wire  [               7:0] r_asid;     
wire                       r_g;     
wire  [              19:0] r_pfn0;     
wire  [               2:0] r_c0;     
wire                       r_d0;     
wire                       r_v0;     
wire  [              19:0] r_pfn1;     
wire  [               2:0] r_c1;     
wire                       r_d1;     
wire                       r_v1;
 
//tlb
tlb u_tlb(
    .clk            (aclk), 

    .s0_vpn2        (s0_vpn2),
    .s0_odd_page    (s0_odd_page),
    .s0_asid        (s0_asid),     
    .s0_found       (s0_found),
    .s0_index       (s0_index),
    .s0_pfn         (s0_pfn),
    .s0_c           (s0_c),
    .s0_d           (s0_d),
    .s0_v           (s0_v),
  
    .s1_vpn2        (s1_vpn2),
    .s1_odd_page    (s1_odd_page),
    .s1_asid        (s1_asid),     
    .s1_found       (s1_found),
    .s1_index       (s1_index),
    .s1_pfn         (s1_pfn),
    .s1_c           (s1_c),
    .s1_d           (s1_d),
    .s1_v           (s1_v),
     
    .we              (tlb_we), 
    .w_index         (w_index),  
    .w_vpn2          (w_vpn2),   
    .w_asid          (w_asid), 
    .w_g             (w_g),
    .w_pfn0          (w_pfn0),  
    .w_c0            (w_c0),  
    .w_d0            (w_d0), 
    .w_v0            (w_v0),  
    .w_pfn1          (w_pfn1),  
    .w_c1            (w_c1),  
    .w_d1            (w_d1), 
    .w_v1            (w_v1),  
      
    .r_index       (r_index),
    .r_vpn2        (r_vpn2),  
    .r_asid        (r_asid),  
    .r_g           (r_g),  
    .r_pfn0        (r_pfn0),  
    .r_c0          (r_c0),  
    .r_d0          (r_d0),  
    .r_v0          (r_v0), 
    .r_pfn1        (r_pfn1),  
    .r_c1          (r_c1),     
    .r_d1          (r_d1),  
    .r_v1          (r_v1) 
);

//sram_axi_bridge
axi_bridge u_axi_bridge(
    .clk      (aclk       ),
    .reset    (reset    ),  

    .arid      (arid      ),
    .araddr    (araddr    ),
    .arlen     (arlen     ),
    .arsize    (arsize    ),
    .arburst   (arburst   ),
    .arlock    (arlock    ),
    .arcache   (arcache   ),
    .arprot    (arprot    ),
    .arvalid   (arvalid   ),
    .arready   (arready   ),
                
    .rid       (rid       ),
    .rdata     (rdata     ),
    .rresp     (rresp     ),
    .rlast     (rlast     ),
    .rvalid    (rvalid    ),
    .rready    (rready    ),
               
    .awid      (awid      ),
    .awaddr    (awaddr    ),
    .awlen     (awlen     ),
    .awsize    (awsize    ),
    .awburst   (awburst   ),
    .awlock    (awlock    ),
    .awcache   (awcache   ),
    .awprot    (awprot    ),
    .awvalid   (awvalid   ),
    .awready   (awready   ),
    
    .wid       (wid       ),
    .wdata     (wdata     ),
    .wstrb     (wstrb     ),
    .wlast     (wlast     ),
    .wvalid    (wvalid    ),
    .wready    (wready    ),
    
    .bid       (bid       ),
    .bresp     (bresp     ),
    .bvalid    (bvalid    ),
    .bready    (bready    ),

    .inst_sram_req    (inst_sram_req    ),
    //.inst_sram_wr     (inst_sram_wr     ),
    //.inst_sram_size   (inst_sram_size   ),
    //.inst_sram_wstrb  (inst_sram_wstrb  ),
    .inst_sram_addr   (inst_sram_addr  ),
    //.inst_sram_wdata  (inst_sram_wdata  ),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_data_ok(inst_sram_data_ok),
    .inst_sram_rdata  (inst_sram_rdata  ),

    .data_sram_req   (data_sram_req   ),
    .data_sram_wr  (data_sram_wr  ),
    .data_sram_size(data_sram_size),
    .data_sram_wstrb(data_sram_wstrb),
    .data_sram_addr (data_sram_addr ),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata(data_sram_rdata)
);

// mul32
mul32 mml(
    .clk(aclk),
    .resetn(aresetn),
    .is_signed(mul_is_signed),
    .A(mul_A),
    .B(mul_B),
    .product(mul_product)
);
// IF stage
if_stage if_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .ds_allowin     (ds_allowin     ),
    //brbus
    .br_bus         (br_bus         ),
    //outputs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //from ms
    .ms_to_fs_bus   (ms_to_fs_bus)   ,
    // search port0
    .s0_vpn2        (s0_vpn2),
    .s0_odd_page    (s0_odd_page),
    .s0_found       (s0_found),
    .s0_pfn         (s0_pfn),
    .s0_v           (s0_v),
    // inst sram interface
    .inst_sram_req    (inst_sram_req    ),
    //.inst_sram_wr     (inst_sram_wr     ),
    //.inst_sram_size   (inst_sram_size   ),
    //.inst_sram_wstrb  (inst_sram_wstrb  ),
    .inst_sram_addr   (inst_sram_addr  ),
    //.inst_sram_wdata  (inst_sram_wdata  ),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_data_ok(inst_sram_data_ok),
    .inst_sram_rdata  (inst_sram_rdata  )
);
// ID stage
id_stage id_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    //from fs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //to es
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to fs
    .br_bus         (br_bus         ),
    //forward bus
    .es_forward_bus (es_forward_bus ),
    .ms_forward_bus (ms_forward_bus ),
    .ws_to_rf_bus   (ws_to_rf_bus   )
);

// EXE stage
exe_stage exe_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .ms_allowin     (ms_allowin     ),
    .es_allowin     (es_allowin     ),
    //from ds
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to ms
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    //to ds
    .es_forward_bus (es_forward_bus ),
    //from ms
    .ms_to_es_bus   (ms_to_es_bus   ),
    // mul interface
    .mul_is_signed  (mul_is_signed) ,
    .mul_A          (mul_A)         ,
    .mul_B          (mul_B)         ,
    // search port1
    .s1_vpn2        (s1_vpn2),
    .s1_odd_page    (s1_odd_page),    
    .s1_found       (s1_found),
    .s1_pfn         (s1_pfn),
    .s1_c           (s1_c),
    .s1_d           (s1_d),
    .s1_v           (s1_v),
    // data sram interface
    .data_sram_req   (data_sram_req   ),
    .data_sram_wr  (data_sram_wr  ),
    .data_sram_size(data_sram_size),
    .data_sram_wstrb(data_sram_wstrb),
    .data_sram_addr (data_sram_addr ),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_wdata(data_sram_wdata)
);
// MEM stage
mem_stage mem_stage(
    .clk            (aclk            ),
    .reset          (reset           ),
    .int_in         (int             ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .ms_allowin     (ms_allowin     ),
    // tlb
    .s0_asid        (s0_asid),
    .s1_asid        (s1_asid),     
    .s1_found       (s1_found),
    .s1_index       (s1_index),
    .tlb_we          (tlb_we), 
    .w_index         (w_index),  
    .w_vpn2          (w_vpn2),   
    .w_asid          (w_asid), 
    .w_g             (w_g),
    .w_pfn0          (w_pfn0),  
    .w_c0            (w_c0),  
    .w_d0            (w_d0), 
    .w_v0            (w_v0),  
    .w_pfn1          (w_pfn1),  
    .w_c1            (w_c1),  
    .w_d1            (w_d1), 
    .w_v1            (w_v1),  
    .r_index       (r_index),
    .r_vpn2        (r_vpn2),  
    .r_asid        (r_asid),  
    .r_g           (r_g),  
    .r_pfn0        (r_pfn0),  
    .r_c0          (r_c0),  
    .r_d0          (r_d0),  
    .r_v0          (r_v0), 
    .r_pfn1        (r_pfn1),  
    .r_c1          (r_c1),     
    .r_d1          (r_d1),  
    .r_v1          (r_v1),
    //from es
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    //to ws
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //to fs
    .ms_to_fs_bus   (ms_to_fs_bus   ),
    //to es
    .ms_to_es_bus   (ms_to_es_bus   ),
    //mul interface
    .mul_product    (mul_product)    ,
    //to ds
    .ms_forward_bus (ms_forward_bus ),
    //from data-sram
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata(data_sram_rdata)
);
// WB stage
wb_stage wb_stage(
    .clk            (aclk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    //from ms
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

endmodule
