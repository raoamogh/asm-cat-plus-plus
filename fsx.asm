section .data
filename db "file.txt",0

section .bss
buffer resb 64

section .text
global _start

_start:
    mov rax, 2
    mov rdi, filename
    mov rsi, 0
    syscall

    mov rbx, rax

read_loop:
    mov rax, 0
    mov rdi, rbx
    mov rsi, buffer
    mov rdx, 64
    syscall

    cmp rax, 0
    je done

    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    syscall

    jmp read_loop

done:
    mov rax, 60
    mov rdi, 0
    syscall