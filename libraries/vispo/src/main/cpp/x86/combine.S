.global fft_combine_s
.global fft_combine_d

.code32

#  EBP  +8: complex exponent for this stage (w)
#  EBP +12: signal data
#  EBP +16: signal length, complex points (l)
#  EBP +20: number of signal pairs to combine (m)

fft_combine_s:
        push        %ebp
        movl        %esp, %ebp
        push        %ebx
        push        %edi
        push        %esi

        movl        12 (%ebp), %ebx             #  data

        movl        16 (%ebp), %eax             #  signal size in points
        shll        $3, %eax                    #  signal size in bytes
        movl        %eax, %edi

        movl        20 (%ebp), %edx             #  M, number of signals

_next_signal_s:
        movl        8 (%ebp), %esi              #  complex sinusoid lookup table
        movl        %edi, %ecx                  #  signal size in bytes
        shrl        $3, %ecx                    #  N, signal size in points
        test        $0x0f, %esi                 #  alignment check
        jnz         _next_pair_s1
        test        $0x0f, %ebx                 #  alignment check
        jnz         _next_pair_s1
        test        $1, %ecx
        jnz         _next_pair_s1

_next_pair_s2:
        movapd      (%esi), %xmm6               #  { s0, s1 }
        movapd      (%ebx), %xmm4               #  { a0, a1 }
        movapd      (%ebx, %edi), %xmm5         #  { b0, b1 }

        movaps      %xmm5, %xmm0
        shufps      $0xa0, %xmm0, %xmm0         #  { Re(b0), Re(b0), Re(b1), Re(b1) }
        movaps      %xmm5, %xmm1
        shufps      $0xf5, %xmm1, %xmm1         #  { Im(b0), Im(b0), Im(b1), Im(b1) }
        mulps       %xmm6, %xmm0                #  { Re(b0)·Re(s0), Re(b0)·Im(s0), Re(b1)·Re(s1), Re(b1)·Im(s1) }
        mulps       %xmm6, %xmm1                #  { Im(b0)·Re(s0), Im(b0)·Im(s0), Im(b1)·Re(s1), Im(b1)·Im(s1) }
        shufps      $0xb1, %xmm1, %xmm1         #  { Im(b0)·Im(s0), Im(b0)·Re(s0), Im(b1)·Im(s1), Im(b1)·Re(s1) }
        addsubps    %xmm1, %xmm0                #  { b0·s0, b1·s1 }
        movaps      %xmm4, %xmm3                #  { a0, a1 }
        subps       %xmm0, %xmm3                #  { B0 = a0 - b0·s0, B1 = a1 - b1·s1 }
        addps       %xmm0, %xmm4                #  { A0 = a0 + b0·s0, A1 = a1 + b1·s1 }

        movapd      %xmm4, (%ebx)               #  { A0, A1 }
        movapd      %xmm3, (%ebx, %edi)         #  { B0, B1 }

        addl        $16, %ebx                   #  data += 2
        addl        $16, %esi                   #  p_s += 2
        subl        $2, %ecx
        jnz         _next_pair_s2

        jmp         _end_signal_s

_next_pair_s1:
        movlps      (%esi), %xmm6               #  s[k]
        movlps      (%ebx), %xmm4               #  a = data[j]
        movlps      (%ebx, %edi), %xmm5         #  b = data[j + n]

        movlhps     %xmm6, %xmm6                #  XMM6 = { Re(s), Im(s), Re(s), Im(s) }
        movaps      %xmm5, %xmm0
        unpcklps    %xmm0, %xmm0                #  XMM0 = { Re(b), Re(b), Im(b), Im(b) }
        mulps       %xmm6, %xmm0                #  Re(b)·Re(s), Re(b)·Im(s), Im(b)·Re(s), Im(b)·Im(s)

        movaps      %xmm0, %xmm1

        shufps      $0xbb, %xmm1, %xmm1         #  { Im(b)·Im(s), Im(b)·Re(s), Im(b)·Im(s), Im(b)·Re(s) }
        movlhps     %xmm0, %xmm0                #  { Re(b)·Re(s), Re(b)·Im(s), Re(b)·Re(s), Re(b)·Im(s) }
        addsubps    %xmm1, %xmm0                #  { b·s, b·s }
        movlhps     %xmm4, %xmm4                #  { a, a }
        movaps      %xmm4, %xmm3
        subps       %xmm0, %xmm3                #  { B, B }
        addps       %xmm0, %xmm4                #  { A, A }

        movlps      %xmm4, (%ebx)               #  A
        movlps      %xmm3, (%ebx, %edi)         #  B

        addl        $8, %ebx                    #  data += 1
        addl        $8, %esi                    #  p_s += 1
        subl        $1, %ecx
        jnz         _next_pair_s1

_end_signal_s:
        addl        %edi, %ebx                  #  data += n

        subl        $1, %edx                    #  signal counter
        jnz         _next_signal_s

        emms

        pop         %esi
        pop         %edi
        pop         %ebx
        pop         %ebp
        ret

fft_combine_d:
        push        %ebp
        movl        %esp, %ebp
        push        %ebx
        push        %edi
        push        %esi

        movl        12 (%ebp), %ebx             #  data

        movl        16 (%ebp), %eax             #  L, signal size in points
        shll        $4, %eax                    #  signal size in bytes
        movl        %eax, %edi

        movl        20 (%ebp), %edx             #  M, number of signals

_next_signal_d:
        movl        8 (%ebp), %esi              #  complex sinusoid lookup table
        movl        %edi, %ecx                  #  signal size in bytes
        shrl        $4, %ecx                    #  L, signal size in points
_next_pair_d:
        movapd      (%esi), %xmm6               #  s[j]
        movapd      (%ebx), %xmm4               #  a = data[j]
        movapd      (%ebx, %edi), %xmm5         #  b = data[n + j]

        movapd      %xmm5, %xmm0
        movapd      %xmm5, %xmm1
        unpcklpd    %xmm0, %xmm0                #  { Re(b), Re(b) }
        unpckhpd    %xmm1, %xmm1                #  { Im(b), Im(b) }
        mulpd       %xmm6, %xmm0                #  { Re(b)·Re(s), Re(b)·Im(s) }
        mulpd       %xmm6, %xmm1                #  { Im(b)·Re(s), Im(b)·Im(s) }
        shufpd      $1, %xmm1, %xmm1            #  { Im(b)·Im(s), Im(b)·Re(s) }
        addsubpd    %xmm1, %xmm0                #  { b·s }
        movapd      %xmm4, %xmm3                #  { a }
        subpd       %xmm0, %xmm3                #  { B = a - b·s }
        addpd       %xmm0, %xmm4                #  { A = a + b·s }

        movapd      %xmm4, (%ebx)               #  A
        movapd      %xmm3, (%ebx, %edi)         #  B

        addl        $16, %ebx                   #  data += 1
        addl        $16, %esi                   #  p_s += 1
        subl        $1, %ecx
        jnz         _next_pair_d

        addl        %edi, %ebx                  #  data += n

        subl        $1, %edx                    #  signal counter
        jnz         _next_signal_d

        emms

        pop         %esi
        pop         %edi
        pop         %ebx
        pop         %ebp
        ret

