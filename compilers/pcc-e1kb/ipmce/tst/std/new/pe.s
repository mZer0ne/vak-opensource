КАС2011 Файл PE : Лист 1 Дата 7.3.89 (0:6)


Тг   Адрес Код:		Строка	Текст

				1	; ****************************************************************
				2	; *								 *
				3	; *	  'БЫСТРЫЙ' ТЕСТ ОПЕРАТИВНОЙ ПАМЯТИ ВК 'ЭЛЬБРУС-Б'	 *
				4	; *								 *
				5	; *  В ТЕСТЕ ОРГАНИЗУЕТСЯ 'БЫСТРЫЙ' ПРОХОД ПО ОПЕРАТИВНОЙ ПАМЯТИ *
				6	; *  В ГРУППОВОМ РЕЖИМЕ. РАЗМЕР ЛИСТА ЗАДАЕТСЯ РАВНЫМ 256К И УС- *
				7	; *  ТАНАВЛИВАЕТСЯ ПРИПИСКА НА ВСЮ ОП. ВСЯ ОП, КРОМЕ ОБЛАСТИ ТЕ- *
				8	; *  СТА РАСПИСЫВАЕТСЯ КОДОМ 'ВСЕ ЕДИНИЦЫ'. ПОСЛЕ ЭТОГО ВЫПОЛНЯ- *
				9	; *  ЕТСЯ ЧТЕНИЕ ПО ПРОВЕРЯЕМОЙ ОБЛАСТИ С ЗАМЕНОЙ НА 'ШАХМАТНЫЙ' *
				10	; *  КОД/ЧЕРЕДОВАНИЕ КОДОВ '0101...01' И '1010...10'/. ПОСЛЕ ЗА- *
				11	; *  МЕНЫ ПОДСЧИТЫВАЕТСЯ КОНТРОЛЬНАЯ СУММА ПРОВЕРЯЕМОЙ ОБЛАСТИ И *
				12	; *  СРАВНИВАЕТСЯ С ЭТАЛОННОЙ. ПРИ НЕСОВПАДЕНИИ ПРОИСХОДИТ ОСТА- *
				13	; *  НОВ. ОПЕРАЦИИ ВЫПОЛНЯЮТСЯ В ГРУППОВОМ РЕЖИМЕ. ПЕРЕБОР АДРЕ- *
				14	; *  СОВ ОТ МЛАДШИХ К СТАРШИМ. ЗАТЕМ ТОТ ЖЕ АЛГОРИТМ ВЫПОЛНЯЕТСЯ *
				15	; *  С ПЕРЕБОРОМ АДРЕСОВ ОТ СТАРШИХ К МЛАДШИМ.			 *
				16	; *								 *
				17	; * ВХОДНЫЕ ПАРАМЕТРЫ:						 *
				18	; *  НЕТ							 *
				19	; *								 *
				20	; * ОСТАНОВЫ ПРОГРАММЫ:						 *
				21	; *  СТОП 0 - ТЕСТ ВЫПОЛНЕН					 *
				22	; *  СТОП 1 - НЕ СОВПАЛА КОНТРОЛЬНАЯ СУММА ТЕСТА		 *
				23	; *  СТОП 2-37(8) - ЛОВУШКИ ПРЕРЫВАНИЙ И ЭКСТРАКОДОВ		 *
				24	; *  СТОП 100(8) - НЕ СОХРАНИЛИСЬ РЕГИСТРЫ ПРИПИСКИ		 *
				25	; *  СТОП 51(8) - КОНТРОЛЬНАЯ СУММА РОСПИСИ НЕ СОВПАЛА С ЭТАЛОН- *
				26	; *		  НОЙ ПРИ ПЕРЕБОРЕ АДРЕСОВ ОТ МЛАДШИХ К СТАРШИМ	 *
				27	; *  СТОП 52(8) - КОНТРОЛЬНАЯ СУММА РОСПИСИ НЕ СОВПАЛА С ЭТАЛОН- *
				28	; *		  НОЙ ПРИ ПЕРЕБОРЕ АДРЕСОВ ОТ СТАРШИХ К МЛАДШИМ	 *
				29	; *								 *
				30	; * ИСПОЛЬЗУЕМЫЕ ИНДЕКС-РЕГИСТРЫ:				 *
				31	; *  И1	 - АДРЕС ЗАПИСИ/ЧТЕНИЯ					 *
				32	; *  И10 - СЧЕТЧИК ПРОХОДОВ ТЕСТА				 *
				33	; *  И12 - ПАРАМЕТР ЦИКЛОВ УСТАНОВКИ ПРИПИСКИ, КОНТРОЛЯ УСТАНОВ- *
				34	; *	   КИ И ЦИКЛА КОНТРОЛЬНОГО СУММИРОВАНИЯ			 *
				35	; *  И16 - ТОЧКА ВХОДА В ТЕСТ ПОСЛЕ КОНТРОЛЬНОГО СУММИРОВАНИЯ	 *
				36	; * ЗДЕСЬ И ДАЛЕЕ НОМЕРА СПЕЦИАЛЬНЫХ РЕГИСТРОВ И ИНДЕКСНЫХ РЕГИ- *
				37	; * СТРОВ УКАЗЫВАЮТСЯ В 8-М ВИДЕ.				 *
				38	; *								 *
				39	; * ЗАМЕЧАНИЯ:							 *
				40	; *  1)ТЕСТ РАССЧИТАН НА ОПЕРАТИВНУЮ ПАМЯТЬ ОБ'ЕМА 8 МЛН. СЛОВ И *
				41	; *    КОЛИЧЕСТВО ПОВТОРОВ 10(8). ПРИ ИЗМЕНЕНИИ ОБ'ЕМА ОПЕРАТИВ- *
				42	; *    НОЙ ПАМЯТИ ИЛИ КОЛИЧЕСТВА ПОВТОРОВ ТЕСТА НЕОБХОДИМО ИЗМЕ- *
				43	; *    НИТЬ ЗНАЧЕНИЯ СТАДР ИЛИ ЧПВТ.				 *
				44	; *  2)КОНТРОЛЬНАЯ СУММА ТЕСТА И СОХРАННОСТЬ ПРИПИСКИ ПРОВЕРЯЮТ- *
				45	; *    СЯ ПРИ КАЖДОМ ПРОХОДЕ ТЕСТА.				 *
				46	; ****************************************************************
				47	
				48		.ОБЛ	ПЭ(1)
00 0000001 00 077 006 0020	49	ТПЭ	ЗР	020		;ПКЛ=0,ПКП=0
	   00 030 0000041	50		ПБ	НАЧТ
				51	
				52	; ***********************************************
				53	; *						*
				54	; *	 ЛОВУШКИ ПРЕРЫВАНИЙ И ЭКСТРАКОДОВ	*
				55	; *						*
				56	; * ИНДИКАЦИЯ:					*
				57	; *  48-33РР. СМ - ГРВП ПРИ ОСТ 2		*
				58	; *  32-01РР. СМ - РПР ПРИ ОСТ 4,5,6,7		*
				59	; ***********************************************
				60	
00 0000002 00 077 002 0047	61	ПВНЕ	ЧР	047
	   00 077 007 0002	62		ОСТ	02		;ВНЕШНЕЕ ПРЕРЫВАНИЕ
КАС2011 Файл PE : Лист 2 Дата 7.3.89 (0:6)


Тг   Адрес Код:		Строка	Текст

00 0000003 00 077 007 0003	63	ПЭР3	ОСТ	03		;ЭКСТРАКОД В РЕЖИМЕ 3
	   00 072 0000000
00 0000004 00 077 002 0037	64	ПВ12	ЧР	037
	   00 077 007 0004	65		ОСТ	04		;ВНУТРЕННЕЕ ПРЕРЫВАНИЕ В РЕЖИМЕ 1-2
00 0000005 00 077 002 0037	66	ПЗ12	ЧР	037
	   00 077 007 0005	67		ОСТ	05		;ЗАПРЕЩЕННАЯ КОМАНДА В РЕЖИМЕ 1-2
00 0000006 00 077 002 0037	68	ПВР3	ЧР	037
	   00 077 007 0006	69		ОСТ	06		;ВНУТРЕННЕЕ ПРЕРЫВАНИЕ В РЕЖИМЕ 3
00 0000007 00 077 002 0037	70	ПЗК3	ЧР	037
	   00 077 007 0007	71		ОСТ	07		;ЗАПРЕЩЕННАЯ КОМАНДА В РЕЖИМЕ 3
00 0000010 00 077 007 0010	72	ПЭ50	ОСТ	010		;ЭКСТРАКОД 50(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000011 00 077 007 0011	73	ПЭ51	ОСТ	011		;ЭКСТРАКОД 51(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000012 00 077 007 0012	74	ПЭ52	ОСТ	012		;ЭКСТРАКОД 52(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000013 00 077 007 0013	75	ПЭ53	ОСТ	013		;ЭКСТРАКОД 53(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000014 00 077 007 0014	76	ПЭ54	ОСТ	014		;ЭКСТРАКОД 54(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000015 00 077 007 0015	77	ПЭ55	ОСТ	015		;ЭКСТРАКОД 55(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000016 00 077 007 0016	78	ПЭ56	ОСТ	016		;ЭКСТРАКОД 56(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000017 00 077 007 0017	79	ПЭ57	ОСТ	017		;ЭКСТРАКОД 57(8) РЕЖИМА 1-2 
	   00 072 0000000
00 0000020 00 077 007 0020	80	ПЭ60	ОСТ	020		;ЭКСТРАКОД 60(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000021 00 077 007 0021	81	ПЭ61	ОСТ	021		;ЭКСТРАКОД 61(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000022 00 077 007 0022	82	ПЭ62	ОСТ	022		;ЭКСТРАКОД 62(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000023 00 077 007 0023	83	ПЭ63	ОСТ	023		;ЭКСТРАКОД 63(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000024 00 077 007 0024	84	ПЭ64	ОСТ	024		;ЭКСТРАКОД 64(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000025 00 077 007 0025	85	ПЭ65	ОСТ	025		;ЭКСТРАКОД 65(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000026 00 077 007 0026	86	ПЭ66	ОСТ	026		;ЭКСТРАКОД 66(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000027 00 077 007 0027	87	ПЭ67	ОСТ	027		;ЭКСТРАКОД 67(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000030 00 077 007 0030	88	ПЭ70	ОСТ	030		;ЭКСТРАКОД 70(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000031 00 077 007 0031	89	ПЭ71	ОСТ	031		;ЭКСТРАКОД 71(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000032 00 077 007 0032	90	ПЭ72	ОСТ	032		;ЭКСТРАКОД 72(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000033 00 077 007 0033	91	ПЭ73	ОСТ	033		;ЭКСТРАКОД 73(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000034 00 077 007 0034	92	ПЭ74	ОСТ	034		;ЭКСТРАКОД 74(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000035 00 077 007 0035	93	ПЭ75	ОСТ	035		;ЭКСТРАКОД 75(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000036 00 077 007 0036	94	ПЭ76	ОСТ	036		;ЭКСТРАКОД 76(8) РЕЖИМА 1-2
	   00 072 0000000
00 0000037 00 077 007 0037	95	ПЭ77	ОСТ	037		;ЭКСТРАКОД 77(8) РЕЖИМА 1-2
				96	
				97	; ***********************************************
				98	; *		 ХОРОШИЙ ОСТАНОВ		*
				99	; ***********************************************
				100	
КАС2011 Файл PE : Лист 3 Дата 7.3.89 (0:6)


Тг   Адрес Код:		Строка	Текст

	   00 072 0000000
00 0000040 17 074 0000001	101	СТП	ПА	1,15
	   17 077 007 0040	102		ОСТ	040,15
   0000041			103	НАЧТ
00 0000041 10 074 0000000	104		ПА	0,8		;ИНИЦИАЦИЯ СЧЕТЧИКА ПОВТОРОВ
	   00 030 0000055	105		ПБ	НАЧТ1		;ВРЕМЕННО ОБХОД КСУМ/ПА НАЧТ1,14 ПБ КС/
   0000042			106	ВЫХТ
00 0000042 10 075 0000001	107		СА	1,8		;СЧЕТЧИК ПРОХОДОВ + 1
	   00 077 042 0010	108		ВИ	8
00 0000043 00 112 0000002	109		СРЛ	ЧПВТ
	   00 050 0000040	110		УР	СТП		;ИСЧЕРПАНО ЧИСЛО ПРОХОДОВ
00 0000044 00 030 0000063	111		ПБ	КПРИ		;ВРЕМЕННО ОБХОД КСУМ
	   00 072 0000000
   0000045			112	КС
				113	
				114	; ***********************************************
				115	; *	    КОНТРОЛЬНОЕ СУММИРОВАНИЕ		*
				116	; ***********************************************
				117	
00 0000045 00 064 0000135	118		ЗН	РАЯ
	   12 074 3777646	119		ПА	ТПЭ-КСУМТ+1,10	;И12:=1-ДЛИНА ТЕСТА
00 0000046 12 060 0000133	120	КСУМ	СТ	КСУМТ-1,10
	   00 013 0000135	121		ЦС	РАЯ
00 0000047 00 000 0000135	122		ЗЧ	РАЯ		;СУММИРУЕМ ОЧЕРЕДНОЕ СЛОВО
	   00 077 030 2760	123		ВР	02760
00 0000050 00 077 026 1707	124		СД	1024-57
	   00 013 0000135	125		ЦС	РАЯ
00 0000051 00 000 0000135	126		ЗЧ	РАЯ		;ДОБАВИЛИ ЕГО ТЕГ
	   12 033 0000046	127		КЦ	КСУМ,10		;КЦ КОНТРОЛЬНОГО СУММИРОВАНИЯ
00 0000052 00 012 0000134	128		СР	КСУМТ		;СРАВНИМ С ЭТАЛОННОЙ КС
	   16 050 0000000	129		УР	,14
				130	
				131	; ***********************************************
				132	; *						*
				133	; *	   НЕ СОВПАЛА КОНТРОЛЬНАЯ СУММА		*
				134	; *						*
				135	; * ИНДИКАЦИЯ:					*
				136	; *  ВР	 - ЭТАЛОННАЯ КОНТРОЛЬНАЯ СУММА		*
				137	; *  СМ	 - КОД НЕСРАВНЕНИЯ			*
				138	; *  РМР - ПОДСЧИТАН2НАЯ СУММА			*
				139	; ***********************************************
				140	
00 0000053 00 073 0000134	141		ИК	КСУМТ
	   00 077 007 0001	142		ОСТ	1
00 0000054 00 030 0000041	143		ПБ	НАЧТ		;ПОВТОР КОНТРОЛЬНОГО СУММИРОВАНИЯ
				144	
	   00 072 0000000
   0000055			145	НАЧТ1
				146	
				147	; ***********************************************
				148	; *		НАЧАЛЬНАЯ НАСТРОЙКА		*
				149	; ***********************************************
				150	
00 0000055 00 010 0000130	151		СЧ	ВСЕЕД
	   00 077 006 0042	152		ЗР	042		;РАЗМЕР ЛИСТА=256К
00 0000056 00 077 006 0051	153		ЗР	051		;ОБРАЩЕНИЕ КО ВСЕМ ЛИСТАМ
	   00 010 0000000	154		СЧ	0
00 0000057 00 077 006 0052	155		ЗР	052		;НЕТ ЗАЩИТЫ ЗАПИСИ
				156	
				157	; ***********************************************
				158	; *		РОСПИСЬ ПРИПИСКИ		*
				159	; ***********************************************
КАС2011 Файл PE : Лист 4 Дата 7.3.89 (0:6)


Тг   Адрес Код:		Строка	Текст

				160	
	   00 072 0000000
   0000060			161	РОСПП
00 0000060 00 010 0000132	162		СЧ	ПРИП
	   12 074 3777741	163		ПА	-31,10		;ЦИКЛ НА 32 РЕГИСТРА
00 0000061 12 077 006 0137	164	РОСП	ЗР	0137,10
	   00 013 0000133	165		ЦС	Е41Е9		;ОЧЕРЕДНОЙ КОД
00 0000062 12 033 0000061	166		КЦ	РОСП,10		;КЦ РОСПИСИ ПРИПИСКИ
	   00 072 0000000
   0000063			167	КПРИ
				168	
				169	; ***********************************************
				170	; *	    КОНТРОЛЬ УСТАНОВКИ ПРИПИСКИ		*
				171	; ***********************************************
				172	
00 0000063 12 074 3777741	173		ПА	-31,10		;ЦИКЛ НА 32 РЕГИСТРА
	   00 010 0000132	174		СЧ	ПРИП
00 0000064 00 000 0000135	175	КПРИП	ЗЧ	РАЯ
	   12 077 002 0137	176		ЧР	0137,10
00 0000065 00 077 040 0000	177		УИ	0		;ВЫДЕРЖКА
	   00 012 0000135	178		СР	РАЯ
00 0000066 00 050 0000071	179		УР	КЦПРИП
				180	
				181	; ***********************************************
				182	; *						*
				183	; *	      ПРИПИСКА НЕ СОХРАНИЛАСЬ		*
				184	; *						*
				185	; * ИНДИКАЦИЯ:					*
				186	; *  ВР	 - ЭТАЛОННЫЙ КОД			*
				187	; *  СМ	 - КОД НЕСРАВНЕНИЯ			*
				188	; *  РМР - СЧИТАННЫЙ КОД			*
				189	; *  И12 - НОМЕР НЕСОХРАНИВШЕГОСЯ РЕГИСТРА	*
				190	; ***********************************************
				191	
	   12 075 0000037	192		СА	31,10		;ДЛЯ ИНДИКАЦИИ
00 0000067 00 073 0000135	193		ИК	РАЯ
	   12 077 007 0100	194		ОСТ	0100,10
00 0000070 00 030 0000060	195		ПБ	РОСПП		;ПОВТОР РОСПИСИ И КОНТРОЛЯ
				196	
	   00 072 0000000
00 0000071 00 010 0000135	197	КЦПРИП	СЧ	РАЯ
	   00 013 0000133	198		ЦС	Е41Е9		;ОЧЕРЕДНОЙ КОД
00 0000072 12 033 0000064	199		КЦ	КПРИП,10	;КЦ КОНТРОЛЯ УСТАНОВКИ ПРИПИСКИ
	   16 074 0000063	200		ПА	КПРИ,14		;ВХОД В ТЕСТ НА СЛЕДУЮЩИХ ПРОХОДАХ
				201	
   0000073			202	ШАГ1
				203	
				204	; ***********************************************
				205	; *	ПЕРЕБОР АДРЕСОВ ОТ МЛАДШИХ К СТАРШИМ	*
				206	; ***********************************************
				207	
				208	; * РОСПИСЬ КОДОМ 'ВСЕ ЕДИНИЦЫ' -----------
				209	
00 0000073 00 010 0000130	210		СЧ	ВСЕЕД		;СМ:='ВСЕ 1'
	   00 072 0000000	211		ПФ			;'ПУСТАЯ' КОМАНДА, ЧТОБЫ УГ БЫЛА ЛЕВОЙ
00 0000074 01 074 0000136	212		ПА	К+1,1		;ОБЛАСТЬ ТЕСТА ПРОПУСТИМ
	   00 072 0003777	213		ПФ	СТАДР
00 0000075 00 076 0007641	214		УГ	07777-К-1	;ПГ=1,ИС10=ОБ'ЕМ ОП - ДЛИНА ТЕСТА
	   01 140 0000001	215		ЗЧК	1,1
00 0000076 00 077 001 0000	216		ВТ			;ВЫТОЛКНЕМ В ОП
	   00 072 0000000
				217	
КАС2011 Файл PE : Лист 5 Дата 7.3.89 (0:6)


Тг   Адрес Код:		Строка	Текст

   0000077			218	РШАХ1				;РОСПИСЬ 'ШАХМАТНЫМ' КОДОМ
				219	
00 0000077 00 010 0000131	220		СЧ	ШАХМ		;СМ:='0101....01' 
	   01 074 0000136	221		ПА	К+1,1		;ОБЛАСТЬ ТЕСТА ПРОПУСТИМ
00 0000100 00 072 0003777	222		ПФ	СТАДР
	   00 076 0007641	223		УГ	07777-К-1	;ЛГ=1,ИС10=ОБ'ЕМ ОП - ДЛИНА ТЕСТА
00 0000101 01 152 0000000	224		СРК	,1
	   01 140 0000001	225		ЗЧК	1,1
00 0000102 00 077 001 0000	226		ВТ			;ВЫТОЛКНЕМ В ОП
	   00 072 0000000
				227	
   0000103			228	ЦС1				; ПОДСЧЕТ КОНТРОЛЬНОЙ СУММЫ РОСПИСИ
				229	
00 0000103 00 010 0000000	230		СЧ	0
	   01 074 0000136	231		ПА	К+1,1
00 0000104 00 077 037 1000	232		РА	01000		;ЦС "ПО-СТАРОМУ"
	   00 072 0003777	233		ПФ	СТАДР
00 0000105 00 076 0007641	234		УГ	07777-К-1
	   01 153 0000001	235		ЦСК	1,1
00 0000106 00 012 0000130	236		СР	ЭСУМ		;СРАВНИМ С ЭТАЛОННОЙ СУММОЙ
	   00 050 0000111	237		УР	ШАГ2
				238	
				239	; ***********************************************
				240	; *						*
				241	; *	  НЕСРАВНЕНИЕ С ЭТАЛОННОЙ СУММОЙ	*		
				242	; *						*
				243	; * ИНДИКАЦИЯ:					*
				244	; *  ВР	 - ЭТАЛОННАЯ СУММА			*
				245	; *  СМ	 - КОД НЕСРАВНЕНИЯ			*
				246	; *  РМР - ПОДСЧИТАННАЯ СУММА			*
				247	; ***********************************************
				248	
00 0000107 00 073 0000130	249		ИК	ЭСУМ
	   00 077 007 0051	250		ОСТ	051
00 0000110 00 030 0000073	251		ПБ	ШАГ1		;ПОВТОР		
	   00 072 0000000
   0000111			252	ШАГ2
				253	
				254	; ***********************************************
				255	; *	ПЕРЕБОР АДРЕСОВ ОТ СТАРШИХ К МЛАДШИМ	*
				256	; ***********************************************
				257	
00 0000111 00 072 0003777	258		ПФ	СТАДР
	   01 074 0007777	259		ПА	07777,1		;И1:=ПОСЛЕДНИЙ АДРЕС ПРОВЕРЯЕМОГО ОБ'ЕМА
				260	
				261	; * РОСПИСЬ КОДОМ 'ВСЕ ЕДИНИЦЫ' --------------
				262	
00 0000112 00 010 0000130	263		СЧ	ВСЕЕД		;СМ:='ВСЕ 1'
	   00 072 0003777	264		ПФ	СТАДР
00 0000113 00 076 0007641	265		УГ	07777-К-1	;ПГ=1,ИС10:=ОБ'ЕМ ОП-ДЛИНА ТЕСТА
	   01 140 3777777	266		ЗЧК	-1,1
00 0000114 00 077 001 0000	267		ВТ			;ВЫТОЛКНЕМ В ОП
	   00 072 0000000
				268	
   0000115			269	РШАХ2				;РОСПИСЬ ОП 'ШАХМАТНЫМ' КОДОМ
00 0000115 00 072 0003777	270		ПФ	СТАДР
	   01 074 0007777	271		ПА	07777,1		;И1:=ПОСЛЕДНИЙ АДРЕС ОП
00 0000116 00 010 0000131	272		СЧ	ШАХМ		;СМ:='0101....01'
	   00 072 0000000	273		ПФ			;'ПУСТАЯ' КОМАНДА, ЧТОБЫ УГ БЫЛА ПРАВОЙ
00 0000117 00 072 0003777	274		ПФ	СТАДР
	   00 076 0007641	275		УГ	07777-К-1	;ЛГ=1,ИС10=ОБ'ЕМ ОП-ДЛИНА ТЕСТА
00 0000120 01 152 0000000	276		СРК	,1
КАС2011 Файл PE : Лист 6 Дата 7.3.89 (0:6)


Тг   Адрес Код:		Строка	Текст

	   01 140 3777777	277		ЗЧК	-1,1
00 0000121 00 077 001 0000	278		ВТ			;ВЫТОЛКНЕМ В ОП
	   00 072 0000000
				279	
   0000122			280	ЦС2				;СУММИРОВАНИЕ ОП
00 0000122 00 072 0003777	281		ПФ	СТАДР
	   01 074 0007777	282		ПА	07777,1		;И1:=ПОСЛЕДНИЙ АДРЕС ОП
00 0000123 00 010 0000000	283		СЧ	0
	   00 072 0003777	284		ПФ	СТАДР
00 0000124 00 076 0007641	285		УГ	07777-К-1	;ПГ=1,ИС10:=ОБ'ЕМ ОП - ДЛИНА ТЕСТА
	   01 153 3777777	286		ЦСК	-1,1
00 0000125 00 012 0000130	287		СР	ЭСУМ		;СРАВНИМ С ЭТАЛОННОЙ СУММОЙ
	   00 050 0000042	288		УР	ВЫХТ
				289	
				290	; ***********************************************
				291	; *						*
				292	; *	  НЕСРАВНЕНИЕ С ЭТАЛОННОЙ СУММОЙ	*
				293	; *						*
				294	; * ИНДИКАЦИЯ:					*
				295	; *  ВР	 - ЭТАЛОННАЯ СУММА			*
				296	; *  СМ	 - КОД НЕСРАВНЕНИЯ			*
				297	; *  РМР - ПОДСЧИТАННАЯ СУММА			*
				298	; ***********************************************
				299	
00 0000126 00 073 0000130	300		ИК	ЭСУМ
	   00 077 007 0052	301		ОСТ	052
00 0000127 00 030 0000111	302		ПБ	ШАГ2		;ПОВТОР
				303	
				304	; ***********************************************
				305	; *		  КОНСТАНТЫ ТЕСТА		*
				306	; ***********************************************
				307	
	   00 072 0000000
00 0000130 377 377 377 377	308	ВСЕЕД	.КОД	-1		;'ВСЕ 1'
	   377 377 377 377
00 0000131 125 125 125 125	309	ШАХМ	.КОД	0525252525252525252525
	   125 125 125 125
00 0000132 000 000 000 377	310	ПРИП	.КОД	0377<32		;НАЧАЛЬНАЯ КОНСТАНТА ПРИПИСКИ
	   000 000 000 000
00 0000133 000 000 001 000	311	Е41Е9	.КОД	1<32!1<8
	   000 000 001 000
00 0000134 000 000 000 000	312	КСУМТ	.КОД	0		;КОНТРОЛЬНАЯ СУММА ТЕСТА
	   000 000 000 000
				313	
				314	; ***********************************************
				315	; *		  РАБОЧИЕ ЯЧЕЙКИ		*					
				316	; ***********************************************	
				317	
00 0000135 0 0 0 0 0 0 0 0	318	РАЯ	.ПАМ	1
				319	
				320	; ***********************************************
				321	; *		  ЭКВИВАЛЕНТНОСТИ		*
				322	; ***********************************************
				323	
	  =00000000135		324	К	.ЭКВ	РАЯ
	  =00000000002		325	ЧПВТ	.ЭКВ	2		;ЧИСЛО ПОВТОРОВ ТЕСТА
	  =00000003777		326	СТАДР	.ЭКВ	03777		;СТАРШИЕ 12РР. АДРЕСА ДЛЯ ПФ
	  =00000000130		327	ЭСУМ	.ЭКВ	ВСЕЕД		;ЭТАЛОННАЯ СУММА РОСПИСИ
				328	
				329		.КНЦ			;'БЫСТРОГО' ТЕСТА

Начало трансляции	00:05:41.
Конец  трансляции	00:06:35.
Транслировано строк	329
