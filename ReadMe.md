Welcome to *libpruw1* library project,

- a [one wire (W1)](https://en.wikipedia.org/wiki/1-Wire) driver for AM335x micro processors,
- designed for [Beaglebone hardware](http://www.beaglebone.org), providing
- configuration of any GPIO as W1 bus (without additional hardware), for
- sending digital output and receiving digital input from the bus,
- logging the bus data line state for monitoring purposes,
- supporting parasite power mode.

*libpruw1* software runs on the host (ARM) and in parallel on a
Programmable Realtime Unit SubSystem (= PRUSS or just PRU) for accurate
bus timing.

The driver provides functions to

- scan the bus for all device IDs,
- send a single byte or a block of eight bytes to the bus,
- receive a single byte or a block of bytes from the bus,
- calculate the CRC checksum for a block of data, and
- compute the temperature in °C (centigrade) from Dallas sensors (types `&h10`, `&h20`, `&h22`, `&h28`, `&h3B` or `&h42`).

The *libpruw1* project is [hosted at GitHub](https://github.com/DTJF/libpruw1). It's
developed and tested on a Beaglebone Black under Debian Image
2014-08-05. It should run on all Beaglebone platforms with Debian based
LINUX operating system. It's compiled by the [FreeBasic
compiler](http://www.freebasic.net). A wrapper for C programming
language is included.

Find more information in the online documentation at

- http://users.freebasic-portal.de/tjf/Projekte/libpruw1/doc/html/

or at related forum pages:

- [BeagleBoard: libpruw1 (one wire driver using GPIO)](https://forum.beagleboard.org/t/libpruw1-one-wire-driver-using-gpio/35688)
- [EN-FreeBASIC: libpruw1 (one wire driver using GPIO)](https://www.freebasic.net/forum/viewtopic.php?t=32356)
- [DE-FreeBASIC: libpruw1](https://www.freebasic-portal.de/downloads/fb-on-arm/libpruw1-402.html)


Licence:
========

libpruw1 (LGPLv2.1):
--------------------------

Copyright &copy; 2015-2023 by Thomas{ doT ]Freiherr[ At ]gmx[ DoT }net

This program is free software; you can redistribute it and/or modify it
under the terms of the Lesser GNU General Public License (LGPLv2.1)
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-
1301, USA. For further details please refer to:
http://www.gnu.org/licenses/lgpl-2.0.html


Examples and utility programs (GPLv3):
--------------------------------------

Copyright &copy; 2015-2023 by Thomas{ doT ]Freiherr[ At ]gmx[ DoT }net

The examples of this bundle are free software as well; you can
redistribute them and/or modify them under the terms of the GNU
General Public License version 3 as published by the Free Software
Foundation.

The programs are distributed in the hope that they will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-
1301, USA. For further details please refer to:
http://www.gnu.org/licenses/gpl-3.0.html
