LameMouseConverter by John "Lameguy" Villamor (Lameguy64)
Protected under the Mozilla Public License v2
2022 Meido-Tek Productions "KYS" Hardware Division


Table of Contents

  1. Introduction
  2. New in Version 1.14
  3. Construction
    3.1. Component List
    3.2. Flashing the .HEX File
    3.3. Construction Tips
  4. Operation and Usage
    4.1. Status Light
    4.2. Configuring the LameMouseConverter
  5. Software Configuration
    5.1. Baud Rate Configuration  
    5.2. Report Rate Configuration
    5.3. Mouse Data Format Selection
  6. Technical Commands
    6.1. Status
    6.2. Format and Firmware Revision
    6.3. Format and Report Mode
    6.4. Detecting the LameMouseConverter
  7. Software Commands Summary
  8. Mouse Data Formats
    8.1. Three Byte Packed Format
    8.2. Mouse Systems Compatible Format
    8.3. Microsoft Compatible Format
    8.4. SummaMouse MM Series Format
    8.5. Quadrature Mouse
  9. Logitech C-model and MouseWare Negotiation
  10. Erratas and Workarounds
  11. Credits and References


1. Introduction

    The LameMouseConverter by Lameguy64  is  the  definitive  follow-up of the
    original ps2serial mouse  converter  originally  released in 2018 under an
    open-source license, significantly  improving  upon  the original. Written
    entirely in assembly  language  using  all-original  software routines, as
    well as improved interfacing circuitry, the  LameMouseConverter offers the
    most compatible and least latent  mouse  conversion solution possible that
    any electronics tinkerer can produce at home.
    
    The LameMouseConverter is an 'intelligent' protocol conversion device that
    takes input data from a PS/2 pointing device and relays it as serial mouse
    inputs, intended  to be used with older computer systems (such as 486, 386
    and older that lack native hardware  support  for  PS/2 mice and simulates
    most popular mouse protocols  as  Mouse Systems and Microsoft serial mice.
    The LameMouseConverter also provides  sufficient  simulation of a Logitech
    C-model mouse providing improved mouse performance nearly matching that of
    an actual PS/2 mouse, when configured and  used with the appropriate mouse
    driver software.  The supposed older 3-byte Mouse Systems protocol for use
    with Sun workstations is also supported in addition to quadrature mice.
    
    Much of the PS/2 mouse processing  and protocol conversion is performed by
    a single  Microchip/Atmel ATmega328P or 168P micro-controller operating at
    16MHz by an Arduino compatible board or a self-built board.  The converter
    firmware utilizes PS/2 streaming mode for reading input data from the PS/2
    mouse with an interrupt driven handling routine-  not a single mouse input
    is missed by the LameMouseConverter. The firmware also uses 16-bit accumu-
    lative counters to track total mouse movement,  in  addition  to  buffered
    mouse clicks using an eight-level  internal FIFO to guarantee every button
    input is delivered to the host system  regardless of report rate and band-
    width differences between the PS/2 mouse and serial interface.


2. What's new

    Version 1.15 rewrites the quadrature mouse simulation routines as the pre-
    vious implementation from 1.14 was flawed, resulting in uneven and jittery
    mouse movement most apparent on the Amiga.  The rewritten routines employs
    a timer-based implementation operating at 20KHz,  relaying one  quadrature
    cycle per timer tick until  all  accumulated  movement has been relayed as
    quadrature signals.

    Version 1.14 adds 2-button  quadrature  mouse  simulation for use with any
    quadrature based  mouse  interfaces  such  Microsoft InPort, Bus Mouse and
    Amiga mouse to name a few.  The  quadrature  mouse  simulation function is
    always active  and  inputs  are  relayed  within  the PS/2 mouse interrupt
    handler- yielding even less input latency than serial. Both interfaces can
    be used simultaneously with two completely separate host systems.
    
    Another addition is the  implementation  of  a  watchdog timer to ensure a
    continuously  operating  mouse  converter  in the event of a very rare but
    still possible firmware lock-up.  The mouse converter will self-reset when
    such a lock-up occurs and mouse parameters such as format, baud and report
    rates are preserved after this reset.  However,  this feature may not work
    properly as it was never properly tested due  to  AVR bootloaders clearing
    the watchdog reset bit, and flashing without a bootloader was not possible
    due to inadequate equipment in the development of this release. This reset
    condition is not induced when  the  PS/2 mouse  is  disconnected while the
    mouse converter is still operating.


3. Construction

    The LameMouseConverter may  be  constructed  as  a relatively simple hobby
    project, more-so if the  Arduino  platform is used to provide the required
    micro-controller. The PS/2  interface  is  simply  wired directly to their
    respective I/O pins without any  additional components apart from the PS/2
    connector and a small  capacitor  to  decouple the voltage supply from the
    rest of the circuit. The RS-232 interface  circuit  is more involved as it
    uses a MAX232 coupled with external  capacitors  for  the  internal charge
    pump circuits, to translate  logic  levels  between RS-232 to TTL and vice
    versa. RS-232 'shields' may  work  when  building the converter around the
    Arduino platform, but  Microsoft  mouse  compatibility  is not possible if
    the shield does not provide level translation of the RTS line.


  3.1. Component List

    1 x Arduino UNO R3 or bare ATmega328P and support circuitry for the micro-
        controller to operate at 16MHz, whichever is most desired.
    1 x Maxim / Texas Instruments MAX232.
    1 x 100pf bipolar ceramic capacitor.
    4 x 16v 1uf polarized electrolytic capacitors (for MAX232).
    1 x 16v 22uf polarized electrolytic capacitor (for decoupling PS/2 power).
    1 x DB9 female connector.
    1 x 6-pin mini-DIN female connector.
    1 x Length of wire with four conductors. Solid core recommended.

    The wiring schematics are  provided  as  a  stand-alone KiCad eeschema do-
    cument and should be included with this repository.


  3.2. Flashing the .HEX File

    Arduino users should use 'avrdude'  normally  provided  in one of the bin
    directories of the Arduino IDE distribution. Use  the sample command-line
    to write the firmware to the  Arduino  board  and  make sure the COM port
    number matches that of the Arduino board to be flashed.
    
    avrdude -patmega328p -carduino -D -P COM2 -U flash:w:PS2SER2.hex:i


  3.3. Construction Tips
  
    If constructing the LameMouseConverter  using  the Arduino UNO prototyping
    platform is most desired it  is recommended  to use any of the third-party
    prototyping 'shield' boards that  comprises  primarily  of vias as it per-
    mits mounting the mini-DIN connector directly onto the board, if the conn-
    ector used is of the board-mounted type. The expanded soldering space also
    simplifies mounting  of the DIP16  socket  for the MAX232 chip and suppor-
    ting capacitors, while the RX and RTS  jumper  connections are optional if
    hardware configuration for Microsoft or Mouse Systems/C-model operation is
    desired, as the mouse converter supports  a software command to select the
    latter mode if hardware jumpers are unavailable.
    
    The serial cable can be wired  directly  onto  the board around the MAX232
    chip connecting to their respective  pins  and ground. The mouse converter
    only needs four conductors for  TX, RX, RTS and Ground  while flow control
    lines CTS and DSR can be asserted  by  simply connecting DTR back to those
    lines on the connector itself. The loop-back is important for transmitting
    software commands to the mouse using  operating system commands (ie. ECHO)
    before loading the mouse driver,  otherwise  device errors will occur when
    attempting to transmit commands to the device without the loop-back.
    
    The AUTOBAUD connection is a left-over from earlier plans to support auto-
    matic baud rate detection specific to SummaGraphics MM series pointing de-
    vices. This feature is not enabled by  default on on most Logitech C-model
    pointing devices with the exception of the C7-SG, and the MouseWare driver
    uses software polling to locate  the pointing  device instead of using the
    automatic baud rate feature to synchronize to the peripheral as originally
    believed. So the AUTOBAUD connection may be omitted entirely from the pro-
    ject.

    When wiring for the quadrature pins as described by pin definitions in the
    LMC.ASM file be sure that the pin assigned by QS_* is driven high when the
    mouse converter is connected as a quadrature mouse.  This signals the con-
    verter firmware to configure  the  PS/2 mouse with a report rate of 200Hz,
    which is the preferred  report  rate  for  quadrature simulation. If mouse
    movement is inverted  on  one  of  the  axis'  simply  swap the quadrature
    signal pins around.
    
     
4. Operation and Usage

    The LameMouseConverter must be supplied  with at least 9v from an external
    power supply as the serial port cannot provide sufficient current to run
    both the micro-controller and the PS/2 device.


  4.1. Status Light

    Pin PB5 or the L13 LED  on  Arduino  boards  is  used as a status light to
    indicate status or activity  of  the  LameMouseConverter. On power-up, the
    status light blinks  once  to  indicate  successful  initialization. If no
    PS/2 mouse is connected an initialization error is indicated by a flashing
    status light. After  five  flashes the mouse converter repeats the process
    until a PS/2 mouse has been detected and successfully initialized.
    
    Under normal operation the  status  light will flash briefly whenever the
    mouse is manipulated to indicate  activity  as the mouse converter is re-
    laying the input as a serial mouse  packet.  The duration is based on the
    time taken to transmit the mouse packet through the serial interface.
    

  4.2. Configuring the Mouse Converter

    If constructed with jumpers the LameMouseConverter can be hard-wired to a
    specific mouse protocol by preventing  the converter from sensing the RTS
    line or receiving command bytes from the host system. The mouse converter
    will always select Mouse Systems as  the initial protocol mode regardless
    of the jumper settings.
    
    +------+------+---------------------------------------------+
    | RTS  | RX   | Protocol                                    |
    +------+------+---------------------------------------------+
    | OFF  | OFF  | Mouse Systems only                          |
    | ON   | OFF  | Mouse Systems or Microsoft compatible       |
    | OFF  | ON   | Mouse Systems or C-model compatible         |
    | ON   | ON   | Mouse Systems or Microsoft compatible*      |
    +------+------+---------------------------------------------+
    * Permits C-model commands to be used.
    
    The mouse converter properly  implements  the  'half-packet' format of the
    five byte Mouse Systems protocol  and  smoother mouse movement will be ob-
    served when using the original  Mouse Systems  driver  software. The  con-
    verter only enters Microsoft protocol format if a RTS line toggle has been
    detected.
    
    For a Logitech mouse driver to recognize  the mouse converter as a C-model
    mouse the RTS jumper must be left open as the converter does not currently
    implement the extra negotiation commands  employed on Microsoft compatible
    C-model devices (ie. C7-M). The mouse  driver will recognize the converter
    as a standard Microsoft  compatible  mouse  instead and enhanced features,
    such as faster baud and report rates, will not be available.
    
    In case hardware jumpers are  not  available  the  LameMouseConverter also
    provides a software based solution to bring the mouse converter to C-model
    compatible mode by means of  a  software  command. Transmitting 'm' to the
    mouse converter will  inhibit  RTS  detection  in  software and brings the
    mouse converter to  C-model  compatible  mode.


5. Software Configuration

    The new RS-232 interface circuit  of  the  LameMouseConverter provides the
    capability to receive data  bytes  from  the  host system  and permits the
    implementation of software commands for configuring the converter. This is
    typically accomplished by transmitting  command characters using operating
    system commands such as ECHO and piping the output to a serial device such
    as COM1 provided the RX jumper is set. This  only  works  if the loop-back
    connections are wired on the RS-232 side.
    
    The initial line settings of the  LameMouseConverter  regardless of jumper
    settings are 1200 baud, 8 data  bits, 1 stop  bit and no parity. The mouse
    converter ignores frame and parity  errors  if line settings are incorrect
    provided the baud rate matches, as  the  firmware only processes the first
    seven bits of received  characters. So  transmitting  commands  with 7-bit 
    characters will work. An example  to  send a command character from MS-DOS
    to disable RTS detection is as follows:
    
    MODE COM1 BAUD=1200 DATA=8 PARITY=N STOP=1
    ECHO m>COM1

    Take note that some mouse settings,  such  as  baud and mouse report rate,
    will be reverted to 1200 baud and  60 reports per second if the mouse con-
    verter detects an RTS line toggle.


  5.1. Baud Rate Configuration

    The baud rate at which  mouse  packets  are  transmitted can be configured
    by means of a two character command  sequence. Changing the baud rate man-
    ually will not work if the mouse driver  software does not explicitly sup-
    port or recognize higher baud rates. Using  higher baud rates not only re-
    duces input latency but  also  provides  headroom  to support higher mouse
    report rates or mickeys.

    Command     Baud Rate

      *n        1200
      *o        2400
      *p        4800
      *q        9600
        
    
  5.2. Report Rate Configuration

    The mouse report rate  can  also  be  configured  to utilize the increased
    bandwidth of higher baud rate settings. The  mouse converter can be set to
    report mouse events  at  select  rates  from 10 to 200 reports per second.
    The report rate is governed by  the  PS/2 mouse itself and not on the con-
    verter and as the PS/2 mouse  protocol  only  supports set values, the in-
    tended rates from  the C7  specifications  are  rounded  up to the nearest
    value supported by the PS/2 mouse. The  table  that follows lists the com-
    mand characters, the intended and the actual report rate selected:
    
    Command     Intended Rate   Actual Rate

      J           10              10
      K           20              20
      L           35              40
      R           50              40
      M           60              60
      Q           100             100
      N           150             200
    
    Take note that the higher report rates  are  only effective if the current
    baud rate setting can provide the  bandwidth  to support the rate of mouse
    packets specified. To avoid  the  potential  for lost inputs regardless of
    bandwidth constraints, the  mouse  converter  employs  16-bit accumulative
    counters for each motion axis and an eight-level FIFO for buffering button
    presses. The result is an effective  pull-down of mouse inputs, however it
    introduces latent inputs which can be observed by the user as a 'jello' or
    'rubber-banding' effect.
    
    The following table lists the estimated maximum report rates supported for
    each baud rate and mouse format  setting.  The  original C7 and compatible
    devices two stop bits  while  the  LameMouseConverter  only employs one to
    attain the most optimal throughput possible.
    
    Baud Rate    Est. Max Rate    Est. Max Rate    Est. Max Rate   
                 (Microsoft)      (Mouse Systems)  (MM Series/C-model)

      1200         44               40             36            
      2400         88               80             73
      4800         177              160            145
      9600         355              320            290

    The maximums are calculated  using  the  following formulas with start and
    stop bits accounted for,  as  well  as  the  parity  bit for the MM series 
    packet format:
   
      Microsoft         ( baud rate / 9 ) / 3 = max rate
      Mouse Systems     ( baud rate / 10 ) / 5 * (5 / 3) = max rate
      MM Series         ( baud rate / 11 ) / 3 = max rate

    Take note that the mouse report  rate  is  also reverted to 60 reports per
    second if an RTS line toggle was detected.


  5.3. Mouse Data Format Selection

    On some situations it may  be  necessary  to configure the mouse to a spe-
    cific mouse protocol prior to loading the mouse driver software or a mouse
    compatible software program that does  not interface the mouse through the
    standard mouse interfaces. One  such  case  is  selecting  the  Three Byte
    Packed mouse format to use the mouse  converter on systems that expect the
    old Mouse Systems format, also known as the Sun mouse format, as the mouse
    converter has no means to automatically  detect when this protocol mode is
    most appropriate for the host system.
    
    The appropriate data format can  be  selected  manually by means of trans-
    mitting the  appropriate  character  command  to  the  mouse  converter as
    follows. Only the most commonly used protocol formats are implemented:
    
    Command     Hex Digit   Description

      S           53h       SummaMouse MM Series format (C-model native)
      T           54h       Three Byte Packed format (old Mouse Systems/Sun)
      U           55h       Mouse Systems compatible format
      V           56h       Microsoft compatible format


6. Technical Commands

    The following details explained  in  this  section are intended for driver
    software developers who wish to implement support for the C-model features
    of the LameMouseConverter.


  6.1. Status
  
    The LameMouseConverter and C-model pointing devices supports the MM Series
    status command character 't'. Both  devices  will  return a status byte of
    the following format:
    
      b7  b6  b5  b4  b3  b2  b1  b0
      ------------------------------    
       0  pm   0   0   1   1   1   1
       
    Only bit 6 is relevant for the LameMouseConverter:
    
      pm = 0      Prompt mode disabled (incremental stream mode).
      pm = 1      Prompt mode enabled
      
    The remaining bits report a healthy SummaMouse.


  6.2. Format and Firmware Revision
  
    The LameMouseConverter and C-model  pointing devices will return a format
    and revision byte in response to the command character 'f'. The format of
    the byte obtained is as follows:
    
      b7  b6  b5  b4  b3  b2  b1  b0
      ------------------------------
      rv3 rv2 rv1 rv0 fm2 fm1 fm0  0

    The fm bits form a decimal value of the current mouse format:
    
    Number      Format
    
      0           Mouse Systems compatible format
      1           Three Byte Packed format (old Mouse Systems/Sun)
      5           SummaMouse MM Series compatible format
      7           Microsoft compatible format

    The rv bits form a decimal value of 1, which  corresponds  to firmware 3.0
    on the Logitech MouseWare driver.

  
  6.3. Format and Report Mode
  
    The LameMouseConverter and  C-model  devices  return  two ASCII characters
    of the current format  and  report  mode  in  response  to the 't' command
    character. This is also the only  command  that  returns the current mouse
    report mode. The first character returned specifies the mouse format:
    
    Character   Hex Digit   Description
    
      S           53h       SummaMouse MM Series format
      T           54h       Three Byte Packed format (old Mouse Systems/Sun)
      U           55h       Mouse Systems compatible format
      V           56h       Microsoft compatible format
      
    The second character specifies the report mode:
      
    Character   Hex Digit   Description
    
      J           4Ah       10 reports per second incremental streaming
      K           4Bh       20 reports per second incremental streaming
      L           4Ch       40 reports per second incremental streaming
      R           52h       40 reports per second incremental streaming
      M           4Dh       60 reports per second incremental streaming
      Q           51h       100 reports per second incremental streaming
      N           4Eh       200 reports per second incremental streaming
      D           44h       Prompt mode
      
    Conversely the returned characters  are also command characters and can be
    transmitted back to the LameMouseConverter.


  6.4. Detecting the LameMouseConverter

    Before using any of the extended mouse command supported, detection of the
    LameMouseConverter should first be  performed using the status (s) command
    at 1200 baud. If no response is returned transmit the same command at 2400
    baud, then 4800 and 9600 until  one  of  the baud rates yields a response.
    A delay of at least 100ms must be placed between each probe attempt. If no
    response is obtained from all the baud rates repeat the process on another
    port, otherwise presume the device as a Microsoft (confirm with a RTS tog-
    gle) or a Mouse Systems device.
    
    After successful probing the mouse  converter  may then be negotiated to a
    desired baud rate and confirm the new  rate  by  transmitting a status (s)
    command at the negotiated baud rate.  From  there the desired mouse format
    and report rate can be  issued,  the  new  settings  of  which can be con-
    firmed using the format and report mode (t) command.


7. Software Commands Summary

    The following is a summary of the  extended  mouse command characters sup-
    ported by the LameMouseConverter. These commands may be used to pre-confi-
    gure the mouse converter to specific  settings  using the method described
    in "Software Configuration".
    
    Command     Hex Digit   Description

      D           44h       Set prompt mode (disables incremental streaming)
      P           50h       Request mouse report and enters prompt mode
      J           4Ah       Set 10 reports per second incremental streaming
      K           4Bh       Set 20 reports per second incremental streaming
      L           4Ch       Set 40 reports per second incremental streaming
      R           52h       Set 40 reports per second incremental streaming
      M           4Dh       Set 60 reports per second incremental streaming
      Q           51h       Set 100 reports per second incremental streaming
      N           4Eh       Set 200 reports per second incremental streaming
      S           53h       Set SummaMouse MM Series format
      T           54h       Set Three Byte Packed format (old Mouse Systems)
      U           55h       Set Mouse Systems compatible format
      V           56h       Set Microsoft compatible format
      c           63h       Get copyright info string
      k           6Bh       Get number of mouse keys (buttons)
      s           73h       Get SummaMouse status
      t           74h       Get current format and report mode
      f           66h       Get format and revision byte
      m           6Dh       Software disable RTS detection (C7 mode)*
      *n          6Eh       Set 1200 baud rate
      *o          6Fh       Set 2400 baud rate
      *p          70h       Set 4800 baud rate
      *q          71h       Set 9600 baud rate

      * LameMouseConverter specific command.


8. Mouse Data Formats

    The LameMouseConverter  supports  four  protocol  formats; the  Three Byte
    Packed format (old Mouse Systems/Sun),  Mouse Systems  compatible  format,
    the Microsoft compatible format and  the SummaMouse MM Series format. Each
    of the protocol formats can be  selected  using  software commands, or the
    RTS toggle to invoke automatic  configuration  to the Microsoft compatible
    format.

  8.1. Three Byte Packed Format (command: 'T')

    The Three Byte Packed format resembling the old Mouse Systems or Sun mouse
    protocol is comprised of  three  8-bit  bytes  transmitted at 8 data bits,
    1 stop bit and no parity. The data format is described as follows.

      Byte b7  b6  b5  b4  b3  b2  b1  b0
      -----------------------------------    
       1st  0   0   0   0   0  LB  MB  RB
       2nd x7  x6  x5  x4  x3  x2  x1  x0
       3rd y7  y6  y5  y5  y3  y2  y1  y0
       
       LB,MB,RB    Button state (1 = pressed)
       x0-x7       X motion as signed two's complement (-128 to 127).
       y0-y7       Y motion as signed two's complement (-128 to 127).


  8.2. Mouse Systems Compatible Format (command: 'U')

    The following table describes the data format of the Mouse Systems
    compatible format. Packets are reported at 1200 baud, 8 data bits,
    1 stop bit and no parity.

      Byte b7  b6  b5  b4  b3  b2  b1  b0
      -----------------------------------    
       1st  1   0   0   0   0  LB  MB  RB
       2nd x7  x6  x5  x4  x3  x2  x1  x0
       3rd y7  y6  y5  y5  y3  y2  y1  y0
       4th x7  x6  x5  x4  x3  x2  x1  x0
       5th y7  y6  y5  y5  y3  y2  y1  y0
       
       LB,MB,RB    Button state (0 =  pressed)
       x0-x7       X motion as signed two's complement (-128 to 127).
       y0-y7       Y motion as signed two's complement (-128 to 127).

    The 4th and 5th bytes are not a  duplicate, but rather a "half packet" of
    of the amount the mouse has moved  during  the  transmission of the first
    three bytes. A properly written  Mouse Systems driver must interpret this
    second half as another mouse  movement  event if the coordinates are non-
    zero for smoother continuous motion.


  8.3. Microsoft Compatible Format (command: 'V' or toggle RTS)

    The following table  describes  the  packet  format of the Microsoft com-
    patible format. Packets are  reported  at  1200 baud, 7 data bits, 1 stop
    bit and no parity. Middle button  is  supported  by means of transmitting
    the mouse packet with zero motion values, but the mouse button states are
    kept from the last packet. A compatible  mouse driver will interpret this
    packet as a toggle of the middle button.

      Byte b6  b5  b4  b3  b2  b1  b0
      -------------------------------
       1st  1  LB  RB  y7  y6  x7  x6
       2nd  0  x5  x4  x3  x2  x1  x0
       3rd  0  y5  y5  y3  y2  y1  y0

       LB,RB       Button state (1 =  pressed)
       x0-x7       X motion as signed two's complement (-128 to 127).
       y0-y7       Y motion as signed two's complement (-128 to 127).


  8.4. SummaMouse MM Series Format (command: 'S')

    The following table  describes  the  packet  format  of the MM Series com-
    patible format as used  by  SummaGraphics MM Series products.  Packets are
    typically reported at 2400 baud, 8 data bits, 1 stop bit and odd parity.

      Byte b7  b6  b5  b4  b3  b2  b1  b0
      ----------------------------------- 
       1st  1   0   0  Sx  Sy  LB  MB  RB
       2nd  0  x6  x5  x4  x3  x2  x1  x0
       3rd  0  y6  y5  y4  y3  y2  y1  y0
       
       LB,MB,RB    Button state (1 =  pressed)
       Sx,Sy       Positive flag of each axis (0 = negative, 1 = positive)
       x0-x6       X movement amount as unsigned (0 to 127)
       x0-y6       Y movement amount as unsigned (0 to 127)

     The Sx and Sy bits are not sign  values,  but  rather a flag whether the
     motion values should be treated as a positive value or a negative value.


  8.5. Quadrature Mouse

     While not necessarily a protocol it was a signalling scheme used by older
     pointing devices. A quadrature mouse is nothing more but a pair of rotary
     encoders with Schmitt-triggers  to  'square out'  the signals coming from
     the encoders before feeding it to the host system.  Essentially the mouse
     controller is inside the computer instead of the mouse itself.

     The mouse converter emulates quadrature  inputs  by  simulating the pulse
     cycles of a rotary encoder.  Simulating cycling rate based on velocity is
     not necessary as most interfaces simply  count  the  cycles as opposed to
     determining the frequency of the pulses.

       Signal >0 >1 >2 >3
       -------------------
        A      0  1  1  0
        B      0  0  1  1

       Signal <0 <1 <2 <3
       -------------------
        A      0  0  1  1
        B      0  1  1  0


9. Logitech C-model and MouseWare Negotiation

  9.1. MS-DOS Driver Negotiation
  
    The first detection phase consists of  the RTS line toggle used for Micro-
    soft compatible serial mice. In this phase the MouseWare driver configures
    the serial port to 1200 baud, 8 data bits, odd parity and 2 stop bits. The
    driver ignores parity and  frame  errors so that line settings, apart from
    baud rate, do not matter and the  emulated  mouse should also do the same.
    The sequence starts with  asserting  the  RTS  line for at least 550ms and
    then toggled for 650ms. If  the  Microsoft  response character (M) was not
    received within 500ms the driver enters the C-model detection phase.
    
    If the Microsoft response  character  was  received the driver attempts an
    extra negotiation using the extended command '*?'. If no valid response is
    returned the MouseWare driver will deduce the device as a Microsoft compa-
    tible serial mouse. The correct response  for the '*?' command and further
    negotiation is not yet known as  this  appears to be supported only on the
    C7-M and other Microsoft-compatible C-model pointing devices, as these de-
    tails were observed from a regular C7 and does not support the extra nego-
    tiation command.
    
    In the C-model detection phase the  MouseWare  driver probes for a C-model
    mouse by transmitting a  status  command  (s)  at least twice if the first
    command did not receive  a  response  within  80ms. If no response was re-
    ceived after both attempts the  driver  attempts to transmit the same com-
    mand at 2400 baud, then 4800 baud and  finally 9600 baud with a 80ms delay
    in each attempt, as the C-model mouse can either be hard-wired or software
    configured to a specific baud rate.  If  the driver is still unable to de-
    tect a C-model mouse on all  baud  rates  it  then performs the entire de-
    tection sequence again on another serial port and will display an error if
    no mouse is detected on  that  port  either.  If  the  driver successfully
    obtains the status byte it then proceeds to the setup phase.
    
    In the setup phase the MouseWare driver  transmits the prompt mode command
    (D) and waits for at least 90ms. It  then  transmits  a string of commands
    consisting of MM Series  format  (S),  150 reports per second (N) additio-
    nally disabling prompt mode, and  2400 baud mode (*o). The driver then re-
    configures the serial port  to  2400  baud  and  waits for at least 120ms,
    after which the MouseWare  driver  transmits  the keys command (k) and the
    response must be an ASCII decimal  value  of the number of buttons suppor-
    ted (ie. '2' or '3'). The driver then waits another 80ms and transmits the
    format and revision command (f), the  response  of  which must be a binary
    byte of the current mouse format  and  firmware  revision. The driver then
    transmits the 150 reports per second (N) command once more.
    
    If the above sequence  has  been  satisfied  the  MouseWare  driver should
    recognize the device as a  C-model  mouse  indicated  by a C in a bracket.
    Enhanced mouse features such as  higher  baud and report rate settings are
    now applicable.
    
    To summarize, the following criteria must be met as a minimum:
    
    * No response should be given after the RTS toggle.
    * Respond with a status byte for the status (s) command.
    * Implement the MM Series format (S) command.
    * Implement the baud rate selection commands (*o).
    * Respond with an ASCII number for the keys (k) command.
    * Respond with a format and revision byte for the format (f) command.


  9.2. Windows 3.1 Driver Negotiation

    The Windows driver performs  mouse  detection and setup more or less iden-
    tically to the MS-DOS driver,  with  the  only  major difference being the
    C-model detection phase. The Windows driver probes for the mouse using the
    the prompt mode (D) and status (s) commands together. The status byte must
    report the prompt mode status correctly, otherwise the Windows driver will
    not recognize the mouse and  continues  to  attempt detection at different 
    baud and serial ports. The setup phase after successful detection is most-
    ly identical to the MS-DOS driver only without the keys (k) and format (f)
    commands.
    
  
10. Known Erratas and Workarounds

  10.1. Windows 95/98 Logitech Serial Mouse Driver Workaround (0.12)
  
    When using the LameMouseConverter under Windows 95/98  using  the included
    Logitech Serial Mouse driver, mouse  movements may behave erratically with
    random button presses. This  is  because  the  mouse  driver transmits the
    MM Series format command after switching to 2400 baud mode which the mouse
    converter was unable to receive successfully  possibly due to insufficient
    delays. The simplest workaround is to use  the  ECHO  command  to transmit
    the  MM Series format command  (S) to  the  mouse converter, preferably by
    placing it in the AUTOEXEC.BAT file.  Loading  the MS-DOS MouseWare driver
    as part of the AUTOEXEC.BAT sequence also remedies this issue.


11. Credits & References

    AVR firmware & schematic: John "Lameguy" Wilbert Villamor (Lameguy64)

    References used:
    The ATmega328P datasheet
    http://www.burtonsys.com/ps2_chapweske.htm
    https://www.win.tue.nl/~aeb/linux/kbd/scancodes-13.html#mousemodes

    Special thanks to Kris Chambers (kristopher) for his PS2Mouse Arduino
    library, which helped spark the idea of developing a PS/2 mouse converter
    using Arduino/AVR controllers and was used in the original 'ps2serial'
    converter project. While none of the PS2Mouse library was used in the
    LameMouseConverter it was used as additional reference when writing the
    PS/2 routines in assembly early in development.
