# Apple II UniDisk 3.5 drive project

The project is based on the knowledge of internal structure of UniDisk 3.5 drive, it uses same HW of Apple II machines. It is a smart device built by controlled drive board powered by

>65c02 mp @2.0 MHz (model GTEu G65SC02P-2 CMOS 8bit 2MHz PDIP40) with 2KB StaticRAM (model HITACHI HM6116LP-2 CMOS 8bit 120ns PDIP24) and 8KB ROM (model A2M2053-V1.0 TC5365P-8718 250ns PDIP28) plus 527 byte of Gate array I/O peripheral locations plus 15 byte of IWM registers in IWM Floppy Disk Controller PROM (model VLI VF4060-001 344-0041-B IWM PDIP28), all addressing by memory mapped method.

The UniDisk 3.5 drives can used directly by Apple //c with 3.5 ROM (ROM version 0) or by Apple IIe or an II Plus using special interface controller card aka "LIRON card".

>(C) 1985 Apple Computer, Inc.
>
>The firmware was written by Michael Askins.
>
>The Liron design team was:
>* Josef Friedman, manager
>* Cheng Lin, hardware
>* Michael Askins, software
>* Cecilia Arboleya, tech support
>* Cameron Birse, tech support


*The Protocol Converter (PC)* is a set of assembly-language routines built in 3.5 ROM or in Liron controller used to support smart external I/O devices (aka SmartPort), like UniDisk 3.5. 

*The Protocol Converter Bus (CBus)* consists of hardware and software components that permit and control communications between the Apple II and intelligent I/O devices (s. a. UniDisk 3.5's) connected o its external disk port.

- The software part of the Protocol Converter Bus includes Protocol Converter and the CBus communication protocol;
- The hardware component of the CBus is a daisy chain made up of the following:
    * The Apple II disk port
    * One or more Intelligent I/O devices (UniDisk drive)
    * One Disk II (optional). If included, the Disk II must be the terminal member of the daisy chain and remains dormant when a bus resident is addressed.

The target of project allows to use UniDisk 3.5 drive resource to process data in-line or off-line on the Apple II like a "co-processor".

The project evolved steps by steps:

1) Simply command and read information of UniDisk (DIB Device Information Block) using Protocol Converter STATUS Call; 

2) Using Protocol Converter CONTROL Call to simply Eject disk; 

3) Using Protocol Converter CONTROL Call (Set Dowload, Download, Run) to Download and Run a special 65c02 subroutine, and using STATUS Call to read the informations. This complex sistem allow to Dumping all UniDisk memory; 

4) Use the seme mechanism of step (3) to download a simply routine to making integer operation at one or two Byte and read the relative results; 

5) Due to UniDisk, less the I/O Disk routine in its ROM, is a bare metal, I decide to implement the Floating Point routine by using WOZ original routine, but I was need to write the converter program from WOZ routine to Applesoft routine. This allow me to execute FP operations; 

6) Use the UniDisk FP operations to execute Graphics calculations.

This project required a great deal of effort due to use only the real Apple IIc machine to coding in 'Merlin' Assembler and 'Applesoft' Basic and then execute the code, because no Apple II simulator is able to emulate UniDisk 3.5 Drive, at now.

The PC/MAC next to the Apple II machine, connected by serial port, allows you to use different special software to compile, manage disks image and then send to Apple II. A custom all-in-one modern IDE also can be creating to automate all this process.

This project allows this target:
* Scan, identify, command and dump memory of UniDisk 3.5
* Allow to use UniDisk 3.5 like an Apple II "co-processor"


![UniDisk](/Images/UniDisk.png)
