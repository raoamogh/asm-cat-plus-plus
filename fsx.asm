section .data
err_msg db "Error: Cannot Open File", 10
err_len equ $ - err_msg

section .bss
buffer resb 4096

section .text
global _start

_start:
    mov rbx, [rsp]
    cmp rbx, 2
    jl exit
    
    mov r13, 1

next_file:
    cmp r13, rbx
    jge exit
    mov rdi, [rsp+r13*8+8]
    mov rax, 2
    mov rsi, 0
    syscall
    cmp rax, 0
    jl open_error
    mov r12, rax

read_loop:
    mov rax, 0
    mov rdi, r12
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    je close_file
    jl close_file
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    syscall
    jmp read_loop

close_file:
    mov rax, 3
    mov rdi, r12
    syscall
    inc r13
    jmp next_file

open_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    inc r13
    jmp next_file

exit:
    mov rax, 60
    xor rdi, rdi
    syscall