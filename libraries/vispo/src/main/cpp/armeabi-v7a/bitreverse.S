.global bit_reverse

.text

bit_reverse:
        rsb         r1, r1, #32
        rbit        r0, r0
        ror         r0, r0, r1
        bx          lr
