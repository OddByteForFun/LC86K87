default Order dec

$include <prelude.sail>

register A : bits(8)
register B : bits(8)
register C : bits(8)
register SP : bits(8)
register PC : bits(16)
register PSW : bits(8)

/* Parité impaire (P = 1 si nombre impair de bits à 1) */
val parity8 : bits(8) -> bit
function parity8(v) = {
    var p : bit = bitzero;
    foreach (i from 0 to 7) {
        if v[i] == bitone then {
            p = if p == bitzero then bitone else bitzero
        }
    };
    p
}

/* Exécution formelle de ADD A, #imm */
val step_add_imm : bits(8) -> unit
function step_add_imm(imm) = {
    let a_val : bits(8) = A;
    let sum9 : bits(9) = (0b0 @ a_val) + (0b0 @ imm);
    let half5 : bits(5) = (0b0 @ a_val[3..0]) + (0b0 @ imm[3..0]);
    let res : bits(8) = sum9[7..0];

    let cy : bit = sum9[8];
    let ac : bit = half5[4];

    let sa : bit = a_val[7];
    let sv : bit = imm[7];
    let sr : bit = res[7];
    let ov : bit = if (sa == sv) & (sa != sr) then bitone else bitzero;
    let p : bit = parity8(res);

    A = res;
    var psw_val : bits(8) = PSW;
    psw_val[7] = cy;
    psw_val[6] = ac;
    psw_val[2] = ov;
    psw_val[0] = p;
    PSW = psw_val
}

/* Exécution formelle de SUB A, #imm */
val step_sub_imm : bits(8) -> unit
function step_sub_imm(imm) = {
    let a_val : bits(8) = A;
    let diff9 : bits(9) = sub_bits(0b0 @ a_val, 0b0 @ imm);
    let res : bits(8) = diff9[7..0];

    let cy : bit = if unsigned(a_val) < unsigned(imm) then bitone else bitzero;
    let ac : bit = if unsigned(a_val[3..0]) < unsigned(imm[3..0]) then bitone else bitzero;

    let sa : bit = a_val[7];
    let sv : bit = imm[7];
    let sr : bit = res[7];
    let ov : bit = if (sa != sv) & (sa != sr) then bitone else bitzero;
    let p : bit = parity8(res);

    A = res;
    var psw_val : bits(8) = PSW;
    psw_val[7] = cy;
    psw_val[6] = ac;
    psw_val[2] = ov;
    psw_val[0] = p;
    PSW = psw_val
}

/* Exécution formelle de AND A, #imm */
val step_and_imm : bits(8) -> unit
function step_and_imm(imm) = {
    let res : bits(8) = A & imm;
    A = res;
    var psw_val : bits(8) = PSW;
    psw_val[0] = parity8(res);
    PSW = psw_val
}

/* Exécution formelle de OR A, #imm */
val step_or_imm : bits(8) -> unit
function step_or_imm(imm) = {
    let res : bits(8) = A | imm;
    A = res;
    var psw_val : bits(8) = PSW;
    psw_val[0] = parity8(res);
    PSW = psw_val
}

/* Exécution formelle de XOR A, #imm */
val step_xor_imm : bits(8) -> unit
function step_xor_imm(imm) = {
    let res : bits(8) = xor_vec(A, imm);
    A = res;
    var psw_val : bits(8) = PSW;
    psw_val[0] = parity8(res);
    PSW = psw_val
}

/* Exécution formelle de ROL A (rotation circulaire simple, CY inchangé) */
val step_rol : unit -> unit
function step_rol() = {
    let a_val : bits(8) = A;
    let res : bits(8) = (a_val[6..0] @ a_val[7..7]);
    A = res
}

/* Exécution formelle de ROR A (rotation circulaire simple, CY inchangé) */
val step_ror : unit -> unit
function step_ror() = {
    let a_val : bits(8) = A;
    let res : bits(8) = (a_val[0..0] @ a_val[7..1]);
    A = res
}

/* Exécution formelle de ROLC A (rotation à travers Carry) */
val step_rolc : unit -> unit
function step_rolc() = {
    let a_val : bits(8) = A;
    let psw_val : bits(8) = PSW;
    let old_cy : bit = psw_val[7];
    let new_cy : bit = a_val[7];
    let res : bits(8) = (a_val[6..0] @ [old_cy]);
    A = res;
    var new_psw : bits(8) = PSW;
    new_psw[7] = new_cy;
    PSW = new_psw
}

/* Exécution formelle de RORC A (rotation à travers Carry) */
val step_rorc : unit -> unit
function step_rorc() = {
    let a_val : bits(8) = A;
    let psw_val : bits(8) = PSW;
    let old_cy : bit = psw_val[7];
    let new_cy : bit = a_val[0];
    let res : bits(8) = ([old_cy] @ a_val[7..1]);
    A = res;
    var new_psw : bits(8) = PSW;
    new_psw[7] = new_cy;
    PSW = new_psw
}

/* Extension de signe 8 bits vers 16 bits */
val sign_ext8 : bits(8) -> bits(16)
function sign_ext8(b) = {
    if b[7] == bitone then (0xFF @ b) else (0x00 @ b)
}

/* Exécution formelle de BZ #rel */
val step_bz : bits(8) -> unit
function step_bz(offset) = {
    let next_pc : bits(16) = PC + 2;
    if A == 0x00 then {
        PC = next_pc + sign_ext8(offset)
    } else {
        PC = next_pc
    }
}

/* Exécution formelle de BNZ #rel */
val step_bnz : bits(8) -> unit
function step_bnz(offset) = {
    let next_pc : bits(16) = PC + 2;
    if A != 0x00 then {
        PC = next_pc + sign_ext8(offset)
    } else {
        PC = next_pc
    }
}

/* Getters et setters pour interfaçage C / Zig */
val get_A : unit -> bits(8)
function get_A() = A

val set_A : bits(8) -> unit
function set_A(v) = { A = v }

val get_PSW : unit -> bits(8)
function get_PSW() = PSW

val set_PSW : bits(8) -> unit
function set_PSW(v) = { PSW = v }

val get_PC : unit -> bits(16)
function get_PC() = PC

val set_PC : bits(16) -> unit
function set_PC(v) = { PC = v }

val main : unit -> unit
function main() = ()
