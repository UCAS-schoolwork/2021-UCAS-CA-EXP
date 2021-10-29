module tlb #(
    parameter TLBNUM = 16 
)
(
    input                       clk, 
    // search port 0
    input  [              18:0] s0_vpn2,
    input                       s0_odd_page,     
    input  [               7:0] s0_asid,     
    output                      s0_found,     
    output [$clog2(TLBNUM)-1:0] s0_index,     
    output [              19:0] s0_pfn,     
    output [               2:0] s0_c,     
    output                      s0_d,     
    output                      s0_v, 

    // search port 1     
    input  [              18:0] s1_vpn2,     
    input                       s1_odd_page,     
    input  [               7:0] s1_asid,     
    output                      s1_found,     
    output [$clog2(TLBNUM)-1:0] s1_index,     
    output [              19:0] s1_pfn,     
    output [               2:0] s1_c,     
    output                      s1_d,     
    output                      s1_v, 

    // write port     
    input                       we,     
    input  [$clog2(TLBNUM)-1:0] w_index,     
    input  [              18:0] w_vpn2,     
    input  [               7:0] w_asid,     
    input                       w_g,     
    input  [              19:0] w_pfn0,     
    input  [               2:0] w_c0,     
    input                       w_d0, 
    input                       w_v0,     
    input  [              19:0] w_pfn1,     
    input  [               2:0] w_c1,     
    input                       w_d1,     
    input                       w_v1, 
    
    // read port     
    input  [$clog2(TLBNUM)-1:0] r_index,     
    output [              18:0] r_vpn2,     
    output [               7:0] r_asid,     
    output                      r_g,     
    output [              19:0] r_pfn0,     
    output [               2:0] r_c0,     
    output                      r_d0,     
    output                      r_v0,     
    output [              19:0] r_pfn1,     
    output [               2:0] r_c1,     
    output                      r_d1,     
    output                      r_v1 
); 
     
reg  [      18:0] tlb_vpn2     [TLBNUM-1:0]; 
reg  [       7:0] tlb_asid     [TLBNUM-1:0]; 
reg               tlb_g        [TLBNUM-1:0]; 
reg  [      19:0] tlb_pfn0     [TLBNUM-1:0]; 
reg  [       2:0] tlb_c0       [TLBNUM-1:0]; 
reg               tlb_d0       [TLBNUM-1:0]; 
reg               tlb_v0       [TLBNUM-1:0]; 
reg  [      19:0] tlb_pfn1     [TLBNUM-1:0]; 
reg  [       2:0] tlb_c1       [TLBNUM-1:0]; 
reg               tlb_d1       [TLBNUM-1:0]; 
reg               tlb_v1       [TLBNUM-1:0]; 

wire [19:0] s0_pfn0;
wire [ 2:0] s0_c0;
wire        s0_d0;
wire        s0_v0;
wire [19:0] s0_pfn1;
wire [ 2:0] s0_c1;
wire        s0_d1;
wire        s0_v1;
wire [19:0] s1_pfn0;
wire [ 2:0] s1_c0;
wire        s1_d0;
wire        s1_v0;
wire [19:0] s1_pfn1;
wire [ 2:0] s1_c1;
wire        s1_d1;
wire        s1_v1;

// search 0
wire [TLBNUM -1:0] match0;
assign s0_found = ~(match0 == {TLBNUM{1'd0}});

genvar i;
generate for(i=0;i<TLBNUM;i=i+1) begin: gen_match0
    assign match0[i] = (s0_vpn2==tlb_vpn2[i] && (tlb_g[i] || s0_asid==tlb_asid[i]));
end endgenerate

    // Index bits are 4 now
index16 u_index0(.match(match0), .index(s0_index));
assign s0_pfn = s0_odd_page ? s0_pfn1 : s0_pfn0;
assign s0_c   = s0_odd_page ? s0_c1 : s0_c0;
assign s0_d   = s0_odd_page ? s0_d1 : s0_d0;
assign s0_v   = s0_odd_page ? s0_v1 : s0_v0;

// search 1
wire [TLBNUM -1:0] match1;
assign s1_found = ~(match1 == {TLBNUM{1'd0}});

// genvar i
generate for(i=0;i<TLBNUM;i=i+1) begin: gen_match1
    assign match1[i] = (s1_vpn2==tlb_vpn2[i] && (tlb_g[i] || s1_asid==tlb_asid[i]));
end endgenerate

    // Index bits are 4 now
index16 u_index1(.match(match1), .index(s1_index));
assign s1_pfn = s1_odd_page ? s1_pfn1 : s1_pfn0;
assign s1_c   = s1_odd_page ? s1_c1 : s1_c0;
assign s1_d   = s1_odd_page ? s1_d1 : s1_d0;
assign s1_v   = s1_odd_page ? s1_v1 : s1_v0;

// read
assign r_vpn2 = tlb_vpn2 [r_index];
assign r_asid = tlb_asid [r_index];
assign r_g    = tlb_g    [r_index];
assign r_pfn0 = tlb_pfn0 [r_index];
assign r_c0   = tlb_c0   [r_index];
assign r_d0   = tlb_d0   [r_index];
assign r_v0   = tlb_v0   [r_index];
assign r_pfn1 = tlb_pfn1 [r_index];
assign r_c1   = tlb_c1   [r_index];
assign r_d1   = tlb_d1   [r_index];
assign r_v1   = tlb_v1   [r_index];  

// write
always@(posedge clk) begin
    if(we) begin
        tlb_vpn2 [w_index] <= w_vpn2;
        tlb_asid [w_index] <= w_asid;
        tlb_g    [w_index] <= w_g   ;
        tlb_pfn0 [w_index] <= w_pfn0;
        tlb_c0   [w_index] <= w_c0;
        tlb_d0   [w_index] <= w_d0;
        tlb_v0   [w_index] <= w_v0;
        tlb_pfn1 [w_index] <= w_pfn1;
        tlb_c1   [w_index] <= w_c1;
        tlb_d1   [w_index] <= w_d1;
        tlb_v1   [w_index] <= w_v1;
    end
end


assign s0_pfn0 =  {20{match0[ 0]}} & tlb_pfn0[ 0]
                | {20{match0[ 1]}} & tlb_pfn0[ 1]
                | {20{match0[ 2]}} & tlb_pfn0[ 2]
                | {20{match0[ 3]}} & tlb_pfn0[ 3]
                | {20{match0[ 4]}} & tlb_pfn0[ 4] 
                | {20{match0[ 5]}} & tlb_pfn0[ 5] 
                | {20{match0[ 6]}} & tlb_pfn0[ 6] 
                | {20{match0[ 7]}} & tlb_pfn0[ 7] 
                | {20{match0[ 8]}} & tlb_pfn0[ 8] 
                | {20{match0[ 9]}} & tlb_pfn0[ 9] 
                | {20{match0[10]}} & tlb_pfn0[10]
                | {20{match0[11]}} & tlb_pfn0[11]
                | {20{match0[12]}} & tlb_pfn0[12]
                | {20{match0[13]}} & tlb_pfn0[13]
                | {20{match0[14]}} & tlb_pfn0[14]
                | {20{match0[15]}} & tlb_pfn0[15];
assign s0_pfn1 =  {20{match0[ 0]}} & tlb_pfn1[ 0]
                | {20{match0[ 1]}} & tlb_pfn1[ 1]
                | {20{match0[ 2]}} & tlb_pfn1[ 2]
                | {20{match0[ 3]}} & tlb_pfn1[ 3]
                | {20{match0[ 4]}} & tlb_pfn1[ 4] 
                | {20{match0[ 5]}} & tlb_pfn1[ 5] 
                | {20{match0[ 6]}} & tlb_pfn1[ 6] 
                | {20{match0[ 7]}} & tlb_pfn1[ 7] 
                | {20{match0[ 8]}} & tlb_pfn1[ 8] 
                | {20{match0[ 9]}} & tlb_pfn1[ 9] 
                | {20{match0[10]}} & tlb_pfn1[10]
                | {20{match0[11]}} & tlb_pfn1[11]
                | {20{match0[12]}} & tlb_pfn1[12]
                | {20{match0[13]}} & tlb_pfn1[13]
                | {20{match0[14]}} & tlb_pfn1[14]
                | {20{match0[15]}} & tlb_pfn1[15];
assign s0_c0 =    {3{match0[ 0]}} & tlb_c0[ 0]
                | {3{match0[ 1]}} & tlb_c0[ 1]
                | {3{match0[ 2]}} & tlb_c0[ 2]
                | {3{match0[ 3]}} & tlb_c0[ 3]
                | {3{match0[ 4]}} & tlb_c0[ 4] 
                | {3{match0[ 5]}} & tlb_c0[ 5] 
                | {3{match0[ 6]}} & tlb_c0[ 6] 
                | {3{match0[ 7]}} & tlb_c0[ 7] 
                | {3{match0[ 8]}} & tlb_c0[ 8] 
                | {3{match0[ 9]}} & tlb_c0[ 9] 
                | {3{match0[10]}} & tlb_c0[10]
                | {3{match0[11]}} & tlb_c0[11]
                | {3{match0[12]}} & tlb_c0[12]
                | {3{match0[13]}} & tlb_c0[13]
                | {3{match0[14]}} & tlb_c0[14]
                | {3{match0[15]}} & tlb_c0[15];
assign s0_c1   =  {3{match0[ 0]}} & tlb_c1[ 0]
                | {3{match0[ 1]}} & tlb_c1[ 1]
                | {3{match0[ 2]}} & tlb_c1[ 2]
                | {3{match0[ 3]}} & tlb_c1[ 3]
                | {3{match0[ 4]}} & tlb_c1[ 4] 
                | {3{match0[ 5]}} & tlb_c1[ 5] 
                | {3{match0[ 6]}} & tlb_c1[ 6] 
                | {3{match0[ 7]}} & tlb_c1[ 7] 
                | {3{match0[ 8]}} & tlb_c1[ 8] 
                | {3{match0[ 9]}} & tlb_c1[ 9] 
                | {3{match0[10]}} & tlb_c1[10]
                | {3{match0[11]}} & tlb_c1[11]
                | {3{match0[12]}} & tlb_c1[12]
                | {3{match0[13]}} & tlb_c1[13]
                | {3{match0[14]}} & tlb_c1[14]
                | {3{match0[15]}} & tlb_c1[15];
assign s0_d0 =    match0[ 0] & tlb_d0[ 0]
                | match0[ 1] & tlb_d0[ 1]
                | match0[ 2] & tlb_d0[ 2]
                | match0[ 3] & tlb_d0[ 3]
                | match0[ 4] & tlb_d0[ 4] 
                | match0[ 5] & tlb_d0[ 5] 
                | match0[ 6] & tlb_d0[ 6] 
                | match0[ 7] & tlb_d0[ 7] 
                | match0[ 8] & tlb_d0[ 8] 
                | match0[ 9] & tlb_d0[ 9] 
                | match0[10] & tlb_d0[10]
                | match0[11] & tlb_d0[11]
                | match0[12] & tlb_d0[12]
                | match0[13] & tlb_d0[13]
                | match0[14] & tlb_d0[14]
                | match0[15] & tlb_d0[15];
assign s0_d1   =  match0[ 0] & tlb_d1[ 0]
                | match0[ 1] & tlb_d1[ 1]
                | match0[ 2] & tlb_d1[ 2]
                | match0[ 3] & tlb_d1[ 3]
                | match0[ 4] & tlb_d1[ 4] 
                | match0[ 5] & tlb_d1[ 5] 
                | match0[ 6] & tlb_d1[ 6] 
                | match0[ 7] & tlb_d1[ 7] 
                | match0[ 8] & tlb_d1[ 8] 
                | match0[ 9] & tlb_d1[ 9] 
                | match0[10] & tlb_d1[10]
                | match0[11] & tlb_d1[11]
                | match0[12] & tlb_d1[12]
                | match0[13] & tlb_d1[13]
                | match0[14] & tlb_d1[14]
                | match0[15] & tlb_d1[15];
assign s0_v0 =    match0[ 0] & tlb_v0[ 0]
                | match0[ 1] & tlb_v0[ 1]
                | match0[ 2] & tlb_v0[ 2]
                | match0[ 3] & tlb_v0[ 3]
                | match0[ 4] & tlb_v0[ 4] 
                | match0[ 5] & tlb_v0[ 5] 
                | match0[ 6] & tlb_v0[ 6] 
                | match0[ 7] & tlb_v0[ 7] 
                | match0[ 8] & tlb_v0[ 8] 
                | match0[ 9] & tlb_v0[ 9] 
                | match0[10] & tlb_v0[10]
                | match0[11] & tlb_v0[11]
                | match0[12] & tlb_v0[12]
                | match0[13] & tlb_v0[13]
                | match0[14] & tlb_v0[14]
                | match0[15] & tlb_v0[15];
assign s0_v1   =  match0[ 0] & tlb_v1[ 0]
                | match0[ 1] & tlb_v1[ 1]
                | match0[ 2] & tlb_v1[ 2]
                | match0[ 3] & tlb_v1[ 3]
                | match0[ 4] & tlb_v1[ 4] 
                | match0[ 5] & tlb_v1[ 5] 
                | match0[ 6] & tlb_v1[ 6] 
                | match0[ 7] & tlb_v1[ 7] 
                | match0[ 8] & tlb_v1[ 8] 
                | match0[ 9] & tlb_v1[ 9] 
                | match0[10] & tlb_v1[10]
                | match0[11] & tlb_v1[11]
                | match0[12] & tlb_v1[12]
                | match0[13] & tlb_v1[13]
                | match0[14] & tlb_v1[14]
                | match0[15] & tlb_v1[15];        


assign s1_pfn0 =  {20{match1[ 0]}} & tlb_pfn0[ 0]
                | {20{match1[ 1]}} & tlb_pfn0[ 1]
                | {20{match1[ 2]}} & tlb_pfn0[ 2]
                | {20{match1[ 3]}} & tlb_pfn0[ 3]
                | {20{match1[ 4]}} & tlb_pfn0[ 4] 
                | {20{match1[ 5]}} & tlb_pfn0[ 5] 
                | {20{match1[ 6]}} & tlb_pfn0[ 6] 
                | {20{match1[ 7]}} & tlb_pfn0[ 7] 
                | {20{match1[ 8]}} & tlb_pfn0[ 8] 
                | {20{match1[ 9]}} & tlb_pfn0[ 9] 
                | {20{match1[10]}} & tlb_pfn0[10]
                | {20{match1[11]}} & tlb_pfn0[11]
                | {20{match1[12]}} & tlb_pfn0[12]
                | {20{match1[13]}} & tlb_pfn0[13]
                | {20{match1[14]}} & tlb_pfn0[14]
                | {20{match1[15]}} & tlb_pfn0[15];
assign s1_pfn1 =  {20{match1[ 0]}} & tlb_pfn1[ 0]
                | {20{match1[ 1]}} & tlb_pfn1[ 1]
                | {20{match1[ 2]}} & tlb_pfn1[ 2]
                | {20{match1[ 3]}} & tlb_pfn1[ 3]
                | {20{match1[ 4]}} & tlb_pfn1[ 4] 
                | {20{match1[ 5]}} & tlb_pfn1[ 5] 
                | {20{match1[ 6]}} & tlb_pfn1[ 6] 
                | {20{match1[ 7]}} & tlb_pfn1[ 7] 
                | {20{match1[ 8]}} & tlb_pfn1[ 8] 
                | {20{match1[ 9]}} & tlb_pfn1[ 9] 
                | {20{match1[10]}} & tlb_pfn1[10]
                | {20{match1[11]}} & tlb_pfn1[11]
                | {20{match1[12]}} & tlb_pfn1[12]
                | {20{match1[13]}} & tlb_pfn1[13]
                | {20{match1[14]}} & tlb_pfn1[14]
                | {20{match1[15]}} & tlb_pfn1[15];
assign s1_c0 =    {3{match1[ 0]}} & tlb_c0[ 0]
                | {3{match1[ 1]}} & tlb_c0[ 1]
                | {3{match1[ 2]}} & tlb_c0[ 2]
                | {3{match1[ 3]}} & tlb_c0[ 3]
                | {3{match1[ 4]}} & tlb_c0[ 4] 
                | {3{match1[ 5]}} & tlb_c0[ 5] 
                | {3{match1[ 6]}} & tlb_c0[ 6] 
                | {3{match1[ 7]}} & tlb_c0[ 7] 
                | {3{match1[ 8]}} & tlb_c0[ 8] 
                | {3{match1[ 9]}} & tlb_c0[ 9] 
                | {3{match1[10]}} & tlb_c0[10]
                | {3{match1[11]}} & tlb_c0[11]
                | {3{match1[12]}} & tlb_c0[12]
                | {3{match1[13]}} & tlb_c0[13]
                | {3{match1[14]}} & tlb_c0[14]
                | {3{match1[15]}} & tlb_c0[15];
assign s1_c1   =  {3{match1[ 0]}} & tlb_c1[ 0]
                | {3{match1[ 1]}} & tlb_c1[ 1]
                | {3{match1[ 2]}} & tlb_c1[ 2]
                | {3{match1[ 3]}} & tlb_c1[ 3]
                | {3{match1[ 4]}} & tlb_c1[ 4] 
                | {3{match1[ 5]}} & tlb_c1[ 5] 
                | {3{match1[ 6]}} & tlb_c1[ 6] 
                | {3{match1[ 7]}} & tlb_c1[ 7] 
                | {3{match1[ 8]}} & tlb_c1[ 8] 
                | {3{match1[ 9]}} & tlb_c1[ 9] 
                | {3{match1[10]}} & tlb_c1[10]
                | {3{match1[11]}} & tlb_c1[11]
                | {3{match1[12]}} & tlb_c1[12]
                | {3{match1[13]}} & tlb_c1[13]
                | {3{match1[14]}} & tlb_c1[14]
                | {3{match1[15]}} & tlb_c1[15];
assign s1_d0 =    match1[ 0] & tlb_d0[ 0]
                | match1[ 1] & tlb_d0[ 1]
                | match1[ 2] & tlb_d0[ 2]
                | match1[ 3] & tlb_d0[ 3]
                | match1[ 4] & tlb_d0[ 4] 
                | match1[ 5] & tlb_d0[ 5] 
                | match1[ 6] & tlb_d0[ 6] 
                | match1[ 7] & tlb_d0[ 7] 
                | match1[ 8] & tlb_d0[ 8] 
                | match1[ 9] & tlb_d0[ 9] 
                | match1[10] & tlb_d0[10]
                | match1[11] & tlb_d0[11]
                | match1[12] & tlb_d0[12]
                | match1[13] & tlb_d0[13]
                | match1[14] & tlb_d0[14]
                | match1[15] & tlb_d0[15];
assign s1_d1   =  match1[ 0] & tlb_d1[ 0]
                | match1[ 1] & tlb_d1[ 1]
                | match1[ 2] & tlb_d1[ 2]
                | match1[ 3] & tlb_d1[ 3]
                | match1[ 4] & tlb_d1[ 4] 
                | match1[ 5] & tlb_d1[ 5] 
                | match1[ 6] & tlb_d1[ 6] 
                | match1[ 7] & tlb_d1[ 7] 
                | match1[ 8] & tlb_d1[ 8] 
                | match1[ 9] & tlb_d1[ 9] 
                | match1[10] & tlb_d1[10]
                | match1[11] & tlb_d1[11]
                | match1[12] & tlb_d1[12]
                | match1[13] & tlb_d1[13]
                | match1[14] & tlb_d1[14]
                | match1[15] & tlb_d1[15];
assign s1_v0 =    match1[ 0] & tlb_v0[ 0]
                | match1[ 1] & tlb_v0[ 1]
                | match1[ 2] & tlb_v0[ 2]
                | match1[ 3] & tlb_v0[ 3]
                | match1[ 4] & tlb_v0[ 4] 
                | match1[ 5] & tlb_v0[ 5] 
                | match1[ 6] & tlb_v0[ 6] 
                | match1[ 7] & tlb_v0[ 7] 
                | match1[ 8] & tlb_v0[ 8] 
                | match1[ 9] & tlb_v0[ 9] 
                | match1[10] & tlb_v0[10]
                | match1[11] & tlb_v0[11]
                | match1[12] & tlb_v0[12]
                | match1[13] & tlb_v0[13]
                | match1[14] & tlb_v0[14]
                | match1[15] & tlb_v0[15];
assign s1_v1   =  match1[ 0] & tlb_v1[ 0]
                | match1[ 1] & tlb_v1[ 1]
                | match1[ 2] & tlb_v1[ 2]
                | match1[ 3] & tlb_v1[ 3]
                | match1[ 4] & tlb_v1[ 4] 
                | match1[ 5] & tlb_v1[ 5] 
                | match1[ 6] & tlb_v1[ 6] 
                | match1[ 7] & tlb_v1[ 7] 
                | match1[ 8] & tlb_v1[ 8] 
                | match1[ 9] & tlb_v1[ 9] 
                | match1[10] & tlb_v1[10]
                | match1[11] & tlb_v1[11]
                | match1[12] & tlb_v1[12]
                | match1[13] & tlb_v1[13]
                | match1[14] & tlb_v1[14]
                | match1[15] & tlb_v1[15];     

endmodule

module index16 (
    input  [15:0] match,
    output [ 3:0] index
);
assign index = {4{match[ 0]}} & 4'd0 
             | {4{match[ 1]}} & 4'd1 
             | {4{match[ 2]}} & 4'd2 
             | {4{match[ 3]}} & 4'd3 
             | {4{match[ 4]}} & 4'd4 
             | {4{match[ 5]}} & 4'd5 
             | {4{match[ 6]}} & 4'd6 
             | {4{match[ 7]}} & 4'd7 
             | {4{match[ 8]}} & 4'd8 
             | {4{match[ 9]}} & 4'd9 
             | {4{match[10]}} & 4'd10
             | {4{match[11]}} & 4'd11
             | {4{match[12]}} & 4'd12
             | {4{match[13]}} & 4'd13
             | {4{match[14]}} & 4'd14
             | {4{match[15]}} & 4'd15;
endmodule