section .data
    msg_lines db "Lines: "
    len_lines equ $ - msg_lines
    msg_words db "Words: "
    len_words equ $ - msg_words
    msg_bytes db "Bytes: "
    len_bytes equ $ - msg_bytes
    newline db 10
    err_msg db "Error: cannot open file", 10
    err_len equ $ - err_msg
    stats_flag db "--stats", 0
    highlight_prefix db "--highlight=", 0
    red_start db 27,"[31m"
    red_len equ $ - red_start
    red_end db 27,"[0m"
    red_end_len equ $ - red_end

section .bss
    buffer resb 4096
    num_buf resb 32

section .text
    global _start

_start:
    pop rax 
    cmp rax, 3
    jl exit_program

    mov rdi, [rsp+8]  
    
    mov rsi, stats_flag
    call strcmp
    test rax, rax
    je stats_mode

    mov rdi, [rsp+8]
    mov rsi, highlight_prefix
    mov rdx, 12
    call strncmp
    test rax, rax
    je highlight_prep

    jmp exit_program

highlight_prep:
    mov r14, [rsp+8]
    add r14, 12
    mov rdi, [rsp+16]
    mov rax, 2
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl open_error
    mov r15, rax

.read_loop:
    mov rax, 0
    mov rdi, r15
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .done_highlight
    mov r13, rax
    xor r12, r12

.scan:
    cmp r12, r13
    jge .read_loop

    mov rbx, r14
    mov r10, r12
    xor rbp, rbp

.match_check:
    movzx r8, byte [rbx]
    test r8, r8
    jz .found_match

    cmp r10, r13
    je .no_match

    movzx r9, byte [buffer + r10]

    mov r11, r8
    cmp r11, 'A'
    jl .skip_p1
    cmp r11, 'Z'
    jg .skip_p1
    or r11, 0x20
.skip_p1:
    mov rdx, r9
    cmp rdx, 'A'
    jl .skip_p2
    cmp rdx, 'Z'
    jg .skip_p2
    or rdx, 0x20
.skip_p2:

    cmp r11, rdx
    jne .no_match

    inc rbx
    inc r10
    inc rbp
    jmp .match_check

.found_match:
    mov rax, 1
    mov rdi, 1
    mov rsi, red_start
    mov rdx, red_len
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [buffer + r12]
    mov rdx, rbp
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, red_end
    mov rdx, red_end_len
    syscall

    add r12, rbp
    jmp .scan

.no_match:
    mov rax, 1
    mov rdi, 1
    lea rsi, [buffer + r12]
    mov rdx, 1
    syscall
    inc r12
    jmp .scan

.done_highlight:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 3          
    mov rdi, r15
    syscall
    jmp exit_program

stats_mode:
    mov rdi, [rsp+16]
    mov rax, 2
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl open_error
    mov r15, rax

    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11

.stats_read:
    mov rax, 0
    mov rdi, r15
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .stats_done
    add r8, rax
    
    xor rcx, rcx
.stats_loop:
    cmp rcx, rax
    jge .stats_read
    movzx rbx, byte [buffer + rcx]

    cmp rbx, 10
    jne .check_ws
    inc r9
.check_ws:
    cmp rbx, 32
    je .is_ws
    cmp rbx, 10
    je .is_ws
    cmp rbx, 9
    je .is_ws

    test r11, r11
    jnz .next_char
    inc r10
    mov r11, 1
    jmp .next_char
.is_ws:
    xor r11, r11
.next_char:
    inc rcx
    jmp .stats_loop

.stats_done:
    mov rax, 3
    mov rdi, r15
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_lines
    mov rdx, len_lines
    syscall
    mov rax, r9
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_words
    mov rdx, len_words
    syscall
    mov rax, r10
    call print_number

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_bytes
    mov rdx, len_bytes
    syscall
    mov rax, r8
    call print_number
    jmp exit_program

open_error:
    mov rax, 1
    mov rdi, 2
    mov rsi, err_msg
    mov rdx, err_len
    syscall

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall

strcmp:
    xor rax, rax
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .ne
    test al, al
    jz .eq
    inc rdi
    inc rsi
    jmp .loop
.ne:
    mov rax, 1
    ret
.eq:
    xor rax, rax
    ret

strncmp:
    xor rax, rax
.loop:
    test rdx, rdx
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
    jmp .loop
.ne:
    mov rax, 1
    ret
.eq:
    xor rax, rax
    ret

print_number:
    mov rbx, 10
    lea rsi, [num_buf + 31]
    mov byte [rsi], 0
    mov r12, rsi
    
    test rax, rax
    jnz .convert
    dec rsi
    mov byte [rsi], '0'
    jmp .output

.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .convert

.output:
    mov rdx, r12
    sub rdx, rsi
    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret