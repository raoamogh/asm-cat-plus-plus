section .data
    msg_bench_cyc  db "Bench - CPU Cycles: ", 0
    msg_bench_time db "Bench - Process Time: ", 0
    msg_bench_size db "Bench - Total Size: ", 0
    msg_bench_tp   db "Bench - Throughput: ", 0
    msg_ms         db " ms", 10, 0
    msg_bytes      db " bytes", 10, 0
    msg_kbs        db " KB/s", 10, 0
    newline        db 10
    highlight_pfx  db "--highlight=", 0
    ic_flag        db "--ignore-case", 0
    ln_flag        db "-n", 0
    bn_flag        db "--bench", 0
    red_s          db 27,"[31m"
    red_s_len      equ $ - red_s
    red_e          db 27,"[0m"
    red_e_len      equ $ - red_e
    err_msg        db "Error: Operation failed", 10
    err_len        equ $ - err_msg
    colon_sep      db ": ", 0

section .bss
    num_buf          resb 32
    current_idx      resq 1
    ignore_case_bool resb 1
    line_num_bool    resb 1
    bench_bool       resb 1
    start_cycles     resq 1
    total_bytes      resq 1
    file_size        resq 1
    mmap_ptr         resq 1
    pattern_ptr      resq 1
    line_counter     resq 1

section .text
    global _start

_start:
    mov rbp, [rsp]          ; argc
    cmp rbp, 2
    jl exit_program

    mov qword [current_idx], 1
    mov byte [ignore_case_bool], 0
    mov byte [line_num_bool], 0
    mov byte [bench_bool], 0
    mov qword [total_bytes], 0
    mov qword [pattern_ptr], 0

.parse_args:
    mov rcx, [current_idx]
    cmp rcx, rbp
    jge .execute_prep
    mov rdi, [rsp + rcx*8 + 8]
    
    mov rsi, ic_flag
    call strcmp
    test rax, rax
    jz .set_ic

    mov rcx, [current_idx]
    mov rdi, [rsp + rcx*8 + 8]
    mov rsi, ln_flag
    call strcmp
    test rax, rax
    jz .set_ln

    mov rcx, [current_idx]
    mov rdi, [rsp + rcx*8 + 8]
    mov rsi, bn_flag
    call strcmp
    test rax, rax
    jz .set_bn

    mov rcx, [current_idx]
    mov rdi, [rsp + rcx*8 + 8]
    mov rsi, highlight_pfx
    mov rdx, 12
    call strncmp
    test rax, rax
    jz .set_hl

    ; If not a flag, assume it's the start of files
    mov rcx, [current_idx]
    mov rdi, [rsp + rcx*8 + 8]
    cmp byte [rdi], '-'
    jne .execute_prep
    inc qword [current_idx]
    jmp .parse_args

.set_ic: mov byte [ignore_case_bool], 1
    inc qword [current_idx]
    jmp .parse_args
.set_ln: mov byte [line_num_bool], 1
    inc qword [current_idx]
    jmp .parse_args
.set_bn: mov byte [bench_bool], 1
    inc qword [current_idx]
    jmp .parse_args
.set_hl: mov rcx, [current_idx]
    mov rdi, [rsp + rcx*8 + 8]
    add rdi, 12
    mov [pattern_ptr], rdi
    inc qword [current_idx]
    jmp .parse_args

.execute_prep:
    cmp byte [bench_bool], 1
    jne .process_files
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [start_cycles], rax

.process_files:
    mov rcx, [current_idx]
    mov rbp, [rsp]
    cmp rcx, rbp
    jge .finish
    mov rdi, [rsp + rcx*8 + 8]
    call process_single_file
    inc qword [current_idx]
    jmp .process_files

.finish:
    cmp byte [bench_bool], 1
    jne .final_nl
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [start_cycles]
    mov r15, rax ; Total cycles

    ; Print Size
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_bench_size
    mov rdx, 20
    syscall
    mov rax, [total_bytes]
    call print_num_raw
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_bytes
    mov rdx, 7
    syscall

    ; Print Time (ms) - Approx 3GHz
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_bench_time
    mov rdx, 22
    syscall
    mov rax, r15
    xor rdx, rdx
    mov rbx, 3000000 
    div rbx
    mov r14, rax ; ms
    call print_num_raw
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_ms
    mov rdx, 4
    syscall

    ; Throughput (Bytes * 1000 / ms) / 1024 = KB/s
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_bench_tp
    mov rdx, 20
    syscall
    test r14, r14
    jz .tp_zero
    mov rax, [total_bytes]
    mov rbx, 1000
    mul rbx             ; rax = total_bytes * 1000
    div r14             ; rax = bytes per second
    shr rax, 10         ; rax = KB/s
    call print_num_raw
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_kbs
    mov rdx, 6
    syscall
    jmp .final_nl

.tp_zero:
    mov rax, 1
    mov rdi, 1
    mov rsi, num_buf
    mov byte [rsi], '0'
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_kbs
    mov rdx, 6
    syscall

.final_nl:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall

process_single_file:
    mov rax, 2
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl .err
    mov r15, rax

    mov rax, 8              ; lseek SEEK_END
    mov rdi, r15
    xor rsi, rsi
    mov rdx, 2
    syscall
    mov [file_size], rax
    add [total_bytes], rax
    test rax, rax
    jz .close_f

    mov rax, 8              ; lseek SEEK_SET
    mov rdi, r15
    xor rsi, rsi
    xor rdx, rdx
    syscall

    mov rax, 9              ; mmap
    xor rdi, rdi
    mov rsi, [file_size]
    mov rdx, 1              ; PROT_READ
    mov r10, 2              ; MAP_PRIVATE
    mov r8, r15
    xor r9, r9
    syscall
    cmp rax, -4095
    jae .err
    mov [mmap_ptr], rax

    mov r12, rax            ; Current ptr
    mov r13, rax
    add r13, [file_size]    ; End ptr
    mov qword [line_counter], 1
    mov r14, 1              ; Newline flag

.scan:
    cmp r12, r13
    jge .done_file
    cmp byte [line_num_bool], 1
    jne .check_hl
    test r14, r14
    jz .check_hl
    mov rax, [line_counter]
    call print_num_raw
    mov rax, 1
    mov rdi, 1
    mov rsi, colon_sep
    mov rdx, 2
    syscall
    xor r14, r14

.check_hl:
    mov rdi, [pattern_ptr]
    test rdi, rdi
    jz .plain
    call regex_match
    test rax, rax
    jz .plain
    mov rbx, rax
    push rax
    mov rax, 1
    mov rdi, 1
    mov rsi, red_s
    mov rdx, red_s_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, r12
    mov rdx, rbx
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, red_e
    mov rdx, red_e_len
    syscall
    pop rax
    add r12, rax
    jmp .scan

.plain:
    movzx rax, byte [r12]
    cmp al, 10
    jne .out
    inc qword [line_counter]
    mov r14, 1
.out:
    mov rax, 1
    mov rdi, 1
    mov rsi, r12
    mov rdx, 1
    syscall
    inc r12
    jmp .scan

.done_file:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 11
    mov rdi, [mmap_ptr]
    mov rsi, [file_size]
    syscall
.close_f:
    mov rax, 3
    mov rdi, r15
    syscall
    ret
.err:
    mov rax, 1
    mov rdi, 2
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    ret

regex_match:
    xor rcx, rcx
.lp:
    mov r8, [pattern_ptr]
    movzx r8, byte [r8 + rcx]
    test r8, r8
    jz .ok
    lea rdx, [r12 + rcx]
    cmp rdx, r13
    jge .fail
    movzx r9, byte [rdx]
    cmp r8, '.'
    je .nxt
    cmp byte [ignore_case_bool], 1
    jne .st
    ; Normalize r8 (pattern)
    cmp r8, 'A'
    jl .c1
    cmp r8, 'Z'
    jg .c1
    or r8, 0x20
.c1: ; Normalize r9 (text)
    cmp r9, 'A'
    jl .c2
    cmp r9, 'Z'
    jg .c2
    or r9, 0x20
.c2:
.st: cmp r8, r9
    jne .fail
.nxt: inc rcx
    jmp .lp
.ok: mov rax, rcx
    ret
.fail: xor rax, rax
    ret

strcmp:
    xor rax, rax
.l: mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .ne
    test al, al
    jz .eq
    inc rdi
    inc rsi
    jmp .l
.ne: mov rax, 1
    ret
.eq: xor rax, rax
    ret

strncmp:
    xor rax, rax
.l: test rdx, rdx
    jz .eq
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .ne
    test al, al
    jz .eq
    inc rdi
    inc rsi
    dec rdx
    jmp .l
.ne: mov rax, 1
    ret
.eq: xor rax, rax
    ret

print_num_raw:
    mov rbx, 10
    lea rsi, [num_buf + 31]
    mov byte [rsi], 0
    mov r8, rsi
    test rax, rax
    jnz .c
    dec rsi
    mov byte [rsi], '0'
    jmp .o
.c: xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .c
.o: mov rdx, r8
    sub rdx, rsi
    mov rax, 1
    mov rdi, 1
    syscall
    ret

print_number:
    call print_num_raw
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret