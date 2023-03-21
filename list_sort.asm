DOSSEG
.model TINY  

print_text MACRO text
    mov dx, offset text
    mov ah, 9h
    int 21h 
ENDM

.data
; 10 x 15
array db "Novikov  A.A.",10,13
      db "Sudakov  E.A.",10,13
      db "Andreev  T.P.",10,13
      db "Argentov P.G.",10,13
      db "Moiseev  F.I.",10,13
      db "Ivanov   O.U.",10,13
      db "Bazaliy  I.A.",10,13
      db "Rakhitov S.Y.",10,13  
      db "Alexeev  D.N.",10,13
      db "Goldberg A.A.",10,13   
      db "$"
      
delimiter db 13 dup("-"),10,13
      db "$"

oldArr db "old array: ",10,13,"$"
newArr db "New array: ",10,13,"$"

.code

swap PROC
    ; пролог функции
    push bp ; запоминаем старый адрес bp
    mov bp, sp ; перемещаем bp в начало функции

    mov bx, [bp + 6] ; указатель на начало строки
    mov cx, 12 ; цикл обмена строк
    for: 
        push bx
        add bx, cx
        dec bx
        mov ax, [bx]        
        mov dx, [bx + 15]  
        mov [bx], dl
        mov [bx + 15], al
        pop bx
    loop for

    ; эпилог функции
    mov sp, bp
    pop bp ; восстанавливаем bp, как он был до вызова функции
    ret 
swap ENDP

start:
    mov ax, @data 
    mov ds, ax  ; ds указывает на сегмент данных 

    ;--Печать исходного массива--
    print_text(oldArr) 

    print_text(array)  

    print_text(delimiter)  
    ;----------------------------

    ;--Сортировка--
    mov cx, 9
    loop2:
        push cx ; запоминаем счетчик цикла loop2
        mov bx, offset array
        loop1:
            mov al, [bx + 24] ; получаем буквы инициала имени
            mov ah, [bx + 9]
            cmp al, ah ; сравниваем инициалы имени в соседних строках
            jae next_pair
            ; если надо поменять строки местами  
            push bx
            push cx
            call swap
            pop cx
            pop bx
        next_pair:
            add bx, 15 ; переход к следующей паре строк
            loop loop1
            pop cx
            loop loop2
    ;----------------------------

    ;--Вывод отсортированного массива--
    print_text(newArr)  
    
    print_text(array)  
    ;----------------------------

    mov ah, 4ch
    int 21h
end start
