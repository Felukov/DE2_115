#ifndef _X86_H_INCLUDED
#define _X86_H_INCLUDED

#define PIT_CONTROL         0x43
#define PIT_TIMER_0         0x40
#define PIT_TIMER_1         0x41
#define PIT_TIMER_2         0x42

#define PIC_IMR             0x20        /* IO base address for master PIC */
#define PIC_IRR             0xA0        /* IO base address for slave PIC */

#define KBD_DATA            0x60

#define UART_DATA           0x0310
#define UART_RX_HAS_DATA    0x0311
#define UART_TX_IS_EMPTY    0x0312

#define ICW1_ICW4           0x01        /* ICW4 (not) needed */
#define ICW1_SINGLE         0x02        /* Single (cascade) mode */
#define ICW1_INTERVAL4      0x04        /* Call address interval 4 (8) */
#define ICW1_LEVEL          0x08        /* Level triggered (edge) mode */
#define ICW1_INIT           0x10        /* Initialization - required! */

#define ICW4_8086           0x01        /* 8086/88 (MCS-80/85) mode */
#define ICW4_AUTO           0x02        /* Auto (normal) EOI */
#define ICW4_BUF_SLAVE      0x08        /* Buffered mode/slave */
#define ICW4_BUF_MASTER     0x0C        /* Buffered mode/master */
#define ICW4_SFNM           0x10        /* Special fully nested (not) */

typedef unsigned char uint8_t;
typedef unsigned int  uint16_t;
typedef unsigned long uint32_t;

extern unsigned _inline_outp(unsigned __port, unsigned __value);
extern unsigned _inline_outpw(unsigned __port,unsigned __value);

extern unsigned _inline_inp(unsigned __port);
extern unsigned _inline_inpw(unsigned __port);

#pragma aux read_byte = \
"       push ds          " \
"       mov  ds, ax      " \
"       mov  al, ds:[bx] " \
"       pop  ds          " \
parm [ax] [bx] modify [al];

#pragma aux write_byte = \
"       push ds          " \
"       mov  ds, ax      " \
"       mov  ds:[bx], dl " \
"       pop  ds          " \
parm [ax] [bx] [dl];

void write_byte(uint16_t ax, uint16_t bx, uint8_t dx);

#pragma aux write_word = \
"       push ds          " \
"       mov  ds, ax      " \
"       mov  ds:[bx], dx " \
"       pop  ds          " \
parm [ax] [bx] [dx];

void write_word(uint16_t ax, uint16_t bx, uint16_t dx);

#pragma aux cpu_halt  = "hlt";

#pragma aux memsetb = \
"       push es          " \
"       mov  es, bx      " \
"       cld              " \
"       rep  stosb       " \
"       pop  es          " \
parm [bx] [di] [al] [cx] modify [di cx];

#pragma aux memcpyb = \
"       push ds          " \
"       push es          " \
"       mov  ds, ax      " \
"       mov  es, bx      " \
"       cld              " \
"       rep  movsb       " \
"       pop  es          " \
"       pop  ds          " \
parm [bx] [di] [ax] [si] [cx] modify [di si cx];

void cpu_halt();

#endif
