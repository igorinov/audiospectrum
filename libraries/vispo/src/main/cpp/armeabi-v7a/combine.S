.global fft_combine_s
.global fft_combine_d

.text

#  R0 - complex exponent for this stage (w)
#  R1 - signal data
#  R2 - signal length, complex points (l)
#  R3 - number of signal pairs to combine (m)
#
#  Q4 .. Q7 are preserved (not used)

fft_combine_s:
        push        { r5, r6, r7, r8 }

        mov         r6, r1                  //  data
        add         r7, r6, r2, lsl #3      //  data + l
_next_signal_s:
        mov         r8, r0                  //  complex sinusoid lookup table
        mov         r5, r2
        tst         r5, #3                  //  is L multiple of 4 ?
        bne         _next_pair_s1

# process 4 pairs (a, b) per iteration

_next_pair_s4:
        vld2.32     { q8, q9 }, [r8]        //  s
        vld2.32     { q0, q1 }, [r6]        //  a
        vld2.32     { q2, q3 }, [r7]        //  b

                    //  q0 = { Re(a0), Re(a1), Re(a2), Re(a3) }
                    //  q1 = { Im(a0), Im(a1), Im(a2), Im(a3) }
                    //  q2 = { Re(b0), Re(b1), Re(b2), Re(b3) }
                    //  q3 = { Im(b0), Im(b1), Im(b2), Im(b3) }
                    //  q4 = { Re(s0), Re(s1), Re(s2), Re(s3) }
                    //  q5 = { Im(s0), Im(s1), Im(s2), Im(s3) }

        vmul.f32    q10, q2, q8             //  Re(b)·Re(s)
        vmul.f32    q11, q2, q9             //  Re(b)·Im(s)
        vmul.f32    q8, q3, q8              //  Im(b)·Re(s)
        vmul.f32    q9, q3, q9              //  Im(b)·Im(s)
        vsub.f32    q10, q10, q9            //  Re(b·s)
        vadd.f32    q11, q11, q8            //  Im(b·s)
        vsub.f32    q2, q0, q10             //  Re(B) = Re(a) - Re(b·s)
        vsub.f32    q3, q1, q11             //  Im(B) = Im(a) - Im(b·s)
        vadd.f32    q0, q0, q10             //  Re(A) = Re(a) + Re(b·s)
        vadd.f32    q1, q1, q11             //  Im(A) = Im(a) + Im(b·s)

                    //  q0 = { Re(A0), Re(A1), Re(A2), Re(A3) }
                    //  q1 = { Im(A0), Im(A1), Im(A2), Im(A3) }
                    //  q2 = { Re(B0), Re(B1), Re(B2), Re(B3) }
                    //  q3 = { Im(B0), Im(B1), Im(B2), Im(B3) }

        vst2.32     { q0, q1 }, [r6]        //  A
        vst2.32     { q2, q3 }, [r7]        //  B

                    // j += 4;

        add         r6, r6, #32
        add         r7, r7, #32
        add         r8, r8, #32

        sub         r5, r5, #4
        cmp         r5, #0
        bne         _next_pair_s4

        b           _end_signal_s

_next_pair_s1:

        vldm        r8, { s4, s5 }          //  s = cs[j]
        vldm        r6, { s0, s1 }          //  a = data[j]
        vldm        r7, { s2, s3 }          //  b = data[j + n]

        vmul.f32    s6, s2, s4              //  Re(b)·Re(s)
        vmul.f32    s7, s3, s5              //  Im(b)·Im(s)
        vmul.f32    s8, s2, s5              //  Re(b)·Im(s)
        vmul.f32    s9, s3, s4              //  Im(b)·Re(s)

        vsub.f32    s4, s6, s7              //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f32    s5, s8, s9              //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f32    s2, s0, s4              //  Re(B) = Re(a) - Re(b·s)
        vsub.f32    s3, s1, s5              //  Im(B) = Im(a) - Im(b·s)
        vadd.f32    s0, s0, s4              //  Re(A) = Re(a) + Re(b·s)
        vadd.f32    s1, s1, s5              //  Im(A) = Im(a) + Im(b·s)

        vstm        r6, { s0, s1 }          //  data[j] = A
        vstm        r7, { s2, s3 }          //  data[j + n] = B

        add         r6, r6, #8
        add         r7, r7, #8
        add         r8, r8, #8

        sub         r5, r5, #1
        cmp         r5, #0
        bne         _next_pair_s1

_end_signal_s:

        add         r6, r6, r2, lsl #3      //  data += l
        add         r7, r7, r2, lsl #3

        sub         r3, r3, #1              //  signal counter
        cmp         r3, #0
        bne         _next_signal_s

        pop         { r5, r6, r7, r8 }
        bx          lr

#  R0 - complex sinusoid for this round
#  R1 - signal data
#  R2 - signal size (L)
#  R3 - number of signals (M)
#
#  D8 .. D15 are preserved (not used)

fft_combine_d:
        push        { r5, r6, r7, r8 }

        mov         r6, r1                  //  data
        add         r7, r6, r2, lsl #4      //  data + l
_next_signal_d:
        mov         r8, r0                  //  complex sinusoid lookup table
        mov         r5, r2
_next_pair_d:
        vldm        r8, { d4, d5 }          //  s[j]
        vldm        r6, { d0, d1 }          //  a[j]
        vldm        r7, { d2, d3 }          //  b[j]

        vmul.f64    d6, d2, d4              //  Re(b)·Re(s)
        vmul.f64    d7, d3, d5              //  Im(b)·Im(s)
        vmul.f64    d2, d2, d5              //  Re(b)·Im(s)
        vmul.f64    d3, d3, d4              //  Im(b)·Re(s)

        vsub.f64    d4, d6, d7              //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d5, d2, d3              //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d2, d0, d4              //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d3, d1, d5              //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d0, d0, d4              //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d1, d1, d5              //  Im(A) = Im(a) + Im(b·s)

        vstm        r6, { d0, d1 }          //  A
        vstm        r7, { d2, d3 }          //  B

        add         r6, r6, #16             //  data += 1;
        add         r7, r7, #16
        add         r8, r8, #16

        sub         r5, r5, #1
        cmp         r5, #0
        bne         _next_pair_d

        add         r6, r6, r2, lsl #4      //  data += l;
        add         r7, r7, r2, lsl #4

        sub         r3, r3, #1              //  signal counter
        cmp         r3, #0
        bne         _next_signal_d

        pop         { r5, r6, r7, r8 }
        bx          lr

#        .size       fft_join_s, . - fft_join_s

