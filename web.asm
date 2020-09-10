global _start:

section .text
print_string:
    push	rax
    push	rdi

    mov	rax, 1
    mov	rdi, 1
    syscall

    pop	rdi
    pop	rax
    ret

quit:
    mov	rax, 60
    xor	rdi, rdi
    syscall

_start:
    mov	rsi, msg
    mov	rdx, len
    call	print_string

    jmp	 quit

section .data
msg: db "Hello, World!", 10
len: equ $-msg
