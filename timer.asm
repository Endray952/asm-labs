DOSSEG

.MODEL TINY
.STACK 100h


change_input_handler MACRO handler ; подмена обработчика прерываний клавиатуры
    CLI
        mov ah, 35h ;выдает адрес обработчика прерывания под номером al=9h (прерывания клавиатура)
        mov al, 9h
        int 21h ;в es-сегмент(адрес), в bx-смещение

        ;Сохраняем текущий обработчик в программе
        mov word ptr [offset oldvect], bx
        mov word ptr [offset oldvect + 2], es

        ;Подменяем  на новый обработчик
        mov dx, offset handler
        mov ah, 25h ;устанавливаем вектор прерываний (подмена обработчика прерывания)
        mov al, 9h
        int 21h
    STI
ENDM

clear_console MACRO ;очистка экрана путем установки нового режима
    mov ah, 0 ;номер функции установки режима дисплея
    mov al, 2 ;код текстового режима 80*25(разрешения) черно-белый
    int 10H   ;очистка экрана
ENDM


print_sec_remain MACRO sec_left ;вывод секунд на экран
local n1, n2
    mov di, 0
    mov ax,  word ptr sec_left
    mov bx, 10;для вывода секунд (деление на 10)

    ;вывод секунд на экран
     n1:
        mov dx, 0
        div bx ;div = (dx ax) / bx ->(результат целочисленного деления) ax
        push dx ;остаток от деления
        add di, 1
        cmp ax, 0 
        jnz  n1 ;проверка if ax not zero 
        mov ah, 2
    n2:
        pop dx
        add dx, 30h
        int 21h
        dec di
        cmp di, 0
        jnz  n2
ENDM

make_sound MACRO
    mov bx, 500     ;частота 
    mov ax, 34DDh
    mov dx, 12h    ;(dx,ax)=1193181
    cmp dx, bx     ;если bx < 18Гц, то выход
    jnb exit      ;чтобы избежать переполнения
    div bx        ;ax=(dx,ax)/bx
    mov bx, ax    ;Значение счетчика 2-го канала вычисляется по формуле n=1193181/f=1234DDh/f (1193181 - тактовая частота таймера в Гц, f - требуемая частота звука).


    mov al, 0B6h            
    out 43h, al     ; задаем контрольный байт (Режим 3 (генератор меандра? то есть прямоугольные биты), канал 2 )

    ;задаем частоту
    mov al, bl     
    out 42h, al     
    mov al, bh     
    out 42h, al     

    in al, 61h    
    or al, 3        ;установить биты 0-1. Бит 0 разрешает сигналу таймера поступать на звукогенератор, бит 1 разрешает вывод звука 
    out 61h, al     ;(Бит 0 фактически разрешает работу данного канала таймера, а бит 1 включает динамик)
    

    mov dx, 80
    pause1:	; внешный цикл
    mov cx, 0FFFFh
    pause2:	; внутренный цикл
    loop pause2	; пока cx не станет равным нулю
    dec dx
    jnz pause1

    in  al, 61h  ;чтение с порта динамика
    and al, not 3;сброс битов 0-1, завершение работы динамика
    out 61h, al  ;возвращаем значение в порт
ENDM

reset_handler MACRO
    CLI
        push ds
        mov dx, word ptr [offset oldvect]
        mov ax, word ptr [offset oldvect + 2]
        mov ds, ax
        mov ah, 25h
        mov al, 9
        int 21h
        pop ds
    STI
ENDM

scan_char MACRO
    mov ah, 01h
    int 21h
ENDM

print_text MACRO text
    mov ah, 9
    mov dx, offset text
    int 21h
ENDM

ascii_to_int MACRO ;перевод из ASCII в число, результат в al
    sub al, 30h
ENDM

scan_minutes MACRO minToSec
    ;ожидание ввода символа с клавиатуры
    scan_char()
    ;перевод из ASCII в число
    ascii_to_int()
    mov bl, al

    ;десятки минут(первый символ)
    mov al, 10
    MUL bl ; умножение al на bl и результат в ax 
    mov bx, ax

    ;ожидание ввода 1-иц (минут)
    scan_char()
    ascii_to_int()

    ;прибавляем именно al
    mov ah, 0
    add bx, ax

    ;перевод минут в секунды
    mov al, 60
    MUL bx
    mov bx, ax

    ;кладём в minToSec bx
    mov word ptr minToSec, bx
ENDM

scan_seconds MACRO seconds
    scan_char()
    ascii_to_int()
    mov bl, al

    mov al, 10
    MUL bl
    mov bx, ax

    scan_char()
    ascii_to_int()

    mov ah, 0
    add bx, ax

    mov word ptr seconds, bx
ENDM

get_current_ticks MACRO
    mov ah, 0  ;читать часы (счетчик тиков)
    int 1AH    ;получаем значение счетчика, результат в dx
ENDM

timer MACRO seconds
    newSecond:
        get_current_ticks()
        add dx, 18 ;добавляем 1 сек. к младшему слову, 18тиков = 1сек
        mov word ptr nextSecond, dx ; запоминаем требуемое значение в nextSecond

    ;---постоянная проверка значения счетчика времени суток BIOS
    waitNextSecond:
        cmp end_flag, 0 ;Проверка нажатой клавиши (если нажали клавишу во время отсчета таймера, то выходим из программы)
        jne exit
        get_current_ticks() ;количество тиков в dx
        cmp dx, nextSecond  ;сравниваем с искомым
        jne waitNextSecond  ;если не равен, то повторяем снова

    dec word ptr seconds

    clear_console()

    print_sec_remain(seconds)

    cmp word ptr seconds, 0
    jne newSecond
ENDM

.DATA


    totalSec    dw 0, 0
    minToSec    dw 0, 0
    nextSecond  dw 0, 0 ;количество тиков на следующей секунде
    min         db 13, 10, 'minutes:', 13, 10, '$'
    sec         db 13, 10, 'seconds:', 13, 10, '$'
    oldvect     dd 0
    msg         db 13,'Error',10,13,'$'
    n_int       db 0 ;количество вызванных прерываний
    end_flag    db 0 ;флаг завершения таймера по причине нажатия на клавишу

.CODE

    mov ax, @Data
    mov ds, ax
    
    print_text(min) ;вывод надписи 'minutes'
    scan_minutes(minToSec) ;ввод минут - резултат в секундах

    clear_console() ;очистка экрана путем установки нового режима

    print_text(sec) ;вывод надписи 'seconds'
    scan_seconds(totalSec) ;аналогично минутам ввод секунд

    clear_console() ;очистка экрана путем установки нового режима

    mov ax, word ptr minToSec;суммарное значение секунд
    add word ptr totalSec,  ax
    
    print_sec_remain(totalSec)
    
    change_input_handler(int09h_handler)

    timer(totalSec)

    make_sound()

    exit:
        reset_handler()
        mov ah, 4ch
        int 21h

    ; Обработчик прерывания ввода с клавиатуры
    int09h_handler:

        push ax
        push dx
        push ds

        mov ax, @Data
        mov ds, ax

        cmp n_int, 1 
        jl up
        je down
        ja exit_handler

        ; Клавиша НАЖАТА
        down:
            print_text(msg)
            inc byte ptr n_int
            mov byte ptr end_flag, 1
            jmp exit_handler 

        ; Клавиша ОТЖАТА
        up:
            inc byte ptr n_int
            jmp exit_handler
        
        exit_handler:
            pop ds
            pop dx
            pop ax
            jmp dword ptr oldvect 

END