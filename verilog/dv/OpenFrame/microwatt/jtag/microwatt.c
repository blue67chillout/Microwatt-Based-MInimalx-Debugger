#include "microwatt_util.h"
#include <stdint.h>

#define JTAG_BASE       0xC0009000

#define CONTROL_REG     (JTAG_BASE + 0x04)

int main(void)
{
	microwatt_alive();

	uint8_t *control = (uint8_t *) CONTROL_REG;
	(*control) &= ~(1<<2);

	while (1) {
	}
}
