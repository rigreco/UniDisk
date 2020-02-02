# Apple II Unidisk 3.5 drive project

The project is based on the knowing of internal structure of Unidisk 3.5 drive, it use same HW of Apple II machines. It's a smart device built by controlled drive board powered by 65c02 mp @2.0 Hz with 2KB RAM and 8KB ROM plus 527 byte of I/O peripheral registers, all addressing by memory mapped method. The UniDisk 3.5 drives can use directly by Apple //c with 3.5 ROM (ROM version 0) or by Apple IIe or an II Plus using special interface controller card aka "LIRON card". The Protocol Converter is a set of assembly-lenguage routines built in 3.5 ROM or in Liron controller used to support smart external I/O devices (aka SmartPort), like UniDisk 3.5. The target of project is allow to use UniDisk 3.5 drive resource to process data in-line or off-line the Apple II like a "co-processor". The project evolved steps by steps:
1) Simply command and read information of UniDisk (DIB Device Information Block) using Protocol Converter STATUS Call; 
2) Using Protocol Converter CONTROL Call to simply Eject disk; 
3) Using Protocol Converter CONTROL Call (Set Dowload, Download, Run) to Download and Run a special 65c02 subroutine, and using STATUS Call to read the informations. This complex sistem allow to Dumping all UnidisK memory; 
4) Use the seme mechanism of step (3) to download a simply routine to making integer operation at one or two Byte and read the relative results; 
5) Due to UniDisk, less the I/O Disk routine in its ROM, is a bare metal, i decide to implement the Floating Point routine by using WOZ original routine, but I was need to write the converter program from WOZ routine to Applesoft routine. This allow me to execute FP operations; 
6) Use the UniDisk FP operations to execute Graphics calculations.
This project required a great deal of effort due to use only the real Apple IIc machine to coding in 'Merlin' Assembler and 'Applesoft' Basic, because no Apple II simulator is able to emulate Unidik Drive, at now.

This project allow this target:
* Scan, identify, command and dump memory of Unidisk 3.5
* Allow to use Unidisk 3.5 like an Apple II "co-processor"
