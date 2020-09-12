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

%define LSEEK_END 2
%define LSEEK_SET 0

%define PROT_READ 1
%define PROT_WRITE 2
%define MAP_PRIVATE 2
%define MAP_ANONYMOUS 32

section .text
print_string:
    push	rax
    push	rdi

    mov	rax, SYS_WRITE
    mov	rdi, STDOUT
    syscall

    pop	rdi
    pop	rax
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

    ;TODO: use stack instead of filed
fopen:
.openfile:
    mov	rax, SYS_OPEN
    mov	rdi, filepath
    mov	rsi, O_RDONLY
    syscall
    mov	[filed], rax
    cmp	rax, 0
    jle	.end
.getsize:
    mov	rax, SYS_LSEEK
    mov	rdi, [filed]
    mov	rsi, 0
    mov	rdx, LSEEK_END
    syscall
    mov	[filelen], rax
    cmp	rax, 0
    jle	.end
    mov	rax, SYS_LSEEK
    mov	rdx, LSEEK_SET
    syscall
.alloc:
    mov	rax, SYS_MMAP
    xor	rdi, rdi
    mov	rsi, [filelen]
    mov	rdx, PROT_READ | PROT_WRITE
    mov	r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov	r8, -1
    xor	r9, r9
    syscall
    mov	rsi, rax
.read:
    mov	rax, SYS_READ
    mov	rdi, [filed]
    mov	rdx, [filelen]
    syscall
    mov	[fileb], rsi
.close:
    mov	rax, SYS_CLOSE
    mov	rdi, [filed]
    syscall
.end:
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

    mov	rax, SYS_BIND
    mov	rdi, [sfd]
    mov	rsi, server
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
    mov	rsi, server
    mov	rdx, serverlen
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

    call	fopen
    mov	rsi, [fileb]
    mov	rdx, [filelen]
    call	print_string

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

    jmp	client_loop

    jmp	quit

section .data
msg: db "Khello", 10
len: equ $-msg
errormsg: db "Failed to create socket", 10
errorlen: equ $-errormsg

filepath: db "./index.html", 0

section .bss
sfd: RESD 1
opt: RESQ 1
port: RESW 1
client: RESD 1

filed: RESW 1
fileb: RESQ 1
filelen: RESW 1


buffer: resb 1024

server:
.sin_family: RESW 1
.sin_port: RESW 1
.sin_addr: RESD 1
serverlen: RESD 1
