Changelog & Credits {#ChaChangelog}
===================
\tableofcontents


# Further Development {#SecFurtherVev}

- Move PRU parameters to upper bound of DRam, so that libpruio can use
  more memory for pre-triggers.

- FIXME

Feel free to send further ideas to the author (\Email).


# libpruw1-0.4 {#SecV-0-4}

Released on 2020 Nov.

- new: using SRam (12kB) for logs (instead of DRam/8kB)
- fix: fb_examples linking (SONAME "o" trick)
- fix: dependency prussdrv library removed
- fix: using pruio_prussdrv.bi (libpruio-0.6) header
- fix: Doc-Chapter Preparation adapted
- fix: CTOR uses correct IRam

# libpruw1-0.2 {#SecV-0-2}

Released on 2020 Apr.

- fix: bugfix in function T_fam10()

# libpruw1-0.0 {#SecV-0-0}

Released on 2016 July, 5.


# Credits  {#SecCredits}

Thanks go to:

- Texas Instruments for creating that great ARM Sitara processors with
  PRU subsystems and related software.

- The Beagleboard developer team for building a board and operating
  system around that CPU.

- The FreeBASIC developer team for creating a great compiler and the
  support to adapt it for ARM platforms.

- Dimitri van Heesch for creating the Doxygen tool, which is used to
  generate this documentations.

- AT&T and Bell-Labs for developing the graphviz package, which is used
  to generate the graphs in this documentation.

- All others I forgot to mention.
