.global fft8_fwd_s
.global fft8_inv_s
.global fft8_fwd_d
.global fft8_inv_d

.text

#  R0 - complex exponent for this stage (S)
#  R1 - signal data
#  R2 - number of 8-point signals to compute (M)
#
#  Q4 .. Q7 are preserved (not used)

fft8_fwd_s:
        push        { r5, r6, r7, r8 }

        mov         r6, r1                  //  data
        mov         r7, r1
        mov         r8, r0                  //  complex sinusoid lookup table
        vld2.32     { q8, q9 }, [r8]        //  s

_next_octet_fwd_s:

        // data = { a₀, b₀, a₁, b₁, a₂, b₂, a₃, b₃ }

        vld4.32     { d0, d2, d4, d6 }, [r6]!
        vld4.32     { d1, d3, d5, d7 }, [r6]!

        // Combine 4 pairs of 1-point signals
        //  q0 = { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
        //  q1 = { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
        //  q2 = { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
        //  q3 = { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        vmov        q10, q2
        vmov        q11, q3
        vsub.f32    q2, q0, q10         // Re(Bⱼ) = Re(aⱼ) - Re(bⱼ)
        vadd.f32    q0, q0, q10         // Re(Aⱼ) = Re(aⱼ) + Re(bⱼ)
        vsub.f32    q3, q1, q11         // Im(Bⱼ) = Im(aⱼ) - Im(bⱼ)
        vadd.f32    q1, q1, q11         // Im(Aⱼ) = Im(aⱼ) + Im(bⱼ)

        vtrn.32     d0, d1
        vtrn.32     d2, d3
        vtrn.32     d4, d5
        vtrn.32     d6, d7

        // Combine 2 pairs of 2-point signals
        // This part is different for forward and inverse transform
        //  q0 = { Re(A₀), Re(A₂), Re(A₁), Re(A₃) } -> { Re(a₀), Re(a₂), Re(b₀), Re(b₂) }
        //  q1 = { Im(A₀), Im(A₂), Im(A₁), Im(A₃) } -> { Im(a₀), Im(a₂), Im(b₀), Im(b₂) }
        //  q2 = { Re(B₀), Re(B₂), Re(B₁), Re(B₃) } -> { Re(a₁), Re(a₃), Re(b₁), Re(b₃) }
        //  q3 = { Im(B₀), Im(B₂), Im(B₁), Im(B₃) } -> { Im(a₁), Im(a₃), Im(b₁), Im(b₃) }

        vmov        d20, d1
        vmov        d22, d3
        vsub.f32    d1, d0, d20         //  Re(B₀) = Re(a₀) - Re(b₀); Re(B₂) = Re(a₂) - Re(b₂)
        vsub.f32    d3, d2, d22         //  Im(B₀) = Im(a₀) - Im(b₀); Im(B₂) = Im(a₂) - Im(b₂)
        vadd.f32    d0, d0, d20         //  Re(A₀) = Re(a₀) + Re(b₂); Re(A₂) = Re(a₂) + Re(b₂)
        vadd.f32    d2, d2, d22         //  Im(A₀) = Im(a₀) + Im(b₂); Im(A₂) = Im(a₂) + Im(b₂)

        vmov        d21, d5
        vmov        d23, d7
        vsub.f32    d5, d4, d23         //  Re(B₁) = Re(a₁) - Im(b₁); Re(B₃) = Re(a₃) - Im(b₃)
        vadd.f32    d7, d6, d21         //  Im(B₁) = Im(a₁) + Re(b₁); Im(B₃) = Im(a₃) + Re(b₃)
        vadd.f32    d4, d4, d23         //  Re(A₁) = Re(a₁) + Im(b₁); Re(A₃) = Re(a₃) + Im(b₃)
        vsub.f32    d6, d6, d21         //  Im(A₁) = Im(a₁) - Re(b₁); Im(A₃) = Im(a₃) - Re(b₃)

        vtrn.f32    q0, q2
        vtrn.f32    q1, q3

        // Combine 1 pair of 4-point signals
        //  q0 = { Re(A₀), Re(A₁), Re(B₀), Re(B₁) } -> { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
        //  q1 = { Im(A₀), Im(A₁), Im(B₀), Im(B₁) } -> { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
        //  q2 = { Re(A₂), Re(A3), Re(B₂), Re(B₃) } -> { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
        //  q3 = { Im(A₂), Im(A3), Im(B₂), Im(B₃) } -> { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        vmul.f32    q10, q2, q8                 //  Re(b)·Re(s)
        vmul.f32    q11, q2, q9                 //  Re(b)·Im(s)
        vmul.f32    q12, q3, q8                 //  Im(b)·Re(s)
        vmul.f32    q13, q3, q9                 //  Im(b)·Im(s)
        vsub.f32    q10, q10, q13               //  Re(b·s)
        vadd.f32    q11, q11, q12               //  Im(b·s)
        vsub.f32    q2, q0, q10                 //  Re(B) = Re(a) - Re(b·s)
        vsub.f32    q3, q1, q11                 //  Im(B) = Im(a) - Im(b·s)
        vadd.f32    q0, q0, q10                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f32    q1, q1, q11                 //  Im(A) = Im(a) + Im(b·s)

        //  q0 = { Re(A0), Re(A1), Re(A2), Re(A3) }
        //  q1 = { Im(A0), Im(A1), Im(A2), Im(A3) }
        //  q2 = { Re(B0), Re(B1), Re(B2), Re(B3) }
        //  q3 = { Im(B0), Im(B1), Im(B2), Im(B3) }

        vst2.32     { d0, d1, d2, d3 }, [r7]!
        vst2.32     { d4, d5, d6, d7 }, [r7]!

        sub         r2, r2, #1
        cmp         r2, #0
        bne         _next_octet_fwd_s

        pop         { r5, r6, r7, r8 }
        bx          lr

fft8_inv_s:
        push        { r5, r6, r7, r8 }

        mov         r6, r1                  //  data
        mov         r7, r1
        mov         r8, r0                  //  complex sinusoid lookup table
        vld2.32     { q8, q9 }, [r8]        //  s

_next_octet_inv_s:

        // data = { a₀, b₀, a₁, b₁, a₂, b₂, a₃, b₃ }

        vld4.32     { d0, d2, d4, d6 }, [r6]!
        vld4.32     { d1, d3, d5, d7 }, [r6]!

        // Combine 4 pairs of 1-point signals
        //  q0 = { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
        //  q1 = { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
        //  q2 = { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
        //  q3 = { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        vmov        q10, q2
        vmov        q11, q3
        vsub.f32    q2, q0, q10
        vadd.f32    q0, q0, q10
        vsub.f32    q3, q1, q11
        vadd.f32    q1, q1, q11

        vtrn.32     d0, d1
        vtrn.32     d2, d3
        vtrn.32     d4, d5
        vtrn.32     d6, d7

        // Combine 2 pairs of 2-point signals
        // This part is different for forward and inverse transform
        //  q0 = { Re(A₀), Re(A₂), Re(A₁), Re(A₃) } -> { Re(a₀), Re(a₂), Re(b₀), Re(b₂) }
        //  q1 = { Im(A₀), Im(A₂), Im(A₁), Im(A₃) } -> { Im(a₀), Im(a₂), Im(b₀), Im(b₂) }
        //  q2 = { Re(B₀), Re(B₂), Re(B₁), Re(B₃) } -> { Re(a₁), Re(a₃), Re(b₁), Re(b₃) }
        //  q3 = { Im(B₀), Im(B₂), Im(B₁), Im(B₃) } -> { Im(a₁), Im(a₃), Im(b₁), Im(b₃) }

        vmov        d20, d1
        vmov        d22, d3
        vsub.f32    d1, d0, d20         //  Re(B₀) = Re(a₀) - Re(b₀); Re(B₂) = Re(a₂) - Re(b₂)
        vsub.f32    d3, d2, d22         //  Im(B₀) = Im(a₀) - Im(b₀); Im(B₂) = Im(a₂) - Im(b₂)
        vadd.f32    d0, d0, d20         //  Re(A₀) = Re(a₀) + Re(b₀); Re(A₂) = Re(a₂) + Re(b₂)
        vadd.f32    d2, d2, d22         //  Im(A₀) = Im(a₀) + Im(b₀); Im(A₂) = Im(a₂) + Im(b₂)


        vmov        d21, d5
        vmov        d23, d7
        vadd.f32    d5, d4, d23         //  Re(B₁) = Re(a₁) + Im(b₁); Re(B₃) = Re(a₃) + Im(b₃)
        vsub.f32    d7, d6, d21         //  Im(B₁) = Im(a₁) - Re(b₁); Im(B₃) = Im(a₃) - Re(b₃)
        vsub.f32    d4, d4, d23         //  Re(A₁) = Re(a₁) - Im(b₁); Re(A₃) = Re(a₃) - Im(b₃)
        vadd.f32    d6, d6, d21         //  Im(A₁) = Im(a₁) + Re(b₁); Im(A₃) = Im(a₃) + Re(b₃)

        vtrn.f32    q0, q2
        vtrn.f32    q1, q3

        // Combine 1 pair of 4-point signals
        //  q0 = { Re(A₀), Re(A₁), Re(B₀), Re(B₁) } -> { Re(a₀), Re(a₁), Re(a₂), Re(a₃) }
        //  q1 = { Im(A₀), Im(A₁), Im(B₀), Im(B₁) } -> { Im(a₀), Im(a₁), Im(a₂), Im(a₃) }
        //  q2 = { Re(A₂), Re(A₃), Re(B₂), Re(B₃) } -> { Re(b₀), Re(b₁), Re(b₂), Re(b₃) }
        //  q3 = { Im(A₂), Im(A₃), Im(B₂), Im(B₃) } -> { Im(b₀), Im(b₁), Im(b₂), Im(b₃) }

        vmul.f32    q10, q2, q8                 //  Re(b)·Re(s)
        vmul.f32    q11, q2, q9                 //  Re(b)·Im(s)
        vmul.f32    q12, q3, q8                 //  Im(b)·Re(s)
        vmul.f32    q13, q3, q9                 //  Im(b)·Im(s)
        vsub.f32    q10, q10, q13               //  Re(b·s)
        vadd.f32    q11, q11, q12               //  Im(b·s)
        vsub.f32    q2, q0, q10                 //  Re(B) = Re(a) - Re(b·s)
        vsub.f32    q3, q1, q11                 //  Im(B) = Im(a) - Im(b·s)
        vadd.f32    q0, q0, q10                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f32    q1, q1, q11                 //  Im(A) = Im(a) + Im(b·s)

        //  q0 = { Re(A₀), Re(A₁), Re(A₂), Re(A₃) }
        //  q1 = { Im(A₀), Im(A₁), Im(A₂), Im(A₃) }
        //  q2 = { Re(B₀), Re(B₁), Re(B₂), Re(B₃) }
        //  q3 = { Im(B₀), Im(B₁), Im(B₂), Im(B₃) }

        vst2.32     { d0, d1, d2, d3 }, [r7]!
        vst2.32     { d4, d5, d6, d7 }, [r7]!

        sub         r2, r2, #1
        cmp         r2, #0
        bne         _next_octet_inv_s

        pop         { r5, r6, r7, r8 }
        bx          lr

#  R0 - complex sinusoid for this round
#  R1 - signal data
#  R2 - number of 8-point signals (M)
#
#  D8 .. D15 are preserved (saved on stack)

fft8_fwd_d:
        push        { r5, r6, r7, r8 }
        vpush       { q4 - q7 }

        mov         r6, r1                      //  data
        mov         r7, r1

        mov         r8, r0                      //  complex sinusoid lookup table
        vldm        r8, { d16 - d23 }           //  s[j]
_next_octet_fwd_d:
        vldm        r6!, { d0 - d15 }           // { a₀, b₀, a₁, b₁, a2, b2, a₃, b₃ }

        vmov        q12, q1
        vsub.f64    d2, d0, d24                 //  B₀ = a₀ - b₀
        vsub.f64    d3, d1, d25                 //  B₀ = a₀ - b₀
        vadd.f64    d0, d0, d24                 //  A₀ = a₀ + b₀
        vadd.f64    d1, d1, d25                 //  A₀ = a₀ + b₀

        vmov        q13, q3
        vsub.f64    d6, d4, d26                 //  B1 = a₁ - b₁
        vsub.f64    d7, d5, d27                 //  B1 = a₁ - b₁
        vadd.f64    d4, d4, d26                 //  A1 = a₁ + b₁
        vadd.f64    d5, d5, d27                 //  A1 = a₁ + b₁

        vmov        q14, q5
        vsub.f64    d10, d8, d28                //  B₂ = a₂ - b₂
        vsub.f64    d11, d9, d29                //  B₂ = a₂ - b₂
        vadd.f64    d8, d8, d28                 //  A₂ = a₂ + b₂
        vadd.f64    d9, d9, d29                 //  A₂ = a₂ + b₂

        vmov        q15, q7
        vsub.f64    d14, d12, d30               //  B₃ = a₃ - b₃
        vsub.f64    d15, d13, d31               //  B₃ = a₃ - b₃
        vadd.f64    d12, d12, d30               //  A₃ = a₃ + b₃
        vadd.f64    d13, d13, d31               //  A₃ = a₃ + b₃

// A₀ -> a₀
// B₀ -> a₁
// A₁ -> b₀
// B₁ -> b₁
// A₂ -> a₂
// B₂ -> a₃
// A₃ -> b₂
// B₃ -> b₃

        vmov        q12, q2                     //  b₀
        vsub.f64    d4, d0, d24                 //  B₀ = a₀ - b₀
        vsub.f64    d5, d1, d25                 //  B₀ = a₀ - b₀
        vadd.f64    d0, d0, d24                 //  A₀ = a₀ + b₀
        vadd.f64    d1, d1, d25                 //  A₀ = a₀ + b₀

        vmov        q13, q3                     //  b₁
        vsub.f64    d6, d2, d27                 //  Re(B₁) = Re(a₁) - Im(b₁)
        vadd.f64    d7, d3, d26                 //  Im(B₁) = Im(a₁) + Re(b₁)
        vadd.f64    d2, d2, d27                 //  Re(A₁) = Re(a₁) + Im(b₁)
        vsub.f64    d3, d3, d26                 //  Im(A₁) = Im(a₁) - Re(b₁)

        vmov        q14, q6                     //  b₂
        vsub.f64    d12, d8, d28                //  B₂ = a₂ - b₂
        vsub.f64    d13, d9, d29                //  B₂ = a₂ - b₂
        vadd.f64    d8, d8, d28                 //  A₂ = a₂ + b₂
        vadd.f64    d9, d9, d29                 //  A₂ = a₂ + b₂

        vmov        q15, q7                     //  b₃
        vsub.f64    d14, d10, d31               //  Re(B₃) = Re(a₃) - Im(b₃)
        vadd.f64    d15, d11, d30               //  Im(B₃) = Im(a₃) + Re(b₃)
        vadd.f64    d10, d10, d31               //  Re(A₃) = Re(a₃) + Im(b₃)
        vsub.f64    d11, d11, d30               //  Im(A₃) = Im(a₃) - Re(b₃)

// Combine 1 pair of 4-point signals

        vmul.f64    d24, d8, d16                //  Re(b₀)·Re(s₀)
        vmul.f64    d25, d9, d17                //  Im(b₀)·Im(s₀)
        vmul.f64    d26, d8, d17                //  Re(b₀)·Im(s₀)
        vmul.f64    d27, d9, d16                //  Im(b₀)·Re(s₀)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d8, d0, d24                 //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d9, d1, d25                 //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d0, d0, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d1, d1, d25                 //  Im(A) = Im(a) + Im(b·s)

        vmul.f64    d24, d10, d18               //  Re(b₁)·Re(s₁)
        vmul.f64    d25, d11, d19               //  Im(b₁)·Im(s₁)
        vmul.f64    d26, d10, d19               //  Re(b₁)·Im(s₁)
        vmul.f64    d27, d11, d18               //  Im(b₁)·Re(s₁)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d10, d2, d24                //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d11, d3, d25                //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d2, d2, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d3, d3, d25                 //  Im(A) = Im(a) + Im(b·s)

        vmul.f64    d24, d12, d20               //  Re(b₂)·Re(s₂)
        vmul.f64    d25, d13, d21               //  Im(b₂)·Im(s₂)
        vmul.f64    d26, d12, d21               //  Re(b₂)·Im(s₂)
        vmul.f64    d27, d13, d20               //  Im(b₂)·Re(s₂)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d12, d4, d24                //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d13, d5, d25                //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d4, d4, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d5, d5, d25                 //  Im(A) = Im(a) + Im(b·s)

        vmul.f64    d24, d14, d22               //  Re(b₃)·Re(s₃)
        vmul.f64    d25, d15, d23               //  Im(b₃)·Im(s₃)
        vmul.f64    d26, d14, d23               //  Re(b₃)·Im(s₃)
        vmul.f64    d27, d15, d22               //  Im(b₃)·Re(s₃)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d14, d6, d24                //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d15, d7, d25                //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d6, d6, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d7, d7, d25                 //  Im(A) = Im(a) + Im(b·s)

        vstm        r7!, { d0 - d15 }           // { a₀, b₀, a₁, b₁, a₂, b₂, a₃, b₃ }

        sub         r2, r2, #1
        cmp         r2, #0
        bne         _next_octet_fwd_d

        vpop        { q4 - q7 }
        pop         { r5, r6, r7, r8 }
        bx          lr

fft8_inv_d:
        push        { r5, r6, r7, r8 }
        vpush       { q4 - q7 }

        mov         r6, r1                      //  data
        mov         r7, r1

        mov         r8, r0                      //  complex sinusoid lookup table
        vldm        r8, { d16 - d23 }           //  s[j]
_next_octet_inv_d:
        vldm        r6!, { d0 - d15 }           // { a₀, b₀, a₁, b₁, a2, b2, a₃, b₃ }

        vmov        q12, q1
        vsub.f64    d2, d0, d24                 //  B₀ = a₀ - b₀
        vsub.f64    d3, d1, d25                 //  B₀ = a₀ - b₀
        vadd.f64    d0, d0, d24                 //  A₀ = a₀ + b₀
        vadd.f64    d1, d1, d25                 //  A₀ = a₀ + b₀

        vmov        q13, q3
        vsub.f64    d6, d4, d26                 //  B1 = a₁ - b₁
        vsub.f64    d7, d5, d27                 //  B1 = a₁ - b₁
        vadd.f64    d4, d4, d26                 //  A1 = a₁ + b₁
        vadd.f64    d5, d5, d27                 //  A1 = a₁ + b₁

        vmov        q14, q5
        vsub.f64    d10, d8, d28                //  B₂ = a₂ - b₂
        vsub.f64    d11, d9, d29                //  B₂ = a₂ - b₂
        vadd.f64    d8, d8, d28                 //  A₂ = a₂ + b₂
        vadd.f64    d9, d9, d29                 //  A₂ = a₂ + b₂

        vmov        q15, q7
        vsub.f64    d14, d12, d30               //  B₃ = a₃ - b₃
        vsub.f64    d15, d13, d31               //  B₃ = a₃ - b₃
        vadd.f64    d12, d12, d30               //  A₃ = a₃ + b₃
        vadd.f64    d13, d13, d31               //  A₃ = a₃ + b₃

// A₀ -> a₀
// B₀ -> a₁
// A₁ -> b₀
// B₁ -> b₁
// A₂ -> a₂
// B₂ -> a₃
// A₃ -> b₂
// B₃ -> b₃

        vmov        q12, q2                     //  b₀
        vsub.f64    d4, d0, d24                 //  B₀ = a₀ - b₀
        vsub.f64    d5, d1, d25                 //  B₀ = a₀ - b₀
        vadd.f64    d0, d0, d24                 //  A₀ = a₀ + b₀
        vadd.f64    d1, d1, d25                 //  A₀ = a₀ + b₀

        vmov        q13, q3                     //  b₁
        vadd.f64    d6, d2, d27                 //  Re(B₁) = Re(a₁) + Im(b₁)
        vsub.f64    d7, d3, d26                 //  Im(B₁) = Im(a₁) - Re(b₁)
        vsub.f64    d2, d2, d27                 //  Re(A₁) = Re(a₁) - Im(b₁)
        vadd.f64    d3, d3, d26                 //  Im(A₁) = Im(a₁) + Re(b₁)

        vmov        q14, q6                     //  b₂
        vsub.f64    d12, d8, d28                //  B₂ = a₂ - b₂
        vsub.f64    d13, d9, d29                //  B₂ = a₂ - b₂
        vadd.f64    d8, d8, d28                 //  A₂ = a₂ + b₂
        vadd.f64    d9, d9, d29                 //  A₂ = a₂ + b₂

        vmov        q15, q7                     //  b₃
        vadd.f64    d14, d10, d31               //  Re(B₃) = Re(a₃) + Im(b₃)
        vsub.f64    d15, d11, d30               //  Im(B₃) = Im(a₃) - Re(b₃)
        vsub.f64    d10, d10, d31               //  Re(A₃) = Re(a₃) - Im(b₃)
        vadd.f64    d11, d11, d30               //  Im(A₃) = Im(a₃) + Re(b₃)

// Combine 1 pair of 4-point signals

        vmul.f64    d24, d8, d16                //  Re(b₀)·Re(s₀)
        vmul.f64    d25, d9, d17                //  Im(b₀)·Im(s₀)
        vmul.f64    d26, d8, d17                //  Re(b₀)·Im(s₀)
        vmul.f64    d27, d9, d16                //  Im(b₀)·Re(s₀)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d8, d0, d24                 //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d9, d1, d25                 //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d0, d0, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d1, d1, d25                 //  Im(A) = Im(a) + Im(b·s)

        vmul.f64    d24, d10, d18               //  Re(b₁)·Re(s₁)
        vmul.f64    d25, d11, d19               //  Im(b₁)·Im(s₁)
        vmul.f64    d26, d10, d19               //  Re(b₁)·Im(s₁)
        vmul.f64    d27, d11, d18               //  Im(b₁)·Re(s₁)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d10, d2, d24                //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d11, d3, d25                //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d2, d2, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d3, d3, d25                 //  Im(A) = Im(a) + Im(b·s)

        vmul.f64    d24, d12, d20               //  Re(b₂)·Re(s₂)
        vmul.f64    d25, d13, d21               //  Im(b₂)·Im(s₂)
        vmul.f64    d26, d12, d21               //  Re(b₂)·Im(s₂)
        vmul.f64    d27, d13, d20               //  Im(b₂)·Re(s₂)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d12, d4, d24                //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d13, d5, d25                //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d4, d4, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d5, d5, d25                 //  Im(A) = Im(a) + Im(b·s)

        vmul.f64    d24, d14, d22               //  Re(b₃)·Re(s₃)
        vmul.f64    d25, d15, d23               //  Im(b₃)·Im(s₃)
        vmul.f64    d26, d14, d23               //  Re(b₃)·Im(s₃)
        vmul.f64    d27, d15, d22               //  Im(b₃)·Re(s₃)

        vsub.f64    d24, d24, d25               //  Re(b·s) = Re(b)·Re(s) - Im(b)·Im(s)
        vadd.f64    d25, d26, d27               //  Im(b·s) = Re(b)·Im(s) + Im(b)·Re(s)

        vsub.f64    d14, d6, d24                //  Re(B) = Re(a) - Re(b·s)
        vsub.f64    d15, d7, d25                //  Im(B) = Im(a) - Im(b·s)
        vadd.f64    d6, d6, d24                 //  Re(A) = Re(a) + Re(b·s)
        vadd.f64    d7, d7, d25                 //  Im(A) = Im(a) + Im(b·s)

        vstm        r7!, { d0 - d15 }           // { a₀, b₀, a₁, b₁, a₂, b₂, a₃, b₃ }

        sub         r2, r2, #1
        cmp         r2, #0
        bne         _next_octet_inv_d

        vpop        { q4 - q7 }
        pop         { r5, r6, r7, r8 }
        bx          lr
