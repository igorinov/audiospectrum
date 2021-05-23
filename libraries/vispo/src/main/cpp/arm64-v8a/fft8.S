.global fft8_fwd_s
.global fft8_inv_s
.global fft8_fwd_d
.global fft8_inv_d

.text

#  X0 - complex exponent for this stage (S)
#  X1 - signal data
#  X2 - number of 8-point signals to compute (M)
#
#  V8-V15 are preserved (not used)

fft8_fwd_s:
        mov         x6, x1                  //  data
        mov         x7, x1
        mov         x8, x0                  //  complex exponent lookup table

        ld2         { v24.4s, v25.4s }, [x8]  // s

_next_octet_fwd_s:

        // data = { a₀, b₀, a₁, b₁, a₂, b₂, a₃, b₃ }

        ld4         { v0.4s, v1.4s, v2.4s, v3.4s }, [x6]
        add         x6, x6, #64

                    // v0 = { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
                    // v1 = { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
                    // v2 = { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
                    // v3 = { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        // Combine 4 pairs of 1-point signals

        mov         v6.4s, v2.4s
        mov         v7.4s, v3.4s
        fsub        v2.4s, v0.4s, v6.4s     // Re(Bⱼ) = Re(aⱼ) - Re(bⱼ)
        fadd        v0.4s, v0.4s, v6.4s     // Re(Aⱼ) = Re(aⱼ) + Re(bⱼ)
        fsub        v3.4s, v1.4s, v7.4s     // Im(Bⱼ) = Im(aⱼ) - Im(bⱼ)
        fadd        v1.4s, v1.4s, v7.4s     // Im(Aⱼ) = Im(aⱼ) + Im(bⱼ)

        // Combine 2 pairs of 2-point signals
        // This part is different for forward and inverse transform
        //  v0 = { Re(A₀), Re(A₁), Re(A₂), Re(A₃) } -> { Re(a₀), Re(b₀), Re(a₂), Re(b₂) }
        //  v1 = { Im(A₀), Im(A₁), Im(A₂), Im(A₃) } -> { Im(a₀), Im(b₀), Im(a₂), Im(b₂) }
        //  v2 = { Re(B₀), Re(B₁), Re(B₂), Re(B₃) } -> { Re(a₁), Re(b₁), Re(a₃), Re(b₃) }
        //  v3 = { Im(B₀), Im(B₁), Im(B₂), Im(B₃) } -> { Im(a₁), Im(b₁), Im(a₃), Im(b₃) }

        trn1        v4.4s, v0.4s, v1.4s     //  { Re(a0), Im(a0), Re(a2), Im(a2) }
        trn2        v5.4s, v0.4s, v1.4s     //  { Re(b0), Im(b0), Re(b2), Im(b2) }
        trn1        v6.4s, v2.4s, v3.4s     //  { Re(a1), Im(a1), Re(a3), Im(a3) }
        trn2        v7.4s, v3.4s, v2.4s     //  { Im(b1), Re(b1), Im(b3), Re(b3) }

         //  Re(B₀) = Re(a₀) - Re(b₀); Re(B₂) = Re(a₂) - Re(b₂)
         //  Im(B₀) = Im(a₀) - Im(b₀); Im(B₂) = Im(a₂) - Im(b₂)
         //  Re(A₀) = Re(a₀) + Re(b₀); Re(A₂) = Re(a₂) + Re(b₂)
         //  Im(A₀) = Im(a₀) + Im(b₀); Im(A₂) = Im(a₂) + Im(b₂)

        fsub        v1.4s, v4.4s, v5.4s     //  { Re(B0), Im(B0), Re(B2), Im(B2) }
        fadd        v0.4s, v4.4s, v5.4s     //  { Re(A0), Im(A0), Re(A2), Im(A2) }

         //  Re(B₁) = Re(a₁) - Im(b₁); Re(B₃) = Re(a₃) - Im(b₃)
         //  Im(B₁) = Im(a₁) + Re(b₁); Im(B₃) = Im(a₃) + Re(b₃)
         //  Re(A₁) = Re(a₁) + Im(b₁); Re(A₃) = Re(a₃) + Im(b₃)
         //  Im(A₁) = Im(a₁) - Re(b₁); Im(A₃) = Im(a₃) - Re(b₃)

        fsub        v3.4s, v6.4s, v7.4s     //  { Re(B1), Im(A1), Re(B3), Im(A3) }
        fadd        v2.4s, v6.4s, v7.4s     //  { Re(A1), Im(B1), Re(A3), Im(B3) }

        trn1        v4.4s, v2.4s, v3.4s     //  { Re(A1), Re(B1), Re(A3), Re(B3) }
        trn2        v5.4s, v3.4s, v2.4s     //  { Im(A1), Im(B1), Im(A3), Im(B3) }

        trn1        v6.4s, v0.4s, v1.4s     //  { Re(A0), Re(B0), Re(A2), Re(B2) }
        trn2        v7.4s, v0.4s, v1.4s     //  { Im(A0), Im(B0), Im(A2), Im(B2) }

        zip1        v0.4s, v6.4s, v4.4s     //  { Re(A0), Re(A1), Re(B0), Re(B1) }
        zip1        v1.4s, v7.4s, v5.4s     //  { Im(A0), Im(A1), Im(B0), Im(B1) }
        zip2        v2.4s, v6.4s, v4.4s     //  { Re(A2), Re(A3), Re(B2), Re(B3) }
        zip2        v3.4s, v7.4s, v5.4s     //  { Im(A2), Im(A3), Im(B2), Im(B3) }

        // Combine 1 pair of 4-point signals
        //  v0 = { Re(A₀), Re(A₁), Re(B₀), Re(B₁) } -> { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
        //  v1 = { Im(A₀), Im(A₁), Im(B₀), Im(B₁) } -> { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
        //  v2 = { Re(A₂), Re(A3), Re(B₂), Re(B₃) } -> { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
        //  v3 = { Im(A₂), Im(A3), Im(B₂), Im(B₃) } -> { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        fmul        v16.4s, v2.4s, v24.4s       //  Re(b)·Re(s)
        fmul        v17.4s, v2.4s, v25.4s       //  Re(b)·Im(s)
        fmul        v18.4s, v3.4s, v24.4s       //  Im(b)·Re(s)
        fmul        v19.4s, v3.4s, v25.4s       //  Im(b)·Im(s)

        fsub        v16.4s, v16.4s, v19.4s      //  Re(b·s)
        fadd        v17.4s, v17.4s, v18.4s      //  Im(b·s)
        fsub        v2.4s, v0.4s, v16.4s        //  Re(B) = Re(a) - Re(b·s)
        fsub        v3.4s, v1.4s, v17.4s        //  Im(B) = Im(a) - Im(b·s)
        fadd        v0.4s, v0.4s, v16.4s        //  Re(A) = Re(a) + Re(b·s)
        fadd        v1.4s, v1.4s, v17.4s        //  Im(A) = Im(a) + Im(b·s)

        //  v0 = { Re(A0), Re(A1), Re(A2), Re(A3) }
        //  v1 = { Im(A0), Im(A1), Im(A2), Im(A3) }
        //  v2 = { Re(B0), Re(B1), Re(B2), Re(B3) }
        //  v3 = { Im(B0), Im(B1), Im(B2), Im(B3) }

        st2         { v0.4s, v1.4s }, [x7]
        add         x7, x7, #32
        st2         { v2.4s, v3.4s }, [x7]
        add         x7, x7, #32

        sub         x2, x2, #1
        cmp         x2, #0
        bne         _next_octet_fwd_s

        ret

fft8_inv_s:
        mov         x6, x1                  //  data
        mov         x7, x1
        mov         x8, x0                  //  complex exponent lookup table

        ld2         { v24.4s, v25.4s }, [x8]  // s

_next_octet_inv_s:

        // data = { a₀, b₀, a₁, b₁, a₂, b₂, a₃, b₃ }

        ld4         { v0.4s, v1.4s, v2.4s, v3.4s }, [x6]
        add         x6, x6, #64

                    // v0 = { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
                    // v1 = { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
                    // v2 = { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
                    // v3 = { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        // Combine 4 pairs of 1-point signals

        mov         v6.4s, v2.4s
        mov         v7.4s, v3.4s
        fsub        v2.4s, v0.4s, v6.4s     // Re(Bⱼ) = Re(aⱼ) - Re(bⱼ)
        fadd        v0.4s, v0.4s, v6.4s     // Re(Aⱼ) = Re(aⱼ) + Re(bⱼ)
        fsub        v3.4s, v1.4s, v7.4s     // Im(Bⱼ) = Im(aⱼ) - Im(bⱼ)
        fadd        v1.4s, v1.4s, v7.4s     // Im(Aⱼ) = Im(aⱼ) + Im(bⱼ)


        // Combine 2 pairs of 2-point signals
        // This part is different for forward and inverse transform

        //  v0 = { Re(A₀), Re(A₁), Re(A₂), Re(A₃) } -> { Re(a₀), Re(b₀), Re(a₂), Re(b₂) }
        //  v1 = { Im(A₀), Im(A₁), Im(A₂), Im(A₃) } -> { Im(a₀), Im(b₀), Im(a₂), Im(b₂) }
        //  v2 = { Re(B₀), Re(B₁), Re(B₂), Re(B₃) } -> { Re(a₁), Re(b₁), Re(a₃), Re(b₃) }
        //  v3 = { Im(B₀), Im(B₁), Im(B₂), Im(B₃) } -> { Im(a₁), Im(b₁), Im(a₃), Im(b₃) }

        trn1        v4.4s, v0.4s, v1.4s     //  { Re(a0), Im(a0), Re(a2), Im(a2) }
        trn2        v5.4s, v0.4s, v1.4s     //  { Re(b0), Im(b0), Re(b2), Im(b2) }
        trn1        v6.4s, v2.4s, v3.4s     //  { Re(a1), Im(a1), Re(a3), Im(a3) }
        trn2        v7.4s, v3.4s, v2.4s     //  { Im(b1), Re(b1), Im(b3), Re(b3) }

         //  Re(B₀) = Re(a₀) - Re(b₀); Re(B₂) = Re(a₂) - Re(b₂)
         //  Im(B₀) = Im(a₀) - Im(b₀); Im(B₂) = Im(a₂) - Im(b₂)
         //  Re(A₀) = Re(a₀) + Re(b₀); Re(A₂) = Re(a₂) + Re(b₂)
         //  Im(A₀) = Im(a₀) + Im(b₀); Im(A₂) = Im(a₂) + Im(b₂)

        fsub        v1.4s, v4.4s, v5.4s     //  { Re(B0), Im(B0), Re(B2), Im(B2) }
        fadd        v0.4s, v4.4s, v5.4s     //  { Re(A0), Im(A0), Re(A2), Im(A2) }

         //  Re(B₁) = Re(a₁) + Im(b₁); Re(B₃) = Re(a₃) + Im(b₃)
         //  Im(B₁) = Im(a₁) - Re(b₁); Im(B₃) = Im(a₃) - Re(b₃)
         //  Re(A₁) = Re(a₁) - Im(b₁); Re(A₃) = Re(a₃) - Im(b₃)
         //  Im(A₁) = Im(a₁) + Re(b₁); Im(A₃) = Im(a₃) + Re(b₃)

        fsub        v2.4s, v6.4s, v7.4s     //  { Re(A1), Im(B1), Re(A3), Im(B3) }
        fadd        v3.4s, v6.4s, v7.4s     //  { Re(B1), Im(A1), Re(B3), Im(A3) }

        trn1        v4.4s, v2.4s, v3.4s     //  { Re(A1), Re(B1), Re(A3), Re(B3) }
        trn2        v5.4s, v3.4s, v2.4s     //  { Im(A1), Im(B1), Im(A3), Im(B3) }

        trn1        v6.4s, v0.4s, v1.4s     //  { Re(A0), Re(B0), Re(A2), Re(B2) }
        trn2        v7.4s, v0.4s, v1.4s     //  { Im(A0), Im(B0), Im(A2), Im(B2) }

        zip1        v0.4s, v6.4s, v4.4s     //  { Re(A0), Re(A1), Re(B0), Re(B1) }
        zip1        v1.4s, v7.4s, v5.4s     //  { Im(A0), Im(A1), Im(B0), Im(B1) }
        zip2        v2.4s, v6.4s, v4.4s     //  { Re(A2), Re(A3), Re(B2), Re(B3) }
        zip2        v3.4s, v7.4s, v5.4s     //  { Im(A2), Im(A3), Im(B2), Im(B3) }

        // Combine 1 pair of 4-point signals
        //  v0 = { Re(A₀), Re(A₁), Re(B₀), Re(B₁) } -> { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
        //  v1 = { Im(A₀), Im(A₁), Im(B₀), Im(B₁) } -> { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
        //  v2 = { Re(A₂), Re(A3), Re(B₂), Re(B₃) } -> { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
        //  v3 = { Im(A₂), Im(A3), Im(B₂), Im(B₃) } -> { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        fmul        v16.4s, v2.4s, v24.4s       //  Re(b)·Re(s)
        fmul        v17.4s, v2.4s, v25.4s       //  Re(b)·Im(s)
        fmul        v18.4s, v3.4s, v24.4s       //  Im(b)·Re(s)
        fmul        v19.4s, v3.4s, v25.4s       //  Im(b)·Im(s)

        fsub        v16.4s, v16.4s, v19.4s      //  Re(b·s)
        fadd        v17.4s, v17.4s, v18.4s      //  Im(b·s)
        fsub        v2.4s, v0.4s, v16.4s        //  Re(B) = Re(a) - Re(b·s)
        fsub        v3.4s, v1.4s, v17.4s        //  Im(B) = Im(a) - Im(b·s)
        fadd        v0.4s, v0.4s, v16.4s        //  Re(A) = Re(a) + Re(b·s)
        fadd        v1.4s, v1.4s, v17.4s        //  Im(A) = Im(a) + Im(b·s)

        //  v0 = { Re(A0), Re(A1), Re(A2), Re(A3) }
        //  v1 = { Im(A0), Im(A1), Im(A2), Im(A3) }
        //  v2 = { Re(B0), Re(B1), Re(B2), Re(B3) }
        //  v3 = { Im(B0), Im(B1), Im(B2), Im(B3) }

        st2         { v0.4s, v1.4s }, [x7]
        add         x7, x7, #32
        st2         { v2.4s, v3.4s }, [x7]
        add         x7, x7, #32

        sub         x2, x2, #1
        cmp         x2, #0
        bne         _next_octet_inv_s

        ret


#  V0 - complex sinusoid for this round
#  V1 - signal data
#  V2 - number of 8-point signals (M)
#
#  V8 .. V15 are preserved (saved on stack)

fft8_fwd_d:
        mov         x6, x1                  //  data
        mov         x7, x1
        mov         x8, x0                  //  complex exponent lookup table

        ld2         { v24.2d, v25.2d }, [x8]  // s
        add         x8, x8, #32
        ld2         { v26.2d, v27.2d }, [x8]  // s
        add         x8, x8, #32

_next_octet_fwd_d:

        // data = { a₀, b₀, a₁, b₁, a₂, b₂, a₃, b₃ }

        ld1         { v0.2d, v1.2d, v2.2d, v3.2d }, [x6]
        add         x6, x6, #64
        ld1         { v4.2d, v5.2d, v6.2d, v7.2d }, [x6]
        add         x6, x6, #64

                    // v0 = { Re(a), Im(a) }
                    // v1 = { Re(b), Im(b) }
                    // v2 = { Re(c), Im(c) }
                    // v3 = { Re(d), Im(d) }
                    // v4 = { Re(e), Im(e) }
                    // v5 = { Re(f), Im(f) }
                    // v6 = { Re(g), Im(g) }
                    // v7 = { Re(h), Im(h) }

        // Combine 4 pairs of 1-point signals

        fadd        v16.2d, v0.2d, v1.2d    //  { Re(A), Im(A) }
        fsub        v17.2d, v0.2d, v1.2d    //  { Re(B), Im(B) }
        fadd        v18.2d, v2.2d, v3.2d    //  { Re(C), Im(C) }
        fsub        v19.2d, v2.2d, v3.2d    //  { Re(D), Im(D) }

        fadd        v20.2d, v4.2d, v5.2d    //  { Re(E), Im(E) }
        fsub        v21.2d, v4.2d, v5.2d    //  { Re(F), Im(F) }
        fadd        v22.2d, v6.2d, v7.2d    //  { Re(G), Im(G) }
        fsub        v23.2d, v6.2d, v7.2d    //  { Re(H), Im(H) }

        // Combine 2 pairs of 2-point signals

        fadd        v0.2d, v16.2d, v18.2d   //  { Re(A), Im(A) }
        fsub        v1.2d, v16.2d, v18.2d   //  { Re(C), Im(C) }

        mov         v28.d[0], v19.d[1]
        mov         v28.d[1], v19.d[0]
                                             //  { Im(d), Re(d) }

        fadd        v2.2d, v17.2d, v28.2d    //  { Re(B), Im(D) }
        fsub        v3.2d, v17.2d, v28.2d    //  { Re(D), Im(B) }

        trn1        v16.2d, v0.2d, v2.2d     //  { Re(A), Re(B) }
        trn2        v17.2d, v0.2d, v3.2d     //  { Im(A), Im(B) }
        trn1        v18.2d, v1.2d, v3.2d     //  { Re(C), Re(D) }
        trn2        v19.2d, v1.2d, v2.2d     //  { Im(C), Im(D) }

        fadd        v4.2d, v20.2d, v22.2d   //  { Re(E), Im(E) }
        fsub        v5.2d, v20.2d, v22.2d   //  { Re(G), Im(G) }

        mov         v30.d[0], v23.d[1]
        mov         v30.d[1], v23.d[0]
                                             //  { Im(h), Re(h) }

        fadd        v6.2d, v21.2d, v30.2d    //  { Re(F), Im(H) }
        fsub        v7.2d, v21.2d, v30.2d    //  { Re(H), Im(F) }

        trn1        v20.2d, v4.2d, v6.2d     //  { Re(E), Re(F) }
        trn2        v21.2d, v4.2d, v7.2d     //  { Im(E), Im(F) }
        trn1        v22.2d, v5.2d, v7.2d     //  { Re(G), Re(H) }
        trn2        v23.2d, v5.2d, v6.2d     //  { Im(G), Im(H) }

        // Combine 1 pair of 4-point signals

        fmul        v28.2d, v20.2d, v24.2d    //  { Re(e)·Re(s0), Re(f)·Re(s1) }
        fmul        v29.2d, v20.2d, v25.2d    //  { Re(e)·Im(s0), Re(f)·Im(s1) }
        fmul        v30.2d, v21.2d, v24.2d    //  { Im(e)·Re(s0), Im(f)·Re(s1) }
        fmul        v31.2d, v21.2d, v25.2d    //  { Im(e)·Im(s0), Im(f)·Im(s1) }

        fsub        v20.2d, v28.2d, v31.2d    //  { Re(e·s0), Re(f·s1) }
        fadd        v21.2d, v29.2d, v30.2d    //  { Im(e·s0), Im(f·s1) }

        fadd        v0.2d, v16.2d, v20.2d     //  { Re(A), Re(B) }
        fadd        v1.2d, v17.2d, v21.2d     //  { Im(A), Im(B) }
        fsub        v4.2d, v16.2d, v20.2d     //  { Re(E), Re(F) }
        fsub        v5.2d, v17.2d, v21.2d     //  { Im(E), Im(F) }

        fmul        v28.2d, v22.2d, v26.2d    //  { Re(g)·Re(s2), Re(h)·Re(s3) }
        fmul        v29.2d, v22.2d, v27.2d    //  { Re(g)·Im(s2), Re(h)·Im(s3) }
        fmul        v30.2d, v23.2d, v26.2d    //  { Im(g)·Re(s2), Im(h)·Re(s3) }
        fmul        v31.2d, v23.2d, v27.2d    //  { Im(g)·Im(s2), Im(h)·Im(s3) }

        fsub        v22.2d, v28.2d, v31.2d    //  { Re(g·s2), Re(h·s3) }
        fadd        v23.2d, v29.2d, v30.2d    //  { Im(g·s2), Im(h·s3) }

        fadd        v2.2d, v18.2d, v22.2d     //  { Re(C), Re(D) }
        fadd        v3.2d, v19.2d, v23.2d     //  { Im(C), Im(D) }
        fsub        v6.2d, v18.2d, v22.2d     //  { Re(G), Re(H) }
        fsub        v7.2d, v19.2d, v23.2d     //  { Im(G), Im(H) }

        st2         { v0.2d, v1.2d }, [x7]
        add         x7, x7, #32
        st2         { v2.2d, v3.2d }, [x7]
        add         x7, x7, #32
        st2         { v4.2d, v5.2d }, [x7]
        add         x7, x7, #32
        st2         { v6.2d, v7.2d }, [x7]
        add         x7, x7, #32

        sub         x2, x2, #1
        cmp         x2, #0
        bne         _next_octet_fwd_d

        ret

fft8_inv_d:

        mov         x6, x1                  //  data
        mov         x7, x1
        mov         x8, x0                  //  complex exponent lookup table

        ld2         { v24.2d, v25.2d }, [x8]
                    // v24 = { Re(s₀), Re(s₁) }
                    // v25 = { Im(s₀), Im(s₁) }
        add         x8, x8, #32
        ld2         { v26.2d, v27.2d }, [x8]
                    // v26 = { Re(s₂), Re(s₃) }
                    // v27 = { Im(s₂), Im(s₃) }
        add         x8, x8, #32

_next_octet_inv_d:

        ld1         { v0.2d, v1.2d, v2.2d, v3.2d }, [x6]
        add         x6, x6, #64
        ld1         { v4.2d, v5.2d, v6.2d, v7.2d }, [x6]
        add         x6, x6, #64

                    // v0 = { Re(a), Im(a) }
                    // v1 = { Re(b), Im(b) }
                    // v2 = { Re(c), Im(c) }
                    // v3 = { Re(d), Im(d) }
                    // v4 = { Re(e), Im(e) }
                    // v5 = { Re(f), Im(f) }
                    // v6 = { Re(g), Im(g) }
                    // v7 = { Re(h), Im(h) }

        // Combine 4 pairs of 1-point signals

        fadd        v16.2d, v0.2d, v1.2d    //  { Re(A), Im(A) }
        fsub        v17.2d, v0.2d, v1.2d    //  { Re(B), Im(B) }
        fadd        v18.2d, v2.2d, v3.2d    //  { Re(C), Im(C) }
        fsub        v19.2d, v2.2d, v3.2d    //  { Re(D), Im(D) }

        fadd        v20.2d, v4.2d, v5.2d    //  { Re(E), Im(E) }
        fsub        v21.2d, v4.2d, v5.2d    //  { Re(F), Im(F) }
        fadd        v22.2d, v6.2d, v7.2d    //  { Re(G), Im(G) }
        fsub        v23.2d, v6.2d, v7.2d    //  { Re(H), Im(H) }

        // Combine 2 pairs of 2-point signals

        fadd        v0.2d, v16.2d, v18.2d   //  { Re(A), Im(A) }
        fsub        v1.2d, v16.2d, v18.2d   //  { Re(C), Im(C) }

        mov         v28.d[0], v19.d[1]
        mov         v28.d[1], v19.d[0]
                                             //  { Im(d), Re(d) }
        // The following two instructions are different for reverse
        fsub        v2.2d, v17.2d, v28.2d    //  { Re(B), Im(D) }
        fadd        v3.2d, v17.2d, v28.2d    //  { Re(D), Im(B) }

        trn1        v16.2d, v0.2d, v2.2d     //  { Re(A), Re(B) }
        trn2        v17.2d, v0.2d, v3.2d     //  { Im(A), Im(B) }
        trn1        v18.2d, v1.2d, v3.2d     //  { Re(C), Re(D) }
        trn2        v19.2d, v1.2d, v2.2d     //  { Im(C), Im(D) }

        fadd        v4.2d, v20.2d, v22.2d   //  { Re(E), Im(E) }
        fsub        v5.2d, v20.2d, v22.2d   //  { Re(G), Im(G) }

        mov         v30.d[0], v23.d[1]
        mov         v30.d[1], v23.d[0]
                                             //  { Im(h), Re(h) }

        // The following two instructions are different for reverse
        fsub        v6.2d, v21.2d, v30.2d    //  { Re(F), Im(H) }
        fadd        v7.2d, v21.2d, v30.2d    //  { Re(H), Im(F) }

        trn1        v20.2d, v4.2d, v6.2d     //  { Re(E), Re(F) }
        trn2        v21.2d, v4.2d, v7.2d     //  { Im(E), Im(F) }
        trn1        v22.2d, v5.2d, v7.2d     //  { Re(G), Re(H) }
        trn2        v23.2d, v5.2d, v6.2d     //  { Im(G), Im(H) }

        // Combine 1 pair of 4-point signals

        fmul        v28.2d, v20.2d, v24.2d    //  { Re(e)·Re(s₀), Re(f)·Re(s₁) }
        fmul        v29.2d, v20.2d, v25.2d    //  { Re(e)·Im(s₀), Re(f)·Im(s₁) }
        fmul        v30.2d, v21.2d, v24.2d    //  { Im(e)·Re(s₀), Im(f)·Re(s₁) }
        fmul        v31.2d, v21.2d, v25.2d    //  { Im(e)·Im(s₀), Im(f)·Im(s₁) }

        fsub        v20.2d, v28.2d, v31.2d    //  { Re(e·s₀), Re(f·s₁) }
        fadd        v21.2d, v29.2d, v30.2d    //  { Im(e·s₀), Im(f·s₁) }

        fadd        v0.2d, v16.2d, v20.2d     //  { Re(A), Re(B) }
        fadd        v1.2d, v17.2d, v21.2d     //  { Im(A), Im(B) }
        fsub        v4.2d, v16.2d, v20.2d     //  { Re(E), Re(F) }
        fsub        v5.2d, v17.2d, v21.2d     //  { Im(E), Im(F) }

        fmul        v28.2d, v22.2d, v26.2d    //  { Re(g)·Re(s₂), Re(h)·Re(s3) }
        fmul        v29.2d, v22.2d, v27.2d    //  { Re(g)·Im(s₂), Re(h)·Im(s3) }
        fmul        v30.2d, v23.2d, v26.2d    //  { Im(g)·Re(s₂), Im(h)·Re(s3) }
        fmul        v31.2d, v23.2d, v27.2d    //  { Im(g)·Im(s₂), Im(h)·Im(s3) }

        fsub        v22.2d, v28.2d, v31.2d    //  { Re(g·s2), Re(h·s3) }
        fadd        v23.2d, v29.2d, v30.2d    //  { Im(g·s2), Im(h·s3) }

        fadd        v2.2d, v18.2d, v22.2d     //  { Re(C), Re(D) }
        fadd        v3.2d, v19.2d, v23.2d     //  { Im(C), Im(D) }
        fsub        v6.2d, v18.2d, v22.2d     //  { Re(G), Re(H) }
        fsub        v7.2d, v19.2d, v23.2d     //  { Im(G), Im(H) }

        st2         { v0.2d, v1.2d }, [x7]
        add         x7, x7, #32
        st2         { v2.2d, v3.2d }, [x7]
        add         x7, x7, #32
        st2         { v4.2d, v5.2d }, [x7]
        add         x7, x7, #32
        st2         { v6.2d, v7.2d }, [x7]
        add         x7, x7, #32

        sub         x2, x2, #1
        cmp         x2, #0
        bne         _next_octet_inv_d

        ret
