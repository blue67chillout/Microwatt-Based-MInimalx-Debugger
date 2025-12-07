#include "microwatt_util.h"
#include "microwatt_soc.h"
#include <stdint.h>

#define JTAG_BASE       0xC0009000


// ---------- Register Map ----------
#define REG(offset)     (*(volatile uint32_t*)(JTAG_BASE + (offset)))

#define CLK_DIV_REG     REG(0x00)
#define CONTROL_REG     REG(0x04)
#define DATA_REG        REG(0x08)
#define STATUS_REG      REG(0x0C)
#define IRQ_MASK_REG    REG(0x10)
#define IRQ_STATUS_REG  REG(0x14)
#define IRQ_CLEAR_REG   REG(0x18)


// ---------- STATUS Bits ----------
#define STATUS_BUSY      (1 << 0)
#define STATUS_TDO_VALID (1 << 1)


// ---------- WAIT ----------
static inline void jtag_wait_ready()
{
    while (STATUS_REG & STATUS_BUSY);
}


// ---------- Clock Divider ----------
void jtag_set_clk_div(uint8_t div)
{
    CLK_DIV_REG = div;
}


// ---------- TMS, TRST, EXPOSE ----------
void jtag_set_control(uint8_t tms, uint8_t trst, uint8_t expose)
{
    uint32_t v = 0;
    v |= (tms & 1) << 0;
    v |= (trst    & 1) << 1;
    v |= (expose   & 1) << 2;
    CONTROL_REG = v;
}


// ---------- SHIFT (Main Operation) ----------
uint32_t jtag_shift(uint32_t data, uint8_t len)
{
    uint32_t cmd = (data << 8) | (len & 0xFF);
    DATA_REG = cmd;

    jtag_wait_ready();

    return DATA_REG;
}


// ---------- IRQ Control ----------
void jtag_enable_irq(uint32_t mask)
{
    IRQ_MASK_REG = mask;
}

uint32_t jtag_irq_status()
{
    return IRQ_STATUS_REG;
}

void jtag_irq_clear(uint32_t mask)
{
    IRQ_CLEAR_REG = mask;
}


void firmware_main()
{
    // Basic setup
    jtag_set_clk_div(4);
    jtag_set_control(1, 0, 1);

    // 8-bit shift test
    jtag_shift(0xA5, 8);

    // 24-bit shift
    jtag_shift(0xABCDEF, 24);

    // 256-bit shift (len=0)
    jtag_shift(0x123456, 0);

    // Back-to-back
    jtag_shift(0x111111, 4);
    jtag_shift(0x222222, 4);
    jtag_shift(0x333333, 4);

    // Interrupt test
    jtag_enable_irq(0x03);
    jtag_shift(0x555555, 8);
    jtag_irq_clear(0x03);

    // DONE: Loop forever
    while (1);
}


// ===========================================
//     ENTRY POINT (depends on CPU)
// ===========================================
int main()
{
    microwatt_alive();
    firmware_main();
    return 0;
}
