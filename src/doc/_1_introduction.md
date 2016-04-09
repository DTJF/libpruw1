Introduction {#ChaIntro}
============
\tableofcontents


# FAQ

##There're plenty of W1 solution available, why a further one?

\Proj is a low cost solution. Besides the sensors, you'll some just
some cable and an external 4.7 k resistor to get the bus working.

is a flexible solution. You can use any GPIO pin as W1 bus. In fact,
you can switch the pin at run-time.

can send any data to and receive any data from the bus. You're not
limited to the communication prepared in any cryptic kernel code.
Especially you can trigger temperature conversation for all sensors by
a broadcast message and read the samples afterwards in a fast manner.
