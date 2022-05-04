; f(void *input_img, int width, int height, void *output_img, int newWidth, int newHeight);

; input_img - rdi
; width - rsi
; height - rdx
; output_img - rcx
; newWidth - r8
; newHeight - r9


section .text
global f

f:
    push rbp
    mov rbp, rsp
    sub rsp, 24

    push rbx
    push r12
    push r13
    push r14
    push r15

    movdqu [rbp-24], xmm6

    cvtsi2ss xmm5, esi
    cvtsi2ss xmm6, r8d
    divss xmm6, xmm5            ; scale = newWidth / width

    mov r15, rdx
    mov eax, esi
    and eax, 3
    lea r10d, [esi+esi*2]
    add r10d, eax
    mov [rbp-4], r10d           ; row width (bytes)

    mov eax, r8d
    and eax, 3
    lea r10d, [r8d+r8d*2]
    add r10d, eax
    mov [rbp-8], r10d           ; new row width (bytes)

    xor r14, r14
    xor rbx, rbx

    dec rsi
    dec r15
loop:
    cvtsi2ss xmm0, r14          ; float(x)
    cvtsi2ss xmm1, rbx          ; float(y)
    divss xmm0, xmm6            ; float(float(x) / scale)
    divss xmm1, xmm6            ; float(float(y) / scale)

    cvttss2si r12d, xmm0        ; int(float(x) / scale)
    cvttss2si r13d, xmm1        ; int(float(y) / scale)

    cmp r12d, esi
    jb row_loop
    cvtsi2ss xmm0, esi
    mov r12d, esi
row_loop:
    cmp r13d, r15d
    jb column_loop
    cvtsi2ss xmm1, r15d
    mov r13d, r15d
column_loop:
    cvtsi2ss xmm2, r12d
    cvtsi2ss xmm3, r13d

    subss xmm0, xmm2            ; dx = float(x/scale) - int(x/scale)
    subss xmm1, xmm3            ; dy = float(y/scale) - int(y/scale)

    mov eax, r13d
    mul DWORD[rbp-4]

    lea r10d, [r12d +r12d*2]
    add r10d, eax               ; first pixel
    add r10, rdi

    mov eax, [rbp-4]
    mov r11, r10
    add r11, rax

    mov eax, ebx
    mul DWORD[rbp-8]
    lea r13d, [r14d+r14d*2]

    add r13d, eax               ; new pixel position
    add r13, rcx

    xor r12, r12
set_color:
    ; x0 = c00 + (c10-c00)*dx
    ; x1 = c01 + (c11-c01)*dx
    ; xy = x0 + (x1-x0)*dy
    movzx edx, BYTE[r10+r12]    ; c00 - top left pixel
    cvtsi2ss xmm2, edx
    movzx edx, BYTE[r10+r12+3]  ; c10 - top right pixel
    cvtsi2ss xmm3, edx

    movzx edx, BYTE[r11+r12]    ; c01 - bottom left pixel
    cvtsi2ss xmm4, edx
    movzx edx, BYTE[r11+r12+3]  ; c11 - bottom right pixel
    cvtsi2ss xmm5, edx

    subss xmm3, xmm2
    mulss xmm3, xmm0
    addss xmm3, xmm2            ; x0

    subss xmm5, xmm4
    mulss xmm5, xmm0
    addss xmm5, xmm4            ; x1

    subss xmm5, xmm3
    mulss xmm5, xmm1
    addss xmm5, xmm3            ; xy

    cvttss2si edx, xmm5         ; new color

    ; set new color
    mov [r13+r12], dl

    inc r12
    cmp r12, 3
    jnz set_color

    inc r14
    cmp r14, r8
    jnz loop

    inc rbx
    xor r14, r14
    cmp rbx, r9
    jnz loop

    movdqu xmm6, [rbp-24]

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    mov rsp, rbp
    pop rbp
    ret