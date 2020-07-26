.global bit_reverse

.text

bit_reverse:
        mov         x2, #64
        sub         x1, x2, x1
        rbit        x0, x0
        ror         x0, x0, x1
        ret
