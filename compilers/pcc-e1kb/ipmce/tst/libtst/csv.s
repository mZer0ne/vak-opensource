; Порядок обращения к с-подпрограмме.
; -----------------------------------
;
; На стек помещаем сумматор, далее на стеке
; размещаются параметры вызываемой подпрограммы
; в прямом порядке. На сумматор заносится размер
; памяти занимаемой параметрами со знаком минус.
; Адрес возврата из подпрограммы должен
; находиться в ир14.
;
; Структура стека в момент вызова с-подпрограммы.
; -----------------------------------------------
;
;    указатель          ----------------------
;    стека после  -->  /|      сумматор      |
;    возврата        /  |--------------------| -
;                  /    |      параметр 1    |  |
; здесь          /      |--------------------|  |
; возвращается /        |                    |  |
; результат             |       . . .        |  | r слов
;                       |                    |  |
;    указатель          |--------------------|  |
;    стека              |      параметр n    |  |
;    в момент входа     ---------------------- -
;    в п/п        -->
;                       ----------------------
;        сумматор       |      - r           |
;                       ----------------------
;
; Структура стека с-подпрограммы.
; -------------------------------
;
;    указатель          ----------------------
;    стека после   --> /|      сумматор      |
;    возврата        /  |--------------------| -
;                  /    |      параметр 1    |  | <-- ир 12
;                /      |--------------------|  |
; здесь        /        |                    |  |
; возвращается          |       . . .        |  | r слов
; результат             |                    |  |
; работы п/п            |--------------------|  |
;                       |      параметр n    |  |
;                       |--------------------| -
;                       |      - r           |
;                       |--------------------|
;                       |      ир 14         |
;                       |--------------------|
;                       |      ир 1          |
;                       |--------------------|
;                       |                    |
;                       |      . . .         |
;                       |                    |
;                       |--------------------|
;                       |      ир 13         |
;                       |--------------------|
;            ир 13 -->  |                    |
;                       |      локалы п/п    |
;                       |                    |
;        указатель      ----------------------
;        стека     -->

;-------------------------------
; Процедура сохранения регистров
; на входе в подпрограмму.
; Вызов:        its 14
;               vjm csv,14
; Действия: сумматор (старый ир14)
; и 1-13 регистры запихивает в стек.
; Устанавливает ир12 на 1-й параметр,
; ир13 - на 1-ю лок. переменную.
;-------------------------------
	.text
csv:    .globl  csv

;       its     1
;       its     2
;       its     3
;       its     4
;       its     5
;       its     6
;       its     7
;       its     8
	its     9
	its     10
	its     12
	its     13
	its
	wtc     -6,15   ; -13 =
	utcs    ,15     ; -number of saved registers - 2
	vtm     -6,12
	mtj     13,15
	uj      ,14

;-------------------------------
; Процедура восстановления
; регистров и возврата.
; Вызов:        uj cret
; Действия: восстанавливает
; упрятанные регистры 1-13, а также
; состояние стека на входе в п/п,
; возвращает управление в
; вызывающую функцию.
;-------------------------------
	.text
cret:   .globl  cret

	mtj     15,13
	stx     -1,12
	sti     13
	sti     12
	sti     10
	sti     9
;       sti     8
;       sti     7
;       sti     6
;       sti     5
;       sti     4
;       sti     3
;       sti     2
;       sti     1
	wtc     -1,15
	utm     -1,15
	sti     14      ; на сумматоре результат
	uj      ,14

	.data
cshift: .globl  cshift
	.word   8000000000000000h
	.word   8100000000000000h
	.word   8200000000000000h
	.word   8300000000000000h
	.word   8400000000000000h
	.word   8500000000000000h
	.word   8600000000000000h
	.word   8700000000000000h

cmask:  .globl  cmask
	.word   0ffffffffffffff00h
	.word   0ffffffffffff00ffh
	.word   0ffffffffff00ffffh
	.word   0ffffffff00ffffffh
	.word   0ffffff00ffffffffh
	.word   0ffff00ffffffffffh
	.word   0ff00ffffffffffffh
	.word   000ffffffffffffffh
