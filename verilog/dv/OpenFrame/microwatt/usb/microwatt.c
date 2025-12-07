#include "console.h"
#include "microwatt_util.h"

// ----------------- Bit fields (from usbh_host_defs.v) -----------------
// USB_CTRL bits
#define CTRL_ENABLE_SOF          (0u << 0)     // bit 0
#define CTRL_PHY_OPMODE_SHIFT    1             // bits [2:1]//made 0 later
#define CTRL_PHY_XCVRSELECT_SHIFT 3            // bits [4:3]// made 01 later ie full speed
#define CTRL_PHY_TERMSELECT      (1u << 5)     // bit 5
#define CTRL_PHY_DPPULLDOWN      (1u << 6)     // bit 6
#define CTRL_PHY_DMPULLDOWN      (1u << 7)     // bit 7
#define CTRL_TX_FLUSH            (1u << 8)     // bit 8

// USB_IRQ_STS / USB_IRQ_ACK / USB_IRQ_MASK bits
#define IRQ_SOF                  (1u << 0)
#define IRQ_DONE                 (1u << 1)
#define IRQ_ERR                  (1u << 2)
#define IRQ_DEVICE_DETECT        (1u << 3)

// USB_XFER_TOKEN fields
#define XFER_START               (1u << 31)    // START bit
#define XFER_IN                  (1u << 30)    // 1=IN, 0=OUT/SETUP
#define XFER_ACK                 (1u << 29)    // expect a response/handshake
#define XFER_PID_DATAX           (1u << 28)    // 0=DATA0, 1=DATA1
#define XFER_PID_BITS_SHIFT      16            // [23:16]
#define XFER_DEV_ADDR_SHIFT      9             // [15:9]
#define XFER_EP_ADDR_SHIFT       5             // [8:5]

// Token PIDs (from the SIE?s localparams)
#define PID_OUT  0xE1
#define PID_IN   0x69
#define PID_SOF  0xA5
#define PID_SETUP 0x2D

// ------------- Small helpers for MMIO -------------
static inline void wr32(uint32_t off, uint32_t v) { writel(v, USB_BASE + off); }
static inline uint32_t rd32(uint32_t off)         { return readl(USB_BASE + off); }

// ----------------- Wait for DONE (poll) -----------------
static void usb_wait_done(void)
{
	// Poll the DONE bit in USB_IRQ_STS (bit 1) until set.

	uint32_t temp = ((rd32(USB_IRQ_STS) & IRQ_DONE) == 0);
	// ACK the DONE interrupt (write-1-to-clear)
	wr32(USB_IRQ_ACK, IRQ_DONE);
}

// ----------------- Initialize PHY & IRQ mask -----------------
static void usb_init(void)
{
	// Build a sane USB_CTRL for Full-Speed host:
	// - OPMODE = 00 (normal)             -> bits [2:1] = 0
	// - XCVRSELECT = 01 (Full-Speed)     -> bits [4:3] = 01
	// - TERMSELECT = 1                   -> bit 5
	// - D+/- pulldown = 1,1              -> bits 6 & 7
	// - TX_FLUSH = 1 (clear TX FIFO now) -> bit 8
	//
	// NOTE: We do NOT enable SOF here (ENABLE_SOF=0) to keep the
	//       example deterministic in a bare sim without a PHY model.
	uint32_t ctrl = 0;
	ctrl |= (0u << CTRL_PHY_OPMODE_SHIFT);        // opmode = 00 (normal)
	ctrl |= (1u << CTRL_PHY_XCVRSELECT_SHIFT);    // xvcrselect bit3=1, bit4=0 (01 = FS)
	ctrl |= CTRL_PHY_TERMSELECT;                  // enable FS terminations
	ctrl |= CTRL_PHY_DPPULLDOWN | CTRL_PHY_DMPULLDOWN; // host pulls
	ctrl |= CTRL_TX_FLUSH;                        // flush TX FIFO once

	wr32(USB_CTRL, ctrl);

	// Enable the interrupts we?ll use:
	// - DONE (transaction complete)
	// - ERR  (timeout/CRC error)
	// (SOF left masked/off for this minimal demo)
	wr32(USB_IRQ_MASK, IRQ_DONE | IRQ_ERR);
}

// ----------------- Single OUT transfer (WITH ACK expected) -----------------
static void usb_out_no_ack(uint8_t dev, uint8_t ep, const uint8_t *buf, uint16_t len, int datax)
{
    // 1) Load TX FIFO with payload bytes
    for (uint16_t i = 0; i < len; i++)
        wr32(USB_WR_DATA, buf[i]);

    // *** 2) Program TX length FIRST ***
    wr32(USB_XFER_DATA, (uint32_t)len);

    // *** 3) SMALL DELAY ? absolutely required ***
    // Hardware needs at least 1 Wishbone clock to latch XFER_DATA
    for (volatile int i = 0; i < 50; i++);    // or 5

    // 4) Build the token:
    uint32_t tok = 0;
    tok |= ((uint32_t)PID_OUT << XFER_PID_BITS_SHIFT);
    tok |= ((uint32_t)dev      << XFER_DEV_ADDR_SHIFT);
    tok |= ((uint32_t)ep       << XFER_EP_ADDR_SHIFT);

    // Expect a handshake ? MUST set ACK = 1
    tok |= XFER_ACK;

    if (datax) tok |= XFER_PID_DATAX;

    // *** 5) VERY IMPORTANT ? assert START LAST ***
    tok |= XFER_START;
    wr32(USB_XFER_TOKEN, tok);

    // 6) Wait for DONE (tx_done_o)
    usb_wait_done();

    // 7) Read RX_STAT (optional)
    uint32_t rxstat = rd32(USB_RX_STAT);
}


int main(void)
{
	console_init();
	microwatt_alive();

	usb_init();

	// Example payload: one byte 0xAB
	uint8_t payload[1] = { 0xAB };

	// OUT to address 0, endpoint 0, DATA0, length 1, without expecting handshake.
	// In a real system you?d set ACK=1 and check RESP_BITS (ACK/NAK/STALL),
	// but for a bare sim with no device this avoids timeouts.
	usb_out_no_ack(/*dev=*/0, /*ep=*/0, payload, /*len=*/1, /*datax=*/0);



	return 0;
}

