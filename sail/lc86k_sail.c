#include "sail.h"
#include "sail_config.h"
#include "rts.h"
#include "elf.h"
#ifdef __cplusplus
extern "C" {
#endif
void (*sail_rts_set_coverage_file)(const char *) = NULL;
#include "lc86k_sail.h"

static void CREATE(zexception)(struct zexception *op) {
  op->kind = Kind_z__dummy_exnz3;
}

static void RECREATE(zexception)(struct zexception *op) {

}

static void KILL(zexception)(struct zexception *op) {

}

static void COPY(zexception)(struct zexception *rop, struct zexception op) {
  ;
  rop->kind = op.kind;
  switch (op.kind) {
  case Kind_z__dummy_exnz3: {
    rop->variants.z__dummy_exnz3 = op.variants.z__dummy_exnz3;
    break;
  }
  }
}

static bool EQUAL(zexception)(struct zexception op1, struct zexception op2) {
  if (op1.kind != op2.kind) {
    return false;
  }
  switch (op1.kind) {
  case Kind_z__dummy_exnz3: {
    return EQUAL(unit)(op1.variants.z__dummy_exnz3, op2.variants.z__dummy_exnz3);
    break;
  }
  }
  return false;
}

static void z__dummy_exnz3(struct zexception *rop, unit op) {

  rop->kind = Kind_z__dummy_exnz3;
  rop->variants.z__dummy_exnz3 = op;
}

struct zexception *current_exception = NULL;

bool have_exception = false;

sail_string *throw_location = NULL;

// register zA
uint64_t zA;

// register zB
uint64_t zB;

// register zC
uint64_t zC;

// register zSP
uint64_t zSP;

// register zPC
uint64_t zPC;

// register zPSW
uint64_t zPSW;

static const size_t SAIL_TEST_COUNT = 0;
static unit (*const SAIL_TESTS[1])(unit) = {
  NULL
};
static const char* const SAIL_TEST_NAMES[1] = {
  NULL
};

uint64_t zparity8(uint64_t zv)
{
  uint64_t z8zE1;
  uint64_t zp;
  zp = UINT64_C(0b0);
  int64_t z3zE38;
  {    z3zE38 = INT64_C(0);
  }
  int64_t z3zE39;
  {    z3zE39 = INT64_C(7);
  }
  int64_t z3zE40;
  {    z3zE40 = INT64_C(1);
  }
  {
    int64_t zi;
    zi = z3zE38;
    unit z3zE41;
  for_start_62: ;
    {
      if ((zi > z3zE39)) goto for_end_63;
      bool z2zE36;
      {
        uint64_t z2zE35;
        {
          lbits z3zE45;
          CREATE(lbits)(&z3zE45);
          CONVERT_OF(lbits, fbits)(&z3zE45, zv, UINT64_C(8) , true);
          sail_int z3zE46;
          CREATE(sail_int)(&z3zE46);
          CONVERT_OF(sail_int, mach_int)(&z3zE46, zi);
          z2zE35 = bitvector_access(z3zE45, z3zE46);
          KILL(sail_int)(&z3zE46);
          KILL(lbits)(&z3zE45);
        }
        {
          lbits z3zE43;
          CREATE(lbits)(&z3zE43);
          CONVERT_OF(lbits, fbits)(&z3zE43, z2zE35, UINT64_C(1) , true);
          lbits z3zE44;
          CREATE(lbits)(&z3zE44);
          CONVERT_OF(lbits, fbits)(&z3zE44, UINT64_C(0b1), UINT64_C(1) , true);
          z2zE36 = eq_bits(z3zE43, z3zE44);
          KILL(lbits)(&z3zE44);
          KILL(lbits)(&z3zE43);
        }
      }
      if (z2zE36) {
        bool z2zE37;
        {
          lbits z3zE47;
          CREATE(lbits)(&z3zE47);
          CONVERT_OF(lbits, fbits)(&z3zE47, zp, UINT64_C(1) , true);
          lbits z3zE48;
          CREATE(lbits)(&z3zE48);
          CONVERT_OF(lbits, fbits)(&z3zE48, UINT64_C(0b0), UINT64_C(1) , true);
          z2zE37 = eq_bits(z3zE47, z3zE48);
          KILL(lbits)(&z3zE48);
          KILL(lbits)(&z3zE47);
        }
        if (z2zE37) {  zp = UINT64_C(0b1);  } else {  zp = UINT64_C(0b0);  }
        z3zE41 = UNIT;
      } else {  z3zE41 = UNIT;  }
      zi = (zi + z3zE40);
      goto for_start_62;
    }
  for_end_63: ;
  }
  unit z3zE42;
  z3zE42 = UNIT;
  z8zE1 = zp;
end_function_64: ;
  return z8zE1;
end_block_exception_65: ;

  return UINT64_C(0);
}

unit zstep_add_imm(uint64_t zimm)
{
  unit z8zE2;
  uint64_t za_val;
  za_val = zA;
  uint64_t zsum9;
  {
    uint64_t z2zE33;
    {
      lbits z3zE55;
      CREATE(lbits)(&z3zE55);
      CONVERT_OF(lbits, fbits)(&z3zE55, UINT64_C(0b0), UINT64_C(1) , true);
      lbits z3zE56;
      CREATE(lbits)(&z3zE56);
      CONVERT_OF(lbits, fbits)(&z3zE56, za_val, UINT64_C(8) , true);
      lbits z3zE57;
      CREATE(lbits)(&z3zE57);
      append(&z3zE57, z3zE55, z3zE56);
      z2zE33 = CONVERT_OF(fbits, lbits)(z3zE57, true);
      KILL(lbits)(&z3zE57);
      KILL(lbits)(&z3zE56);
      KILL(lbits)(&z3zE55);
    }
    uint64_t z2zE34;
    {
      lbits z3zE52;
      CREATE(lbits)(&z3zE52);
      CONVERT_OF(lbits, fbits)(&z3zE52, UINT64_C(0b0), UINT64_C(1) , true);
      lbits z3zE53;
      CREATE(lbits)(&z3zE53);
      CONVERT_OF(lbits, fbits)(&z3zE53, zimm, UINT64_C(8) , true);
      lbits z3zE54;
      CREATE(lbits)(&z3zE54);
      append(&z3zE54, z3zE52, z3zE53);
      z2zE34 = CONVERT_OF(fbits, lbits)(z3zE54, true);
      KILL(lbits)(&z3zE54);
      KILL(lbits)(&z3zE53);
      KILL(lbits)(&z3zE52);
    }
    {
      lbits z3zE49;
      CREATE(lbits)(&z3zE49);
      CONVERT_OF(lbits, fbits)(&z3zE49, z2zE33, UINT64_C(9) , true);
      lbits z3zE50;
      CREATE(lbits)(&z3zE50);
      CONVERT_OF(lbits, fbits)(&z3zE50, z2zE34, UINT64_C(9) , true);
      lbits z3zE51;
      CREATE(lbits)(&z3zE51);
      add_bits(&z3zE51, z3zE49, z3zE50);
      zsum9 = CONVERT_OF(fbits, lbits)(z3zE51, true);
      KILL(lbits)(&z3zE51);
      KILL(lbits)(&z3zE50);
      KILL(lbits)(&z3zE49);
    }
  }
  uint64_t zhalf5;
  {
    uint64_t z2zE31;
    {
      uint64_t z2zE29;
      {
        lbits z3zE61;
        CREATE(lbits)(&z3zE61);
        CONVERT_OF(lbits, fbits)(&z3zE61, za_val, UINT64_C(8) , true);
        sail_int z3zE62;
        CREATE(sail_int)(&z3zE62);
        CONVERT_OF(sail_int, mach_int)(&z3zE62, INT64_C(3));
        sail_int z3zE63;
        CREATE(sail_int)(&z3zE63);
        CONVERT_OF(sail_int, mach_int)(&z3zE63, INT64_C(0));
        lbits z3zE64;
        CREATE(lbits)(&z3zE64);
        vector_subrange_lbits(&z3zE64, z3zE61, z3zE62, z3zE63);
        z2zE29 = CONVERT_OF(fbits, lbits)(z3zE64, true);
        KILL(lbits)(&z3zE64);
        KILL(sail_int)(&z3zE63);
        KILL(sail_int)(&z3zE62);
        KILL(lbits)(&z3zE61);
      }
      {
        lbits z3zE58;
        CREATE(lbits)(&z3zE58);
        CONVERT_OF(lbits, fbits)(&z3zE58, UINT64_C(0b0), UINT64_C(1) , true);
        lbits z3zE59;
        CREATE(lbits)(&z3zE59);
        CONVERT_OF(lbits, fbits)(&z3zE59, z2zE29, UINT64_C(4) , true);
        lbits z3zE60;
        CREATE(lbits)(&z3zE60);
        append(&z3zE60, z3zE58, z3zE59);
        z2zE31 = CONVERT_OF(fbits, lbits)(z3zE60, true);
        KILL(lbits)(&z3zE60);
        KILL(lbits)(&z3zE59);
        KILL(lbits)(&z3zE58);
      }
    }
    uint64_t z2zE32;
    {
      uint64_t z2zE30;
      {
        lbits z3zE68;
        CREATE(lbits)(&z3zE68);
        CONVERT_OF(lbits, fbits)(&z3zE68, zimm, UINT64_C(8) , true);
        sail_int z3zE69;
        CREATE(sail_int)(&z3zE69);
        CONVERT_OF(sail_int, mach_int)(&z3zE69, INT64_C(3));
        sail_int z3zE70;
        CREATE(sail_int)(&z3zE70);
        CONVERT_OF(sail_int, mach_int)(&z3zE70, INT64_C(0));
        lbits z3zE71;
        CREATE(lbits)(&z3zE71);
        vector_subrange_lbits(&z3zE71, z3zE68, z3zE69, z3zE70);
        z2zE30 = CONVERT_OF(fbits, lbits)(z3zE71, true);
        KILL(lbits)(&z3zE71);
        KILL(sail_int)(&z3zE70);
        KILL(sail_int)(&z3zE69);
        KILL(lbits)(&z3zE68);
      }
      {
        lbits z3zE65;
        CREATE(lbits)(&z3zE65);
        CONVERT_OF(lbits, fbits)(&z3zE65, UINT64_C(0b0), UINT64_C(1) , true);
        lbits z3zE66;
        CREATE(lbits)(&z3zE66);
        CONVERT_OF(lbits, fbits)(&z3zE66, z2zE30, UINT64_C(4) , true);
        lbits z3zE67;
        CREATE(lbits)(&z3zE67);
        append(&z3zE67, z3zE65, z3zE66);
        z2zE32 = CONVERT_OF(fbits, lbits)(z3zE67, true);
        KILL(lbits)(&z3zE67);
        KILL(lbits)(&z3zE66);
        KILL(lbits)(&z3zE65);
      }
    }
    {
      lbits z3zE72;
      CREATE(lbits)(&z3zE72);
      CONVERT_OF(lbits, fbits)(&z3zE72, z2zE31, UINT64_C(5) , true);
      lbits z3zE73;
      CREATE(lbits)(&z3zE73);
      CONVERT_OF(lbits, fbits)(&z3zE73, z2zE32, UINT64_C(5) , true);
      lbits z3zE74;
      CREATE(lbits)(&z3zE74);
      add_bits(&z3zE74, z3zE72, z3zE73);
      zhalf5 = CONVERT_OF(fbits, lbits)(z3zE74, true);
      KILL(lbits)(&z3zE74);
      KILL(lbits)(&z3zE73);
      KILL(lbits)(&z3zE72);
    }
  }
  uint64_t zres;
  {
    lbits z3zE101;
    CREATE(lbits)(&z3zE101);
    CONVERT_OF(lbits, fbits)(&z3zE101, zsum9, UINT64_C(9) , true);
    sail_int z3zE102;
    CREATE(sail_int)(&z3zE102);
    CONVERT_OF(sail_int, mach_int)(&z3zE102, INT64_C(7));
    sail_int z3zE103;
    CREATE(sail_int)(&z3zE103);
    CONVERT_OF(sail_int, mach_int)(&z3zE103, INT64_C(0));
    lbits z3zE104;
    CREATE(lbits)(&z3zE104);
    vector_subrange_lbits(&z3zE104, z3zE101, z3zE102, z3zE103);
    zres = CONVERT_OF(fbits, lbits)(z3zE104, true);
    KILL(lbits)(&z3zE104);
    KILL(sail_int)(&z3zE103);
    KILL(sail_int)(&z3zE102);
    KILL(lbits)(&z3zE101);
  }
  uint64_t zcy;
  {
    lbits z3zE99;
    CREATE(lbits)(&z3zE99);
    CONVERT_OF(lbits, fbits)(&z3zE99, zsum9, UINT64_C(9) , true);
    sail_int z3zE100;
    CREATE(sail_int)(&z3zE100);
    CONVERT_OF(sail_int, mach_int)(&z3zE100, INT64_C(8));
    zcy = bitvector_access(z3zE99, z3zE100);
    KILL(sail_int)(&z3zE100);
    KILL(lbits)(&z3zE99);
  }
  uint64_t zac;
  {
    lbits z3zE97;
    CREATE(lbits)(&z3zE97);
    CONVERT_OF(lbits, fbits)(&z3zE97, zhalf5, UINT64_C(5) , true);
    sail_int z3zE98;
    CREATE(sail_int)(&z3zE98);
    CONVERT_OF(sail_int, mach_int)(&z3zE98, INT64_C(4));
    zac = bitvector_access(z3zE97, z3zE98);
    KILL(sail_int)(&z3zE98);
    KILL(lbits)(&z3zE97);
  }
  uint64_t zsa;
  {
    lbits z3zE95;
    CREATE(lbits)(&z3zE95);
    CONVERT_OF(lbits, fbits)(&z3zE95, za_val, UINT64_C(8) , true);
    sail_int z3zE96;
    CREATE(sail_int)(&z3zE96);
    CONVERT_OF(sail_int, mach_int)(&z3zE96, INT64_C(7));
    zsa = bitvector_access(z3zE95, z3zE96);
    KILL(sail_int)(&z3zE96);
    KILL(lbits)(&z3zE95);
  }
  uint64_t zsv;
  {
    lbits z3zE93;
    CREATE(lbits)(&z3zE93);
    CONVERT_OF(lbits, fbits)(&z3zE93, zimm, UINT64_C(8) , true);
    sail_int z3zE94;
    CREATE(sail_int)(&z3zE94);
    CONVERT_OF(sail_int, mach_int)(&z3zE94, INT64_C(7));
    zsv = bitvector_access(z3zE93, z3zE94);
    KILL(sail_int)(&z3zE94);
    KILL(lbits)(&z3zE93);
  }
  uint64_t zsr;
  {
    lbits z3zE91;
    CREATE(lbits)(&z3zE91);
    CONVERT_OF(lbits, fbits)(&z3zE91, zres, UINT64_C(8) , true);
    sail_int z3zE92;
    CREATE(sail_int)(&z3zE92);
    CONVERT_OF(sail_int, mach_int)(&z3zE92, INT64_C(7));
    zsr = bitvector_access(z3zE91, z3zE92);
    KILL(sail_int)(&z3zE92);
    KILL(lbits)(&z3zE91);
  }
  uint64_t zov;
  {
    bool z2zE28;
    {
      bool z2zE27;
      {
        lbits z3zE77;
        CREATE(lbits)(&z3zE77);
        CONVERT_OF(lbits, fbits)(&z3zE77, zsa, UINT64_C(1) , true);
        lbits z3zE78;
        CREATE(lbits)(&z3zE78);
        CONVERT_OF(lbits, fbits)(&z3zE78, zsv, UINT64_C(1) , true);
        z2zE27 = eq_bits(z3zE77, z3zE78);
        KILL(lbits)(&z3zE78);
        KILL(lbits)(&z3zE77);
      }
      bool z3zE32;
      if (z2zE27) {
        {
          lbits z3zE75;
          CREATE(lbits)(&z3zE75);
          CONVERT_OF(lbits, fbits)(&z3zE75, zsa, UINT64_C(1) , true);
          lbits z3zE76;
          CREATE(lbits)(&z3zE76);
          CONVERT_OF(lbits, fbits)(&z3zE76, zsr, UINT64_C(1) , true);
          z3zE32 = neq_bits(z3zE75, z3zE76);
          KILL(lbits)(&z3zE76);
          KILL(lbits)(&z3zE75);
        }
      } else {  z3zE32 = false;  }
      z2zE28 = z3zE32;
    }
    if (z2zE28) {  zov = UINT64_C(0b1);  } else {  zov = UINT64_C(0b0);  }
  }
  uint64_t zp;
  zp = zparity8(zres);
  zA = zres;
  unit z3zE33;
  z3zE33 = UNIT;
  uint64_t zpsw_val;
  zpsw_val = zPSW;
  {
    lbits z3zE88;
    CREATE(lbits)(&z3zE88);
    CONVERT_OF(lbits, fbits)(&z3zE88, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE89;
    CREATE(sail_int)(&z3zE89);
    CONVERT_OF(sail_int, mach_int)(&z3zE89, INT64_C(7));
    lbits z3zE90;
    CREATE(lbits)(&z3zE90);
    update_lbits(&z3zE90, z3zE88, z3zE89, zcy);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE90, true);
    KILL(lbits)(&z3zE90);
    KILL(sail_int)(&z3zE89);
    KILL(lbits)(&z3zE88);
  }
  unit z3zE37;
  z3zE37 = UNIT;
  {
    lbits z3zE85;
    CREATE(lbits)(&z3zE85);
    CONVERT_OF(lbits, fbits)(&z3zE85, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE86;
    CREATE(sail_int)(&z3zE86);
    CONVERT_OF(sail_int, mach_int)(&z3zE86, INT64_C(6));
    lbits z3zE87;
    CREATE(lbits)(&z3zE87);
    update_lbits(&z3zE87, z3zE85, z3zE86, zac);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE87, true);
    KILL(lbits)(&z3zE87);
    KILL(sail_int)(&z3zE86);
    KILL(lbits)(&z3zE85);
  }
  unit z3zE36;
  z3zE36 = UNIT;
  {
    lbits z3zE82;
    CREATE(lbits)(&z3zE82);
    CONVERT_OF(lbits, fbits)(&z3zE82, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE83;
    CREATE(sail_int)(&z3zE83);
    CONVERT_OF(sail_int, mach_int)(&z3zE83, INT64_C(2));
    lbits z3zE84;
    CREATE(lbits)(&z3zE84);
    update_lbits(&z3zE84, z3zE82, z3zE83, zov);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE84, true);
    KILL(lbits)(&z3zE84);
    KILL(sail_int)(&z3zE83);
    KILL(lbits)(&z3zE82);
  }
  unit z3zE35;
  z3zE35 = UNIT;
  {
    lbits z3zE79;
    CREATE(lbits)(&z3zE79);
    CONVERT_OF(lbits, fbits)(&z3zE79, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE80;
    CREATE(sail_int)(&z3zE80);
    CONVERT_OF(sail_int, mach_int)(&z3zE80, INT64_C(0));
    lbits z3zE81;
    CREATE(lbits)(&z3zE81);
    update_lbits(&z3zE81, z3zE79, z3zE80, zp);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE81, true);
    KILL(lbits)(&z3zE81);
    KILL(sail_int)(&z3zE80);
    KILL(lbits)(&z3zE79);
  }
  unit z3zE34;
  z3zE34 = UNIT;
  zPSW = zpsw_val;
  z8zE2 = UNIT;
end_function_60: ;
  return z8zE2;
end_block_exception_61: ;

  return UNIT;
}

unit zstep_sub_imm(uint64_t zimm)
{
  unit z8zE3;
  uint64_t za_val;
  za_val = zA;
  uint64_t zdiff9;
  {
    uint64_t z2zE25;
    {
      lbits z3zE111;
      CREATE(lbits)(&z3zE111);
      CONVERT_OF(lbits, fbits)(&z3zE111, UINT64_C(0b0), UINT64_C(1) , true);
      lbits z3zE112;
      CREATE(lbits)(&z3zE112);
      CONVERT_OF(lbits, fbits)(&z3zE112, za_val, UINT64_C(8) , true);
      lbits z3zE113;
      CREATE(lbits)(&z3zE113);
      append(&z3zE113, z3zE111, z3zE112);
      z2zE25 = CONVERT_OF(fbits, lbits)(z3zE113, true);
      KILL(lbits)(&z3zE113);
      KILL(lbits)(&z3zE112);
      KILL(lbits)(&z3zE111);
    }
    uint64_t z2zE26;
    {
      lbits z3zE108;
      CREATE(lbits)(&z3zE108);
      CONVERT_OF(lbits, fbits)(&z3zE108, UINT64_C(0b0), UINT64_C(1) , true);
      lbits z3zE109;
      CREATE(lbits)(&z3zE109);
      CONVERT_OF(lbits, fbits)(&z3zE109, zimm, UINT64_C(8) , true);
      lbits z3zE110;
      CREATE(lbits)(&z3zE110);
      append(&z3zE110, z3zE108, z3zE109);
      z2zE26 = CONVERT_OF(fbits, lbits)(z3zE110, true);
      KILL(lbits)(&z3zE110);
      KILL(lbits)(&z3zE109);
      KILL(lbits)(&z3zE108);
    }
    {
      lbits z3zE105;
      CREATE(lbits)(&z3zE105);
      CONVERT_OF(lbits, fbits)(&z3zE105, z2zE25, UINT64_C(9) , true);
      lbits z3zE106;
      CREATE(lbits)(&z3zE106);
      CONVERT_OF(lbits, fbits)(&z3zE106, z2zE26, UINT64_C(9) , true);
      lbits z3zE107;
      CREATE(lbits)(&z3zE107);
      sub_bits(&z3zE107, z3zE105, z3zE106);
      zdiff9 = CONVERT_OF(fbits, lbits)(z3zE107, true);
      KILL(lbits)(&z3zE107);
      KILL(lbits)(&z3zE106);
      KILL(lbits)(&z3zE105);
    }
  }
  uint64_t zres;
  {
    lbits z3zE156;
    CREATE(lbits)(&z3zE156);
    CONVERT_OF(lbits, fbits)(&z3zE156, zdiff9, UINT64_C(9) , true);
    sail_int z3zE157;
    CREATE(sail_int)(&z3zE157);
    CONVERT_OF(sail_int, mach_int)(&z3zE157, INT64_C(7));
    sail_int z3zE158;
    CREATE(sail_int)(&z3zE158);
    CONVERT_OF(sail_int, mach_int)(&z3zE158, INT64_C(0));
    lbits z3zE159;
    CREATE(lbits)(&z3zE159);
    vector_subrange_lbits(&z3zE159, z3zE156, z3zE157, z3zE158);
    zres = CONVERT_OF(fbits, lbits)(z3zE159, true);
    KILL(lbits)(&z3zE159);
    KILL(sail_int)(&z3zE158);
    KILL(sail_int)(&z3zE157);
    KILL(lbits)(&z3zE156);
  }
  uint64_t zcy;
  {
    bool z2zE24;
    {
      int64_t z2zE22;
      {
        lbits z3zE118;
        CREATE(lbits)(&z3zE118);
        CONVERT_OF(lbits, fbits)(&z3zE118, za_val, UINT64_C(8) , true);
        sail_int z3zE119;
        CREATE(sail_int)(&z3zE119);
        sail_unsigned(&z3zE119, z3zE118);
        z2zE22 = CONVERT_OF(mach_int, sail_int)(z3zE119);
        KILL(sail_int)(&z3zE119);
        KILL(lbits)(&z3zE118);
      }
      int64_t z2zE23;
      {
        lbits z3zE116;
        CREATE(lbits)(&z3zE116);
        CONVERT_OF(lbits, fbits)(&z3zE116, zimm, UINT64_C(8) , true);
        sail_int z3zE117;
        CREATE(sail_int)(&z3zE117);
        sail_unsigned(&z3zE117, z3zE116);
        z2zE23 = CONVERT_OF(mach_int, sail_int)(z3zE117);
        KILL(sail_int)(&z3zE117);
        KILL(lbits)(&z3zE116);
      }
      {
        sail_int z3zE114;
        CREATE(sail_int)(&z3zE114);
        CONVERT_OF(sail_int, mach_int)(&z3zE114, z2zE22);
        sail_int z3zE115;
        CREATE(sail_int)(&z3zE115);
        CONVERT_OF(sail_int, mach_int)(&z3zE115, z2zE23);
        z2zE24 = lt(z3zE114, z3zE115);
        KILL(sail_int)(&z3zE115);
        KILL(sail_int)(&z3zE114);
      }
    }
    if (z2zE24) {  zcy = UINT64_C(0b1);  } else {  zcy = UINT64_C(0b0);  }
  }
  uint64_t zac;
  {
    bool z2zE21;
    {
      int64_t z2zE19;
      {
        uint64_t z2zE17;
        {
          lbits z3zE122;
          CREATE(lbits)(&z3zE122);
          CONVERT_OF(lbits, fbits)(&z3zE122, za_val, UINT64_C(8) , true);
          sail_int z3zE123;
          CREATE(sail_int)(&z3zE123);
          CONVERT_OF(sail_int, mach_int)(&z3zE123, INT64_C(3));
          sail_int z3zE124;
          CREATE(sail_int)(&z3zE124);
          CONVERT_OF(sail_int, mach_int)(&z3zE124, INT64_C(0));
          lbits z3zE125;
          CREATE(lbits)(&z3zE125);
          vector_subrange_lbits(&z3zE125, z3zE122, z3zE123, z3zE124);
          z2zE17 = CONVERT_OF(fbits, lbits)(z3zE125, true);
          KILL(lbits)(&z3zE125);
          KILL(sail_int)(&z3zE124);
          KILL(sail_int)(&z3zE123);
          KILL(lbits)(&z3zE122);
        }
        {
          lbits z3zE120;
          CREATE(lbits)(&z3zE120);
          CONVERT_OF(lbits, fbits)(&z3zE120, z2zE17, UINT64_C(4) , true);
          sail_int z3zE121;
          CREATE(sail_int)(&z3zE121);
          sail_unsigned(&z3zE121, z3zE120);
          z2zE19 = CONVERT_OF(mach_int, sail_int)(z3zE121);
          KILL(sail_int)(&z3zE121);
          KILL(lbits)(&z3zE120);
        }
      }
      int64_t z2zE20;
      {
        uint64_t z2zE18;
        {
          lbits z3zE128;
          CREATE(lbits)(&z3zE128);
          CONVERT_OF(lbits, fbits)(&z3zE128, zimm, UINT64_C(8) , true);
          sail_int z3zE129;
          CREATE(sail_int)(&z3zE129);
          CONVERT_OF(sail_int, mach_int)(&z3zE129, INT64_C(3));
          sail_int z3zE130;
          CREATE(sail_int)(&z3zE130);
          CONVERT_OF(sail_int, mach_int)(&z3zE130, INT64_C(0));
          lbits z3zE131;
          CREATE(lbits)(&z3zE131);
          vector_subrange_lbits(&z3zE131, z3zE128, z3zE129, z3zE130);
          z2zE18 = CONVERT_OF(fbits, lbits)(z3zE131, true);
          KILL(lbits)(&z3zE131);
          KILL(sail_int)(&z3zE130);
          KILL(sail_int)(&z3zE129);
          KILL(lbits)(&z3zE128);
        }
        {
          lbits z3zE126;
          CREATE(lbits)(&z3zE126);
          CONVERT_OF(lbits, fbits)(&z3zE126, z2zE18, UINT64_C(4) , true);
          sail_int z3zE127;
          CREATE(sail_int)(&z3zE127);
          sail_unsigned(&z3zE127, z3zE126);
          z2zE20 = CONVERT_OF(mach_int, sail_int)(z3zE127);
          KILL(sail_int)(&z3zE127);
          KILL(lbits)(&z3zE126);
        }
      }
      {
        sail_int z3zE132;
        CREATE(sail_int)(&z3zE132);
        CONVERT_OF(sail_int, mach_int)(&z3zE132, z2zE19);
        sail_int z3zE133;
        CREATE(sail_int)(&z3zE133);
        CONVERT_OF(sail_int, mach_int)(&z3zE133, z2zE20);
        z2zE21 = lt(z3zE132, z3zE133);
        KILL(sail_int)(&z3zE133);
        KILL(sail_int)(&z3zE132);
      }
    }
    if (z2zE21) {  zac = UINT64_C(0b1);  } else {  zac = UINT64_C(0b0);  }
  }
  uint64_t zsa;
  {
    lbits z3zE154;
    CREATE(lbits)(&z3zE154);
    CONVERT_OF(lbits, fbits)(&z3zE154, za_val, UINT64_C(8) , true);
    sail_int z3zE155;
    CREATE(sail_int)(&z3zE155);
    CONVERT_OF(sail_int, mach_int)(&z3zE155, INT64_C(7));
    zsa = bitvector_access(z3zE154, z3zE155);
    KILL(sail_int)(&z3zE155);
    KILL(lbits)(&z3zE154);
  }
  uint64_t zsv;
  {
    lbits z3zE152;
    CREATE(lbits)(&z3zE152);
    CONVERT_OF(lbits, fbits)(&z3zE152, zimm, UINT64_C(8) , true);
    sail_int z3zE153;
    CREATE(sail_int)(&z3zE153);
    CONVERT_OF(sail_int, mach_int)(&z3zE153, INT64_C(7));
    zsv = bitvector_access(z3zE152, z3zE153);
    KILL(sail_int)(&z3zE153);
    KILL(lbits)(&z3zE152);
  }
  uint64_t zsr;
  {
    lbits z3zE150;
    CREATE(lbits)(&z3zE150);
    CONVERT_OF(lbits, fbits)(&z3zE150, zres, UINT64_C(8) , true);
    sail_int z3zE151;
    CREATE(sail_int)(&z3zE151);
    CONVERT_OF(sail_int, mach_int)(&z3zE151, INT64_C(7));
    zsr = bitvector_access(z3zE150, z3zE151);
    KILL(sail_int)(&z3zE151);
    KILL(lbits)(&z3zE150);
  }
  uint64_t zov;
  {
    bool z2zE16;
    {
      bool z2zE15;
      {
        lbits z3zE136;
        CREATE(lbits)(&z3zE136);
        CONVERT_OF(lbits, fbits)(&z3zE136, zsa, UINT64_C(1) , true);
        lbits z3zE137;
        CREATE(lbits)(&z3zE137);
        CONVERT_OF(lbits, fbits)(&z3zE137, zsv, UINT64_C(1) , true);
        z2zE15 = neq_bits(z3zE136, z3zE137);
        KILL(lbits)(&z3zE137);
        KILL(lbits)(&z3zE136);
      }
      bool z3zE26;
      if (z2zE15) {
        {
          lbits z3zE134;
          CREATE(lbits)(&z3zE134);
          CONVERT_OF(lbits, fbits)(&z3zE134, zsa, UINT64_C(1) , true);
          lbits z3zE135;
          CREATE(lbits)(&z3zE135);
          CONVERT_OF(lbits, fbits)(&z3zE135, zsr, UINT64_C(1) , true);
          z3zE26 = neq_bits(z3zE134, z3zE135);
          KILL(lbits)(&z3zE135);
          KILL(lbits)(&z3zE134);
        }
      } else {  z3zE26 = false;  }
      z2zE16 = z3zE26;
    }
    if (z2zE16) {  zov = UINT64_C(0b1);  } else {  zov = UINT64_C(0b0);  }
  }
  uint64_t zp;
  zp = zparity8(zres);
  zA = zres;
  unit z3zE27;
  z3zE27 = UNIT;
  uint64_t zpsw_val;
  zpsw_val = zPSW;
  {
    lbits z3zE147;
    CREATE(lbits)(&z3zE147);
    CONVERT_OF(lbits, fbits)(&z3zE147, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE148;
    CREATE(sail_int)(&z3zE148);
    CONVERT_OF(sail_int, mach_int)(&z3zE148, INT64_C(7));
    lbits z3zE149;
    CREATE(lbits)(&z3zE149);
    update_lbits(&z3zE149, z3zE147, z3zE148, zcy);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE149, true);
    KILL(lbits)(&z3zE149);
    KILL(sail_int)(&z3zE148);
    KILL(lbits)(&z3zE147);
  }
  unit z3zE31;
  z3zE31 = UNIT;
  {
    lbits z3zE144;
    CREATE(lbits)(&z3zE144);
    CONVERT_OF(lbits, fbits)(&z3zE144, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE145;
    CREATE(sail_int)(&z3zE145);
    CONVERT_OF(sail_int, mach_int)(&z3zE145, INT64_C(6));
    lbits z3zE146;
    CREATE(lbits)(&z3zE146);
    update_lbits(&z3zE146, z3zE144, z3zE145, zac);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE146, true);
    KILL(lbits)(&z3zE146);
    KILL(sail_int)(&z3zE145);
    KILL(lbits)(&z3zE144);
  }
  unit z3zE30;
  z3zE30 = UNIT;
  {
    lbits z3zE141;
    CREATE(lbits)(&z3zE141);
    CONVERT_OF(lbits, fbits)(&z3zE141, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE142;
    CREATE(sail_int)(&z3zE142);
    CONVERT_OF(sail_int, mach_int)(&z3zE142, INT64_C(2));
    lbits z3zE143;
    CREATE(lbits)(&z3zE143);
    update_lbits(&z3zE143, z3zE141, z3zE142, zov);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE143, true);
    KILL(lbits)(&z3zE143);
    KILL(sail_int)(&z3zE142);
    KILL(lbits)(&z3zE141);
  }
  unit z3zE29;
  z3zE29 = UNIT;
  {
    lbits z3zE138;
    CREATE(lbits)(&z3zE138);
    CONVERT_OF(lbits, fbits)(&z3zE138, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE139;
    CREATE(sail_int)(&z3zE139);
    CONVERT_OF(sail_int, mach_int)(&z3zE139, INT64_C(0));
    lbits z3zE140;
    CREATE(lbits)(&z3zE140);
    update_lbits(&z3zE140, z3zE138, z3zE139, zp);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE140, true);
    KILL(lbits)(&z3zE140);
    KILL(sail_int)(&z3zE139);
    KILL(lbits)(&z3zE138);
  }
  unit z3zE28;
  z3zE28 = UNIT;
  zPSW = zpsw_val;
  z8zE3 = UNIT;
end_function_58: ;
  return z8zE3;
end_block_exception_59: ;

  return UNIT;
}

unit zstep_and_imm(uint64_t zimm)
{
  unit z8zE4;
  uint64_t zres;
  {
    lbits z3zE163;
    CREATE(lbits)(&z3zE163);
    CONVERT_OF(lbits, fbits)(&z3zE163, zA, UINT64_C(8) , true);
    lbits z3zE164;
    CREATE(lbits)(&z3zE164);
    CONVERT_OF(lbits, fbits)(&z3zE164, zimm, UINT64_C(8) , true);
    lbits z3zE165;
    CREATE(lbits)(&z3zE165);
    and_bits(&z3zE165, z3zE163, z3zE164);
    zres = CONVERT_OF(fbits, lbits)(z3zE165, true);
    KILL(lbits)(&z3zE165);
    KILL(lbits)(&z3zE164);
    KILL(lbits)(&z3zE163);
  }
  zA = zres;
  unit z3zE24;
  z3zE24 = UNIT;
  uint64_t zpsw_val;
  zpsw_val = zPSW;
  uint64_t z2zE14;
  z2zE14 = zparity8(zres);
  {
    lbits z3zE160;
    CREATE(lbits)(&z3zE160);
    CONVERT_OF(lbits, fbits)(&z3zE160, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE161;
    CREATE(sail_int)(&z3zE161);
    CONVERT_OF(sail_int, mach_int)(&z3zE161, INT64_C(0));
    lbits z3zE162;
    CREATE(lbits)(&z3zE162);
    update_lbits(&z3zE162, z3zE160, z3zE161, z2zE14);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE162, true);
    KILL(lbits)(&z3zE162);
    KILL(sail_int)(&z3zE161);
    KILL(lbits)(&z3zE160);
  }
  unit z3zE25;
  z3zE25 = UNIT;
  zPSW = zpsw_val;
  z8zE4 = UNIT;
end_function_56: ;
  return z8zE4;
end_block_exception_57: ;

  return UNIT;
}

unit zstep_or_imm(uint64_t zimm)
{
  unit z8zE5;
  uint64_t zres;
  {
    lbits z3zE169;
    CREATE(lbits)(&z3zE169);
    CONVERT_OF(lbits, fbits)(&z3zE169, zA, UINT64_C(8) , true);
    lbits z3zE170;
    CREATE(lbits)(&z3zE170);
    CONVERT_OF(lbits, fbits)(&z3zE170, zimm, UINT64_C(8) , true);
    lbits z3zE171;
    CREATE(lbits)(&z3zE171);
    or_bits(&z3zE171, z3zE169, z3zE170);
    zres = CONVERT_OF(fbits, lbits)(z3zE171, true);
    KILL(lbits)(&z3zE171);
    KILL(lbits)(&z3zE170);
    KILL(lbits)(&z3zE169);
  }
  zA = zres;
  unit z3zE22;
  z3zE22 = UNIT;
  uint64_t zpsw_val;
  zpsw_val = zPSW;
  uint64_t z2zE13;
  z2zE13 = zparity8(zres);
  {
    lbits z3zE166;
    CREATE(lbits)(&z3zE166);
    CONVERT_OF(lbits, fbits)(&z3zE166, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE167;
    CREATE(sail_int)(&z3zE167);
    CONVERT_OF(sail_int, mach_int)(&z3zE167, INT64_C(0));
    lbits z3zE168;
    CREATE(lbits)(&z3zE168);
    update_lbits(&z3zE168, z3zE166, z3zE167, z2zE13);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE168, true);
    KILL(lbits)(&z3zE168);
    KILL(sail_int)(&z3zE167);
    KILL(lbits)(&z3zE166);
  }
  unit z3zE23;
  z3zE23 = UNIT;
  zPSW = zpsw_val;
  z8zE5 = UNIT;
end_function_54: ;
  return z8zE5;
end_block_exception_55: ;

  return UNIT;
}

unit zstep_xor_imm(uint64_t zimm)
{
  unit z8zE6;
  uint64_t zres;
  {
    lbits z3zE175;
    CREATE(lbits)(&z3zE175);
    CONVERT_OF(lbits, fbits)(&z3zE175, zA, UINT64_C(8) , true);
    lbits z3zE176;
    CREATE(lbits)(&z3zE176);
    CONVERT_OF(lbits, fbits)(&z3zE176, zimm, UINT64_C(8) , true);
    lbits z3zE177;
    CREATE(lbits)(&z3zE177);
    xor_bits(&z3zE177, z3zE175, z3zE176);
    zres = CONVERT_OF(fbits, lbits)(z3zE177, true);
    KILL(lbits)(&z3zE177);
    KILL(lbits)(&z3zE176);
    KILL(lbits)(&z3zE175);
  }
  zA = zres;
  unit z3zE20;
  z3zE20 = UNIT;
  uint64_t zpsw_val;
  zpsw_val = zPSW;
  uint64_t z2zE12;
  z2zE12 = zparity8(zres);
  {
    lbits z3zE172;
    CREATE(lbits)(&z3zE172);
    CONVERT_OF(lbits, fbits)(&z3zE172, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE173;
    CREATE(sail_int)(&z3zE173);
    CONVERT_OF(sail_int, mach_int)(&z3zE173, INT64_C(0));
    lbits z3zE174;
    CREATE(lbits)(&z3zE174);
    update_lbits(&z3zE174, z3zE172, z3zE173, z2zE12);
    zpsw_val = CONVERT_OF(fbits, lbits)(z3zE174, true);
    KILL(lbits)(&z3zE174);
    KILL(sail_int)(&z3zE173);
    KILL(lbits)(&z3zE172);
  }
  unit z3zE21;
  z3zE21 = UNIT;
  zPSW = zpsw_val;
  z8zE6 = UNIT;
end_function_52: ;
  return z8zE6;
end_block_exception_53: ;

  return UNIT;
}

unit zstep_rol(unit z3zE19)
{
  unit z8zE7;
  uint64_t za_val;
  za_val = zA;
  uint64_t zres;
  {
    uint64_t z2zE10;
    {
      lbits z3zE185;
      CREATE(lbits)(&z3zE185);
      CONVERT_OF(lbits, fbits)(&z3zE185, za_val, UINT64_C(8) , true);
      sail_int z3zE186;
      CREATE(sail_int)(&z3zE186);
      CONVERT_OF(sail_int, mach_int)(&z3zE186, INT64_C(6));
      sail_int z3zE187;
      CREATE(sail_int)(&z3zE187);
      CONVERT_OF(sail_int, mach_int)(&z3zE187, INT64_C(0));
      lbits z3zE188;
      CREATE(lbits)(&z3zE188);
      vector_subrange_lbits(&z3zE188, z3zE185, z3zE186, z3zE187);
      z2zE10 = CONVERT_OF(fbits, lbits)(z3zE188, true);
      KILL(lbits)(&z3zE188);
      KILL(sail_int)(&z3zE187);
      KILL(sail_int)(&z3zE186);
      KILL(lbits)(&z3zE185);
    }
    uint64_t z2zE11;
    {
      lbits z3zE181;
      CREATE(lbits)(&z3zE181);
      CONVERT_OF(lbits, fbits)(&z3zE181, za_val, UINT64_C(8) , true);
      sail_int z3zE182;
      CREATE(sail_int)(&z3zE182);
      CONVERT_OF(sail_int, mach_int)(&z3zE182, INT64_C(7));
      sail_int z3zE183;
      CREATE(sail_int)(&z3zE183);
      CONVERT_OF(sail_int, mach_int)(&z3zE183, INT64_C(7));
      lbits z3zE184;
      CREATE(lbits)(&z3zE184);
      vector_subrange_lbits(&z3zE184, z3zE181, z3zE182, z3zE183);
      z2zE11 = CONVERT_OF(fbits, lbits)(z3zE184, true);
      KILL(lbits)(&z3zE184);
      KILL(sail_int)(&z3zE183);
      KILL(sail_int)(&z3zE182);
      KILL(lbits)(&z3zE181);
    }
    {
      lbits z3zE178;
      CREATE(lbits)(&z3zE178);
      CONVERT_OF(lbits, fbits)(&z3zE178, z2zE10, UINT64_C(7) , true);
      lbits z3zE179;
      CREATE(lbits)(&z3zE179);
      CONVERT_OF(lbits, fbits)(&z3zE179, z2zE11, UINT64_C(1) , true);
      lbits z3zE180;
      CREATE(lbits)(&z3zE180);
      append(&z3zE180, z3zE178, z3zE179);
      zres = CONVERT_OF(fbits, lbits)(z3zE180, true);
      KILL(lbits)(&z3zE180);
      KILL(lbits)(&z3zE179);
      KILL(lbits)(&z3zE178);
    }
  }
  zA = zres;
  z8zE7 = UNIT;
end_function_50: ;
  return z8zE7;
end_block_exception_51: ;

  return UNIT;
}

unit zstep_ror(unit z3zE18)
{
  unit z8zE8;
  uint64_t za_val;
  za_val = zA;
  uint64_t zres;
  {
    uint64_t z2zE8;
    {
      lbits z3zE196;
      CREATE(lbits)(&z3zE196);
      CONVERT_OF(lbits, fbits)(&z3zE196, za_val, UINT64_C(8) , true);
      sail_int z3zE197;
      CREATE(sail_int)(&z3zE197);
      CONVERT_OF(sail_int, mach_int)(&z3zE197, INT64_C(0));
      sail_int z3zE198;
      CREATE(sail_int)(&z3zE198);
      CONVERT_OF(sail_int, mach_int)(&z3zE198, INT64_C(0));
      lbits z3zE199;
      CREATE(lbits)(&z3zE199);
      vector_subrange_lbits(&z3zE199, z3zE196, z3zE197, z3zE198);
      z2zE8 = CONVERT_OF(fbits, lbits)(z3zE199, true);
      KILL(lbits)(&z3zE199);
      KILL(sail_int)(&z3zE198);
      KILL(sail_int)(&z3zE197);
      KILL(lbits)(&z3zE196);
    }
    uint64_t z2zE9;
    {
      lbits z3zE192;
      CREATE(lbits)(&z3zE192);
      CONVERT_OF(lbits, fbits)(&z3zE192, za_val, UINT64_C(8) , true);
      sail_int z3zE193;
      CREATE(sail_int)(&z3zE193);
      CONVERT_OF(sail_int, mach_int)(&z3zE193, INT64_C(7));
      sail_int z3zE194;
      CREATE(sail_int)(&z3zE194);
      CONVERT_OF(sail_int, mach_int)(&z3zE194, INT64_C(1));
      lbits z3zE195;
      CREATE(lbits)(&z3zE195);
      vector_subrange_lbits(&z3zE195, z3zE192, z3zE193, z3zE194);
      z2zE9 = CONVERT_OF(fbits, lbits)(z3zE195, true);
      KILL(lbits)(&z3zE195);
      KILL(sail_int)(&z3zE194);
      KILL(sail_int)(&z3zE193);
      KILL(lbits)(&z3zE192);
    }
    {
      lbits z3zE189;
      CREATE(lbits)(&z3zE189);
      CONVERT_OF(lbits, fbits)(&z3zE189, z2zE8, UINT64_C(1) , true);
      lbits z3zE190;
      CREATE(lbits)(&z3zE190);
      CONVERT_OF(lbits, fbits)(&z3zE190, z2zE9, UINT64_C(7) , true);
      lbits z3zE191;
      CREATE(lbits)(&z3zE191);
      append(&z3zE191, z3zE189, z3zE190);
      zres = CONVERT_OF(fbits, lbits)(z3zE191, true);
      KILL(lbits)(&z3zE191);
      KILL(lbits)(&z3zE190);
      KILL(lbits)(&z3zE189);
    }
  }
  zA = zres;
  z8zE8 = UNIT;
end_function_48: ;
  return z8zE8;
end_block_exception_49: ;

  return UNIT;
}

unit zstep_rolc(unit z3zE14)
{
  unit z8zE9;
  uint64_t za_val;
  za_val = zA;
  uint64_t zpsw_val;
  zpsw_val = zPSW;
  uint64_t zold_cy;
  {
    lbits z3zE212;
    CREATE(lbits)(&z3zE212);
    CONVERT_OF(lbits, fbits)(&z3zE212, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE213;
    CREATE(sail_int)(&z3zE213);
    CONVERT_OF(sail_int, mach_int)(&z3zE213, INT64_C(7));
    zold_cy = bitvector_access(z3zE212, z3zE213);
    KILL(sail_int)(&z3zE213);
    KILL(lbits)(&z3zE212);
  }
  uint64_t znew_cy;
  {
    lbits z3zE210;
    CREATE(lbits)(&z3zE210);
    CONVERT_OF(lbits, fbits)(&z3zE210, za_val, UINT64_C(8) , true);
    sail_int z3zE211;
    CREATE(sail_int)(&z3zE211);
    CONVERT_OF(sail_int, mach_int)(&z3zE211, INT64_C(7));
    znew_cy = bitvector_access(z3zE210, z3zE211);
    KILL(sail_int)(&z3zE211);
    KILL(lbits)(&z3zE210);
  }
  uint64_t zres;
  {
    uint64_t z2zE7;
    {
      lbits z3zE203;
      CREATE(lbits)(&z3zE203);
      CONVERT_OF(lbits, fbits)(&z3zE203, za_val, UINT64_C(8) , true);
      sail_int z3zE204;
      CREATE(sail_int)(&z3zE204);
      CONVERT_OF(sail_int, mach_int)(&z3zE204, INT64_C(6));
      sail_int z3zE205;
      CREATE(sail_int)(&z3zE205);
      CONVERT_OF(sail_int, mach_int)(&z3zE205, INT64_C(0));
      lbits z3zE206;
      CREATE(lbits)(&z3zE206);
      vector_subrange_lbits(&z3zE206, z3zE203, z3zE204, z3zE205);
      z2zE7 = CONVERT_OF(fbits, lbits)(z3zE206, true);
      KILL(lbits)(&z3zE206);
      KILL(sail_int)(&z3zE205);
      KILL(sail_int)(&z3zE204);
      KILL(lbits)(&z3zE203);
    }
    uint64_t z3zE15;
    z3zE15 = UINT64_C(0b0);
    z3zE15 = update_fbits(z3zE15, INT64_C(0), zold_cy);
    {
      lbits z3zE200;
      CREATE(lbits)(&z3zE200);
      CONVERT_OF(lbits, fbits)(&z3zE200, z2zE7, UINT64_C(7) , true);
      lbits z3zE201;
      CREATE(lbits)(&z3zE201);
      CONVERT_OF(lbits, fbits)(&z3zE201, z3zE15, UINT64_C(1) , true);
      lbits z3zE202;
      CREATE(lbits)(&z3zE202);
      append(&z3zE202, z3zE200, z3zE201);
      zres = CONVERT_OF(fbits, lbits)(z3zE202, true);
      KILL(lbits)(&z3zE202);
      KILL(lbits)(&z3zE201);
      KILL(lbits)(&z3zE200);
    }
  }
  zA = zres;
  unit z3zE16;
  z3zE16 = UNIT;
  uint64_t znew_psw;
  znew_psw = zPSW;
  {
    lbits z3zE207;
    CREATE(lbits)(&z3zE207);
    CONVERT_OF(lbits, fbits)(&z3zE207, znew_psw, UINT64_C(8) , true);
    sail_int z3zE208;
    CREATE(sail_int)(&z3zE208);
    CONVERT_OF(sail_int, mach_int)(&z3zE208, INT64_C(7));
    lbits z3zE209;
    CREATE(lbits)(&z3zE209);
    update_lbits(&z3zE209, z3zE207, z3zE208, znew_cy);
    znew_psw = CONVERT_OF(fbits, lbits)(z3zE209, true);
    KILL(lbits)(&z3zE209);
    KILL(sail_int)(&z3zE208);
    KILL(lbits)(&z3zE207);
  }
  unit z3zE17;
  z3zE17 = UNIT;
  zPSW = znew_psw;
  z8zE9 = UNIT;
end_function_46: ;
  return z8zE9;
end_block_exception_47: ;

  return UNIT;
}

unit zstep_rorc(unit z3zE10)
{
  unit z8zE10;
  uint64_t za_val;
  za_val = zA;
  uint64_t zpsw_val;
  zpsw_val = zPSW;
  uint64_t zold_cy;
  {
    lbits z3zE226;
    CREATE(lbits)(&z3zE226);
    CONVERT_OF(lbits, fbits)(&z3zE226, zpsw_val, UINT64_C(8) , true);
    sail_int z3zE227;
    CREATE(sail_int)(&z3zE227);
    CONVERT_OF(sail_int, mach_int)(&z3zE227, INT64_C(7));
    zold_cy = bitvector_access(z3zE226, z3zE227);
    KILL(sail_int)(&z3zE227);
    KILL(lbits)(&z3zE226);
  }
  uint64_t znew_cy;
  {
    lbits z3zE224;
    CREATE(lbits)(&z3zE224);
    CONVERT_OF(lbits, fbits)(&z3zE224, za_val, UINT64_C(8) , true);
    sail_int z3zE225;
    CREATE(sail_int)(&z3zE225);
    CONVERT_OF(sail_int, mach_int)(&z3zE225, INT64_C(0));
    znew_cy = bitvector_access(z3zE224, z3zE225);
    KILL(sail_int)(&z3zE225);
    KILL(lbits)(&z3zE224);
  }
  uint64_t zres;
  {
    uint64_t z2zE6;
    {
      lbits z3zE217;
      CREATE(lbits)(&z3zE217);
      CONVERT_OF(lbits, fbits)(&z3zE217, za_val, UINT64_C(8) , true);
      sail_int z3zE218;
      CREATE(sail_int)(&z3zE218);
      CONVERT_OF(sail_int, mach_int)(&z3zE218, INT64_C(7));
      sail_int z3zE219;
      CREATE(sail_int)(&z3zE219);
      CONVERT_OF(sail_int, mach_int)(&z3zE219, INT64_C(1));
      lbits z3zE220;
      CREATE(lbits)(&z3zE220);
      vector_subrange_lbits(&z3zE220, z3zE217, z3zE218, z3zE219);
      z2zE6 = CONVERT_OF(fbits, lbits)(z3zE220, true);
      KILL(lbits)(&z3zE220);
      KILL(sail_int)(&z3zE219);
      KILL(sail_int)(&z3zE218);
      KILL(lbits)(&z3zE217);
    }
    uint64_t z3zE11;
    z3zE11 = UINT64_C(0b0);
    z3zE11 = update_fbits(z3zE11, INT64_C(0), zold_cy);
    {
      lbits z3zE214;
      CREATE(lbits)(&z3zE214);
      CONVERT_OF(lbits, fbits)(&z3zE214, z3zE11, UINT64_C(1) , true);
      lbits z3zE215;
      CREATE(lbits)(&z3zE215);
      CONVERT_OF(lbits, fbits)(&z3zE215, z2zE6, UINT64_C(7) , true);
      lbits z3zE216;
      CREATE(lbits)(&z3zE216);
      append(&z3zE216, z3zE214, z3zE215);
      zres = CONVERT_OF(fbits, lbits)(z3zE216, true);
      KILL(lbits)(&z3zE216);
      KILL(lbits)(&z3zE215);
      KILL(lbits)(&z3zE214);
    }
  }
  zA = zres;
  unit z3zE12;
  z3zE12 = UNIT;
  uint64_t znew_psw;
  znew_psw = zPSW;
  {
    lbits z3zE221;
    CREATE(lbits)(&z3zE221);
    CONVERT_OF(lbits, fbits)(&z3zE221, znew_psw, UINT64_C(8) , true);
    sail_int z3zE222;
    CREATE(sail_int)(&z3zE222);
    CONVERT_OF(sail_int, mach_int)(&z3zE222, INT64_C(7));
    lbits z3zE223;
    CREATE(lbits)(&z3zE223);
    update_lbits(&z3zE223, z3zE221, z3zE222, znew_cy);
    znew_psw = CONVERT_OF(fbits, lbits)(z3zE223, true);
    KILL(lbits)(&z3zE223);
    KILL(sail_int)(&z3zE222);
    KILL(lbits)(&z3zE221);
  }
  unit z3zE13;
  z3zE13 = UNIT;
  zPSW = znew_psw;
  z8zE10 = UNIT;
end_function_44: ;
  return z8zE10;
end_block_exception_45: ;

  return UNIT;
}

uint64_t zsign_ext8(uint64_t zb)
{
  uint64_t z8zE11;
  bool z2zE5;
  {
    uint64_t z2zE4;
    {
      lbits z3zE230;
      CREATE(lbits)(&z3zE230);
      CONVERT_OF(lbits, fbits)(&z3zE230, zb, UINT64_C(8) , true);
      sail_int z3zE231;
      CREATE(sail_int)(&z3zE231);
      CONVERT_OF(sail_int, mach_int)(&z3zE231, INT64_C(7));
      z2zE4 = bitvector_access(z3zE230, z3zE231);
      KILL(sail_int)(&z3zE231);
      KILL(lbits)(&z3zE230);
    }
    {
      lbits z3zE228;
      CREATE(lbits)(&z3zE228);
      CONVERT_OF(lbits, fbits)(&z3zE228, z2zE4, UINT64_C(1) , true);
      lbits z3zE229;
      CREATE(lbits)(&z3zE229);
      CONVERT_OF(lbits, fbits)(&z3zE229, UINT64_C(0b1), UINT64_C(1) , true);
      z2zE5 = eq_bits(z3zE228, z3zE229);
      KILL(lbits)(&z3zE229);
      KILL(lbits)(&z3zE228);
    }
  }
  if (z2zE5) {
    {
      lbits z3zE235;
      CREATE(lbits)(&z3zE235);
      CONVERT_OF(lbits, fbits)(&z3zE235, UINT64_C(0xFF), UINT64_C(8) , true);
      lbits z3zE236;
      CREATE(lbits)(&z3zE236);
      CONVERT_OF(lbits, fbits)(&z3zE236, zb, UINT64_C(8) , true);
      lbits z3zE237;
      CREATE(lbits)(&z3zE237);
      append(&z3zE237, z3zE235, z3zE236);
      z8zE11 = CONVERT_OF(fbits, lbits)(z3zE237, true);
      KILL(lbits)(&z3zE237);
      KILL(lbits)(&z3zE236);
      KILL(lbits)(&z3zE235);
    }
  } else {
    {
      lbits z3zE232;
      CREATE(lbits)(&z3zE232);
      CONVERT_OF(lbits, fbits)(&z3zE232, UINT64_C(0x00), UINT64_C(8) , true);
      lbits z3zE233;
      CREATE(lbits)(&z3zE233);
      CONVERT_OF(lbits, fbits)(&z3zE233, zb, UINT64_C(8) , true);
      lbits z3zE234;
      CREATE(lbits)(&z3zE234);
      append(&z3zE234, z3zE232, z3zE233);
      z8zE11 = CONVERT_OF(fbits, lbits)(z3zE234, true);
      KILL(lbits)(&z3zE234);
      KILL(lbits)(&z3zE233);
      KILL(lbits)(&z3zE232);
    }
  }
end_function_42: ;
  return z8zE11;
end_block_exception_43: ;

  return UINT64_C(0xdeadc0de);
}

unit zstep_bzz(uint64_t zoffset)
{
  unit z8zE12;
  uint64_t znext_pc;
  {
    lbits z3zE243;
    CREATE(lbits)(&z3zE243);
    CONVERT_OF(lbits, fbits)(&z3zE243, zPC, UINT64_C(16) , true);
    sail_int z3zE244;
    CREATE(sail_int)(&z3zE244);
    CONVERT_OF(sail_int, mach_int)(&z3zE244, INT64_C(2));
    lbits z3zE245;
    CREATE(lbits)(&z3zE245);
    add_bits_int(&z3zE245, z3zE243, z3zE244);
    znext_pc = CONVERT_OF(fbits, lbits)(z3zE245, true);
    KILL(lbits)(&z3zE245);
    KILL(sail_int)(&z3zE244);
    KILL(lbits)(&z3zE243);
  }
  bool z2zE2;
  {
    lbits z3zE241;
    CREATE(lbits)(&z3zE241);
    CONVERT_OF(lbits, fbits)(&z3zE241, zA, UINT64_C(8) , true);
    lbits z3zE242;
    CREATE(lbits)(&z3zE242);
    CONVERT_OF(lbits, fbits)(&z3zE242, UINT64_C(0x00), UINT64_C(8) , true);
    z2zE2 = eq_bits(z3zE241, z3zE242);
    KILL(lbits)(&z3zE242);
    KILL(lbits)(&z3zE241);
  }
  if (z2zE2) {
    uint64_t z2zE3;
    z2zE3 = zsign_ext8(zoffset);
    {
      lbits z3zE238;
      CREATE(lbits)(&z3zE238);
      CONVERT_OF(lbits, fbits)(&z3zE238, znext_pc, UINT64_C(16) , true);
      lbits z3zE239;
      CREATE(lbits)(&z3zE239);
      CONVERT_OF(lbits, fbits)(&z3zE239, z2zE3, UINT64_C(16) , true);
      lbits z3zE240;
      CREATE(lbits)(&z3zE240);
      add_bits(&z3zE240, z3zE238, z3zE239);
      zPC = CONVERT_OF(fbits, lbits)(z3zE240, true);
      KILL(lbits)(&z3zE240);
      KILL(lbits)(&z3zE239);
      KILL(lbits)(&z3zE238);
    }
    z8zE12 = UNIT;
  } else {
    zPC = znext_pc;
    z8zE12 = UNIT;
  }
end_function_40: ;
  return z8zE12;
end_block_exception_41: ;

  return UNIT;
}

unit zstep_bnzz(uint64_t zoffset)
{
  unit z8zE13;
  uint64_t znext_pc;
  {
    lbits z3zE251;
    CREATE(lbits)(&z3zE251);
    CONVERT_OF(lbits, fbits)(&z3zE251, zPC, UINT64_C(16) , true);
    sail_int z3zE252;
    CREATE(sail_int)(&z3zE252);
    CONVERT_OF(sail_int, mach_int)(&z3zE252, INT64_C(2));
    lbits z3zE253;
    CREATE(lbits)(&z3zE253);
    add_bits_int(&z3zE253, z3zE251, z3zE252);
    znext_pc = CONVERT_OF(fbits, lbits)(z3zE253, true);
    KILL(lbits)(&z3zE253);
    KILL(sail_int)(&z3zE252);
    KILL(lbits)(&z3zE251);
  }
  bool z2zE0;
  {
    lbits z3zE249;
    CREATE(lbits)(&z3zE249);
    CONVERT_OF(lbits, fbits)(&z3zE249, zA, UINT64_C(8) , true);
    lbits z3zE250;
    CREATE(lbits)(&z3zE250);
    CONVERT_OF(lbits, fbits)(&z3zE250, UINT64_C(0x00), UINT64_C(8) , true);
    z2zE0 = neq_bits(z3zE249, z3zE250);
    KILL(lbits)(&z3zE250);
    KILL(lbits)(&z3zE249);
  }
  if (z2zE0) {
    uint64_t z2zE1;
    z2zE1 = zsign_ext8(zoffset);
    {
      lbits z3zE246;
      CREATE(lbits)(&z3zE246);
      CONVERT_OF(lbits, fbits)(&z3zE246, znext_pc, UINT64_C(16) , true);
      lbits z3zE247;
      CREATE(lbits)(&z3zE247);
      CONVERT_OF(lbits, fbits)(&z3zE247, z2zE1, UINT64_C(16) , true);
      lbits z3zE248;
      CREATE(lbits)(&z3zE248);
      add_bits(&z3zE248, z3zE246, z3zE247);
      zPC = CONVERT_OF(fbits, lbits)(z3zE248, true);
      KILL(lbits)(&z3zE248);
      KILL(lbits)(&z3zE247);
      KILL(lbits)(&z3zE246);
    }
    z8zE13 = UNIT;
  } else {
    zPC = znext_pc;
    z8zE13 = UNIT;
  }
end_function_38: ;
  return z8zE13;
end_block_exception_39: ;

  return UNIT;
}

uint64_t zget_A(unit z3zE9)
{
  uint64_t z8zE14;
  z8zE14 = zA;
end_function_36: ;
  return z8zE14;
end_block_exception_37: ;

  return UINT64_C(0xdeadc0de);
}

unit zset_A(uint64_t zv)
{
  unit z8zE15;
  zA = zv;
  z8zE15 = UNIT;
end_function_34: ;
  return z8zE15;
end_block_exception_35: ;

  return UNIT;
}

uint64_t zget_PSW(unit z3zE8)
{
  uint64_t z8zE16;
  z8zE16 = zPSW;
end_function_32: ;
  return z8zE16;
end_block_exception_33: ;

  return UINT64_C(0xdeadc0de);
}

unit zset_PSW(uint64_t zv)
{
  unit z8zE17;
  zPSW = zv;
  z8zE17 = UNIT;
end_function_30: ;
  return z8zE17;
end_block_exception_31: ;

  return UNIT;
}

uint64_t zget_PC(unit z3zE7)
{
  uint64_t z8zE18;
  z8zE18 = zPC;
end_function_28: ;
  return z8zE18;
end_block_exception_29: ;

  return UINT64_C(0xdeadc0de);
}

unit zset_PC(uint64_t zv)
{
  unit z8zE19;
  zPC = zv;
  z8zE19 = UNIT;
end_function_26: ;
  return z8zE19;
end_block_exception_27: ;

  return UNIT;
}

unit zmain(unit z3zE6)
{
  unit z8zE20;
  z8zE20 = UNIT;
end_function_24: ;
  return z8zE20;
end_block_exception_25: ;

  return UNIT;
}

unit zinitializze_registers(unit z3zE0)
{
  unit z8zE21;
  {
    sail_int z3zE264;
    CREATE(sail_int)(&z3zE264);
    CONVERT_OF(sail_int, mach_int)(&z3zE264, INT64_C(8));
    lbits z3zE265;
    CREATE(lbits)(&z3zE265);
    UNDEFINED(lbits)(&z3zE265, z3zE264);
    zA = CONVERT_OF(fbits, lbits)(z3zE265, true);
    KILL(lbits)(&z3zE265);
    KILL(sail_int)(&z3zE264);
  }
  unit z3zE5;
  z3zE5 = UNIT;
  {
    sail_int z3zE262;
    CREATE(sail_int)(&z3zE262);
    CONVERT_OF(sail_int, mach_int)(&z3zE262, INT64_C(8));
    lbits z3zE263;
    CREATE(lbits)(&z3zE263);
    UNDEFINED(lbits)(&z3zE263, z3zE262);
    zB = CONVERT_OF(fbits, lbits)(z3zE263, true);
    KILL(lbits)(&z3zE263);
    KILL(sail_int)(&z3zE262);
  }
  unit z3zE4;
  z3zE4 = UNIT;
  {
    sail_int z3zE260;
    CREATE(sail_int)(&z3zE260);
    CONVERT_OF(sail_int, mach_int)(&z3zE260, INT64_C(8));
    lbits z3zE261;
    CREATE(lbits)(&z3zE261);
    UNDEFINED(lbits)(&z3zE261, z3zE260);
    zC = CONVERT_OF(fbits, lbits)(z3zE261, true);
    KILL(lbits)(&z3zE261);
    KILL(sail_int)(&z3zE260);
  }
  unit z3zE3;
  z3zE3 = UNIT;
  {
    sail_int z3zE258;
    CREATE(sail_int)(&z3zE258);
    CONVERT_OF(sail_int, mach_int)(&z3zE258, INT64_C(8));
    lbits z3zE259;
    CREATE(lbits)(&z3zE259);
    UNDEFINED(lbits)(&z3zE259, z3zE258);
    zSP = CONVERT_OF(fbits, lbits)(z3zE259, true);
    KILL(lbits)(&z3zE259);
    KILL(sail_int)(&z3zE258);
  }
  unit z3zE2;
  z3zE2 = UNIT;
  {
    sail_int z3zE256;
    CREATE(sail_int)(&z3zE256);
    CONVERT_OF(sail_int, mach_int)(&z3zE256, INT64_C(16));
    lbits z3zE257;
    CREATE(lbits)(&z3zE257);
    UNDEFINED(lbits)(&z3zE257, z3zE256);
    zPC = CONVERT_OF(fbits, lbits)(z3zE257, true);
    KILL(lbits)(&z3zE257);
    KILL(sail_int)(&z3zE256);
  }
  unit z3zE1;
  z3zE1 = UNIT;
  {
    sail_int z3zE254;
    CREATE(sail_int)(&z3zE254);
    CONVERT_OF(sail_int, mach_int)(&z3zE254, INT64_C(8));
    lbits z3zE255;
    CREATE(lbits)(&z3zE255);
    UNDEFINED(lbits)(&z3zE255, z3zE254);
    zPSW = CONVERT_OF(fbits, lbits)(z3zE255, true);
    KILL(lbits)(&z3zE255);
    KILL(sail_int)(&z3zE254);
  }
  z8zE21 = UNIT;
end_function_22: ;
  return z8zE21;
end_block_exception_23: ;

  return UNIT;
}

void model_init(void)
{
  setup_rts();
  current_exception = sail_new(struct zexception);
  CREATE(zexception)(current_exception);
  throw_location = sail_new(sail_string);
  CREATE(sail_string)(throw_location);
  zinitializze_registers(UNIT);
}

void model_fini(void)
{
  cleanup_rts();
  if (have_exception) {fprintf(stderr, "Exiting due to uncaught exception: %s\n", *throw_location);}
  KILL(zexception)(current_exception);
  sail_free(current_exception);
  KILL(sail_string)(throw_location);
  sail_free(throw_location);
  if (have_exception) {exit(EXIT_FAILURE);}
}



void model_pre_exit()
{
}

int model_main(int argc, char *argv[])
{
  model_init();
  if (process_arguments(argc, argv)) exit(EXIT_FAILURE);
  zmain(UNIT);
  model_fini();
  model_pre_exit();
  return EXIT_SUCCESS;
}

void model_test(void)
{
  for (size_t i = 0; i < SAIL_TEST_COUNT; ++i) {
    model_init();
    printf("Testing %s\n", SAIL_TEST_NAMES[i]);
    SAIL_TESTS[i](UNIT);
    printf("Pass\n");
    model_fini();
  }
}



#ifdef __cplusplus
}
#endif
