#pragma once

#include "sail.h"
#include "sail_config.h"
#include "rts.h"
#include "elf.h"
#ifdef __cplusplus
extern "C" {
#endif
extern void (*sail_rts_set_coverage_file)(const char *);

// union exception
enum kind_zexception { Kind_z__dummy_exnz3 };

struct zexception {
  enum kind_zexception kind;
  union {struct { unit z__dummy_exnz3; };} variants;
};

// type abbreviation bit
typedef uint64_t zbit;

uint64_t zparity8(uint64_t);

unit zstep_add_imm(uint64_t);

unit zstep_sub_imm(uint64_t);

unit zstep_and_imm(uint64_t);

unit zstep_or_imm(uint64_t);

unit zstep_xor_imm(uint64_t);

unit zstep_rol(unit);

unit zstep_ror(unit);

unit zstep_rolc(unit);

unit zstep_rorc(unit);

uint64_t zsign_ext8(uint64_t);

unit zstep_bzz(uint64_t);

unit zstep_bnzz(uint64_t);

uint64_t zget_A(unit);

unit zset_A(uint64_t);

uint64_t zget_PSW(unit);

unit zset_PSW(uint64_t);

uint64_t zget_PC(unit);

unit zset_PC(uint64_t);

unit zmain(unit);

unit zinitializze_registers(unit);

extern struct zexception *current_exception;

extern bool have_exception;

extern sail_string *throw_location;

// register zA
extern uint64_t zA;

// register zB
extern uint64_t zB;

// register zC
extern uint64_t zC;

// register zSP
extern uint64_t zSP;

// register zPC
extern uint64_t zPC;

// register zPSW
extern uint64_t zPSW;



#ifdef __cplusplus
}
#endif
