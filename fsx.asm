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
    current_idx resq 1

section .text
    global _start

_start:
    mov rbx, [rsp]
    cmp rbx, 2
    jl exit_program

    mov rdi, [rsp+16]
    mov rsi, stats_flag
    call strcmp
    test rax, rax
    je stats_init

    mov rdi, [rsp+16]
    mov rsi, highlight_prefix
    mov rdx, 12
    call strncmp
    test rax, rax
    je highlight_init

    mov qword [current_idx], 2
    jmp default_loop

highlight_init:
    mov r14, [rsp+16]
    add r14, 12
    mov qword [current_idx], 3
    jmp highlight_loop

stats_init:
    mov qword [current_idx], 3
    jmp stats_loop

default_loop:
    mov rbx, [rsp]
    mov rsi, [current_idx]
    cmp rsi, rbx
    jg exit_program
    mov rdi, [rsp + rsi*8]
    mov rax, 2
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl open_error_d
    mov r15, rax
.r:
    mov rax, 0
    mov rdi, r15
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .c
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    syscall
    jmp .r
.c:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 3
    mov rdi, r15
    syscall
    inc qword [current_idx]
    jmp default_loop

highlight_loop:
    mov rbx, [rsp]
    mov rsi, [current_idx]
    cmp rsi, rbx
    jg exit_program
    mov rdi, [rsp + rsi*8]
    mov rax, 2
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl open_error_h
    mov r15, rax
.read:
    mov rax, 0
    mov rdi, r15
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .close
    mov r13, rax
    xor r12, r12
.scan:
    cmp r12, r13
    jge .read
    mov rbx, r14
    mov r10, r12
    xor rbp, rbp
.match:
    movzx rdx, byte [rbx]
    test rdx, rdx
    jz .found
    cmp r10, r13
    je .no_match
    movzx rax, byte [buffer + r10]
    mov r9, rdx
    cmp r9, 'A'
    jl .c1
    cmp r9, 'Z'
    jg .c1
    or r9, 0x20
.c1:
    mov r11, rax
    cmp r11, 'A'
    jl .c2
    cmp r11, 'Z'
    jg .c2
    or r11, 0x20
.c2:
    cmp r9, r11
    jne .no_match
    inc rbx
    inc r10
    inc rbp
    jmp .match
.found:
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
.close:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 3
    mov rdi, r15
    syscall
    inc qword [current_idx]
    jmp highlight_loop

stats_loop:
    mov rbx, [rsp]
    mov rsi, [current_idx]
    cmp rsi, rbx
    jg exit_program
    mov rdi, [rsp + rsi*8]
    mov rax, 2
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl open_error_s
    mov r15, rax
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
.read:
    mov rax, 0
    mov rdi, r15
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .done
    add r8, rax
    xor rcx, rcx
.l:
    cmp rcx, rax
    jge .read
    movzx rbx, byte [buffer + rcx]
    cmp rbx, 10
    jne .w
    inc r9
.w:
    cmp rbx, 32
    je .is_w
    cmp rbx, 10
    je .is_w
    cmp rbx, 9
    je .is_w
    test r11, r11
    jnz .next
    inc r10
    mov r11, 1
    jmp .next
.is_w:
    xor r11, r11
.next:
    inc rcx
    jmp .l
.done:
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
    inc qword [current_idx]
    jmp stats_loop

open_error_d:
    mov rax, 1
    mov rdi, 2
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    inc qword [current_idx]
    jmp default_loop

open_error_h:
    mov rax, 1
    mov rdi, 2
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    inc qword [current_idx]
    jmp highlight_loop

open_error_s:
    mov rax, 1
    mov rdi, 2
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    inc qword [current_idx]
    jmp stats_loop

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
    jnz .conv
    dec rsi
    mov byte [rsi], '0'
    jmp .out
.conv:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .conv
.out:
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