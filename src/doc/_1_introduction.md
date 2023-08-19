Introduction {#ChaIntro}
============
\tableofcontents


#There're plenty of W1 solution available, why a further one?

\Proj is a low cost solution. Beside the sensors, you'll need just
some cable for wiring (and perhaps an external 4k7 resistor to get
the bus working).

It's a flexible solution. You can use any GPIO pin as W1 bus. In fact,
you can switch the pin at run-time.

You're free to send any data to the bus and to receive any data from
the bus. You're not limited to the communication prepared in any
cryptic kernel code. Especially you can trigger adc sampling (ie.
temperature conversation) for all devices (sensors) by sending a
broadcast message and then read the samples from each sensor afterwards
in a fast manner, performing a simultaneous measurement.

Finally, it supports a monitoring feature that can show the bus state
during operation, supporting checks for hardware (wiring) issues.
