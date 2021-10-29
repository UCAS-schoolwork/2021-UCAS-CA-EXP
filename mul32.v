
module mul32(
    input clk,
    input resetn,
    input is_signed,
    input [31:0] A,
    input [31:0] B,
    output [63:0] product
);
wire [65:0] p33;
wire [32:0] a33;
wire [32:0] b33;
assign a33 = {A[31] & is_signed, A[31:0]};
assign b33 = {B[31] & is_signed, B[31:0]};
assign product = p33[63:0];

mul33 m33(
    .clk(clk),
    .resetn(resetn),
    .A(a33),
    .B(b33),
    .product(p33)
);

endmodule


module mul33(
    input clk,
    input resetn,
    input [32:0] A,
    input [32:0] B,
    output [65:0] product
);
wire [65:0] p [16:0];
wire [16:0] c;
wire [65:0] X [16:0];

assign X[0] = {{33{A[32]}},A[32:0]};
assign X[1] = {{31{A[32]}},A[32:0],2'b0};
assign X[2] = {{29{A[32]}},A[32:0],4'b0};
assign X[3] = {{27{A[32]}},A[32:0],6'b0};
assign X[4] = {{25{A[32]}},A[32:0],8'b0};
assign X[5] = {{23{A[32]}},A[32:0],10'b0};
assign X[6] = {{21{A[32]}},A[32:0],12'b0};
assign X[7] = {{19{A[32]}},A[32:0],14'b0};
assign X[8] = {{17{A[32]}},A[32:0],16'b0};
assign X[9] = {{15{A[32]}},A[32:0],18'b0};
assign X[10] = {{13{A[32]}},A[32:0],20'b0};
assign X[11] = {{11{A[32]}},A[32:0],22'b0};
assign X[12] = {{9{A[32]}},A[32:0],24'b0};
assign X[13] = {{7{A[32]}},A[32:0],26'b0};
assign X[14] = {{5{A[32]}},A[32:0],28'b0};
assign X[15] = {{3{A[32]}},A[32:0],30'b0};
assign X[16] = {A[32],A[32:0],32'b0};

booth b0(
	.y2(B[1]),
	.y1(B[0]),
	.y0(1'b0),
	.X(X[0]),
	.p(p[0]),
	.c(c[0])
);
genvar pi;
generate 
    for(pi = 1; pi<16; pi=pi+1)
        begin: booth_gen
            booth boothi(
                .y2(B[2*pi+1]),
                .y1(B[2*pi]),
                .y0(B[2*pi-1]),
                .X(X[pi]),
                .p(p[pi]),
                .c(c[pi])
            );
        end
endgenerate

//Notice that c[16] is constantly 0
booth b16(
	.y2(B[32]),
	.y1(B[32]),
	.y0(B[31]),
	.X(X[16]),
	.p(p[16]),
	.c(c[16])
);

wire [13:0] cout[65:0];
wire [65:0] C;
wire [65:0] S;
Wallace w0(
    .n0(p[0][0]),
    .n1(p[1][0]),
    .n2(p[2][0]),
    .n3(p[3][0]),
    .n4(p[4][0]),
    .n5(p[5][0]),
    .n6(p[6][0]),
    .n7(p[7][0]),
    .n8(p[8][0]),
    .n9(p[9][0]),
    .n10(p[10][0]),
    .n11(p[11][0]),
    .n12(p[12][0]),
    .n13(p[13][0]),
    .n14(p[14][0]),
    .n15(p[15][0]),
    .n16(p[16][0]),
    .cin0(c[0]),
    .cin1(c[1]),
    .cin2(c[2]),
    .cin3(c[3]),
    .cin4(c[4]),
    .cin5(c[5]),
    .cin6(c[6]),
    .cin7(c[7]),
    .cin8(c[8]),
    .cin9(c[9]),
    .cin10(c[10]),
    .cin11(c[11]),
    .cin12(c[12]),
    .cin13(c[13]),
    .c11(cout[0][0]),
    .c12(cout[0][1]),
    .c13(cout[0][2]),
    .c14(cout[0][3]),
    .c15(cout[0][4]),
    .c21(cout[0][5]),
    .c22(cout[0][6]),
    .c23(cout[0][7]),
    .c24(cout[0][8]),
    .c31(cout[0][9]),
    .c32(cout[0][10]),
    .c41(cout[0][11]),
    .c42(cout[0][12]),
    .c51(cout[0][13]),
    .c61(C[0]),
    .s61(S[0])
);
genvar wi;
generate 
    for(wi = 1; wi<66; wi=wi+1)
        begin: Wallace_gen
            Wallace wallacei(
                .n0(p[0][wi]),
                .n1(p[1][wi]),
                .n2(p[2][wi]),
                .n3(p[3][wi]),
                .n4(p[4][wi]),
                .n5(p[5][wi]),
                .n6(p[6][wi]),
                .n7(p[7][wi]),
                .n8(p[8][wi]),
                .n9(p[9][wi]),
                .n10(p[10][wi]),
                .n11(p[11][wi]),
                .n12(p[12][wi]),
                .n13(p[13][wi]),
                .n14(p[14][wi]),
                .n15(p[15][wi]),
                .n16(p[16][wi]),
                .cin0(cout[wi-1][0]),
                .cin1(cout[wi-1][1]),
                .cin2(cout[wi-1][2]),
                .cin3(cout[wi-1][3]),
                .cin4(cout[wi-1][4]),
                .cin5(cout[wi-1][5]),
                .cin6(cout[wi-1][6]),
                .cin7(cout[wi-1][7]),
                .cin8(cout[wi-1][8]),
                .cin9(cout[wi-1][9]),
                .cin10(cout[wi-1][10]),
                .cin11(cout[wi-1][11]),
                .cin12(cout[wi-1][12]),
                .cin13(cout[wi-1][13]),
                .c11(cout[wi][0]),
                .c12(cout[wi][1]),
                .c13(cout[wi][2]),
                .c14(cout[wi][3]),
                .c15(cout[wi][4]),
                .c21(cout[wi][5]),
                .c22(cout[wi][6]),
                .c23(cout[wi][7]),
                .c24(cout[wi][8]),
                .c31(cout[wi][9]),
                .c32(cout[wi][10]),
                .c41(cout[wi][11]),
                .c42(cout[wi][12]),
                .c51(cout[wi][13]),
                .c61(C[wi]),
                .s61(S[wi])
            );
        end
endgenerate

wire [65:0] in_A;
wire [65:0] in_B;
assign in_A = S;
assign in_B = {C[64:0],c[14]};

reg [65:0] in_A_r;
reg [65:0] in_B_r;
reg cin_r;
always @(posedge clk) begin
    if(!resetn) begin
        in_A_r <= 66'd0;
        in_B_r <= 66'd0;
        cin_r  <= 1'd0;
    end
    else begin 
        in_A_r <= in_A;
        in_B_r <= in_B;
        cin_r  <= c[15];
    end
end

adder66 add66(
	.cin(cin_r),
	.A(in_A_r),
	.B(in_B_r),
	.sum(product),
	.cout()
);


endmodule

module booth(
    input y2,
    input y1,
    input y0,
    input [65:0] X,
    output [65:0] p,
    output c
);

wire addx,add2x,subx,sub2x;
assign addx = ~y2&y1&~y0|~y2&~y1&y0;
assign add2x = ~y2&y1&y0;
assign subx = y2&y1&~y0|y2&~y1&y0;
assign sub2x = y2&~y1&~y0;
assign c = subx | sub2x;
assign p[0] = subx&~X[0] | addx&X[0] | sub2x;
genvar nbit;
generate 
    for(nbit = 1; nbit<66; nbit = nbit+1)
        begin: kkk
            assign p[nbit] = subx&~X[nbit]|sub2x&~X[nbit-1]|addx&X[nbit]|add2x&X[nbit-1];
        end
    
endgenerate

endmodule

module Full_adder(
    input A,
    input B,
    input cin,
    output sum,
    output cout
);
assign sum = ~A & ~B & cin | ~A & B & ~cin | A & ~B & ~cin | A & B & cin;
assign cout = A & B | A & cin | B & cin;

endmodule

module Wallace(
    input n0,
    input n1,
    input n2,
    input n3,
    input n4,
    input n5,
    input n6,
    input n7,
    input n8,
    input n9,
    input n10,
    input n11,
    input n12,
    input n13,
    input n14,
    input n15,
    input n16,
    input cin0,
    input cin1,
    input cin2,
    input cin3,
    input cin4,
    input cin5,
    input cin6,
    input cin7,
    input cin8,
    input cin9,
    input cin10,
    input cin11,
    input cin12,
    input cin13,
    output c11,
    output c12,
    output c13,
    output c14,
    output c15,
    output c21,
    output c22,
    output c23,
    output c24,
    output c31,
    output c32,
    output c41,
    output c42,
    output c51,
    output c61,
    output s61
);
wire s11,s12,s13,s14,s15;
wire s21,s22,s23,s24;
wire s31,s32;
wire s41,s42;
wire s51;

Full_adder a11(
    .A(n0),
    .B(n1),
    .cin(n2),
    .sum(s11),
    .cout(c11)
);
Full_adder a12(
    .A(n3),
    .B(n4),
    .cin(n5),
    .sum(s12),
    .cout(c12)
);
Full_adder a13(
    .A(n6),
    .B(n7),
    .cin(n8),
    .sum(s13),
    .cout(c13)
);
Full_adder a14(
    .A(n9),
    .B(n10),
    .cin(n11),
    .sum(s14),
    .cout(c14)
);
Full_adder a15(
    .A(n12),
    .B(n13),
    .cin(n14),
    .sum(s15),
    .cout(c15)
);
Full_adder a21(
    .A(s11),
    .B(s12),
    .cin(s13),
    .sum(s21),
    .cout(c21)
);
Full_adder a22(
    .A(s14),
    .B(s15),
    .cin(n15),
    .sum(s22),
    .cout(c22)
);
Full_adder a23(
    .A(cin0),
    .B(cin1),
    .cin(cin2),
    .sum(s23),
    .cout(c23)
);
Full_adder a24(
    .A(cin3),
    .B(cin4),
    .cin(n16),
    .sum(s24),
    .cout(c24)
);
Full_adder a31(
    .A(s21),
    .B(s22),
    .cin(s23),
    .sum(s31),
    .cout(c31)
);
Full_adder a32(
    .A(s24),
    .B(cin5),
    .cin(cin6),
    .sum(s32),
    .cout(c32)
);
Full_adder a41(
    .A(s31),
    .B(s32),
    .cin(cin7),
    .sum(s41),
    .cout(c41)
);
Full_adder a42(
    .A(cin8),
    .B(cin9),
    .cin(cin10),
    .sum(s42),
    .cout(c42)
);
Full_adder a51(
    .A(s41),
    .B(s42),
    .cin(cin11),
    .sum(s51),
    .cout(c51)
);
Full_adder a61(
    .A(s51),
    .B(cin12),
    .cin(cin13),
    .sum(s61),
    .cout(c61)
);

endmodule


module adder66(
    input cin,
    input [65:0] A,
    input [65:0] B,
    output [65:0] sum,
    output cout
);

assign sum = A + B + cin;
assign cout = 0;

endmodule


