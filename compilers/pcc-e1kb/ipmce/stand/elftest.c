/*
 * Комплексный тест интерфейса Эльбрус-Б - PC AT.
 */

# include "svsb.h"
# include "ucio.h"
# include "bcio.h"

# define OK             0xa5            /* reply statys OK */
# define BAD            0xff            /* reply statys BAD */

# define BUFSZ          256             /* size of UC input-output buffer */
# define BCSZ           (3*1024)        /* size of BC input-output buffer */
# define BCCOUNT        64              /* number of transmissions */

# define in             _in_            /* put word into SVSB HW register */
# define out            _out_           /* get word from SVSB HW register */

# define ODD(c)         (_nbits_ (c) & 1) /* if word has odd number of bits */
# define HALT(c)        _halt_ (c)      /* stop SVSB processor */
# define CLOCK()        _in_ (0x1d)

# define OUTACK(u)      { out ((u), oreg &= ~UC_RDY); out ((u), oreg = UC_RDY | oreg | UC_ACK); }
# define OUTNACK(u)     { out ((u), oreg &= ~UC_RDY); out ((u), oreg = UC_RDY | oreg & ~UC_ACK); }
# define OUTDATA(u,a)   out ((u), oreg = UC_STROBE | oreg & ~UC_PDATA | (a) & UC_PDATA)
# define OUTCLR(u,a)    out ((u), oreg &= ~(a))

# define IDLE()         _out_ (0x14, 0)

int uchan;              /* univ. channel number */
int bchan;              /* byte channel number */

int oreg;               /* contents of UC output register */
int ireg;               /* contents of UC input register */

int rfill;
int sfill;

int ofill;
int o2fill;

int ubuf [BUFSZ];
int u1buf [BUFSZ];
int u2buf [BUFSZ];

char rbbuf [BCSZ];      /* буфер приема по БК */
char bbuf [BCSZ];       /* буфер передачи по БК */
char frbbuf [BCSZ];     /* образец передачи по БК */

main ()
{
	bchan = bprobe ();      /* опознавание байтового канала */

	uchan = uprobe ();      /* опознавание универсального канала */
	uchan = UCREG (uchan);

	for (;;) {
		uctest ();
		bctest ();
	}
}

bprobe ()
{
	struct bccmd ccw;
	int csw, waitmask;      /* биты канала в регистре прерываний */
	int recvmask, sendmask;
	int i, chan;

	bcinit ();

	ccw.addr = (int) bbuf;
	ccw.count = 1024 >> 3;
	ccw.bcount = 0;
	ccw.flg = 0;

	waitmask = 0;           /* наша маска в регистре прерываний БК */
	for (i=0; i<8; ++i)
		waitmask |= BCC_IN (i);

	for (i=0; i<8; ++i)
		out (BC_ICW (i) | BCA_START, ccw);      /* пуск каналов приема */

	while (! (in (BC_CTL) & waitmask))              /* ждем конца обмена */
		IDLE ();

	recvmask = in (BC_CTL) & waitmask;

	bcinit ();

	waitmask = 0;           /* наша маска в регистре прерываний БК */
	for (i=0; i<8; ++i)
		waitmask |= BCC_OUT (i);

	for (i=0; i<8; ++i)
		out (BC_OCW (i) | BCA_START, ccw);      /* пуск каналов выдачи */

	while (! (in (BC_CTL) & waitmask))              /* ждем конца обмена */
		IDLE ();

	sendmask = in (BC_CTL) & waitmask;

	bcinit ();

	chan = -1;
	for (i=0; i<8; ++i)
		if ((recvmask & BCC_IN (i)) ||
		    (sendmask & BCC_OUT (i))) {
			if (chan >= 0)
				HALT (0xbc00);
			chan = i;
		}
	if (chan < 0)
		HALT (0xbc01);

	return (chan);
}

uprobe ()
{
	int i2, i3;

	i2 = in (UCREG (2));
	i3 = in (UCREG (3));

	for (;;) {
		IDLE ();
		if (i2 != in (UCREG (2)))
			return (2);
		if (i3 != in (UCREG (3)))
			return (3);
	}
}

/*****************  Выдача запроса в Э1КБ  *****************
 *
 *   Процедура выдает в Э1КБ 2 байта данных.
 *   В первом байте - код запроса
 *   Во втором байте - код росписи, заданный оператором
 *
 *
 *   Коды запросов в Э1КБ (reqcode):
 *
 *     Байт  | ИД
 *    0123456701
 *
 *   '0000xxxx00' && Запусти БК приема, нормальный обмен
 *   '1000xxxx00' && Запусти БК приема, нормальный обмен с ИПБ
 *   '0100xxxx00' && Запусти БК приема, будет укороченная выдача
 *   '1100xxxx00' && Запусти БК приема, будет удлиненная выдача
 *   '0010xxxx00' && Запусти БК приема, будет ошибка четности
 *
 *   '0001xxxx00' && Запусти БК выдачи, нормальный обмен
 *   '1001xxxx00' && Запусти БК выдачи, нормальный обмен с ИПБ
 *   '0101xxxx00' && Запусти БК выдачи, будет укороченный прием
 *   '1101xxxx00' && Запусти БК выдачи, будет удлиненный прием
 *   '0011xxxx00' && Запусти БК выдачи с формированием ошибки четности
 *
 *   'xxxx100000' && Код обмена: Постоянный код 00
 *   'xxxx010000' && Код обмена: Постоянный код FF
 *   'xxxx110000' && Код обмена: Постоянный код 55
 *   'xxxx001000' && Код обмена: Постоянный код AA
 *   'xxxx101000' && Код обмена: Постоянный код xx
 *
 *   'xxxx100100' && Код обмена: Переменный код 00
 *   'xxxx010100' && Код обмена: Переменный код 55
 *   'xxxx110100' && Код обмена: Переменный код xx
 *   'xxxx001100' && Код обмена: Переменный код бег.1
 *   'xxxx101100' && Код обмена: Переменный код бег.0
 *   'xxxx011100' && Код обмена: Переменный код счет.
 *   'xxxx111100' && Код обмена: Переменный код случ.
 *
 *   'xxxxxxxx10' && Запрос на 1000 обменов.
 */

dofill (fill)
{
	if (fill != ofill) {
		fillarray (u1buf, BUFSZ, fill, 0);
		fillcarray (bbuf, BCSZ, fill, 0);
		inverbuf ((int *) bbuf, BCSZ / sizeof (int));
		ofill = fill;
	}
}

do2fill (fill)
{
	if (fill != o2fill) {
		fillarray (u2buf, BUFSZ, fill, 0);
		fillcarray (frbbuf, BCSZ, fill, 0);
		inverbuf ((int *) frbbuf, BCSZ / sizeof (int));
		o2fill = fill;
	}
}

bctest ()
{
	int ctl, fill, rez;

	ofill = -1;
	o2fill = -1;

	for (;;) {
		ctl = recv (0);

		fill = filltype (ctl >> 4 & 0xf);

		switch (ctl & 0x30f) {
		default:
			break;
		/*
		 * Exit from BC testing loop.
		 */
		case 0x30f:
			return;
		/*
		 * Testing byte channel receiver.
		 */
		case 000:               /* нормальный обмен */
			dofill (fill);
			rez = bcrd (bchan, rbbuf, BCSZ);
			reply ((rez & 0xdf) == 0 && ! bcmp (rbbuf, bbuf, BCSZ));
			break;
		case 001:               /* нормальный обмен с ИПБ */
			dofill (fill);
			rez = bcrd (bchan, rbbuf, BCSZ);
			inverhbuf ((int *) rbbuf, BCSZ / sizeof (int));
			inverbuf ((int *) rbbuf, BCSZ / sizeof (int));
			reply ((rez & 0xdf) == 0 && ! bcmp (rbbuf, bbuf, BCSZ));
			break;
		case 002:               /* будет укороченная выдача */
			dofill (fill);
			rez = bcrd (bchan, rbbuf, BCSZ);
			reply ((rez & 0xdf) == 0x80 && ! bcmp (rbbuf, bbuf, BCSZ - recvlen (bchan)));
			break;
		case 003:               /* будет удлиненная выдача */
			dofill (fill);
			rez = bcrd (bchan, rbbuf, BCSZ);
			reply ((rez & 0xdf) == 0x40 && ! bcmp (rbbuf, bbuf, BCSZ));
			break;
		case 004:               /* будет ошибка четности */
			dofill (fill);
			rez = bcrd (bchan, rbbuf, BCSZ);
			reply ((rez & 0x17) == 0x10);
			break;
		case 007:
			rfill = fill;
			break;
		/*
		 * Testing byte channel transmitter.
		 */
		case 010:               /* нормальный обмен */
			dofill (fill);
			bcwr (bchan, bbuf, BCSZ);
			break;
		case 011:               /* нормальный обмен с ИПБ */
			dofill (fill);
			bcwr (bchan, bbuf, BCSZ);
			break;
		case 012:               /* будет укороченный прием */
			dofill (fill);
			bcwr (bchan, bbuf, BCSZ);
			break;
		case 013:               /* будет удлиненный прием */
			dofill (fill);
			bcwr (bchan, bbuf, BCSZ);
			break;
		case 014:               /* формирование ошибки четности */
			dofill (fill);
			bcwrflags = 0x80000;
			bcwr (bchan, bbuf, BCSZ);
			bcwrflags = 0;
			break;
		case 017:
			sfill = fill;
			break;
		/*
		 * Testing concurrent work of two channels.
		 */
		case 0x100:
			dofill (sfill);
			do2fill (rfill);
			rdwr ();
			reply (1);
			break;
		/*
		 * Testing concurrent work of all four channels.
		 */
		case 0x300:
			dofill (sfill);
			do2fill (rfill);
			rdwrsendrecv (u1buf, u2buf);
			reply (1);
			break;
		}
	}
}

uctest ()
{
	int i;

	/*
	 * I. Waiting for strobe.
	 *    Read UC input register and write it
	 *    to output register until strobe is set.
	 */
	for (;;) {
		IDLE ();
		ireg = in (uchan);
		if (ireg & UC_STROBE)
			break;
		oreg = ireg;
		out (uchan, oreg);
	}

	/*
	 * II. Set STROBE bit and 0 bit of data.
	 */
	oreg = UC_STROBE | 1;
	out (uchan, oreg);

	/*
	 * III. Waiting for READY bit in input register.
	 */
	for (;;) {
		ireg = in (uchan);
		if (ireg & UC_RDY)
			break;
	}

	/*
	 * IV. Set READY bit and 1 bit of data.
	 */
	oreg = UC_RDY | 2;
	out (uchan, oreg);

	/*
	 * V. Receive BUFSZ words of from UC.
	 *    Put them into ubuf.
	 *    Check if this is counter code.
	 *    Send reply through UC.
	 */
	for (i=0; i<BUFSZ; ++i)
		ubuf [i] = recv (0);
	reply (checkcount (ubuf));

	/*
	 * VI. Receive BUFSZ words with bad parity.
	 *     Check if this is counter code.
	 *     Send reply through UC.
	 */
	for (i=0; i<BUFSZ; ++i)
		ubuf [i] = recv (1);
	reply (checkcount (ubuf));

	/*
	 * VII. Send BUFSZ words of counter code to UC.
	 */
	for (i=0; i<BUFSZ; ++i)
		send (ubuf [i], 0);

	/*
	 * VIII. Send BUFSZ words of counter with bad parity.
	 */
	for (i=0; i<BUFSZ; ++i)
		send (ubuf [i], 1);

	/*
	 * IX. Send/receive 2*BUFSZ words.
	 *     Compare received arrays and send status byte.
	 */
	/* genrandom (ubuf); */
	sendrecv (ubuf, u1buf);
	reply (1);
	sendrecv (ubuf, u2buf);
	reply (! bcmp ((char *) u1buf, (char *) u2buf, BUFSZ * sizeof (int)));
}

recv (invpar)
{
	int c;
loop:
	IDLE ();
	ireg = in (uchan);
	if (! (ireg & UC_STROBE))               /* wait for strobe */
		goto loop;

	c = ireg & UC_PDATA;                    /* get data & parity */
	if (invpar) {                           /* invert parity */
		if (ODD (c)) {
			OUTACK (uchan);         /* bad parity */
			HALT (0xdada);
		}
		OUTNACK (uchan);                /* receive ok */
	} else {
		if (! ODD (c)) {
			OUTNACK (uchan);        /* bad parity */
			HALT (0xdada);
		}
		OUTACK (uchan);                 /* receive ok */
	}
	return (c & UC_DATA);
}

send (d, negpar)
{
	d &= UC_DATA;
	if (ODD (d) == negpar)          /* compute parity - make it odd */
		d |= UC_PARITY;
	OUTDATA (uchan, d);
loop:
	IDLE ();
	ireg = in (uchan);
	if (! (ireg & UC_RDY))          /* wait for 'ready' */
		goto loop;
	OUTCLR (uchan, UC_STROBE);

	if (! negpar == ! (ireg & UC_ACK))
		HALT (0xcaca);
}

sendrecv (outbuf, inbuf)
int outbuf [], inbuf [];
{
	int ic, oc, d, c;

	ic = 0;
	oc = 0;

	d = outbuf [oc++] & UC_DATA;
	if (! ODD (d))
		d |= UC_PARITY;
	OUTDATA (uchan, d);
loop:
	IDLE ();
	ireg = in (uchan);

	if (oc < BUFSZ && (ireg & UC_RDY)) {    /* wait for 'ready' */
		OUTCLR (uchan, UC_STROBE);
		if (! (ireg & UC_ACK))   /* bad parity */
			HALT (0xbaba);

		d = outbuf [oc++] & UC_DATA;
		if (! ODD (d))
			d |= UC_PARITY;
		OUTDATA (uchan, d);
	}

	if (ic < BUFSZ && (ireg & UC_STROBE)) { /* wait for strobe */
		c = ireg & UC_PDATA;            /* get data & parity */

		if (! ODD (c))
			HALT (0xfafa);          /* bad parity */

		OUTACK (uchan);                 /* receive ok */
		inbuf [ic++] = c & UC_DATA;
	}

	if (ic < BUFSZ || oc < BUFSZ)
		goto loop;

	while (! (in (uchan) & UC_RDY))       /* wait for 'ready' */
		IDLE ();
	OUTCLR (uchan, UC_STROBE);

	if (! (ireg & UC_ACK))                  /* bad parity */
		HALT (0xbaba);
}

genrandom (buf)
int buf [];
{
	int i;

	srand (CLOCK ());
	for (i=0; i<BUFSZ; ++i)
		buf [i] = rand () & 0x3ff;
}

checkcount (buf)
int buf [];
{
	int i, c;

	for (i=0; i<BUFSZ; ++i) {
		c = i & 0xff | i<<8 & 0x300;
		if (buf [i] != c)
			return (0);
	}
	return (1);
}

reply (ok)
{
	if (ok)
		send (OK, 0);
	else {
		send (BAD, 0);
		HALT (0xbad);
	}
}

fillcarray (buf, length, mode, ucode)
char buf [];
{
	register count;

	switch (mode) {
	default:                /* 00 - Не расписывать, возврат */
		return;
	case 0x22:              /* 22 - Переменный код 00 */
		ucode = 0x00;
varloop:
		ucode = ucode & 0xff | ucode << 8 & 0x300;
		for (count=0; count<length; ++count) {
			buf [count] = ucode;
			ucode ^= 0x3ff;
		}
		break;
	case 0x23:              /* 23 - Переменный код 55 */
		ucode = 0x55;
		goto varloop;
	case 0x24:              /* 24 - Переменный код xx */
		goto varloop;
	case 0x25:              /* 25 - Переменный код бег.1 */
		ucode = 1;
		for (count=0; count<length; ++count) {
			buf [count] = ucode;
			ucode = ucode << 1 & 0x3ff;
			if (! ucode)
				ucode = 1;
		}
		break;
	case 0x26:              /* 26 - Переменный код бег.0 */
		ucode = 1;
		for (count=0; count<length; ++count) {
			buf [count] = ucode ^ 0x3ff;
			ucode = ucode << 1 & 0x3ff;
			if (! ucode)
				ucode = 1;
		}
		break;
	case 0x27:              /* 27 - Переменный код счет. */
		for (count=0; count<length; ++count)
			buf [count] = count & 0xff | count << 8 & 0x300;
		break;
	case 0x28:              /* 28 - Переменный код случ. */
		srand (ucode);
		for (count=0; count<length; ++count)
			buf [count] = rand () & 0x3ff;
		break;
	case 0x32:              /* 32 - Постоянный код 00 */
		ucode = 0x00;
fixloop:
		ucode = ucode & 0xff | ucode << 8 & 0x300;
		for (count=0; count<length; ++count)
			buf [count] = ucode;
		break;
	case 0x33:              /* 33 - Постоянный код FF */
		ucode = 0xff;
		goto fixloop;
	case 0x34:              /* 34 - Постоянный код 55 */
		ucode = 0x55;
		goto fixloop;
	case 0x35:              /* 35 - Постоянный код AA */
		ucode = 0xaa;
		goto fixloop;
	case 0x36:              /* 36 - Постоянный код xx */
		goto fixloop;
	}
}

fillarray (buf, length, mode, ucode)
int buf [];
{
	register count;

	switch (mode) {
	default:                /* 00 - Не расписывать, возврат */
		return;
	case 0x22:              /* 22 - Переменный код 00 */
		ucode = 0x00;
varloop:
		ucode = ucode & 0xff | ucode << 8 & 0x300;
		for (count=0; count<length; ++count) {
			buf [count] = ucode;
			ucode ^= 0x3ff;
		}
		break;
	case 0x23:              /* 23 - Переменный код 55 */
		ucode = 0x55;
		goto varloop;
	case 0x24:              /* 24 - Переменный код xx */
		goto varloop;
	case 0x25:              /* 25 - Переменный код бег.1 */
		ucode = 1;
		for (count=0; count<length; ++count) {
			buf [count] = ucode;
			ucode = ucode << 1 & 0x3ff;
			if (! ucode)
				ucode = 1;
		}
		break;
	case 0x26:              /* 26 - Переменный код бег.0 */
		ucode = 1;
		for (count=0; count<length; ++count) {
			buf [count] = ucode ^ 0x3ff;
			ucode = ucode << 1 & 0x3ff;
			if (! ucode)
				ucode = 1;
		}
		break;
	case 0x27:              /* 27 - Переменный код счет. */
		for (count=0; count<length; ++count)
			buf [count] = count & 0xff | count << 8 & 0x300;
		break;
	case 0x28:              /* 28 - Переменный код случ. */
		srand (ucode);
		for (count=0; count<length; ++count)
			buf [count] = rand () & 0x3ff;
		break;
	case 0x32:              /* 32 - Постоянный код 00 */
		ucode = 0x00;
fixloop:
		ucode = ucode & 0xff | ucode << 8 & 0x300;
		for (count=0; count<length; ++count)
			buf [count] = ucode;
		break;
	case 0x33:              /* 33 - Постоянный код FF */
		ucode = 0xff;
		goto fixloop;
	case 0x34:              /* 34 - Постоянный код 55 */
		ucode = 0x55;
		goto fixloop;
	case 0x35:              /* 35 - Постоянный код AA */
		ucode = 0xaa;
		goto fixloop;
	case 0x36:              /* 36 - Постоянный код xx */
		goto fixloop;
	}
}

filltype (fill)
{
	switch (fill) {
	default:        return (0x32);              /* 32 - Постоянный код 00 */
	case 002:       return (0x33);              /* 33 - Постоянный код FF */
	case 003:       return (0x34);              /* 34 - Постоянный код 55 */
	case 004:       return (0x35);              /* 35 - Постоянный код AA */
	case 005:       return (0x36);              /* 36 - Постоянный код xx */

	case 011:       return (0x22);              /* 22 - Переменный код 00 */
	case 012:       return (0x23);              /* 23 - Переменный код 55 */
	case 013:       return (0x24);              /* 24 - Переменный код xx */
	case 014:       return (0x25);              /* 25 - Переменный код бег.1 */
	case 015:       return (0x26);              /* 26 - Переменный код бег.0 */
	case 016:       return (0x27);              /* 27 - Переменный код счет. */
	case 017:       return (0x28);              /* 28 - Переменный код случ. */
	}
}

recvlen (u)             /* вычисление остаточной длины в канале */
{
	struct bccmd ccw;

	*((int *) &ccw) = in (BC_ICW (u) | BCA_NOHALT);
	return ((((ccw.count + 1) & 0xffff) << 3) - ccw.bcount);
}

rdwr ()
{
	struct bccmd ccwr, ccww;
	int cswr, csww;
	int rwaitmask, wwaitmask;       /* биты канала в регистре прерываний */
	int mask;
	int recvcount, sendcount;

	ccwr.addr = (int) rbbuf;
	ccwr.count = BCSZ >> 3;
	ccwr.bcount = 0;
	ccwr.flg = 0;
	ccww.addr = (int) bbuf;
	ccww.count = BCSZ >> 3;
	ccww.bcount = 0;
	ccww.flg = 0;

	rwaitmask = BCC_IN (bchan);     /* наша маска в регистре прерываний БК */
	wwaitmask = BCC_OUT (bchan);    /* наша маска в регистре прерываний БК */

	out (BC_ICW (bchan) | BCA_START, ccwr); /* пуск канала */
	out (BC_OCW (bchan) | BCA_START, ccww); /* пуск канала */

	recvcount = 1;
	sendcount = 1;

loop:
	IDLE ();
	mask = in (BC_CTL);

	if (recvcount < BCCOUNT && (mask & rwaitmask)) { /* ждем конца обмена */
		cswr = in (BC_ISW (bchan) | BCA_NOHALT | BCA_RESET);
		if (cswr & 0xff)                        /* проверили слово состояния */
		     HALT (0xbc0aaa);
		if (bcmp (rbbuf, frbbuf, BCSZ))
		     HALT (0xbc0aa1);

		out (BC_ICW (bchan) | BCA_START, ccwr); /* пуск канала */
		++recvcount;
	}
	if (sendcount < BCCOUNT && (mask & wwaitmask)) { /* ждем конца обмена */
		csww = in (BC_OSW (bchan) | BCA_NOHALT | BCA_RESET);
		if (csww & 0xff)                        /* проверили слово состояния */
		     HALT (0xbc0bbb);

		out (BC_OCW (bchan) | BCA_START, ccww); /* пуск канала */
		++sendcount;
	}

	if (recvcount < BCCOUNT || sendcount < BCCOUNT)
		goto loop;

	while (! (in (BC_CTL) & wwaitmask))      /* ждем конца обмена */
		IDLE ();
	csww = in (BC_OSW (bchan) | BCA_NOHALT | BCA_RESET);
	if (csww & 0xff)                        /* проверили слово состояния */
	     HALT (0xbc0bbb);

	while (! (in (BC_CTL) & rwaitmask))      /* ждем конца обмена */
		IDLE ();
	cswr = in (BC_ISW (bchan) | BCA_NOHALT | BCA_RESET);
	if (cswr & 0xff)                        /* проверили слово состояния */
	     HALT (0xbc0aaa);
}

rdwrsendrecv (outbuf, inbuf)
int outbuf [], inbuf [];
{
	struct bccmd ccwr, ccww;
	int cswr, csww;
	int rwaitmask, wwaitmask;       /* биты канала в регистре прерываний */
	int mask, ireg;
	int recvcount, sendcount;
	int ic, oc, d, c;

	ccwr.addr = (int) rbbuf;
	ccwr.count = BCSZ >> 3;
	ccwr.bcount = 0;
	ccwr.flg = 0;
	ccww.addr = (int) bbuf;
	ccww.count = BCSZ >> 3;
	ccww.bcount = 0;
	ccww.flg = 0;

	rwaitmask = BCC_IN (bchan);     /* наша маска в регистре прерываний БК */
	wwaitmask = BCC_OUT (bchan);    /* наша маска в регистре прерываний БК */

	out (BC_ICW (bchan) | BCA_START, ccwr); /* пуск канала */
	out (BC_OCW (bchan) | BCA_START, ccww); /* пуск канала */

	recvcount = 1;
	sendcount = 1;
	ic = 0;
	oc = 0;

	d = outbuf [oc++] & UC_DATA;
	if (! ODD (d))
		d |= UC_PARITY;
	OUTDATA (uchan, d);
loop:
	IDLE ();
	mask = in (BC_CTL);

	if (recvcount < BCCOUNT && (mask & rwaitmask)) { /* ждем конца обмена */
		cswr = in (BC_ISW (bchan) | BCA_NOHALT | BCA_RESET);
		if (cswr & 0xff)                        /* проверили слово состояния */
		     HALT (0xbc0aaa);
		if (bcmp (rbbuf, frbbuf, BCSZ))
		     HALT (0xbc0aa1);

		out (BC_ICW (bchan) | BCA_START, ccwr); /* пуск канала */
		++recvcount;
	}
	if (sendcount < BCCOUNT && (mask & wwaitmask)) { /* ждем конца обмена */
		csww = in (BC_OSW (bchan) | BCA_NOHALT | BCA_RESET);
		if (csww & 0xff)                        /* проверили слово состояния */
		     HALT (0xbc0bbb);

		out (BC_OCW (bchan) | BCA_START, ccww); /* пуск канала */
		++sendcount;
	}

	ireg = in (uchan);

	if (oc < BUFSZ && (ireg & UC_RDY)) {    /* wait for 'ready' */
		OUTCLR (uchan, UC_STROBE);
		if (! (ireg & UC_ACK))   /* bad parity */
			HALT (0xbaba);

		d = outbuf [oc++] & UC_DATA;
		if (! ODD (d))
			d |= UC_PARITY;
		OUTDATA (uchan, d);
	}
	if (ic < BUFSZ && (ireg & UC_STROBE)) { /* wait for strobe */
		c = ireg & UC_PDATA;            /* get data & parity */

		if (! ODD (c))
			HALT (0xfafa);          /* bad parity */

		OUTACK (uchan);                 /* receive ok */
		if (inbuf [ic++] != (c & UC_DATA))
			HALT (0xffff);          /* bad byte received */
	}
	if (recvcount<BCCOUNT || sendcount<BCCOUNT || ic<BUFSZ || oc<BUFSZ)
		goto loop;

	while (! (in (uchan) & UC_RDY))       /* wait for 'ready' */
		IDLE ();
	OUTCLR (uchan, UC_STROBE);

	if (! (ireg & UC_ACK))                  /* bad parity */
		HALT (0xbaba);

	while (! (in (BC_CTL) & wwaitmask))      /* ждем конца обмена */
		IDLE ();
	csww = in (BC_OSW (bchan) | BCA_NOHALT | BCA_RESET);
	if (csww & 0xff)                        /* проверили слово состояния */
	     HALT (0xbc0bbb);

	while (! (in (BC_CTL) & rwaitmask))      /* ждем конца обмена */
		IDLE ();
	cswr = in (BC_ISW (bchan) | BCA_NOHALT | BCA_RESET);
	if (cswr & 0xff)                        /* проверили слово состояния */
	     HALT (0xbc0aaa);
}
