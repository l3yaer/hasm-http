global _start:

%define AF_INET 2
%define SOCK_STREAM 1
%define SO_REUSEADDR 2
%define SOL_SOCKET 1

%define STDIN 0
%define STDOUT 1

%define SYS_ACCEPT 43
%define SYS_BIND 49
%define SYS_CLOSE 3
%define SYS_LISTEN 50
%define SYS_LSEEK 8
%define SYS_MMAP 9
%define SYS_MUNMAP 11
%define SYS_OPEN 2
%define SYS_QUIT 60
%define SYS_READ 0
%define SYS_SOCKET 41
%define SYS_SOCKOPT 54
%define SYS_WRITE 1

%define O_RDONLY 0
%define O_WRONLY 1
%define O_RDWR 2

%define SEEK_END 2
%define SEEK_SET 0

%define PROT_READ 1
%define PROT_WRITE 2
%define MAP_PRIVATE 2
%define MAP_ANONYMOUS 32

section .text
print_string:
    mov	rax, SYS_WRITE
    mov	rdi, STDOUT
    syscall
    ret

quit:
    mov	rax, SYS_QUIT
    xor	rdi, rdi
    syscall

error_quit:
    mov	rsi, errormsg
    mov	rdx, errorlen
    call	print_string

    mov	rax, SYS_QUIT
    mov	rdi, 1
    syscall

fopen:
    push	rbp
    mov	rbp, rsp
    sub	rsp, 48
.openfile:
    mov	rax, SYS_OPEN
    mov	rdi, filepath
    mov	rsi, O_RDONLY
    syscall
    mov	[rbp-8], rax        ;file descriptor
    cmp	rax, 0
    jle	.end
.getsize:
    mov	rax, SYS_LSEEK
    mov	rdi, [rbp-8]
    mov	rsi, 0
    mov	rdx, SEEK_END
    syscall
    mov	[rbp-16], rax       ;file size
    cmp	rax, 0
    jle	.end
    mov	rax, SYS_LSEEK
    mov	rdx, SEEK_SET
    syscall
.alloc:
    mov	rax, SYS_MMAP
    xor	rdi, rdi
    mov	rsi, [rbp-16]
    mov	rdx, PROT_READ | PROT_WRITE
    mov	r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov	r8, -1
    xor	r9, r9
    syscall
    mov	[rbp-24], qword rax       ;file contents
.read:
    mov	rax, SYS_READ
    mov	rdi, [rbp-8]
    mov	rsi, qword [rbp-24]
    mov	rdx, [rbp-16]
    syscall
.close:
    mov	rax, SYS_CLOSE
    mov	rdi, [rbp-8]
    syscall
.end:
    mov	rax, [rbp-16]
    mov	rdx, qword [rbp-24]
    mov	rsp, rbp
    pop	rbp
    mov	[filelen], rax
    mov	[fileb], qword rdx
    ret

socket:
    mov	rax, SYS_SOCKET
    mov	rdi, AF_INET
    mov	rsi, SOCK_STREAM
    mov	rdx, 0
    syscall
    ret

sockopt:
    mov	rax, SYS_SOCKOPT
    mov	rdi, [sfd]
    mov	rsi, SOL_SOCKET
    mov	rdx, SO_REUSEADDR
    mov	r10, opt
    mov	r8, 8
    syscall
    ret

bind:
    mov	rax, 8000
    xchg	al, ah
    mov [sa + sin_port], eax

    mov	rax, SYS_BIND
    mov	rdi, [sfd]
    mov	rsi, sa
    mov	rdx, 16
    syscall
    ret

listen:
    mov	rax, SYS_LISTEN
    mov	rdi, [sfd]
    mov	rsi, 3
    syscall
    ret

accept:
    mov	rax, SYS_ACCEPT
    mov	rdi, [sfd]
    xor	rsi, rsi
    xor	rdx, rdx
    syscall
    ret

write:
    mov	rax, SYS_WRITE
    syscall
    ret

close:
    mov	rax, SYS_CLOSE
    syscall
    ret

_start:

    call	fopen

    call	socket
    mov	[sfd], rax
    cmp	rax, 0
    jle	error_quit

    call	sockopt
    cmp	rax, 0
    jne	error_quit

    call	bind
    cmp	rax, 0
    jne	error_quit

    call	listen
    cmp	rax, 0
    jne	error_quit

client_loop:
    call	accept
    cmp	rax, 0
    jle	error_quit

    mov	[client], rax

    mov	rsi, [fileb]
    mov	rdx, [filelen]
    mov	rdi, [client]
    call	write

    mov	rdi, [client]
    call	close

    mov	rdi, [sfd]
    call	close

    jmp	quit

section .data
errormsg: db "Failed to create socket", 10
errorlen: equ $-errormsg

filepath: db "./index.html", 0

struc sockaddr_in
sin_family: resw 1
sin_port:   resw 1
sin_addr:   resd 1
endstruc

sa: istruc sockaddr_in
at sin_family, dw AF_INET
at sin_port,   dw 8000
at sin_addr,   dd 0 ;INADDR_ANY
iend

section .bss
sfd: RESQ 1
opt: RESQ 1
client: RESQ 1

fileb: RESQ 1
filelen: RESW 1
