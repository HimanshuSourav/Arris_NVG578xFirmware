# Arris_NVG578xFirmware

The Basic Idea behind starting this is to be able to build the firmware for the ziply provided router and tinker with it.


Firmware for Commscope NVG578 taken from https://sourceforge.net/arris/nvg578/

About NVG578HLX
==============================================================================

The NVG578LX is a cost-effective gateway for the GPON passive optical networking standard to deliver managed voice, video, data services with up to 2.5Gb/s symmetrical broadband.

GPON access (up to 2.5/1.25Gbps) is supported using cost-effective fiber on-board (BOSA) technology.

The LAN can make full use of the 2.5Gb/s access speeds with a 2.5Gb/s Ethernet port and high-performance Wi-Fi, that includes the latest Wi-Fi 6 (802.11ax) standard for enhanced performance.

Basic instructions for Ubuntu 20.04
=============================================================================
  All of these commands must be run as root.

  Install toolchains if not done so already

    % ./install_toolchain

  Make sure that /bin/sh points to /bin/bash.
  Under /bin folder,
      rm sh
      ln -s bash sh

  Install any host tools needed
	- make, gcc, etc.  (build-essential)
	- automake
	- gcc-multilib
	- libc6:i386
	- libncurses5:i386
	- libstdc++6:i386
	- libelf1:i386
	- liblzo2-dev
	- uuid-dev
	- quilt
	- gawk
	- flex
	- xutils-dev
	- bison
	- byacc
	- pkg-config
	- python
        - cmake
        - cpio
        - gettext wget
        - mtd-utils
        - zlib1g-dev
        - libtool
        - bc

  Perl must be version 5.22.1.  
	- sudo apt-get install perlbrew
	- perlbrew init
	- perlbrew install perl-5.22.1
          if you encounter an error that perlbrew installation failed, try to install with --notest option
                perlbrew --notest install perl-5.22.1
	- vi ~/.bash_profile and add
		source ~/perl5/perlbrew/etc/bashrc
	- perlbrew switch perl-5.22.1
	- cpan -i Convert::Binary::C
	- cpan -i Digest::CRC

  Add the following line to /etc/environment
	LANG=en_US.UTF-8 


  Run the build (not as root) with the below command:

    % ./build NVG578LX_AX

On successful build, binaries will be available in axis/broadcom/targets/NVG578LX_AX
Ex: bcmNVG578LX_AX_nand_cferom_fs_image_128_puresqubi.w or bcmNVG578LX_AX_nand_fs_image_128_puresqubi.w
