`timescale 1ns / 1ps

`define BELLEK_ADRES    32'h8000_0000
`define VERI_BIT        32
`define ADRES_BIT       32
`define YAZMAC_SAYISI   32

module islemci (
    input                       clk,
    input                       rst,
    output  [`ADRES_BIT-1:0]    bellek_adres,
    input   [`VERI_BIT-1:0]     bellek_oku_veri,
    output  [`VERI_BIT-1:0]     bellek_yaz_veri,
    output                      bellek_yaz
);

localparam GETIR        = 2'd0;
localparam COZYAZMACOKU = 2'd1;
localparam YURUTGERIYAZ = 2'd2;

reg [1:0] simdiki_asama_r;
reg [1:0] simdiki_asama_ns;
reg ilerle_cmb;
reg [31:0] buyruk_r;
reg [6:0] opcode;
reg [4:0] rs1, rs2, rd;
reg [31:0] rs1_deger, rs2_deger;
reg [2:0] funct3;
reg [6:0] funct7;
reg [31:0] imm;
reg bellek_yaz_r;
reg [`VERI_BIT-1:0] bellek_yaz_veri_r;
reg [`ADRES_BIT-1:0] bellek_adres_r;

reg [`VERI_BIT-1:0] yazmac_obegi [0:`YAZMAC_SAYISI-1];
reg [`ADRES_BIT-1:0] ps_r;

// Initialization
integer i;
initial begin
    for (i = 0; i < `YAZMAC_SAYISI; i = i + 1) begin
        yazmac_obegi[i] = 0;
    end
    simdiki_asama_r = GETIR;
    simdiki_asama_ns = GETIR;
    ilerle_cmb = 1;
    bellek_yaz_r = 0;
    bellek_adres_r = `BELLEK_ADRES;
    ps_r = `BELLEK_ADRES;
end

//state transitions
always @(posedge clk) begin
    if (rst) begin
        ps_r <= `BELLEK_ADRES;
        simdiki_asama_r <= GETIR;
        ilerle_cmb <= 1;
        bellek_yaz_r <= 0;
        bellek_adres_r <= `BELLEK_ADRES;
        for (i = 0; i < `YAZMAC_SAYISI; i = i + 1) begin
            yazmac_obegi[i] <= 0;
        end
    end
    else begin
        // State transition only when ilerle_cmb is set
        if (ilerle_cmb) begin
            simdiki_asama_r <= simdiki_asama_ns;
        end
    end
end

// Separated always block for the state machine logic
always @(*) begin
    // Default assignments
    simdiki_asama_ns = simdiki_asama_r;
    ilerle_cmb = 1;
    
    case (simdiki_asama_r)
        GETIR: begin
            simdiki_asama_ns = COZYAZMACOKU;
        end
        
        COZYAZMACOKU: begin
            simdiki_asama_ns = YURUTGERIYAZ;
        end
        
        YURUTGERIYAZ: begin
            simdiki_asama_ns = GETIR;
        end
        
        default: begin
            simdiki_asama_ns = GETIR;
        end
    endcase
end

// Separate always block for instruction execution logic
always @(posedge clk) begin
    if (!rst) begin
        case (simdiki_asama_r)
            GETIR: begin
                buyruk_r <= bellek_oku_veri;
                bellek_yaz_r <= 0;
            end
            
            COZYAZMACOKU: begin
                // Decode the instruction
                opcode <= buyruk_r[6:0];
                rd <= buyruk_r[11:7];
                funct3 <= buyruk_r[14:12];
                rs1 <= buyruk_r[19:15];
                rs2 <= buyruk_r[24:20];
                funct7 <= buyruk_r[31:25];
                
                // Extract immediate based on instruction type
                case (buyruk_r[6:0])
                    7'b0010011: imm <= {{20{buyruk_r[31]}}, buyruk_r[31:20]}; // I-type (ADDI)
                    7'b0000011: imm <= {{20{buyruk_r[31]}}, buyruk_r[31:20]}; // Load (LW)
                    7'b0100011: imm <= {{20{buyruk_r[31]}}, buyruk_r[31:25], buyruk_r[11:7]}; // Store (SW)
                    7'b1100011: imm <= {{20{buyruk_r[31]}}, buyruk_r[31], buyruk_r[7], buyruk_r[30:25], buyruk_r[11:8], 1'b0}; // Branch
                    7'b1101111: imm <= {{12{buyruk_r[31]}}, buyruk_r[19:12], buyruk_r[20], buyruk_r[30:21], 1'b0}; // JAL
                    7'b1100111: imm <= {{20{buyruk_r[31]}}, buyruk_r[31:20]}; // JALR
                    7'b0110111: imm <= {buyruk_r[31:12], 12'b0}; // LUI
                    7'b0010111: imm <= {buyruk_r[31:12], 12'b0}; // AUIPC
                    default: imm <= 32'b0;
                endcase
                
                // Read register values for execution
                rs1_deger <= yazmac_obegi[buyruk_r[19:15]];
                rs2_deger <= yazmac_obegi[buyruk_r[24:20]];
                
                // Prepare memory address for load/store instructions
                if (buyruk_r[6:0] == 7'b0000011) begin // LW
                    bellek_adres_r <= yazmac_obegi[buyruk_r[19:15]] + {{20{buyruk_r[31]}}, buyruk_r[31:20]};
                end
                else if (buyruk_r[6:0] == 7'b0100011) begin // SW
                    bellek_adres_r <= yazmac_obegi[buyruk_r[19:15]] + {{20{buyruk_r[31]}}, buyruk_r[31:25], buyruk_r[11:7]};
                    bellek_yaz_veri_r <= yazmac_obegi[buyruk_r[24:20]];
                    bellek_yaz_r <= 1;
                end
            end
            
            YURUTGERIYAZ: begin
                case (opcode)
                    7'b0010011: begin // ADDI
                        if (rd != 0) begin
                            yazmac_obegi[rd] <= rs1_deger + imm;
                        end
                        ps_r <= ps_r + 4;
                    end
                    
                    7'b0110011: begin // R-Type (ADD, SUB, AND, OR, XOR)
                        if (rd != 0) begin
                            case (funct3)
                                3'b000: yazmac_obegi[rd] <= (funct7 == 7'b0100000) ? (rs1_deger - rs2_deger) : (rs1_deger + rs2_deger);
                                3'b111: yazmac_obegi[rd] <= rs1_deger & rs2_deger;
                                3'b110: yazmac_obegi[rd] <= rs1_deger | rs2_deger;
                                3'b100: yazmac_obegi[rd] <= rs1_deger ^ rs2_deger;
                            endcase
                        end
                        ps_r <= ps_r + 4;
                    end
                    
                    7'b0000011: begin // LW (Load Word)
                        if (rd != 0) begin
                            yazmac_obegi[rd] <= bellek_oku_veri;
                        end
                        ps_r <= ps_r + 4;
                    end
                    
                    7'b0100011: begin // SW (Store Word)
                        bellek_yaz_veri_r <= rs2_deger;
                        ps_r <= ps_r + 4;
                    end
                    
                    7'b1100011: begin // BEQ
                        if (funct3 == 3'b000) begin
                            if (rs1_deger == rs2_deger) begin
                                ps_r <= ps_r + imm;
                            end else begin
                                ps_r <= ps_r + 4;
                            end
                        end else begin
                            ps_r <= ps_r + 4;
                        end
                    end
                    
                    7'b1101111: begin // JAL
                        if (rd != 0) begin
                            yazmac_obegi[rd] <= ps_r + 4;
                        end
                        ps_r <= ps_r + imm;
                    end
                    
                    7'b1100111: begin // JALR
                        if (rd != 0) begin
                            yazmac_obegi[rd] <= ps_r + 4;
                        end
                        ps_r <= (rs1_deger + imm) & ~1;
                    end
                    
                    7'b0110111: begin // LUI
                        if (rd != 0) begin
                            yazmac_obegi[rd] <= imm;
                        end
                        ps_r <= ps_r + 4;
                    end
                    
                    7'b0010111: begin // AUIPC
                        if (rd != 0) begin
                            yazmac_obegi[rd] <= ps_r + imm;
                        end
                        ps_r <= ps_r + 4;
                    end
                    
                    default: begin
                        ps_r <= ps_r + 4;
                    end
                endcase
            end
        endcase
    end
end


assign bellek_adres = (simdiki_asama_r == GETIR) ? ps_r : 
                      ((simdiki_asama_r == COZYAZMACOKU || simdiki_asama_r == YURUTGERIYAZ) && 
                       (opcode == 7'b0000011 || opcode == 7'b0100011)) ? bellek_adres_r : ps_r;
assign bellek_yaz_veri = bellek_yaz_veri_r;
assign bellek_yaz = bellek_yaz_r;

endmodule