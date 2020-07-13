/*
 *  Copyright (C) Ivan Gorinov, 2016
 *
 *  SPDX-License-Identifier: BSD-2-Clause
 */

.global bit_reverse
.global fft_combine_s
.global fft_combine_d

.text

bit_reverse:
        mov         x2, #64
        sub         x1, x2, x1
        rbit        x0, x0
        ror         x0, x0, x1
        ret

#  X0 - complex sinusoid for this round
#  X1 - signal data
#  X2 - signal size (L)
#  X3 - number of signals (M)
#
#  V8-V15 are preserved (not used)

fft_combine_s:
        mov         x10, x1                 //  signal data
        add         x11, x10, x2, lsl #3    //  signal data + L
_next_signal_s:
        mov         x12, x0                 //  complex sinusoid table
        mov         x9, x2

        tst         x9, #3                  //  is L multiple of 4 ?
        bne         _next_pair_s1

_next_pair_s4:

        ld2         { v4.4s, v5.4s }, [x12]

                    // v4 = { Re(s0), Re(s1), Re(s2), Re(s3) }
                    // v5 = { Im(s0), Im(s1), Im(s2), Im(s3) }

        ld2         { v0.4s, v1.4s }, [x10]

                    // v0 = { Re(a0), Re(a1), Re(a2), Re(a3) }
                    // v1 = { Im(a0), Im(a1), Im(a2), Im(a3) }

        ld2         { v2.4s, v3.4s }, [x11]

                    // v2 = { Re(b0), Re(b1), Re(b2), Re(b3) }
                    // v3 = { Im(b0), Im(b1), Im(b2), Im(b3) }

        fmul        v6.4s, v2.4s, v4.4s     // Re(b)·Re(s)
        fmul        v7.4s, v2.4s, v5.4s     // Re(b)·Im(s)
        fmul        v4.4s, v3.4s, v4.4s     // Im(b)·Re(s)
        fmul        v5.4s, v3.4s, v5.4s     // Im(b)·Im(s)

        fsub        v6.4s, v6.4s, v5.4s     // Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        fadd        v7.4s, v4.4s, v7.4s     // Im(b·s) = Im(b)·Re(s) + Re(b)·Im(s)

        fsub        v2.4s, v0.4s, v6.4s     // Re(B) = Re(a) - Re(b·s)
        fsub        v3.4s, v1.4s, v7.4s     // Im(B) = Im(a) - Im(b·s)

        fadd        v0.4s, v0.4s, v6.4s     // Re(A) = Re(a) + Re(b·s)
        fadd        v1.4s, v1.4s, v7.4s     // Im(A) = Im(a) + Im(b·s)

                    // v0 = { Re(A0), Re(A1), Re(A2), Re(A3) }
                    // v1 = { Im(A0), Im(A1), Im(A2), Im(A3) }

        st2         { v0.4s, v1.4s }, [x10]

                    // v2 = { Re(B0), Re(B1), Re(B2), Re(B3) }
                    // v3 = { Im(B0), Im(B1), Im(B2), Im(B3) }

        st2         { v2.4s, v3.4s }, [x11]

        add         x10, x10, #32
        add         x11, x11, #32
        add         x12, x12, #32

        sub         x9, x9, #4
        cmp         x9, #0
        bne         _next_pair_s4

        b           _end_signal_s

_next_pair_s1:

        ld1         { v2.2s }, [x12]        // { s }
        ld1         { v0.2s }, [x10]        // { a }
        ld1         { v1.2s }, [x11]        // { b }

        ins         v3.s[0], v2.s[1]
        ins         v3.s[1], v2.s[0]

        fmul        v4.2s, v2.2s, v1.2s     // { Re(b)·Re(s), Im(b)·Im(s) }
        fmul        v5.2s, v3.2s, v1.2s     // { Re(b)·Im(s), Im(b)·Re(s) }

        fneg        v7.2s, v4.2s
        ins         v4.s[1], v7.s[1]
        faddp       v2.2s, v4.2s, v5.2s     // { b·s }

        fsub        v3.2s, v0.2s, v2.2s     // B = a - b·s
        fadd        v0.2s, v0.2s, v2.2s     // A = a + b·s

        st1         { v0.2s }, [x10]        // A
        st1         { v3.2s }, [x11]        // B

        add         x10, x10, #8
        add         x11, x11, #8
        add         x12, x12, #8

        sub         x9, x9, #1
        cmp         x9, #0
        bne         _next_pair_s1

_end_signal_s:
        add         x10, x10, x2, lsl #3    //  signal data += L
        add         x11, x11, x2, lsl #3

        sub         x3, x3, #1              //  signal counter
        cmp         x3, #0
        bne         _next_signal_s

        ret

        .size       fft_combine_s, . - fft_combine_s

fft_combine_d:
        mov         x10, x1                 //  signal data
        add         x11, x10, x2, lsl #4    //  signal data + L
_next_signal_d:
        mov         x12, x0                 //  complex sinusoid table
        mov         x9, x2
_next_pair_d:
        ld1         { v2.2d }, [x12]        // s
        ld1         { v0.2d }, [x10]        // a
        ld1         { v1.2d }, [x11]        // b

        ins         v3.d[0], v2.d[1]
        ins         v3.d[1], v2.d[0]

        fmul        v4.2d, v2.2d, v1.2d     // Re(b)·Re(s), Im(b)·Im(s)
        fmul        v5.2d, v3.2d, v1.2d     // Re(b)·Im(s), Im(b)·Re(s)


        fneg        v7.2d, v4.2d
        ins         v4.d[1], v7.d[1]        // Re(b)·Re(s), -Im(b)·Im(s)
        faddp       v2.2d, v4.2d, v5.2d     // b·s = (Re(b)·Re(s) - Im(b)·Im(s), Re(b)·Im(s) + Im(b)·Re(s)

        fsub        v3.2d, v0.2d, v2.2d     // B = a - b·s
        fadd        v0.2d, v0.2d, v2.2d     // A = a + b·s

        st1         { v0.2d }, [x10]        // A
        st1         { v3.2d }, [x11]        // B

        add         x10, x10, #16
        add         x11, x11, #16
        add         x12, x12, #16

        sub         x9, x9, #1
        cmp         x9, #0
        bne         _next_pair_d

        add         x10, x10, x2, lsl #4    //  signal data += L
        add         x11, x11, x2, lsl #4

        sub         x3, x3, #1              //  m -= 1
        cmp         x3, #0
        bne         _next_signal_d

        ret

        .size       fft_combine_d, . - fft_combine_d

