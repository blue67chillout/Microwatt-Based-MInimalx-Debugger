# Microwatt Tests

To run these you need icarus verilog, and a ppc64le toolchain. On Fedora
these are available as packages:

```
sudo dnf install iverilog gcc-powerpc64le-linux-gnu
```

And on Ubuntu:

```
sudo apt install iverilog gcc-powerpc64le-linux-gnu
```



## jtag
This reads the IDCODE register out of the Microwatt JTAG TAP interface.

## uart
A simple UART test where we send a character to Microwatt and it echoes it back.


