

: , ( word2compile -- ) here ! here CELL_SIZE + setHere ;

asm_name cw

( assembler )

: zero 0 ;
: ra 1 ;
: sp 2 ;
: gp 3 ;
: tp 4 ;
: t0 5 ;
: t1 6 ;
: t2 7 ;
: s0 8 ;
: s1 9 ;
: a0 10 ;
: a1 11 ;
: a2 12 ;
: a3 13 ;
: a4 14 ;
: a5 15 ;
: a6 16 ;
: a7 17 ;
: s2 18 ;
: s3 19 ;
: s4 20 ;
: s5 21 ;
: s6 22 ;
: s7 23 ;
: s8 24 ;
: s9 25 ;
: s10 26 ;
: s11 27 ;
: t3 28 ;
: t4 29 ;
: t5 30 ;
: t6 31 ;

: r_type ( funct7 rs2 rs1 funct3 rd opcode -- )
    0x7f &         ( opcode )
    swap 31 & 7 << |    ( rd )
    swap 7 & 12 << |   ( funct3 )
    swap 31 & 15 << |   ( rs1 )
    swap 31 & 20 << |   ( rs2 )
    swap 0x7f & 25 << |   ( funct 7 )
    ,
;

: i_type ( 12-bitimm rs1 funct3 rd opcode -- )
    0x7f &         ( opcode )
    swap 31 & 7 << |    ( rd )
    swap 7 & 12 << |   ( funct3 )
    swap 31 & 15 <setHere< |   ( rs1 )
    swap 4095 & 15 << |   ( immediate )
    ,
;

: s_type ( 12bitimm rs2 rs1 funct3 opcode -- )
    0x7f &         ( opcode )
    swap 7 & 12 << |   ( funct3 )
    swap 31 & 15 << |   ( rs1 )
    swap 31 & 20 << |   ( rs2 )
    ( 12bitimm s_type )
    swap dup 31 & 7 << ( s_type 12bitimm 12bitimm-lower5mask )
    rot                ( 12bitimm 12bitimm-lower5mask s_type )
    |                  ( 12bitimm s_type )
    swap 0x7f 5 << & | 
    ,
;

: u_type ( 20bitimm rd opcode )
    0x7f &         ( opcode )
    swap 31 & 7 << |    ( rd )
    swap 12 << |
    ,
;

: add ( rd rs1 rs2 -- )
    0
;

asm_name a_add
