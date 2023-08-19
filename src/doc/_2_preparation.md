Preparation {#ChaPreparation}
===========
\tableofcontents

This chapter describes how to get libpruw1 working on your system.


# Tools  {#SecTools}

The further files in this package are related to the version control
system GIT and to automatical builds of the examples and the
documentation by the cross-platform CMake build management system. If
you want to use all package features, you can find in this chapter
information on

- how to prepare your system by installing necessary tools,
- how to get the package using GIT and
- how to automatical build the examples and the documentation.

The following table lists all dependencies for the \Proj package and
their types. At least, you have to install the FreeBASIC compiler on
your system to build any executable using the \Proj features. Beside
this mandatory (M) tool, the others are optional. Some are recommended
(R) in order to make use of all package features. LINUX users find some
packages in their distrubution management system (D).

|                                               Name  | Type |  Function                                                      |
| --------------------------------------------------: | :--: | :------------------------------------------------------------- |
| [fbc](http://www.freebasic.net)                     | M    | FreeBASIC compiler to compile the source code                  |
| [libpruio](https://github.com/DTJF/libpruio)        | M    | Library used for pinmuxing                                     |
| [dtc](https://git.kernel.org/cgit/utils/dtc/dtc.git)| M  D | Device tree compiler to create overlays                        |
| [GIT](http://git-scm.com/)                          | R  D | Version control system to organize the files                   |
| [CMake](http://www.cmake.org)                       | R  D | Build management system to build executables and documentation |
| [cmakefbc](http://github.com/DTJF/cmakefbc)         | R    | FreeBASIC extension for CMake                                  |
| [fbdoc](http://github.com/DTJF/fbdoc)               | R    | FreeBASIC extension tool for Doxygen                           |
| [Doxygen](http://www.doxygen.org/)                  | R  D | Documentation generator (for html output)                      |
| [Graphviz](http://www.graphviz.org/)                | R  D | Graph Visualization Software (caller/callee graphs)            |
| [LaTeX](https://latex-project.org/ftp.html)         | R  D | A document preparation system (for PDF output)                 |

It's beyond the scope of this guide to describe the installation for
those tools. Find detailed installation instructions on the related
websides, linked by the name in the first column.

-# First, install the distributed (D) packages of your choise, either mandatory
   ~~~{.txt}
   sudo apt-get install dtc git cmake
   ~~~
   or full install (recommended)
   ~~~{.txt}
   sudo apt-get install dtc git cmake doxygen graphviz doxygen-latex texlive
   ~~~

-# Then make the FB compiler working:
   ~~~{.txt}
   wget https://www.freebasic-portal.de/dlfiles/625/freebasic_1.06.0debian7_armhf.deb
   sudo dpkg --install freebasic_1.06.0debian7_armhf.deb
   sudo apt-get -f install
   ~~~

-# Continue by installing cmakefbc (if wanted). That's easy, when you
   have GIT and CMake. Execute the commands
   ~~~{.txt}
   git clone https://github.com/DTJF/cmakefbc
   cd cmakefbc
   mkdir build
   cd build
   cmake .. -DCMAKE_MODULE_PATH=../cmake/Modules
   make
   sudo make install
   ~~~
   \note Omit `sudo` in case of non-LINUX systems.

-# And install fbdoc (if wanted) by using GIT and CMake.
   Execute the commands
   ~~~{.txt}
   git clone https://github.com/DTJF/fbdoc
   cd fbdoc
   mkdir build
   cd build
   cmakefbc ..
   make
   sudo make install
   ~~~
   \note Omit `sudo` in case of non-LINUX systems.

-# Then finaly, install libpruio, using GIT and CMake. Execute the commands
   ~~~{.txt}
   git clone https://github.com/DTJF/libpruio
   cd libpruio
   mkdir build
   cd build
   cmakefbc ..
   make
   sudo make install
   sudo ldconfig
   sudo make init
   ~~~
   \note Omit `sudo` in case of non-LINUX systems.


# Get Package  {#SecGet}

Depending on whether you installed the optional GIT package, there're
two ways to get the \Proj package.

## GIT  {#SecGet_Git}

Using GIT is the prefered way to download the \Proj package (since it
helps users to get involved in to the development process). Get your
copy and change to the source tree by executing

~~~{.txt}
git clone https://github.com/DTJF/libpruw1
cd libpruw1
~~~

## ZIP  {#SecGet_Zip}

As an alternative you can download a Zip archive by clicking the
[Download ZIP](https://github.com/DTJF/girtobac/archive/master.zip)
button on the \Proj website, and use your local Zip software to unpack
the archive. Then change to the newly created folder.

\note Zip files always contain the latest development version. You
      cannot switch to a certain point in the history.


# Build Binary

In order to perform an out of source build, execute

~~~{.txt}
mkdir build
cd build
cmakefbc ..
make
sudo make install
sudo ldconfig
~~~

This will build the library binary and install it to `/usr/local/lib`.
The FB header file gets into the folder `BBB` in the FreeBASIC
installation folder.

\note The last command sudo ldconfig is only necessary after first
      install. It makes the newly installed library visible for the
      linker. You can omit it for further updates.

\note The make install script creates files in the system subfolders
      under `/usr/local/`, and a file named `install_manifest.txt`. In
      order to uninstall execute `sudo xargs rm <
      install_manifest.txt`.

# Test

In order to test the installation, first wire a dallas sensor to GND
(`P9_01`) and VDD (3V3 @ `P9_03`) and connect the data line to `P9_15`.
Then build the example applications and run one of them

~~~{.txt}
make examples
src/examples/dallas
~~~

The example uses by default the header pin `P9_15` for the one-wire bus,
pulling it up by the internal pull-up resitor. The command line program
first scans the bus for sensor IDs and lists them as terminal output.
Further output contains eleven blocks of sensor data, sensor ID and
temperature in degree centigrade in each line, like

~~~{.txt}
No parasite powered device.
trying to scan bus ...

found device 0, ID: A7000802E844C310 parasite

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.625 °C

sensor A7000802E844C310 --> CRC OK: 26.6875 °C
~~~

Congrats, the driver is working on your system!


# Examples

The package contains two examples

\Item{src/examples/dallas.bas} Universal application for all dallas
types (`&h10`, `&h20`, `&h22`, `&h28`, `&h3B` or `&h42`) and for
external or parasite powering (by the cost of high power consumption).

\Item{src/examples/onlyDS18S20.bas} Restrictive application handling
only old (type `&h10`) sensors with external powering (VDD = 3V3).

Each of them can handle multiple sensors on the bus.
