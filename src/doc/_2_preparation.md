Preparation {#ChaPreparation}
===========
\tableofcontents

This chapter describes how to get libpruio working on your system. At
the bottom you'll find a step by step guide to install the complete
system. Eager users may skip the theory and jump to \ref
SecInstallation directly.


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
| [fb_prussdrv](https://github.com/DTJF/fb_prussdrv)  | M    | PRU assembler to compile PRU code and libprussdrv              |
| [dtc](https://git.kernel.org/cgit/utils/dtc/dtc.git)| M  D | Device tree compiler to create overlays                        |
| [GIT](http://git-scm.com/)                          | R  D | Version control system to organize the files                   |
| [CMake](http://www.cmake.org)                       | R  D | Build management system to build executables and documentation |
| [cmakefbc](http://github.com/DTJF/cmakefbc)         | R    | FreeBASIC extension for CMake                                  |
| [fb-doc](http://github.com/DTJF/fb-doc)             | R    | FreeBASIC extension tool for Doxygen                           |
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
   wget https://www.freebasic-portal.de/dlfiles/625/freebasic_1.01.0debian7_armhf.deb
   sudo dpkg --install freebasic_1.01.0debian7_armhf.deb
   sudo apt-get -f install
   ~~~

-# Then make the FB version of prussdrv working: ???
   ~~~{.txt}
   wget https://www.freebasic-portal.de/dlfiles/539/FB_prussdrv-0.0.tar.bz2
   tar xjvf FB_prussdrv-0.0.tar.bz2
   cd FB_prussdrv-0.0
   sudo su
   cp bin/libprussdrv.* /usr/local/lib
   ldconfig
   mkdir /usr/local/include/freebasic/BBB
   cp include/* /usr/local/include/freebasic/BBB
   cp bin/pasm /usr/local/bin
   exit
   ~~~

-# Continue by installing cmakefbc (if wanted). That's easy, when you
   have GIT and CMake. Execute the commands
   ~~~{.txt}
   git clone https://github.com/DTJF/cmakefbc
   cd cmakefbc
   mkdir build
   cd build
   cmake ..
   make
   sudo make install
   ~~~
   \note Omit `sudo` in case of non-LINUX systems.

-# And finaly, install fb-doc (if wanted) by using GIT and CMake.
   Execute the commands
   ~~~{.txt}
   git clone https://github.com/DTJF/fb-doc
   cd fb-doc
   mkdir build
   cd build
   cmake ..
   make
   sudo make install
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
git clone https://github.com/DTJF/libpruio
cd libpruio
~~~

## ZIP  {#SecGet_Zip}

As an alternative you can download a Zip archive by clicking the
[Download ZIP](https://github.com/DTJF/girtobac/archive/master.zip)
button on the \Proj website, and use your local Zip software to unpack
the archive. Then change to the newly created folder.

\note Zip files always contain the latest development version. You
      cannot switch to a certain point in the history.
