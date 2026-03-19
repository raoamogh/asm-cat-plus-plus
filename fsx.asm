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

section .bss
buffer resb 4096
num_buf resb 32

section .text
global _start

_start:
    xor r8, r8      
    xor r9, r9      
    xor r10, r10    
    xor r11, r11   

    mov rbx, [rsp]
    cmp rbx, 3
    jl exit

    mov rdi, stats_flag
    mov rsi, [rsp+16]
    call strcmp
    cmp rax, 0
    jne exit

    mov rdi, [rsp+24]

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
    je done
    jl done

    add r8, rax

    xor rcx, rcx

process_buffer:

    cmp rcx, rax
    jge read_loop

    mov bl, [buffer + rcx]

    cmp bl, 10
    jne .no_newline
    inc r9
.no_newline:

    cmp bl, ' '
    je .delimiter
    cmp bl, 10
    je .delimiter
    cmp bl, 9
    je .delimiter

    cmp r11, 1
    je .next
    inc r10
    mov r11, 1
    jmp .next

.delimiter:
    mov r11, 0

.next:
    inc rcx
    jmp process_buffer

done:
    mov rax, 3
    mov rdi, r12
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

    jmp exit

open_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, err_msg
    mov rdx, err_len
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

strcmp:
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .not_equal
    test al, al
    je .equal
    inc rdi
    inc rsi
    jmp .loop

.not_equal:
    mov rax, 1
    ret

.equal:
    xor rax, rax
    ret

print_number:

    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rbx, 10
    lea rsi, [num_buf + 31]   
    mov rcx, 0

    mov byte [rsi], 0
    dec rsi

    cmp rax, 0
    jne .convert
    mov byte [rsi], '0'
    inc rcx
    jmp .done_convert

.convert:
.convert_loop:
    xor rdx, rdx
    div rbx
    add rdx, '0'
    mov [rsi], dl
    dec rsi
    inc rcx
    test rax, rax
    jne .convert_loop

.done_convert:

    inc rsi  
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret