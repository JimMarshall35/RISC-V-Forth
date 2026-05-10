( This is compiled into threaded code with a compiler written in python [see tools/Compiler.py] )
( It is a non standard, non interactive forth compiler that bootstraps a real                  )
( forth system running on the target riscv hardware. This python compiler for example has      )
( control flow words baked into the implementation not done with immediate words, and also     )
( has builtin words for variables and has a fake c preprocessor                                )
#define CARRIAGE_RETURN_CHAR 13
#define NEWLINE_CHAR 10
#define ENTER_CHAR 127
#define BACKSPACE_CHAR 8
#define SPACE_CHAR 32
#define MINUS_CHAR 45

#define HEADER_SIZE 40
#define OFFSET_IMM 36
#define OFFSET_PREV 32

#define CELL_SIZE 4

#define ASCII_NUM_RANGE_START 48

#define ASCII_NUM_RANGE_END 57

#define COMPILE_BIT 1

#define SECONDARY_WORD_MACRO_CODE_SIZE 24

#define RAM_START 0x20000000

buf LineBuffer_ 128
var LineBufferSize_ 0

buf Tokenbuffer_ 32
var TokenBufferSize_ 0

var LineBufferI_ 0

var EvalErrorFlag_ 0

var flags 0

string do_doesStr_ "do_does>"

string JumpStr_ "jp"

string PCStr_ "pc"

string LiteralStr_ "literal"

string ReturnStr_ "r"

string UnknownTokenStartStr_ "unknowntoken:'" ( TODO: needs compiler change to allow spaces within strings but not high priority )

string UnknownTokenEndStr_ "'\n\r"

string branch0TokenStr_ "b0"

string branchTokenStr_ "b"

string pushReturnStr_ ">R"

string popReturnStr_ "<R"

string addStr_ "+"

string twodupStr_ "2dup"

string equalsStr_ "="

string dropStr_ "drop"

string showStr_ "show"

( flags )

: setCompile ( -- ) flags @ COMPILE_BIT | flags ! ;

: setInterpret ( -- ) flags @ COMPILE_BIT -1 ^ & flags ! ;

: get_compile_bit ( -- 1or0 ) flags @ COMPILE_BIT & 0 > if 1 r then 0 ;

( loop counter functions )

: i ( -- i ) -2 R[] @ ;

: j ( -- j ) -4 R[] @ ;

( printing functions )

: print ( pString nStringSize -- )
    0 do
        dup i + c@ emit
    loop
    drop
;

: && ( bool1 bool2 -- 1IfBoth1Else0 ) 
    if
        ( bool2 is true )
        if
            ( bool 1 is true )
            1 r
        else
            0 r
        then
    else
        drop 0 r
    then
;

asm_name logic_and

: || ( bool1 bool2 -- 1IfEitherElse0 ) 
    if drop 1 r then
    if 1 r then
    0 r
;

asm_name logic_or

: logic_not ( bool -- !bool )
    if
        0
    else
        1
    then
;

: >= ( int1 int2 -- 1IfInt1>=Int2 )
    2dup = rot rot > ||
;

asm_name gte

: <= ( int1 int2 -- 1IfInt1>=Int2 )
    2dup = rot rot < ||
;

asm_name lte

: isCharNumeric ( char -- 1IfNumericElse0 )
    dup ASCII_NUM_RANGE_START >= swap ASCII_NUM_RANGE_END <= &&
;

: isStringValidNumber ( pString nStringSize -- 0ifNotValid )
    0 do
        i 0 = if
            dup ( pString pString )
            c@ dup ( pString char char )
            MINUS_CHAR =  ( pString char isMinusChar )
            swap isCharNumeric
            || logic_not if
                ( character is not '-' or 0-9 )
                drop
                <R <R drop drop  
                0
                r
            then
        else
            dup i + c@ isCharNumeric logic_not if
                drop
                <R <R drop drop
                0
                r
            then
        then
    loop
    drop
    1
;


: getHeaderPrev ( pHeader -- pHeader->pPrev ) OFFSET_PREV + @ ; 

: setHeaderPrev ( pPrev pHeader -- ) OFFSET_PREV + ! ; 

: setHeaderImmediate ( bImm pHeader -- ) OFFSET_IMM + ! ;

: getHeaderImmediate ( pHeader -- pHeader->bImmediate ) OFFSET_IMM + @ 1 & ; 

: getHeaderIsPrmitive ( pHeader -- pHeader->bPrimitive ) OFFSET_IMM + @ 2 & ; 

: getXTHeader ( xt -- xtHeader ) HEADER_SIZE - ; 

: getXTImmediate ( xt -- 0IfNotImmediate ) getXTHeader getHeaderImmediate ;

: ptrInRam ( ptr -- isInRam ) RAM_START >= ;

: tokenBufferToHeaderCode ( buffer -- ) TokenBufferSize_ @ swap Tokenbuffer_ swap toCString ;

: headerToThreadStart ( pHeader -- )  HEADER_SIZE SECONDARY_WORD_MACRO_CODE_SIZE + + ;

: , ( word2compile -- ) here ! here CELL_SIZE + setHere ;

asm_name cw

: cr ( -- ) 10 13 emit emit ;

: c, ( byte2compile -- ) here c! here 1 + setHere ;

asm_name cbyte

: doToken  
    TokenBufferSize_ @ Tokenbuffer_ '
    ( either 0 on stack or an excution token )
    dup 0 != if
        ( we've found a valid xt )
        get_compile_bit 0 != if
            dup getXTImmediate if 
                execute
            else
                ,
            then
        else
            execute
        then
    else
        drop ( empty stack )
        ( pString nStringSize -- 0ifNotValid )
        Tokenbuffer_ TokenBufferSize_ @ isStringValidNumber ( 0ifNotValid )
        0 != if
            ( valid number string in token buffer )
            Tokenbuffer_ TokenBufferSize_ @ $  ( converted number on stack )
            get_compile_bit 0 != if
                LiteralStr_ ' , ( TODO: NEED TO IMPLEMENT STRING LITERALS IN COMPILER - WILL HAND EDIT IN )
                ,
            then
        else 
            ( not valid )
            1 EvalErrorFlag_ !
        then
    then 
;

: seekTokenStart ( -- 0or1 )
    begin
        LineBuffer_ LineBufferI_ @ + c@         ( char@I )
        dup SPACE_CHAR != swap NEWLINE_CHAR != && if
            0 r                                ( I points to something other than a space - there's a token to load return 0 )
        then
        LineBufferI_ @ 1 + LineBufferI_ !      ( increment line buffer I )
        LineBufferI_ @ LineBufferSize_ @ = if
            1 r                                ( end of line buffer reached, no next token to load )
        then
    0 until 
;

: loadToken ( -- )
    0 TokenBufferSize_ !
    begin
        LineBuffer_ LineBufferI_ @ + c@         ( char@I )
        LineBufferI_ @ LineBufferSize_ @ = if
            drop 
            0 Tokenbuffer_ TokenBufferSize_ @ + c! ( store '0' terminator at end of token buffer )
            r
        then
        dup
        SPACE_CHAR = if
            drop 
            0 Tokenbuffer_ TokenBufferSize_ @ + c! ( store '0' terminator at end of token buffer )
            r
        then
        ( char@I )
        Tokenbuffer_ TokenBufferSize_ @ + c!
        LineBufferI_ @ 1 + LineBufferI_ !
        TokenBufferSize_ @ 1 + TokenBufferSize_ !
    0 until 
;

: loadNextToken ( -- 0or1 )
    LineBufferI_ @ LineBufferSize_ @ = if
        1 r
    then
    seekTokenStart 1 = if
        1 r
    then
    loadToken 
    0
;

: eval_ ( -- )
    0 LineBufferI_ !
    0 TokenBufferSize_ !
    0 EvalErrorFlag_ !
    begin
        EvalErrorFlag_ @ 0 != if
            UnknownTokenStartStr_ swap print
            Tokenbuffer_ TokenBufferSize_ @ print
            UnknownTokenEndStr_ swap 1 - print     ( TODO: the compilers handling of strings needs to improve - something wrong with how it escapes characters here )
            r
        then
        loadNextToken     ( 0or1 )
        1 != if
            doToken
        else
            r
        then
    0 until 
;

: doBackspace
    LineBufferSize_ @ 0 > if
        BACKSPACE_CHAR emit
        SPACE_CHAR emit
        BACKSPACE_CHAR emit
        ( decrement line buffer size )
        LineBufferSize_ @ 1 - LineBufferSize_ !
    then 
;

: outerInterpreter
    0 LineBufferSize_ !
    begin
        key    ( key )
        dup
        CARRIAGE_RETURN_CHAR = if
            ( enter entered )
            drop           ( )
            NEWLINE_CHAR emit        ( emit newline char )
            CARRIAGE_RETURN_CHAR emit
            eval_  
            0 LineBufferSize_ !
        else dup BACKSPACE_CHAR = if
            ( backspace entered )
            drop
            doBackspace
        else
            ( some other key entered )
            ( key )
            LineBufferSize_ @
            ENTER_CHAR < if
                dup emit
                LineBuffer_ LineBufferSize_ c@ + c!        ( store inputed key at current buffer position )
                LineBufferSize_ @ 1 + LineBufferSize_ c!   ( increment LineBufferSize_ )
            then
        then
        then
    0 until 
;

: compileHeader ( -- pHeader )
    loadNextToken drop
    here here HEADER_SIZE + setHere
    ( pHeader )
    dup tokenBufferToHeaderCode
    dup getDictionaryEnd swap setHeaderPrev
    dup 0 swap setHeaderImmediate
;

: alignHere ( alignment -- )
    ( I know, you don't need a loop you can do this just as a sum, but I couldn't get to work :o )
    begin 
        dup here swap mod 0 = if
            drop
            r
        then 
        here 1 + setHere
    0 until
;

: enter_word_macro ( -- ) 
    ( Implementation is for COMPRESSED INSTRUCTION FORMAT RISC-V            )
                                    ( 1. push s0 to return stack            )
    0xB3 c, 0x82 c, 0x49 c, 0x01 c, (      add	t0,s3,s4                    )
    0x23 c, 0xA0 c, 0x82 c, 0x00 c, (      sw	s0,0[t0]                    )
    0x11 c, 0x0A c,                 (      addi	s4,s4,4                     )
                                    ( 2. set s0 to point to start of thread )
    0x17 c, 0x04 c, 0x00 c, 0x00 c, (      auipc	s0,0x0                  ) 
    0x39 c, 0x04 c,                 (      addi	s0,s0, 14                   )
                                    ( 3. jump into first word in thread     )
    0x83 c, 0x2e c, 0x04 c, 0x00 c, (      lw	t0,0[s0]                    )
    0xE7 c, 0x80 c, 0x0e c, 0x00 c, (      jalr	t0                      )
;

: : ( pHeader )
    4 alignHere
    setCompile
    compileHeader                   
    enter_word_macro
    4 alignHere
;

asm_name bw

: ; ( pHeader -- )
    ReturnStr_ ' ,
    setInterpret
    ( only set the dictionary end ptr, from where token searches start, )
    ( after the word is compiled so that a word can be redfined and use )
    ( its old implementation in its NEW implementation. To call itself  )
    ( a new word needs to be rewritten, recurse.                        )
    setDictionaryEnd
; immediate 

asm_name ew

: if ( -- addressToBackpatch )
    branch0TokenStr_ ' ,
    here
    0 ,
; immediate 

: else ( ifBranchAddressToBackpatch -- elseBranchAddressToBackpatch )
    branchTokenStr_ ' ,
    here                 ( ifBranch here )
    0 ,
    swap dup             ( here ifBranch ifBranch )
    here swap -          ( here ifBranch here-ifBranch )
    swap !               ( here )
; immediate 

: then ( ifBranchAddressToBackpatch -- )
    dup
    here swap -0x17
    swap !
; immediate 

: begin ( -- loopMarker )
    here
; immediate 

: until ( loopMarker -- )
    branch0TokenStr_ ' ,
    here swap - -1 * , 
; immediate 

: do ( -- startLabel initialJump )
    branchTokenStr_ ' ,    ( initial jump to test label )
    here 0 ,
    here                   ( initialJump startlabel )
    swap                   ( startLabel initialJump )
    pushReturnStr_ ' dup , ( compile code to push i onto return stack )
    ,                      ( compile code to push limit onto return stack ) 
; immediate 


: loop ( startLabel initialJump -- ) 
    ( compile code to pop i and limit from return stack )
    popReturnStr_ ' dup , ,

    ( compile code to increment i )
    LiteralStr_ ' ,
    1 ,
    addStr_ ' ,

    ( we are now at the test label )
    dup ( startLabel initialJump initialJump )
    here swap -
    swap !
    ( startLabel )

    ( compile code to compare i and limit and branch if not equal )
    twodupStr_ ' ,
    equalsStr_ ' ,
    branch0TokenStr_ ' ,
    here swap - -1 * ,

    ( compile code to clean up i and limit from int stack now that the loop has ended ) 
    dropStr_ ' dup , , 
; immediate 

: printc ( cstring -- )
    begin 
        dup c@ emit
        1 +
        dup c@ logic_not
    until
    drop
;

: memoryDump ( end begin -- )
    begin
        dup dup . SPACE_CHAR emit @ . cr
        4 +
        2dup swap >=
    until
    drop drop 
;

: showLastWord
    here
    getDictionaryEnd   ( here pEnd )
    dup
    dup . SPACE_CHAR emit printc SPACE_CHAR emit  ( here pEnd ) 
    dup getHeaderImmediate .  SPACE_CHAR emit         ( here pEnd ) 
    dup getHeaderIsPrmitive . cr                      ( here pEnd ) 
    memoryDump
;


: showWords
    here 
    getDictionaryEnd   ( here pEnd )
    begin
        dup
        dup . SPACE_CHAR emit printc SPACE_CHAR emit  ( here pEnd ) 
        dup getHeaderImmediate .  SPACE_CHAR emit         ( here pEnd ) 
        dup getHeaderIsPrmitive . cr                      ( here pEnd ) 
        ( print contents of word )
        2dup ptrInRam swap ptrInRam = if             ( here pEnd )
            ( both ptrs in same region )
            2dup memoryDump                              ( here pEnd ) 
        else
            swap drop
            FORTH_DICT_END swap
            2dup memoryDump
        then
        swap drop dup                                ( pEnd pEnd )
        getHeaderPrev                                ( pEnd pEnd->prev ) 
        dup 0 =                                      ( pEnd pEnd->prev pEnd->prev==0 )
    until
    drop drop 
;

: do_does> ( does_code -- )
    getDictionaryEnd
    headerToThreadStart
    ( iterate over the execution tokens in the last created word, to find )
    ( the return token.                                                   )
    begin 
        dup
        @ ReturnStr_ ' = if
            ( pointer to the return token is on the top of the stack, replace it with a jump )
            dup JumpStr_ ' swap ! 
            ( compile address of the code after does>, the location to jump to               )
            4 + !
            ( early return                                                                   )
            r
        then
        4 +
        0
    until
;

asm_name do_does

: create ( consumes next token )
    4 alignHere
    ( setCompile )
    compileHeader
    enter_word_macro
    LiteralStr_ ' ,
    here 12 + ,
    ReturnStr_ ' ,
    0 ,
    setDictionaryEnd
;

: does>
    ( compile code to push the location we want the last created word to jump to    )
    ( instead of returning                                                          )
    LiteralStr_ ' ,
    here 8 + ,
    ( compile code to overwrite the return execution token of the last created word )
    ( with a jump into THIS word, starting after does>                              )
    do_doesStr_ ' ,
    ( compile a return so that the does> code doesn't execute when the defining word )
    ( is used to create a definition.                                                )
    ReturnStr_ ' ,
; immediate

asm_name does


( CH32 Flash Memory )

#define FLASH_KEY_1 0x45670123
#define FLASH_KEY_2 0xCDEF89AB
#define R32_FLASH_KEYR 0x40022004
#define R32_FLASH_CTLR 0x40022010
#define R32_FLASH_OBKEYR 0x40022008
#define R32_FLASH_STATR 0x4002200C
#define R32_FLASH_ADDR 0x40022014
#define R32_FLASH_OBR 0x4002201C
#define R32_FLASH_WPR 0x40022020
#define R32_FLASH_MODEKEYR 0x40022024

#define FLASH_CTLR_LOCK_BIT 0x80
#define FLASH_CTLR_FLOCK_BIT 0x8000
#define FLASH_CTLR_FTER_BIT 0x20000
#define FLASH_CTLR_FTPG_BIT 0x10000
#define FLASH_CTLR_STRT_BIT 0x40

#define FLASH_STATR_EOP_BIT 0x20
#define FLASH_STATR_BSY_BIT 1

#define PAGE_MASK 0xFFFFFF00

buf pageBuffer 256

: pageAddress ( flashPtr -- page ) PAGE_MASK & ;

: cells ( index -- indexInCells ) CELL_SIZE * ;

: copyPageToBuffer ( pagePtr -- )
    64 0 do
        dup i cells + @ pageBuffer i cells + !
    loop
;

: flashLocked ( -- 0IfFlashUnlocked ) R32_FLASH_CTLR @ FLASH_CTLR_LOCK_BIT & ;

: fastFlashLocked ( -- 0IfFastFlashUnlocked ) R32_FLASH_CTLR @ FLASH_CTLR_FLOCK_BIT & ;

: unlockFlash ( -- ) 
    FLASH_KEY_1 R32_FLASH_KEYR !
    FLASH_KEY_2 R32_FLASH_KEYR !
;

: fastFlashModeUnlock ( -- )
    FLASH_KEY_1 R32_FLASH_MODEKEYR !
    FLASH_KEY_2 R32_FLASH_MODEKEYR !
;

: lockFlash ( -- )
    R32_FLASH_CTLR @ FLASH_CTLR_LOCK_BIT | R32_FLASH_CTLR !
;

: waitForFlashNotBusy ( -- )
    begin
        R32_FLASH_STATR @ FLASH_STATR_BSY_BIT & = 0
    until
;

( erasePage and flashPageBuffer will unlock the flash, but it is the users responsibility to lock flash after use )

: erasePage ( ptrPage -- )
    ( make sure flash is unlocked )
    flashLocked 0 != if
        unlockFlash
    then

    ( make sure fast flash mode is unlocked )
    fastFlashLocked 0 != if 
        fastFlashModeUnlock
    then

    waitForFlashNotBusy

    ( enable fast erase 256 byte page mod )
    R32_FLASH_CTLR @ FLASH_CTLR_FTER_BIT | R32_FLASH_CTLR !
    
    ( write page address to R32_FLASH_ADDR )
    R32_FLASH_ADDR !

    ( trigger the erase operation )
    R32_FLASH_CTLR @ FLASH_CTLR_STRT_BIT | R32_FLASH_CTLR !
    
    ( wait for erase to complete )
    waitForFlashNotBusy

    ( reset eop bit by writing 1 )
    R32_FLASH_STATR @ FLASH_STATR_EOP_BIT | R32_FLASH_STATR !
;

: flashPageBuffer ( flashPagePtr -- )
    ( make sure flash is unlocked )
    flashLocked 0 != if
        unlockFlash
    then

    ( make sure fast flash mode is unlocked )
    fastFlashLocked 0 != if 
        fastFlashModeUnlock
    then

    waitForFlashNotBusy

    ( enable fast program 256 byte page mod )
    R32_FLASH_CTLR @ FLASH_CTLR_FTPG_BIT | R32_FLASH_CTLR !

    64 0 do 
        ( ptrPage )
        dup i cells + pageBuffer i cells + @ swap !
        ( ptrPage )
        waitForFlashNotBusy
    loop
;
