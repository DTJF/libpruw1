Monitoring Feature {#ChaMonitor}
==================
\tableofcontents

The driver has a monitoring feature to visualize the data transmissions
on the bus. The PRU logs the state of this pin at a fixed sampling rate
of 1 us (1 MHz).

This feature has to get compiled in to the library. Define symbol
`__PRUW1_MONITOR__` in file pruw1.hp to enable it. Then re-compile
the library.


# Logging Format {#SecDbgFormat}

Each data block starts with a header line containing the name of the
currently running function and the parameter for the PRU call, like

~~~{.txt}
resetBus: command: 0020 .

tripple: command: 0010 .

sendRom: D1000802E7B0AA10 command: 0840 .....
~~~

Dots behind the command number indicate that the ARM CPU is waiting for
the PRU. Below that header line the state of the bus data line (DQ) is
logged in form of lines of characters. Each character stands for one
micro second, the minus character (dotted line) indicates high state,
and underscore characters indicate low state. Find examples in the
following sections.

The one wire bus works with precise time slots. Transmitting a bit
takes 70 us. Each line of output (70 characters) represents the
transmission of a single bit.


## Successful Transmission {#SecDbgSuccess}

In case of successful transmission you'll see flat lines toggling
between the high and low states. Each line starts in low state for 6
us. That's the masters signal to start the next data transfer. The rest
of the line depends on the action, output or input.


### Output  {#SecDbgOut}

In case of output the master (BBB) controlls the DQ line. First, the
line gets low for 6 us and, depending on the desired transmission, the
line gets high immediately (sent bit = 1)

~~~{.txt}
______----------------------------------------------------------------
~~~

or after 60 us (sent bit = 0).

~~~{.txt}
____________________________________________________________----------
~~~

Bits get send in low to high order, meaning the LSB gets sent first.

### Input  {#SecDbgIn}

In case of input the master (BBB) controlls the DQ line to start the
transmission. The line gets low for 6 us. Then the line switches to
input state and the responding device controls the level. In case of a
set bit the line gets high immediately (received bit = 1)

~~~{.txt}
______----------------------------------------------------------------
~~~

Otherwise it gets high after a certain time of maximum 54 us (received
bit = 0).

~~~{.txt}
________________________----------------------------------------------
~~~

Bits get received in low to high order, meaning the LSB gets fetched
first.


### Special Sequences  {#SecDbgSpecial}

Besides the standard bit transfer special sequences are used.

The reset sequence is used to start any new communication. The master
puts the bus down for 480 us and then switches to input mode and
listens for a presence signal from any devices, like

~~~{.txt}
resetBus: command: 0020 .
______________________________________________________________________
______________________________________________________________________
______________________________________________________________________
______________________________________________________________________
______________________________________________________________________
______________________________________________________________________
____________________________________________________________----------
---------------_______________________________________________________
_________________________________________-----------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------
--------------------------------------------------
~~~

Another special signal is the so called tripple sequence. It's used
after the SEARCH_ROM command in order to scan the bus for device IDs.
Two bits get read and one bit gets sent by the master, like

~~~{.txt}
tripple: command: 0010 .
______----------------------------------------------------------------
________________________----------------------------------------------
____________________________________________________________----------
~~~

Note the different length of the low state by master and slave signal.


## Errors {#SecDbgError}

In case of problems with the bus data line you'll see bit flickering in
the signals, like

~~~{.txt}
tripple: command: 0010 .
________________________----------------------------------------------
______----------------------------------------------------------------
____________________________________________________________----_--_-_
~~~

At the end of the last line the high state isn't stable. In that case
it was caused by a weak connection of the pullup resitor. Disturbances
may also have other reasons, ie. electro magnetical interferences.


# Bus Checking {#SecDbgCheck}

The logging feature may help you to optimize your bus installation.
Once you installed the bus with all sensors, check the signals with the
logging feature. You're lucky if you see signals as in section \ref
SecDbgSuccess. Your bus works fine.

Otherwise you have to do some optimization. The one wire bus isn't
designed for long distances, especially when it's driven by 3V3 as on
the BBB. So use three wires to connect devices (no parasite power mode)
and try to shorten all cables to the minimum. Prefer a tree structure
(devices connected to terminals by short cables) to star structure
(each device has it's own cable to connect to the master). Do not place
the cables near high power electrical loads nor their power lines. Try
a stronger pullup restistor to optimize the signal, or try capacitors
between VDD and GND to stabilize the power supply.
