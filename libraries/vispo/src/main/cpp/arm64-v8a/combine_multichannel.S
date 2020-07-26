/*
 *  Copyright (C) Ivan Gorinov, 2016
 *
 *  SPDX-License-Identifier: BSD-2-Clause
 */

.global fft_combine_multichannel_s
.global fft_combine_multichannel_d

.text

#  X0 - complex sinusoid for this round
#  X1 - signal data
#  X2 - signal size (L)
#  X3 - number of signals (M)
#  X4 - number of channels (N)
#
#  V8-V15 are preserved (not used)

fft_combine_multichannel_s:
        mov         x10, x1                 //  signal data
        mul         x14, x2, x4             //  L * N
        add         x11, x10, x14, lsl #3   //  signal data + L * N
_next_signal_s:
        mov         x12, x0                 //  complex sinusoid table
        mov         x9, x2

        tst         x4, #3                  //  is N multiple of 4 ?
        bne         _next_sample_s1

_next_sample_s4:
        mov         x13, x4
        ld2r        { v4.4s, v5.4s }, [x12]

                    // v4 = { Re(s), Re(s), Re(s), Re(s) }
                    // v5 = { Im(s), Im(s), Im(s), Im(s) }

_next_channel_s4:

        ld2         { v0.4s, v1.4s }, [x10]

                    // v0 = { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
                    // v1 = { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }

        ld2         { v2.4s, v3.4s }, [x11]

                    // v2 = { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
                    // v3 = { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        fmul        v6.4s, v2.4s, v4.4s     // Re(bₖ)·Re(s)
        fmul        v7.4s, v2.4s, v5.4s     // Re(bₖ)·Im(s)
        fmul        v2.4s, v3.4s, v4.4s     // Im(bₖ)·Re(s)
        fmul        v3.4s, v3.4s, v5.4s     // Im(bₖ)·Im(s)

        fsub        v6.4s, v6.4s, v3.4s     // Re(bₖ·s) = Re(bₖ)·Re(s) - Im(bₖ)·Im(s)
        fadd        v7.4s, v2.4s, v7.4s     // Im(bₖ·s) = Im(bₖ)·Re(s) + Re(bₖ)·Im(s)

        fsub        v2.4s, v0.4s, v6.4s     // Re(Bₖ) = Re(aₖ) - Re(bₖ·s)
        fsub        v3.4s, v1.4s, v7.4s     // Im(Bₖ) = Im(aₖ) - Im(bₖ·s)

        fadd        v0.4s, v0.4s, v6.4s     // Re(Aₖ) = Re(aₖ) + Re(bₖ·s)
        fadd        v1.4s, v1.4s, v7.4s     // Im(Aₖ) = Im(aₖ) + Im(bₖ·s)

                    // v0 = { Re(A₀), Re(A₁), Re(A₂), Re(A₃) }
                    // v1 = { Im(A₀), Im(A₁), Im(A₂), Im(A₃) }

        st2         { v0.4s, v1.4s }, [x10]

                    // v2 = { Re(B₀), Re(B₁), Re(B₂), Re(B₃) }
                    // v3 = { Im(B₀), Im(B₁), Im(B₂), Im(B₃) }

        st2         { v2.4s, v3.4s }, [x11]

        add         x10, x10, #32
        add         x11, x11, #32

        sub         x13, x13, #4
        cmp         x13, #0
        bne         _next_channel_s4

        add         x12, x12, #8
        sub         x9, x9, #1
        cmp         x9, #0
        bne         _next_sample_s4

        b           _end_signal_s

_next_sample_s1:
        mov         x13, x4
        ld1         { v6.2s }, [x12]        // { s }
        fneg        v7.2s, v6.2s            // { -s }

        ins         v4.s[0], v6.s[0]        // +Re(s)
        ins         v4.s[1], v7.s[1]        // -Im(s)
        ins         v5.s[0], v6.s[1]        // +Im(s)
        ins         v5.s[1], v6.s[0]        // +Re(s)

_next_channel_s1:
        ld1         { v0.2s }, [x10]        // { a }
        ld1         { v1.2s }, [x11]        // { b }

        fmul        v2.2s, v4.2s, v1.2s     // { Re(b)·Re(s), -Im(b)·Im(s) }
        fmul        v3.2s, v5.2s, v1.2s     // { Re(b)·Im(s), Im(b)·Re(s) }
        faddp       v2.2s, v2.2s, v3.2s     // { b·s }

        fsub        v1.2s, v0.2s, v2.2s     // B = a - b·s
        fadd        v0.2s, v0.2s, v2.2s     // A = a + b·s

        st1         { v0.2s }, [x10]            // A
        st1         { v1.2s }, [x11]            // B

        add         x10, x10, #8
        add         x11, x11, #8

        sub         x13, x13, #1
        cmp         x13, #0
        bne         _next_channel_s1

        add         x12, x12, #8
        sub         x9, x9, #1
        cmp         x9, #0
        bne         _next_sample_s1

_end_signal_s:
        mul         x14, x2, x4
        add         x10, x10, x14, lsl #3    //  signal data += L * N
        add         x11, x11, x14, lsl #3

        sub         x3, x3, #1              //  signal counter
        cmp         x3, #0
        bne         _next_signal_s

        ret

fft_combine_multichannel_d:
        mov         x10, x1                 //  signal data
        mul         x14, x2, x4             //  L * N
        add         x11, x10, x14, lsl #4   //  signal data + L * N
_next_signal_d:
        mov         x12, x0                 //  complex sinusoid table
        mov         x9, x2                  //  sample counter
_next_sample_d:
        mov         x13, x4                 //  channel counter
        ld1         { v6.2d }, [x12]        //   s
        fneg        v7.2d, v6.2d            //  -s
        ins         v4.d[0], v6.d[0]
        ins         v4.d[1], v7.d[1]
        ins         v5.d[0], v6.d[1]
        ins         v5.d[1], v6.d[0]
_next_channel_d:
        ld1         { v0.2d }, [x10]        // a
        ld1         { v1.2d }, [x11]        // b

        fmul        v2.2d, v4.2d, v1.2d     // Re(b)·Re(s), -Im(b)·Im(s)
        fmul        v3.2d, v5.2d, v1.2d     // Re(b)·Im(s), Im(b)·Re(s)

        faddp       v2.2d, v2.2d, v3.2d     // b·s = { Re(b)·Re(s) - Im(b)·Im(s), Re(b)·Im(s) + Im(b)·Re(s) }

        fsub        v1.2d, v0.2d, v2.2d     // B = a - b·s
        fadd        v0.2d, v0.2d, v2.2d     // A = a + b·s

        st1         { v0.2d }, [x10]        // A
        st1         { v1.2d }, [x11]        // B

        add         x10, x10, #16
        add         x11, x11, #16

        sub         x13, x13, #1
        cmp         x13, #0
        bne         _next_channel_d

        add         x12, x12, #16
        sub         x9, x9, #1
        cmp         x9, #0
        bne         _next_sample_d

        mul         x14, x2, x4
        add         x10, x10, x14, lsl #4    //  signal data += L * N
        add         x11, x11, x14, lsl #4

        sub         x3, x3, #1              //  m -= 1
        cmp         x3, #0
        bne         _next_signal_d

        ret
