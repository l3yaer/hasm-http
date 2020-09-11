global _start:

%DEFINE AF_INET 2
%DEFINE SOCK_STREAM 1
%define SO_REUSEADDR 2
%define SOL_SOCKET 1

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

error_quit:
    mov	rsi, errormsg
    mov	rdx, errorlen
    call	print_string

    mov	rax, 60
    mov	rdi, 1
    syscall

socket:
    mov	rax, 41
    mov	rdi, AF_INET
    mov	rsi, SOCK_STREAM
    mov	rdx, 0
    syscall
    ret

sockopt:
    mov	rax, 54
    mov	rsi, SOL_SOCKET
    mov	rdx, SO_REUSEADDR
    mov	r10, opt
    mov	r8, 8
    syscall
    ret

bind:
    mov	rax, [port]
    xchg	al, ah
    mov	[server.sin_port], eax
    mov	[server.sin_family], word AF_INET
    mov	[server.sin_addr], dword 0

    mov	rax, 49
    mov	rdi, [sfd]
    mov	rsi, server
    mov	rdx, 16
    syscall
    ret

listen:
    mov	rax, 50
    mov	rdi, [sfd]
    mov	rsi, 3
    syscall
    ret

accept:
    mov	rax, 43
    mov	rdi, [sfd]
    mov	rsi, server
    mov	rdx, serverlen
    syscall
    ret

write:
    mov	rax, 1
    syscall
    ret

close:
    mov	rax, 3
    syscall
    ret

_start:

    call	socket
    mov	[sfd], rax
    cmp	rax, 0
    jle	error_quit

    mov	rdi, [sfd]
    call	sockopt
    cmp	rax, 0
    jne	error_quit

    mov	[port], word 8000
    call	bind
    cmp	rax, 0
    jne	error_quit

    call	listen
    cmp	rax, 0
    jne	error_quit

    mov	[serverlen], dword 16
client_loop:
    call	accept
    cmp	rax, 0
    jle	error_quit

    mov	[client], rax

    mov	rsi, msg
    mov	rdx, len
    mov	rdi, [client]
    call write

    mov	rdi, [client]
    call	close

    jmp	quit

section .data
msg: db "Khello", 10
len: equ $-msg
errormsg: db "Failed to create socket", 10
errorlen: equ $-errormsg

section .bss
sfd: RESD 1
opt: RESQ 1
port: RESW 1
client: RESD 1

server:
.sin_family: RESW 1
.sin_port: RESW 1
.sin_addr: RESD 1
serverlen: RESD 1
