

module div32(
    input clk,
    input resetn,
    input div,
    input is_signed,
    input [31:0] Ain,
    input [31:0] Bin,
    output complete,
    output [31:0] rem,
    output [31:0] S_out
);

reg [5:0]  counter;
reg [63:0] A;
reg [31:0] B;
reg [31:0] S;
reg sign_A;
reg sign_B;
wire div_first;
assign div_first = div & counter == 6'd0;


// calculate 2's complement
wire [31:0] not_A_in;
wire [31:0] not_B_in;
wire [31:0] not_A_out;
wire [31:0] not_B_out;
assign not_A_out = ~not_A_in + 1'd1;
assign not_B_out = ~not_B_in + 1'd1;

assign not_A_in = div_first ? Ain : A[31:0];
assign not_B_in = div_first ? Bin : S[31:0];

// last clk
assign rem = sign_A ? not_A_out : A[31:0];
assign S_out = sign_A ^ sign_B ? not_B_out : S[31:0];
assign complete = counter == 6'd33;

// skip 0's
wire [5:0] countz_A;
wire [5:0] countz_B;
wire [31:0] A_32;
assign A_32 = A[31:0];
count_zero countA(
    .X(A_32),
    .count(countz_A)
);
count_zero countB(
    .X(B),
    .count(countz_B)
);
reg [6:0] last_counter;
wire [6:0] move_bit;
assign move_bit = {1'd0,countz_A} - {1'd0,countz_B};
wire [6:0] move_counter;
assign move_counter = 6'd32 + move_bit;
wire move_take;
assign move_take = move_bit[6] && move_counter!=counter && move_counter!=last_counter;
wire over_ahead;
wire [32:0] slt_data;
assign slt_data = {1'd0,A[31:0]} + {1'd1,~B} + 1'd1;
assign over_ahead = slt_data[32];

always @(posedge clk) begin 
    if(~resetn)
        last_counter <= 6'd0;
    else 
        last_counter <= counter;
end

// next clk reg renew
wire [31:0] new_S;
wire [63:0] new_A;
always @(posedge clk) begin 
    if(div_first) begin
        A <= {32'd0,Ain[31]&is_signed ? not_A_out : Ain};
        B <= Bin[31]&is_signed ? not_B_out : Bin;
        S <= 32'd0;
        sign_A <= is_signed & Ain[31];
        sign_B <= is_signed & Bin[31];
    end
    else if(~over_ahead & ~move_take) begin
        A <= new_A;
        S <= new_S;
    end 
end

// counter

always @(posedge clk) begin 
    if(~resetn | complete | ~div) 
        counter <= 6'd0;
    else if(div) begin 
        if(div_first)
            counter <= 6'd1;
        else if(over_ahead)
            counter <= 6'd33;
        else if(move_take)
            counter <= move_counter;
        else 
            counter <= counter + 1'd1;
    end
end

// next clk logic
wire [32:0] sub_A;
wire [32:0] sub_B;
wire [32:0] sub_C;
assign sub_B = {1'b0,B};
assign sub_C = sub_A - sub_B;
assign sub_A =    {33{counter == 6'd1}} & A[63:31]
                | {33{counter == 6'd2}} & A[62:30]
                | {33{counter == 6'd3}} & A[61:29]
                | {33{counter == 6'd4}} & A[60:28]
                | {33{counter == 6'd5}} & A[59:27]
                | {33{counter == 6'd6}} & A[58:26]
                | {33{counter == 6'd7}} & A[57:25]
                | {33{counter == 6'd8}} & A[56:24]
                | {33{counter == 6'd9}} & A[55:23]
                | {33{counter == 6'd10}} & A[54:22]
                | {33{counter == 6'd11}} & A[53:21]
                | {33{counter == 6'd12}} & A[52:20]
                | {33{counter == 6'd13}} & A[51:19]
                | {33{counter == 6'd14}} & A[50:18]
                | {33{counter == 6'd15}} & A[49:17]
                | {33{counter == 6'd16}} & A[48:16]
                | {33{counter == 6'd17}} & A[47:15]
                | {33{counter == 6'd18}} & A[46:14]
                | {33{counter == 6'd19}} & A[45:13]
                | {33{counter == 6'd20}} & A[44:12]
                | {33{counter == 6'd21}} & A[43:11]
                | {33{counter == 6'd22}} & A[42:10]
                | {33{counter == 6'd23}} & A[41:9]
                | {33{counter == 6'd24}} & A[40:8]
                | {33{counter == 6'd25}} & A[39:7]
                | {33{counter == 6'd26}} & A[38:6]
                | {33{counter == 6'd27}} & A[37:5]
                | {33{counter == 6'd28}} & A[36:4]
                | {33{counter == 6'd29}} & A[35:3]
                | {33{counter == 6'd30}} & A[34:2]
                | {33{counter == 6'd31}} & A[33:1]
                | {33{counter == 6'd32}} & A[32:0];


assign new_A = sub_C[32] ? A :
                  {33{counter == 6'd1}} & {sub_C,A[30:0]}
                | {33{counter == 6'd2}} & {A[63],sub_C,A[29:0]}
                | {33{counter == 6'd3}} & {A[63:62],sub_C,A[28:0]}
                | {33{counter == 6'd4}} & {A[63:61],sub_C,A[27:0]}
                | {33{counter == 6'd5}} & {A[63:60],sub_C,A[26:0]}
                | {33{counter == 6'd6}} & {A[63:59],sub_C,A[25:0]}
                | {33{counter == 6'd7}} & {A[63:58],sub_C,A[24:0]}
                | {33{counter == 6'd8}} & {A[63:57],sub_C,A[23:0]}
                | {33{counter == 6'd9}} & {A[63:56],sub_C,A[22:0]}
                | {33{counter == 6'd10}} & {A[63:55],sub_C,A[21:0]}
                | {33{counter == 6'd11}} & {A[63:54],sub_C,A[20:0]}
                | {33{counter == 6'd12}} & {A[63:53],sub_C,A[19:0]}
                | {33{counter == 6'd13}} & {A[63:52],sub_C,A[18:0]}
                | {33{counter == 6'd14}} & {A[63:51],sub_C,A[17:0]}
                | {33{counter == 6'd15}} & {A[63:50],sub_C,A[16:0]}
                | {33{counter == 6'd16}} & {A[63:49],sub_C,A[15:0]}
                | {33{counter == 6'd17}} & {A[63:48],sub_C,A[14:0]}
                | {33{counter == 6'd18}} & {A[63:47],sub_C,A[13:0]}
                | {33{counter == 6'd19}} & {A[63:46],sub_C,A[12:0]}
                | {33{counter == 6'd20}} & {A[63:45],sub_C,A[11:0]}
                | {33{counter == 6'd21}} & {A[63:44],sub_C,A[10:0]}
                | {33{counter == 6'd22}} & {A[63:43],sub_C,A[9:0]}
                | {33{counter == 6'd23}} & {A[63:42],sub_C,A[8:0]}
                | {33{counter == 6'd24}} & {A[63:41],sub_C,A[7:0]}
                | {33{counter == 6'd25}} & {A[63:40],sub_C,A[6:0]}
                | {33{counter == 6'd26}} & {A[63:39],sub_C,A[5:0]}
                | {33{counter == 6'd27}} & {A[63:38],sub_C,A[4:0]}
                | {33{counter == 6'd28}} & {A[63:37],sub_C,A[3:0]}
                | {33{counter == 6'd29}} & {A[63:36],sub_C,A[2:0]}
                | {33{counter == 6'd30}} & {A[63:35],sub_C,A[1:0]}
                | {33{counter == 6'd31}} & {A[63:34],sub_C,A[0]}
                | {33{counter == 6'd32}} & {A[63:33],sub_C};


assign new_S =    {32{counter == 6'd1}} & {~sub_C[32],S[30:0]}
                | {32{counter == 6'd2}} & {S[31],~sub_C[32],S[29:0]}
                | {32{counter == 6'd3}} & {S[31:30],~sub_C[32],S[28:0]}
                | {32{counter == 6'd4}} & {S[31:29],~sub_C[32],S[27:0]}
                | {32{counter == 6'd5}} & {S[31:28],~sub_C[32],S[26:0]}
                | {32{counter == 6'd6}} & {S[31:27],~sub_C[32],S[25:0]}
                | {32{counter == 6'd7}} & {S[31:26],~sub_C[32],S[24:0]}
                | {32{counter == 6'd8}} & {S[31:25],~sub_C[32],S[23:0]}
                | {32{counter == 6'd9}} & {S[31:24],~sub_C[32],S[22:0]}
                | {32{counter == 6'd10}} & {S[31:23],~sub_C[32],S[21:0]}
                | {32{counter == 6'd11}} & {S[31:22],~sub_C[32],S[20:0]}
                | {32{counter == 6'd12}} & {S[31:21],~sub_C[32],S[19:0]}
                | {32{counter == 6'd13}} & {S[31:20],~sub_C[32],S[18:0]}
                | {32{counter == 6'd14}} & {S[31:19],~sub_C[32],S[17:0]}
                | {32{counter == 6'd15}} & {S[31:18],~sub_C[32],S[16:0]}
                | {32{counter == 6'd16}} & {S[31:17],~sub_C[32],S[15:0]}
                | {32{counter == 6'd17}} & {S[31:16],~sub_C[32],S[14:0]}
                | {32{counter == 6'd18}} & {S[31:15],~sub_C[32],S[13:0]}
                | {32{counter == 6'd19}} & {S[31:14],~sub_C[32],S[12:0]}
                | {32{counter == 6'd20}} & {S[31:13],~sub_C[32],S[11:0]}
                | {32{counter == 6'd21}} & {S[31:12],~sub_C[32],S[10:0]}
                | {32{counter == 6'd22}} & {S[31:11],~sub_C[32],S[9:0]}
                | {32{counter == 6'd23}} & {S[31:10],~sub_C[32],S[8:0]}
                | {32{counter == 6'd24}} & {S[31:9],~sub_C[32],S[7:0]}
                | {32{counter == 6'd25}} & {S[31:8],~sub_C[32],S[6:0]}
                | {32{counter == 6'd26}} & {S[31:7],~sub_C[32],S[5:0]}
                | {32{counter == 6'd27}} & {S[31:6],~sub_C[32],S[4:0]}
                | {32{counter == 6'd28}} & {S[31:5],~sub_C[32],S[3:0]}
                | {32{counter == 6'd29}} & {S[31:4],~sub_C[32],S[2:0]}
                | {32{counter == 6'd30}} & {S[31:3],~sub_C[32],S[1:0]}
                | {32{counter == 6'd31}} & {S[31:2],~sub_C[32],S[0]}
                | {32{counter == 6'd32}} & {S[31:1],~sub_C[32]};

endmodule

module count_zero(
    input [31:0] X,
    output [5:0] count
);

assign count =    {5{X[31] == 1'd1}} & 5'd0
                | {5{X[31:30] == 2'd1}} & 5'd1
                | {5{X[31:29] == 3'd1}} & 5'd2
                | {5{X[31:28] == 4'd1}} & 5'd3
                | {5{X[31:27] == 5'd1}} & 5'd4
                | {5{X[31:26] == 6'd1}} & 5'd5
                | {5{X[31:25] == 7'd1}} & 5'd6
                | {5{X[31:24] == 8'd1}} & 5'd7
                | {5{X[31:23] == 9'd1}} & 5'd8
                | {5{X[31:22] == 10'd1}} & 5'd9
                | {5{X[31:21] == 11'd1}} & 5'd10
                | {5{X[31:20] == 12'd1}} & 5'd11
                | {5{X[31:19] == 13'd1}} & 5'd12
                | {5{X[31:18] == 14'd1}} & 5'd13
                | {5{X[31:17] == 15'd1}} & 5'd14
                | {5{X[31:16] == 16'd1}} & 5'd15
                | {5{X[31:15] == 17'd1}} & 5'd16
                | {5{X[31:14] == 18'd1}} & 5'd17
                | {5{X[31:13] == 19'd1}} & 5'd18
                | {5{X[31:12] == 20'd1}} & 5'd19
                | {5{X[31:11] == 21'd1}} & 5'd20
                | {5{X[31:10] == 22'd1}} & 5'd21
                | {5{X[31:9] == 23'd1}} & 5'd22
                | {5{X[31:8] == 24'd1}} & 5'd23
                | {5{X[31:7] == 25'd1}} & 5'd24
                | {5{X[31:6] == 26'd1}} & 5'd25
                | {5{X[31:5] == 27'd1}} & 5'd26
                | {5{X[31:4] == 28'd1}} & 5'd27
                | {5{X[31:3] == 29'd1}} & 5'd28
                | {5{X[31:2] == 30'd1}} & 5'd29
                | {5{X[31:1] == 31'd1}} & 5'd30
                | {5{X[31:0] == 32'd1}} & 5'd31;

endmodule