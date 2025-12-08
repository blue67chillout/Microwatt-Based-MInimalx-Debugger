# Design Verification

To run these tests you must require icarus verilog and powerpc64 cross compiler.

### Icarus Verilog (iverilog) 

- For debian based systems icarus verilog can be easily installed via apt
  
    ```
    sudo apt install iverilog
    ```
### Powerpc64 Cross Compiler

- Download and extract the powerpc64 cross compiler ([Download it from here!](https://toolchains.bootlin.com/downloads/releases/toolchains/powerpc64le-power8/tarballs/powerpc64le-power8--glibc--stable-2025.08-1.tar.xz)) to your /home directory

- Do not forget to add the path of powerpc64 binaries to your path environmental variable
    ```
    export PATH=~/powerpc64le-power8--glibc--stable-2025.08-1/bin:$PATH
    ```
## Microwatt Tests

To run any of the tests,

```
cd verilog/dv/Caravel/microwatt/<test>
make all
```

Make sure to run `make clean` after performing the test

Currently, four DV tests are available to verify various subsystems of the design.

### 1. uart
- Sends a character to the Microwatt UART.
- Microwatt echoes the same character back.
- Successful loopback indicates working TX/RX logic and clocking.
- Currently character '7' is sent in tb and a fsm is setup to check if it echoes '7' back.

### 2. jtag (JTAG Slave)

- The DV environment drives the TAP interface.
- The IDCODE register is shifted out and checked.
- Confirms correct TAP state machine and IDCODE implementation.

### 3. jtag_m (JTAG Master)

- Microwatt acts as a master driving another JTAG device in simulation.
- The master shifts instructions/data and receives responses.
- Ensures master timing, state transitions, and TDO sampling logic.

### 4. usb

- Simulated USB packets are transmitted and received.
- Endpoint state machines and handshake responses are exercised.
- Ensures correct behavior of USB protocol logic and PHY-level simulation signals.
