.include "defines.S"
.include "VmMacros.S"
.altmacro
#
#   Prefix any character with ! to use it literally in a macro.
#   We will use "" to denote strings in macro arguments.
#   https://sourceware.org/binutils/docs/as/Altmacro.html
# 

.global emit_impl
.global key_impl
.global loadCell_impl
.global store_impl
.global loadByte_impl
.global storeByte_impl
.global branchIfZero_impl
.global branch_impl
.global forth_add_impl
.global literal_impl
.global dup_impl
.global return_impl
.global forth_minus_impl
.global swap_impl
.global drop_impl
.global dup2_impl
.global findXT_impl
.global doWordFound_impl
.global flags_impl
.global setCompile_impl
.global setInterpret_impl
.global forth_and_impl
.global forth_or_impl
.global get_compile_bit_impl
.global forth_xor_impl
.global get_comment_bit_impl
.global comment_on_impl
.global comment_off_impl
.global here_impl
.global rot_impl
.global push_return_impl
.global pop_return_impl
.global forth_fatoi_impl
.global show_impl
.global execute_impl
.global showR_impl
.global setHere_impl
.global return_stack_index_impl
.global getDictionaryEnd_impl
.global setDictionaryEnd_impl
.global tokenBufferToHeaderCode_impl
.global toCString_impl
.global compileWord_impl
.global endWord_impl
.global getXTHeader_impl
.global isXTImmediate_impl
.global setNumInputHex_impl
.global setNumInputDec_impl
.global equals_impl
.global notEquals_impl
.global lessThan_impl
.global greaterThan_impl
.global modulo_impl
.global forth_mul_impl
.global newline_impl
.global forth_print_int_impl
.global forth_div_impl
.global shift_right_impl
.global shift_left_impl
.global roll_impl
.global pc_impl
.global jump_impl

.global vm_return_stack
.global vm_data_stack

.global last_vm_word

.global vm_p_dictionary_end
.global vm_p_dictionary_end_val

.global vm_free_flash_start
.global vm_free_flash_start_val

.global begin_forth_data_section
.global begin_forth_data_section_data
# mr worldwide

#define VM_STACK_BOUNDS_CHECK

.global vm_flags
    # IMPORTANT! REGISTERS USED BY THE INTERPRETER:

    # Until I can get C Style defines to work you'll just have to read this, assembler.
    # The following registers must not be touched:

    # s0 - instruction pointer
    # s1 - data stack base pointer
    # s2 - data stack size
    # s3 - return stack base pointer
    # s4 - return stack size
    # s5 - memory top


.global vm_run

.section .bss
.balign 4

vm_flags: .word 0

vm_data_stack: .zero DATA_STACK_MAX_SIZE * CELL_SIZE      # 32 cell stack size
vm_return_stack: .zero RETURN_STACK_MAX_SIZE * CELL_SIZE  # 64 cell return stack size

vm_scratch_pad: .zero 64

# dictionary
vm_str_error_message: .word 0
.balign 4


# FORTH DATA SECTION BEGIN
# forth manages its own data section separate from the one setup by startup code (for now)
begin_forth_data_section:

# points to the header of the last word in the dictionary
vm_p_dictionary_end: .word 0

# points to a 4 byte aligned address that's the first free flash memory for new words
vm_free_flash_start: .word 0

# points to AFTER the last word (not necessarily the first free flash memory
vm_after_first_word: .word 0

end_forth_data_section:
# FORTH DATA SECTION END

.section .text
.balign 4

# FORTH FLASH DATA SECTION BEGIN
begin_forth_data_section_data:
vm_p_dictionary_end_val: .word last_word
vm_free_flash_start_val: .word _flash_free_start
vm_after_first_word_val: .word forth_flash_dict_end

end_forth_data_section_data:
# FORTH_FLASH DATA SECTION END

starting_interpreter_string: .ascii "starting outer interpreter...\n\r\0"

show_data_stack_begin_str:   .ascii "data   [ \0"
show_return_stack_begin_str: .ascii "return [ \0"
show_comma_sep_str:          .ascii ", \0"
show_stack_end_str:          .ascii " ]\n\r\0"

.balign 4

vm_error_handler:
    li a1, UART_BASE
    la a0, vm_str_error_message
    lw a0, 0(a0)
    call puts
1:
    j 1b
    ret

data_stack_base: .ascii "data stack base: \0"
return_stack_base: .ascii "return stack base: \0"
instruction_ptr: .ascii "instruction ptr: \0"
mem_end: .ascii "memory end: \0"
dict_end: .ascii "dict end: \0"

linened: .ascii "\n\r\0"
debug_store1: .ascii "Storing word \0"
debug_store2: .ascii " At address \0"
.balign 4

vm_run:
    SaveReturnAddress

    # init dictionary
    # This forth does not use the data section, it uses one or two variables in a data section-like way
    # setup data section
    la t0, begin_forth_data_section
    la t1, begin_forth_data_section_data
    la t3, end_forth_data_section
1:
    lw t2, 0(t1)
    sw t2, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 4
    
    bne t0, t3, 1b


    la a0, starting_interpreter_string
    li a1, UART_BASE
    call puts

    la a0, emit    

    # set interpreter variable registers
    la s1, vm_data_stack
    li s2, 0
    la s3, vm_return_stack
    li s4, 0
    la s5, _dataEnd
    la s0, outerInterpreter_impl

    # DEBUG - PRINT IMPORTANT VM VARS
    la a0, data_stack_base
    la a1, UART_BASE
    call puts
    mv a0, s1
    call print_int
    la a0, linened
    la a1, UART_BASE
    call puts

    la a0, return_stack_base
    la a1, UART_BASE
    call puts
    mv a0, s3
    call print_int
    la a0, linened
    la a1, UART_BASE
    call puts

    la a0, instruction_ptr
    la a1, UART_BASE
    call puts
    mv a0, s0
    call print_int
    la a0, linened
    la a1, UART_BASE
    call puts

    la a0, mem_end
    la a1, UART_BASE
    call puts
    mv a0, s5
    call print_int
    la a0, linened
    la a1, UART_BASE
    call puts

    
    la a0, dict_end
    la a1, UART_BASE
    call puts
    la t0, vm_p_dictionary_end
    lw t0, 0(t0)
    mv a0, t0
    call print_int
    la a0, linened
    la a1, UART_BASE
    call puts

    # DEBUG END

    call outerInterpreter_impl

    RestoreReturnAddress
    ret

word_header_first emit,   "emit",     PRIMITIVE_WORD_BITMASK, key
    PopDataStack a0
    li a1, UART_BASE
    call putc
    end_word

word_header       key,    "key",      PRIMITIVE_WORD_BITMASK, loadCell, emit
    li a0, UART_BASE
    call getc_block         # char in a0
    # call print_int
    # la a0, linened
    # li a1, UART_BASE
    # call puts
    PushDataStack a0
    end_word
                                           
word_header loadCell, "@", PRIMITIVE_WORD_BITMASK, store, key
    PopDataStack t2
    lw t3, 0(t2)
    PushDataStack t3
    end_word

word_header store, "!!", PRIMITIVE_WORD_BITMASK, loadByte, loadCell
    PopDataStack t2
    PopDataStack t3
    # store debug
    # PushReg t2
    # PushReg t3
    # mv t4, t3
    # mv t5, t2

    # la a0, debug_store1
    # li a1, UART_BASE
    # call puts

    # mv a0, t4
    # call print_int

    # la a0, debug_store2
    # li a1, UART_BASE
    # call puts

    # mv a0, t5
    # call print_int
    
    # la a0, linened
    # li a1, UART_BASE
    # call puts
    # PopReg t3
    # PopReg t2
    # store debug end
    sw t3, 0(t2)
    end_word
    
word_header loadByte, "c@", PRIMITIVE_WORD_BITMASK, storeByte, store
    PopDataStack t2
    lb t3, 0(t2)
    PushDataStack t3
    end_word

word_header storeByte, "c!!", PRIMITIVE_WORD_BITMASK, branchIfZero, loadByte
    PopDataStack t2
    PopDataStack t3
    sb t3, 0(t2)
    end_word

word_header branchIfZero, "b0", PRIMITIVE_WORD_BITMASK, branch, storeByte
    PopDataStack t2
    mv t1, s0 # s0 == PC
    beq t2, zero, 1f
    # no branch
    addi s0, s0, CELL_SIZE # skip over literal
    j 2f
1:
    addi t1, t1, CELL_SIZE # get literal
    lw t1, 0(t1)
    add s0, s0, t1         # add literal to PC
2:
    end_word

word_header branch, "b", 0, forth_add, branchIfZero
    mv t1, s0
    addi t1, t1, CELL_SIZE # get literal
    lw t1, 0(t1)
    add s0, s0, t1         # add literal to PC
    end_word

word_header forth_add, "+", 0, literal, branch
    PopDataStack t2
    PopDataStack t3
    add t2, t2, t3
    PushDataStack t2
    end_word
    
word_header literal, "literal", PRIMITIVE_WORD_BITMASK, dup, forth_add
    addi s0, s0, CELL_SIZE
    lw t3, 0(s0)
    PushDataStack t3
    end_word

word_header dup, "dup", PRIMITIVE_WORD_BITMASK, return, literal
    PopDataStack t2
    PushDataStack t2
    PushDataStack t2
    end_word
    
word_header return, "r", PRIMITIVE_WORD_BITMASK, forth_minus, dup
    PopReturnStack s0
    end_word

word_header forth_minus, "-", PRIMITIVE_WORD_BITMASK, swap, return
    PopDataStack t2
    PopDataStack t3
    sub t3, t3, t2
    PushDataStack t3
    end_word
    
word_header swap, "swap", PRIMITIVE_WORD_BITMASK, drop, forth_minus
    PopDataStack t2
    PopDataStack t3
    PushDataStack t2
    PushDataStack t3
    end_word

word_header drop, "drop", PRIMITIVE_WORD_BITMASK, dup2, swap
    PopDataStack t1
    end_word
    
word_header dup2, "2dup", PRIMITIVE_WORD_BITMASK, findXT, drop
    PopDataStack t1
    PopDataStack t2
    PushDataStack t2
    PushDataStack t1
    PushDataStack t2
    PushDataStack t1
    end_word
    
word_header findXT, "!'", 0, forth_and, dup2
    PopDataStack t5   # t5 == string ptr
    PopDataStack t6   # t6 == string length
    
    la t4, vm_p_dictionary_end
    lw t4, 0(t4)

#     mv a0, t4
#     call print_int
# 1:
#     j 1b
1:
    word_code t4, t2

    # DEBUG BEGIN
    # PushReg t2
    # mv a0, t2
    # li a1, UART_BASE
    # call puts
    # la a0, linened
    # li a1, UART_BASE
    # call puts
    # PopReg t2
    # DEBUG_END

    mv a0, t2
    mv a1, t5
    mv a2, t6
    
    PushReg t4
    PushReg t5
    PushReg t6

    call strcmp_fs_cs

    PopReg t6
    PopReg t5
    PopReg t4
# 1:
#     j 1b
    
    bne a3, zero, 3f # its a match! 
    lw t1, OFFSET_PREV(t4)
    beq t1, zero, 2f
    mv t4, t1
    j 1b
2: 
    PushDataStack zero
    end_word
3:
    addi t4, t4, HEADER_SIZE
    PushDataStack t4
    end_word          
    
word_header forth_and, "!&", PRIMITIVE_WORD_BITMASK, forth_or, findXT
    PopDataStack t2
    PopDataStack t3
    and t2, t2, t3
    PushDataStack t2
    end_word

word_header forth_or, "!|", PRIMITIVE_WORD_BITMASK, forth_xor, forth_and
    PopDataStack t2
    PopDataStack t3
    or t2, t2, t3
    PushDataStack t2
    end_word

word_header forth_xor, "!^", PRIMITIVE_WORD_BITMASK, here, forth_or
    PopDataStack t2
    PopDataStack t3
    xor t2, t2, t3
    PushDataStack t2
    end_word
    
word_header here, "here", PRIMITIVE_WORD_BITMASK, rot, forth_xor
    PushDataStack s5
    end_word

word_header rot, "rot", PRIMITIVE_WORD_BITMASK, push_return, here
    PopDataStack t1
    PopDataStack t2
    PopDataStack t3
    PushDataStack t2
    PushDataStack t1
    PushDataStack t3
    end_word
    
word_header push_return, "!>R", PRIMITIVE_WORD_BITMASK, pop_return, rot
    PopDataStack t1
    PushReturnStack t1
    end_word

word_header pop_return, "!<R", PRIMITIVE_WORD_BITMASK, forth_fatoi, push_return
    PopReturnStack t1
    PushDataStack t1
    end_word

word_header forth_fatoi, "$", PRIMITIVE_WORD_BITMASK, show, pop_return
    # ( buffer size -- num )
    PopDataStack a1
    PopDataStack a0
    call fatoi
    PushDataStack a2
    end_word

# Its good to have this one NOT in forth, because you can rely on it working correctly more
# knowing that its not part of the forth system and it is very useful for debugging. There is just
# less things to go wrong this way.
word_header show, "show", PRIMITIVE_WORD_BITMASK, execute, forth_fatoi
    # DATA STACK
    la a0, show_data_stack_begin_str
    li a1, UART_BASE
    call puts

    mv t1, s1               # t1 = data stack ptr
    mv t2, s2               # t2 = data stack size
    beq t2, zero, data_stack_empty
    add t3, t1, t2          # t3 = pointer end point
    li t0, CELL_SIZE
    sub t4, t3, t0 # penultimate pointer value
1:
    lw t0, 0(t1)

    PushReg t1
    PushReg t3
    PushReg t4

    mv a0, t0
    la a1, vm_scratch_pad
    li a2, 64
    call itofa
    
    la a0, vm_scratch_pad
    li a1, UART_BASE
    call puts
    PopReg t4
    PopReg t3
    PopReg t1

    PushReg t3
    PushReg t1
    beq t1, t4, 2f  # skip comma if on last stack entry
    la a0, show_comma_sep_str
    li a1, UART_BASE
    call puts
2:
    PopReg t1
    PopReg t3
    
    
    addi t1, t1, CELL_SIZE
    bne t1, t3, 1b

    la a0, show_stack_end_str
    li a1, UART_BASE
    call puts
    end_word
data_stack_empty:
    la a0, show_stack_end_str
    li a1, UART_BASE
    call puts
    end_word

word_header execute, "execute", PRIMITIVE_WORD_BITMASK, showR, show
    PopDataStack t2
    jalr ra, t2, 0
    end_word         # should never be hit

word_header showR, "showR", PRIMITIVE_WORD_BITMASK, setHere, execute
    # RETURN STACK
    la a0, show_return_stack_begin_str
    li a1, UART_BASE
    call puts

    mv t1, s3               # t1 = data stack ptr
    mv t2, s4               # t2 = data stack size
    beq t2, zero, return_stack_empty
    add t3, t1, t2          # t3 = pointer end point
    li t0, CELL_SIZE
    sub t4, t3, t0 # penultimate pointer value
1:
    lw t0, 0(t1)

    PushReg t1
    PushReg t3
    PushReg t4

    mv a0, t0
    la a1, vm_scratch_pad
    li a2, 64
    call itofa
    
    la a0, vm_scratch_pad
    li a1, UART_BASE
    call puts
    PopReg t4
    PopReg t3
    PopReg t1

    PushReg t3
    PushReg t1
    beq t1, t4, 2f  # skip comma if on last stack entry
    la a0, show_comma_sep_str
    li a1, UART_BASE
    call puts
2:
    PopReg t1
    PopReg t3
    
    
    addi t1, t1, CELL_SIZE
    bne t1, t3, 1b

    la a0, show_stack_end_str
    li a1, UART_BASE
    call puts
    end_word
return_stack_empty:
    la a0, show_stack_end_str
    li a1, UART_BASE
    call puts
    end_word

word_header setHere, "setHere", PRIMITIVE_WORD_BITMASK, return_stack_index, showR
    PopDataStack s5
    end_word

word_header return_stack_index, "R[]", PRIMITIVE_WORD_BITMASK, getDictionaryEnd, setHere
    PopDataStack t3
    bgt t3, zero, invalid_rstack_index
    mv t0, s3 # s3 - return stack base pointer
    mv t1, s4 # s4 - return stack size
    addi t1, t1, -CELL_SIZE
    add t0, t0, t1 # t0 points to end of stack
    
    lw t4, 0(t0)

    li t2, CELL_SIZE
    mul t3, t3, t2
    add t3, t0, t3
    blt t3, s3, invalid_rstack_index
    PushDataStack t3
    end_word
invalid_rstack_index:
    li t3, 0
    PushDataStack t3
    end_word

word_header getDictionaryEnd, "getDictionaryEnd", PRIMITIVE_WORD_BITMASK, setDictionaryEnd, return_stack_index
    # ( -- pDictEnd )
    la t1, vm_p_dictionary_end
    lw t1, 0(t1)
    PushDataStack t1
    end_word

word_header setDictionaryEnd, "setDictionaryEnd", PRIMITIVE_WORD_BITMASK, toCString, getDictionaryEnd
    # ( pDictEndNew -- )
    PopDataStack t1
    la t0, vm_p_dictionary_end
    sw t1, 0(t0)
    end_word

word_header toCString, "toCString", PRIMITIVE_WORD_BITMASK, setNumInputHex, setDictionaryEnd
    # ( inStringLen inString outCString -- )
    PopDataStack a0
    PopDataStack a1
    PopDataStack a2
    call forth_string_to_c
    end_word

word_header setNumInputHex, "ioHex", PRIMITIVE_WORD_BITMASK, setNumInputDec, toCString
    la t1, vm_flags
    lw t0, 0(t1)
    ori t0, t0, NUM_IO_HEX_BIT
    sw t0, 0(t1)
    end_word

word_header setNumInputDec, "ioDec", PRIMITIVE_WORD_BITMASK, equals, setNumInputHex
    la t1, vm_flags
    lw t0, 0(t1)
    li t2, NUM_IO_HEX_BIT
    xori t2, t2, -1
    and t0, t0, t2 # t0 &= ~NUM_IO_HEX_BIT
    sw t0, 0(t1)
    end_word

word_header equals, "!=", PRIMITIVE_WORD_BITMASK, notEquals, setNumInputDec
    PopDataStack t1
    PopDataStack t2
    beq t1, t2, equals_equals
    PushDataStack zero
    j equals_end
equals_equals:
    li t1, 1
    PushDataStack t1
equals_end:
    end_word
    
word_header notEquals, "!!!=", PRIMITIVE_WORD_BITMASK, lessThan, equals
    PopDataStack t1
    PopDataStack t2
    bne t1, t2, nq_equals
    PushDataStack zero
    j nq_end
nq_equals:
    li t2, 1
    PushDataStack t2 
nq_end:
    end_word
    
word_header lessThan, "!<", PRIMITIVE_WORD_BITMASK, greaterThan, notEquals
    PopDataStack t1
    PopDataStack t2
    blt t2, t1, lt
    PushDataStack zero
    j lt_end
lt:
    li t2, 1
    PushDataStack t2
lt_end:
    end_word

word_header greaterThan, "!>", PRIMITIVE_WORD_BITMASK, modulo, lessThan
    PopDataStack t1
    PopDataStack t2
    bgt t2, t1, gt
    PushDataStack zero
    j gt_end
gt:
    li t1, 1
    PushDataStack t1
gt_end:
    end_word

word_header modulo, "mod", PRIMITIVE_WORD_BITMASK, forth_mul, greaterThan
    PopDataStack t1
    PopDataStack t2
    rem t2, t2, t1
    PushDataStack t2
    end_word

word_header forth_mul, "!*", PRIMITIVE_WORD_BITMASK, forth_div, modulo
    PopDataStack t1
    PopDataStack t2
    mul t2, t2, t1
    PushDataStack t2
    end_word

word_header forth_div, "/", PRIMITIVE_WORD_BITMASK, shift_left, forth_mul
    PopDataStack t1
    PopDataStack t2
    div t2, t2, t1
    PushDataStack t2
    end_word

word_header shift_left, "!<!<", PRIMITIVE_WORD_BITMASK, shift_right, forth_div
    PopDataStack t1
    PopDataStack t2
    sll t2, t2, t1
    PushDataStack t2
    end_word

word_header shift_right, "!>!>", PRIMITIVE_WORD_BITMASK, roll, shift_left
    PopDataStack t1
    PopDataStack t2
    srl t2, t2, t1
    PushDataStack t2
    end_word

    # s1 - data stack base pointer
    # s2 - data stack size

word_header roll, "roll", PRIMITIVE_WORD_BITMASK, jump, shift_right
    lw t0, 0(s1)  # store the first value in the stack for later
    add t1, s1, s2 # t1 = ptr end of stack
    addi t2, s1, 4 # t2 = read ptr
1:
    addi t3, t2, -4 # t3 = write ptr
    lw t4, 0(t2)    # iteration stack value
    sw t4, 0(t3)    # store in "empty hole"
    addi t2, t2, 4  # advance read ptr
    bne t2, t1, 1b  # branch if we've not reached the ehd
    addi t1, t1, -4 # pointer to the end
    sw t0, 0(t1)    # write first stack value at the end
    end_word

.balign 4
    
word_header jump, "jp", PRIMITIVE_WORD_BITMASK, pc, roll
    # branch is for PC relative branches, this is for branching to an absolute address
    addi s0, s0, CELL_SIZE # get literal
    lw s0, 0(s0)
    end_word
    
word_header pc, "pc", 0, forth_print_int, jump
    PushDataStack s0
    end_word

last_vm_word: # IMPORTANT: KEEP THIS LABEL POINTING TO THE LAST VM WORD.
word_header forth_print_int, ".", PRIMITIVE_WORD_BITMASK, first_system_word, pc
    PopDataStack a0
    call print_int
    end_word
