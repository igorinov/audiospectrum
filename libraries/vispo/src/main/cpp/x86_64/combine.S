/*
 *  Copyright (C) Ivan Gorinov, 2016
 *
 *  SPDX-License-Identifier: BSD-2-Clause
 */

.global fft_combine_s
.global fft_combine_d
.global pvft_init

.data

_avx_present:
        .byte      0

.code64

pvft_init:
        push        %rbx
        movl        $1, %eax
        cpuid
        test        $(1 << 28), %ecx
        setnz       _avx_present(%rip)
        pop         %rbx
        ret

#  RDI - complex sinusoid for this round
#  RSI - signal data
#  RDX - signal size
#  RCX - number of signals
#
#  RBX, R12 .. R15 are preserved (not used)

fft_combine_s:
        push        %rbx

        movq        %rdx, %r9                   #  L, signal size

        movq        %rdx, %rax                  #  L, signal size
        shlq        $3, %rax                    #  signal size in bytes
        movq        %rax, %r11
        addq        %rsi, %rax                  #  odd spectrum = data + L
        movq        %rax, %r10

_check_s4a:
        cmpb        $0, _avx_present(%rip)
        jz          _check_s2a

        test        $0x1f, %rbx                 #  alignment check
        jnz        _check_s2a

        test       $0x1f, %rsi                  #  alignment check
        jnz        _check_s2a

        test       $0x1f, %r10                 #  alignment check
        jnz         _check_s2a

_next_signal_s4a:

        movq        %rdi, %rbx                  #  S, complex sinusoid for this stage
        movq        %r9, %rdx

_next_pair_s4a:
        vmovaps     (%rbx), %ymm6               #  { s0, s1, s2, s3 }
        vmovaps     (%rsi), %ymm4               #  { a0, a1, a2, a3 }
        vmovaps     (%r10), %ymm5               #  { b0, b1, b2, b3 }

        vmovsldup   %ymm5, %ymm0                #  { Re(b0), Re(b0), Re(b1), Re(b1), Re(b2), Re(b2), Re(b3), Re(b3) }
        vmovshdup   %ymm5, %ymm1                #  { Im(b0), Im(b0), Im(b1), Im(b1), Im(b2), Im(b2), Im(b3), Im(b3) }

        vshufps     $0xb1, %ymm6, %ymm6, %ymm7  #  { Im(s0), Re(s0), Im(s1), Re(s1), Im(s2), Re(s2), Im(s3), Re(s3) }
        vmulps      %ymm6, %ymm0, %ymm0         #  { Re(b0)·Re(s0), Re(b0)·Im(s0), Re(b1)·Re(s1), Re(b1)·Im(s1), ... }
        vmulps      %ymm7, %ymm1, %ymm1         #  { Im(b0)·Im(s0), Im(b0)·Re(s0), Im(b1)·Im(s1), Im(b1)·Re(s1), ... }
        vaddsubps   %ymm1, %ymm0, %ymm0         #  { b0·s0, b1·s1, b2·s2, b3·s3 }
        vmovaps     %ymm4, %ymm3                #  { a0, a1, a2, a3 }
        vsubps      %ymm0, %ymm3, %ymm3         #  B = a - b·s
        vaddps      %ymm0, %ymm4, %ymm4         #  A = a + b·s

        vmovaps     %ymm4, (%rsi)               #  { A0, A1, A2, A3 }
        vmovaps     %ymm3, (%r10)               #  { B0, B1, B2, B3 }

        addq        $32, %rsi                   #  pt_a += 4
        addq        $32, %r10                   #  pt_b += 4
        addq        $32, %rbx                   #  pt_s += 4
        subq        $4, %rdx
        jnz         _next_pair_s4a

        addq        %r11, %rsi                  #  pt_a += n
        addq        %r11, %r10                  #  pt_b += n

        subq        $1, %rcx                    #  signal counter
        jnz         _next_signal_s4a

        jmp         _end_s

_check_s2a:
        test        $0x0f, %rbx                 #  alignment check
        jnz        _next_signal_s1

        test        $0x0f, %rsi                 #  alignment check
        jnz         _next_signal_s1

        test        $0x0f, %r10                 #  alignment check
        jnz         _next_signal_s1

_next_signal_s2a:

        movq        %rdi, %rbx                  #  S, complex sinusoid for this stage
        movq        %r9, %rdx

_next_pair_s2a:
        movaps      (%rbx), %xmm6               #  { s0, s1 }
        movaps      (%rsi), %xmm4               #  { a0, a1 }
        movaps      (%r10), %xmm5               #  { b0, b1 }

        movsldup    %xmm5, %xmm0                #  { Re(b0), Re(b0), Re(b1), Re(b1) }

        movshdup    %xmm5, %xmm1                #  { Im(b0), Im(b0), Im(b1), Im(b1) }

        movaps      %xmm6, %xmm7
        shufps      $0xb1, %xmm6, %xmm7         #  { Im(s0), Re(s0), Im(s1), Re(s1) }
        mulps       %xmm6, %xmm0                #  { Re(b0)·Re(s0), Re(b0)·Im(s0), Re(b1)·Re(s1), Re(b1)·Im(s1) }
        mulps       %xmm7, %xmm1                #  { Im(b0)·Im(s0), Im(b0)·Re(s0), Im(b1)·Im(s1), Im(b1)·Re(s1) }
        addsubps    %xmm1, %xmm0                #  { b0·s0, b1·s1 }
        movaps      %xmm4, %xmm3                #  { a0, a1 }
        subps       %xmm0, %xmm3                #  B = a - b·s
        addps       %xmm0, %xmm4                #  A = a + b·s

        movaps      %xmm4, (%rsi)               #  { A0, A1 }
        movaps      %xmm3, (%r10)               #  { B0, B1 }

        addq        $16, %rsi                   #  pt_a += 4
        addq        $16, %r10                   #  pt_b += 4
        addq        $16, %rbx                   #  pt_s += 4
        subq        $2, %rdx
        jnz         _next_pair_s2a

        addq        %r11, %rsi                  #  pt_a += n
        addq        %r11, %r10                  #  pt_b += n

        subq        $1, %rcx                    #  signal counter
        jnz         _next_signal_s2a

        jmp         _end_s

_next_signal_s1:

        movq        %rdi, %rbx                  #  S, complex sinusoid for this stage
        movq        %r9, %rdx

_next_pair_s1:
        movlps      (%rbx), %xmm6               #  s[j]
        movlps      (%rsi), %xmm4               #  a[j]
        movlps      (%r10), %xmm5               #  b[j]

        movlhps     %xmm6, %xmm6                #  { Re(s), Im(s), Re(s), Im(s) }
        movaps      %xmm5, %xmm0
        unpcklps    %xmm0, %xmm0                #  { Re(b), Re(b), Im(b), Im(b) }
        mulps       %xmm6, %xmm0                #  { Re(b)·Re(s), Re(b)·Im(s), Im(b)·Re(s), Im(b)·Im(s) }

        movaps      %xmm0, %xmm1

        shufps      $0xbb, %xmm1, %xmm1         #  { Im(b)·Im(s), Im(b)·Re(s), Im(b)·Im(s), Im(b)·Re(s) }
        movlhps     %xmm0, %xmm0                #  { Re(b)·Re(s), Re(b)·Im(s), Re(b)·Re(s), Re(b)·Im(s) }
        addsubps    %xmm1, %xmm0                #  { b·s, b·s }

        unpcklps    %xmm4, %xmm4                #  { Re(a),   Re(a),   Im(a),   Im(a)   }
        unpcklps    %xmm0, %xmm0                #  { Re(b·s), Re(b·s), Im(b·s), Im(b·s) }
        addsubps    %xmm0, %xmm4                #  { Re(B),   Re(A),   Im(B),   Im(A)   }
        shufps      $0x8d, %xmm4, %xmm4         #  { Re(A),   Im(A),   Re(B),   Im(B)   }

        movlps      %xmm4, (%rsi)               #  { A }
        movhps      %xmm4, (%r10)               #  { B }

        addq        $8, %rsi                    #  pt_a += 1
        addq        $8, %r10                    #  pt_b += 1
        addq        $8, %rbx                    #  pt_s += 1
        subq        $1, %rdx                    #  sample counter
        jnz         _next_pair_s1

        addq        %r11, %rsi                  #  pt_a += n
        addq        %r11, %r10                  #  pt_b += n

        decq        %rcx                        #  signal counter
        jnz         _next_signal_s1
_end_s:
        emms

        pop         %rbx
        ret

fft_combine_d:
        push        %rbx

        movq        %rdx, %r9                   #  L, signal size

        movq        %rdx, %rax                  #  L, signal size
        shlq        $4, %rax                    #  signal size in bytes
        movq        %rax, %r11
        addq        %rsi, %rax                  #  data + L
        movq        %rax, %r10

        test        $0x1f, %rbx
        jnz         _next_signal_d1

        test        $0x1f, %rsi
        jnz         _next_signal_d1

        test        $0x1f, %r10
        jnz         _next_signal_d1

_next_signal_d2a:
        movq        %rdi, %rbx                  #  S, complex sinusoid lookup table
        movq        %r9, %rdx

_next_pair_d2a:
        vmovapd     (%rbx), %ymm6               #  { s0, s1 }
        vmovapd     (%rsi), %ymm4               #  { a0, a1 }
        vmovapd     (%r10), %ymm5               #  { b0, b1 }

        vunpcklpd   %ymm5, %ymm5, %ymm0         #  YMM0 = { Re(b0), Re(b0), Re(b1), Re(b1) }
        vunpckhpd   %ymm5, %ymm5, %ymm1         #  YMM1 = { Im(b0), Im(b0), Im(b1), Im(b1) }
        vmulpd      %ymm6, %ymm0, %ymm0         #  { Re(b0)·Re(s0), Re(b0)·Im(s0), Re(b1)·Re(s1), Re(b1)·Im(s1) }
        vmulpd      %ymm6, %ymm1, %ymm1         #  { Im(b0)·Re(s0), Im(b0)·Im(s0), Im(b1)·Re(s1), Im(b1)·Im(s1) }
        vshufpd     $0x55, %ymm1, %ymm1, %ymm1  #  { Im(b0)·Im(s0), Im(b0)·Re(s0), Im(b1)·Im(s1), Im(b1)·Re(s1) }
        vaddsubpd   %ymm1, %ymm0, %ymm0         #  { b0·s0, b1·s1 }
        vmovapd     %ymm4, %ymm3                #  { a0, a1 }
        vsubpd      %ymm0, %ymm3, %ymm3         #  { a0 - b0·s0, a1 - b1·s1 }
        vaddpd      %ymm0, %ymm4, %ymm4         #  { a0 + b0·s0, a1 + b1·s1 }

        vmovapd     %ymm4, (%rsi)               #  { A0, A1 }
        vmovapd     %ymm3, (%r10)               #  { B0, B1 }

        addq        $32, %rsi                   #  pt_a += 2
        addq        $32, %r10                   #  pt_b += 2
        addq        $32, %rbx                   #  pt_s += 2
        subq        $2, %rdx                    #  sample counter
        jnz         _next_pair_d2a

        addq        %r11, %rsi                  #  pt_a += n
        addq        %r11, %r10                  #  pt_b += n

        subq        $1, %rcx                    #  signal counter
        jnz         _next_signal_d2a

        jmp         _end_d

_next_signal_d1:
        movq        %rdi, %rbx                  #  S, complex sinusoid lookup table
        movq        %r9, %rdx

_next_pair_d1:
        movapd      (%rbx), %xmm6               #  s[j]
        movapd      (%rsi), %xmm4               #  a[j]
        movapd      (%r10), %xmm5               #  b[j]

        movapd      %xmm5, %xmm0
        movapd      %xmm5, %xmm1
        unpcklpd    %xmm0, %xmm0                #  { Re(b), Re(b) }
        unpckhpd    %xmm1, %xmm1                #  { Im(b), Im(b) }
        mulpd       %xmm6, %xmm0                #  { Re(b)·Re(s), Re(b)·Im(s) }
        mulpd       %xmm6, %xmm1                #  { Im(b)·Re(s), Im(b)·Im(s) }
        shufpd      $0x55, %xmm1, %xmm1         #  { Im(b)·Im(s), Im(b)·Re(s) }
        addsubpd    %xmm1, %xmm0                #  { b·s }
        movapd      %xmm4, %xmm3                #  { a }
        subpd       %xmm0, %xmm3                #  B = a - b·s
        addpd       %xmm0, %xmm4                #  A = a + b·s

        movapd      %xmm4, (%rsi)               #  { A }
        movapd      %xmm3, (%r10)               #  { B }

        addq        $16, %rsi                   #  pt_a += 1
        addq        $16, %r10                   #  pt_b += 1
        addq        $16, %rbx                   #  pt_s += 1
        subq        $1, %rdx                    #  sample counter
        jnz        _next_pair_d1

        addq        %r11, %rsi                  #  pt_a += n
        addq        %r11, %r10                  #  pt_b += n

        subq        $1, %rcx                    #  signal counter
        jnz         _next_signal_d1
_end_d:

        emms

        pop         %rbx
        ret

