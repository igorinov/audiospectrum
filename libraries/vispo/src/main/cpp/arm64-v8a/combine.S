/*
 *  Copyright (C) Ivan Gorinov, 2016
 *
 *  SPDX-License-Identifier: BSD-2-Clause
 */

.global fft_combine_s
.global fft_combine_d

.text

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

_next_pair_s8:
        tst         x9, #7                  //  is L multiple of 8 ?
        bne         _next_pair_s4

        ld4         { v16.4s, v17.4s, v18.4s, v19.4s }, [x12]

                    // v16 = { Re(s0), Re(s2), Re(s4), Re(s6) }
                    // v17 = { Im(s0), Im(s2), Im(s4), Im(s6) }
                    // v18 = { Re(s1), Re(s3), Re(s5), Re(s7) }
                    // v19 = { Im(s1), Im(s3), Im(s5), Im(s7) }

        ld4         { v0.4s, v1.4s, v2.4s, v3.4s }, [x10]

                    // v0 = { Re(a0), Re(a2), Re(a4), Re(a6) }
                    // v1 = { Im(a0), Im(a2), Im(a4), Im(a6) }
                    // v2 = { Re(a1), Re(a3), Re(a5), Re(a7) }
                    // v3 = { Im(a1), Im(a3), Im(a5), Im(a7) }

        ld4         { v4.4s, v5.4s, v6.4s, v7.4s }, [x11]

                    // v4 = { Re(b0), Re(b2), Re(b4), Re(b6) }
                    // v5 = { Im(b0), Im(b2), Im(b4), Im(b6) }
                    // v6 = { Re(b1), Re(b3), Re(b5), Re(b7) }
                    // v7 = { Im(b1), Im(b3), Im(b5), Im(b7) }

        fmul        v24.4s, v4.4s, v16.4s       //  Re(b)·Re(s)
        fmul        v25.4s, v4.4s, v17.4s       //  Re(b)·Im(s)
        fmul        v26.4s, v5.4s, v16.4s       //  Im(b)·Re(s)
        fmul        v27.4s, v5.4s, v17.4s       //  Im(b)·Im(s)

        fmul        v28.4s, v6.4s, v18.4s       //  Re(b)·Re(s)
        fmul        v29.4s, v6.4s, v19.4s       //  Re(b)·Im(s)
        fmul        v30.4s, v7.4s, v18.4s       //  Im(b)·Re(s)
        fmul        v31.4s, v7.4s, v19.4s       //  Im(b)·Im(s)

        fsub        v20.4s, v24.4s, v27.4s      //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        fadd        v21.4s, v25.4s, v26.4s      //  Im(b·s) = Im(b)·Re(s) + Re(b)·Im(s)

        fsub        v22.4s, v28.4s, v31.4s      //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        fadd        v23.4s, v29.4s, v30.4s      //  Im(b·s) = Im(b)·Re(s) + Re(b)·Im(s)

        fsub        v4.4s, v0.4s, v20.4s        //  Re(B) = Re(a) - Re(b·s)
        fsub        v5.4s, v1.4s, v21.4s        //  Im(B) = Im(a) - Im(b·s)
        fadd        v0.4s, v0.4s, v20.4s        //  Re(A) = Re(a) + Re(b·s)
        fadd        v1.4s, v1.4s, v21.4s        //  Im(A) = Im(a) + Im(b·s)

        fsub        v6.4s, v2.4s, v22.4s        //  Re(B) = Re(a) - Re(b·s)
        fsub        v7.4s, v3.4s, v23.4s        //  Im(B) = Im(a) - Im(b·s)
        fadd        v2.4s, v2.4s, v22.4s        //  Re(A) = Re(a) + Re(b·s)
        fadd        v3.4s, v3.4s, v23.4s        //  Im(A) = Im(a) + Im(b·s)

                    // v0 = { Re(A0), Re(A2), Re(A4), Re(A6) }
                    // v1 = { Im(A0), Im(A2), Im(A4), Im(A6) }
                    // v2 = { Re(A1), Re(A3), Re(A5), Re(A7) }
                    // v3 = { Im(A1), Im(A3), Im(A5), Im(A7) }

        st4         { v0.4s, v1.4s, v2.4s, v3.4s }, [x10]

                    // v4 = { Re(B0), Re(B2), Re(B4), Re(B6) }
                    // v5 = { Im(B0), Im(B2), Im(B4), Im(B6) }
                    // v6 = { Re(B1), Re(B3), Re(B5), Re(B7) }
                    // v7 = { Im(B1), Im(B3), Im(B5), Im(B7) }

        st4         { v4.4s, v5.4s, v6.4s, v7.4s }, [x11]

        add         x10, x10, #64
        add         x11, x11, #64
        add         x12, x12, #64

        sub         x9, x9, #8
        cmp         x9, #0
        bne         _next_pair_s4

        b           _end_signal_s


_next_pair_s4:
        tst         x9, #3                  //  is L multiple of 4 ?
        bne         _next_pair_s1

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

        ldp         s4, s5, [x12]           //  s
        ldp         s0, s1, [x10]           //  a
        ldp         s2, s3, [x11]           //  b

        fmul        s12, s2, s4             //  Re(b)·Re(s)
        fmul        s13, s2, s5             //  Re(b)·Im(s)
        fmul        s14, s3, s4             //  Im(b)·Re(s)
        fmul        s15, s3, s5             //  Im(b)·Im(s)

        fsub        s8, s12, s15            //  Re(b·s) =  Re(b)·Re(s) - Im(b)·Im(s)
        fadd        s9, s13, s14            //  Im(b·s) =  Re(b)·Im(s) + Im(b)·Re(s)

        fsub        s2, s0, s8              //  Re(B) = Re(a) - Re(b·s)
        fsub        s3, s1, s9              //  Im(B) = Im(a) - Im(b·s)
        fadd        s0, s0, s8              //  Re(A) = Re(a) + Re(b·s)
        fadd        s1, s1, s9              //  Im(A) = Im(a) + Im(b·s)

        stp         s0, s1, [x10]           //  A
        stp         s2, s3, [x11]           //  B

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

_next_pair_d4:
        tst         x9, #3
        bne         _next_pair_d2

        ld4         { v16.2d, v17.2d, v18.2d, v19.2d }, [x12]   // s
        ld4         { v0.2d, v1.2d, v2.2d, v3.2d }, [x10]       // a
        ld4         { v4.2d, v5.2d, v6.2d, v7.2d }, [x11]       // b

        fmul        v24.2d, v4.2d, v16.2d       //  Re(b)·Re(s)
        fmul        v25.2d, v4.2d, v17.2d       //  Re(b)·Im(s)
        fmul        v26.2d, v5.2d, v16.2d       //  Im(b)·Re(s)
        fmul        v27.2d, v5.2d, v17.2d       //  Im(b)·Im(s)

        fmul        v28.2d, v6.2d, v18.2d       //  Re(b)·Re(s)
        fmul        v29.2d, v6.2d, v19.2d       //  Re(b)·Im(s)
        fmul        v30.2d, v7.2d, v18.2d       //  Im(b)·Re(s)
        fmul        v31.2d, v7.2d, v19.2d       //  Im(b)·Im(s)

        fsub        v20.2d, v24.2d, v27.2d      //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        fadd        v21.2d, v25.2d, v26.2d      //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        fsub        v22.2d, v28.2d, v31.2d      //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        fadd        v23.2d, v29.2d, v30.2d      //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        fsub        v4.2d, v0.2d, v20.2d        //  Re(B) = Re(a) - Re(b·s)
        fsub        v5.2d, v1.2d, v21.2d        //  Im(B) = Im(a) - Im(b·s)
        fadd        v0.2d, v0.2d, v20.2d        //  Re(A) = Re(a) + Re(b·s)
        fadd        v1.2d, v1.2d, v21.2d        //  Im(A) = Im(a) + Im(b·s)

        fsub        v6.2d, v2.2d, v22.2d        //  Re(B) = Re(a) - Re(b·s)
        fsub        v7.2d, v3.2d, v23.2d        //  Im(B) = Im(a) - Im(b·s)
        fadd        v2.2d, v2.2d, v22.2d        //  Re(A) = Re(a) + Re(b·s)
        fadd        v3.2d, v3.2d, v23.2d        //  Im(A) = Im(a) + Im(b·s)

        st4         { v0.2d, v1.2d, v2.2d, v3.2d }, [x10]
        st4         { v4.2d, v5.2d, v6.2d, v7.2d }, [x11]

        add         x10, x10, #64
        add         x11, x11, #64
        add         x12, x12, #64

        sub         x9, x9, #4
        cmp         x9, #0
        bne         _next_pair_d4

        b           _end_signal_d

_next_pair_d2:
        tst         x9, #1
        bne         _next_pair_d

        ld2         { v4.2d, v5.2d }, [x12]        // s
        ld2         { v0.2d, v1.2d }, [x10]        // a
        ld2         { v2.2d, v3.2d }, [x11]        // b

        fmul        v16.2d, v2.2d, v4.2d     // Re(b)·Re(s)
        fmul        v17.2d, v2.2d, v5.2d     // Re(b)·Im(s)
        fmul        v18.2d, v3.2d, v4.2d     // Im(b)·Re(s)
        fmul        v19.2d, v3.2d, v5.2d     // Im(b)·Im(s)

        fsub        v6.2d, v16.2d, v19.2d   //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        fadd        v7.2d, v17.2d, v18.2d   //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        fsub        v2.2d, v0.2d, v6.2d     //  Re(B) = Re(a) - Re(b·s)
        fsub        v3.2d, v1.2d, v7.2d     //  Im(B) = Im(a) - Im(b·s)
        fadd        v0.2d, v0.2d, v6.2d     //  Re(A) = Re(a) + Re(b·s)
        fadd        v1.2d, v1.2d, v7.2d     //  Im(A) = Im(a) + Im(b·s)

        st2         { v0.2d, v1.2d }, [x10]
        st2         { v2.2d, v3.2d }, [x11]

        add         x10, x10, #32
        add         x11, x11, #32
        add         x12, x12, #32

        sub         x9, x9, #2
        cmp         x9, #0
        bne         _next_pair_d2

        b           _end_signal_d

_next_pair_d:
        ldp         d4, d5, [x12]           //  s
        ldp         d0, d1, [x10]           //  a
        ldp         d2, d3, [x11]           //  b

        fmul        d12, d2, d4             //  Re(b)·Re(s)
        fmul        d13, d2, d5             //  Re(b)·Im(s)
        fmul        d14, d3, d4             //  Im(b)·Re(s)
        fmul        d15, d3, d5             //  Im(b)·Im(s)

        fsub        d8, d12, d15            //  Re(b·s) =  Re(b)·Re(s) - Im(b)·Im(s)
        fadd        d9, d13, d14            //  Im(b·s) =  Re(b)·Im(s) + Im(b)·Re(s)

        fsub        d2, d0, d8              //  Re(B) = Re(a) - Re(b·s)
        fsub        d3, d1, d9              //  Im(B) = Im(a) - Im(b·s)
        fadd        d0, d0, d8              //  Re(A) = Re(a) + Re(b·s)
        fadd        d1, d1, d9              //  Im(A) = Im(a) + Im(b·s)

        stp         d0, d1, [x10]           //  A
        stp         d2, d3, [x11]           //  B

        add         x10, x10, #16
        add         x11, x11, #16
        add         x12, x12, #16

        sub         x9, x9, #1
        cmp         x9, #0
        bne         _next_pair_d

_end_signal_d:

        add         x10, x10, x2, lsl #4    //  signal data += L
        add         x11, x11, x2, lsl #4

        sub         x3, x3, #1              //  m -= 1
        cmp         x3, #0
        bne         _next_signal_d

        ret

        .size       fft_combine_d, . - fft_combine_d

