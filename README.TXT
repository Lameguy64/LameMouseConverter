LameMouseConverter by John "Lameguy" Villamor / Lameguy64
Protected under Mozilla Public License v2
2021 Meido-Tek KYS Hardware Division

Introduction

    The follow-up of Lameguy64's first attempt of a serial mouse converter;
    ps2serial, the LameMouseConverter improves upon the original converter
    project significantly. It not only addresses all the shortcomings of the
    original ps2serial converter but also a much improved interface circuit
    featuring a MAX232 level translator, improving compatibility with less
    sensitive RS-232 interfaces and allows support for software based mouse
    configuration.

    The LameMouseConverter can be used to adapt any PS/2 mouse, ball or
    optical, into a 3-button Mouse Systems or Microsoft compatible serial
    mouse. Coupled with the baud rate and mouse rate configuration features
    the conversion may become indistinguishable when using a mouse driver
    that can utilize said serial mouse features.


Features

    - Uses PS/2 mouse streaming mode at 40Hz report rate, utilizing hardware
      interrupts for handlding PS/2 data transfers which greatly improves
      mouse compatibility and responsiveness. Mouse report rate can be
      changed with software commands.
      
    - Supports Mouse Systems (known as 5 byte packed in MouseWare), Microsoft
      3-button and Logitech C7 Three Byte Packed protocol modes. Protocol
      modes can be selected through software commands.
      
    - Supports software controlled baud rate configuration, mouse report rate
      and mouse mode selection through software commands inherited from the
      Logitech C7 mouse.
    
    - Firmware written entirely in AVR assembly. Uses no dependencies apart
      from Atmel provided header files. Compatible with the open source AVRA
      assembler.


Component List

    1 x Arduino UNO R3 or ATmega328P and support circuitry required to run
        the controller at 16MHz, whichever you find is most convenient.
    1 x Maxim / Texas Instruments MAX232.
    1 x 100pf bipolar ceramic capacitor (for decoupling MAX232).
    4 x 16v 1uf polarized electrolytic capacitors (for MAX232).
    1 x DB9 female connector.
    1 x 6-pin mini-DIN female connector.
    
    For the wiring diagram a KiCad .sch file should be provided in the code
    repository.


Operating Characteristics

    On power-up, the L13 LED (or pin PB5 on the ATmega controller) will blink
    once to indicate successful initialization of the connected PS/2 mouse.
    On failure the L13 LED will blink repeatedly to indicate a initialization
    error. It is not recommended to connect a PS/2 mouse while the converter
    is powered on as this tends to trip the brown-out detection feature of
    the ATmega controller.
    
    Once powered up and initialized, the LameMouseConverter behaves as a
    Mouse Systems compatible serial mouse initially. If the RTS pin is
    toggled (ie. when a Microsoft or Logitech compatible mouse driver is
    loaded) the converter will automatically switch to emulating a Microsoft
    3-button serial mouse instead.

    Once a mouse driver is installed one may immediately find mouse input to
    be a bit laggy with the converter, this is largely the result of the slow
    transfer speed of 1200 baud serial adding a fair bit of latency as a
    mouse packet is being transmitted to the host system. This becomes more
    apparent when using a modern optical mouse as such input devices are
    commonly associated with fast input reponses which exacerbates this side
    effect of protocol conversion. Depending on the mouse driver used, mouse
    inputs would be too sensitive when using an optical mouse that has a
    considerably higher dpi resolution than ball mice.
    
    In both modes of operation the PS/2 mouse is configured for 40 reports
    per second to match the report rate of serial mice, which have a typical
    report at 40 to 44 reports per second due to bandwidth constraints of
    1200 baud serial. As a MAX232 is used to translate TTL RS-232 levels to
    standard levels and vice versa this allows the LameMouseConverter to
    receive commands from the host system, using commands supported by the
    Logitech Logimouse C7 which the mouse converter inherits. Only a subset
    of the commands are supported however and is not yet tested with the
    Logitech MouseWare drivers extensively, so the extended mouse features
    may not be detected by the driver.
    
    
Baud Rate Configuration

    The baud rate at which mouse packets are transmitted can be configured
    by sending a 2-byte command sequence to the converter at the same baud
    rate mouse commands are received at. By default the serial parameters are
    1200 baud, 7 data bits, 2 stop bits, no parity unless changed previously.
    These parameters will work regardless of whether the converter is in
    Mouse Systems or Microsoft mode as the firmware always ignores the 8th
    bit for command bytes. Toggling the RTS pin can be used to bring the
    converter to a known baud rate, as the baud rate is also reset to 1200
    baud when switching to Microsoft compatible mode in response to the RTS
    signal toggle. Using higher baud rates reduces mouse input latency.

    Command	Baud Rate

      *n	  1200

      *o	  2400

      *p	  4800

      *q	  9600
    
    When writing a mouse driver, it is best to check if Logitech extended
    mouse commands are supported by sending a 'f' character to the mouse,
    which in turn should report with a format and revision number byte. If
    the mouse does not report a response byte back then it likely does not
    support the Logitech extended mouse commands.
    
    
Mouse Report Rate Configuration

    In addition to adjusting the baud rate, the mouse report rate can also be
    adjusted to take advantage of the increased serial bandwidth. the mouse
    converter can be configured to report mouse events at select rates from
    10 reports all the way up to 200 reports per second.
    
    The actual mouse report rate is governed by the PS/2 mouse itself and not
    on the LameMouseConverter. If the mouse rate exceeds the rate at which the
    current baud rate can support, mouse movement coordinates are accumulated
    onto internal counters and button clicks are buffered to make sure rapid
    mouse clicks are not missed. However, this tends to exhibit a jello-like
    effect in mouse motions.

    The following table lists the supported mouse rates and the command byte
    to select it. As the mouse rate is handled by the PS/2 mouse the actual
    mouse report rates are substituted to the closest compatible mouse rate
    instead for compatibility reasons.

    Command	Intended Rate	Actual Rate

      J		  10		  10

      K		  20		  20

      L		  35		  40

      R		  50		  40

      M		  60		  60

      Q		  100		  100

      N		  150		  200


    The following table describes the estimated maximum mouse rates for each
    of the available baud rate options. The mouse rate selected must be equal
    or less than what the baud rate can support.

    Baud Rate	Est. Max Rate 	Est. Max Rate*
    		(Microsoft)	(Mouse Systems)

      1200	  44		  40

      2400	  88		  80

      4800	  177		  160

      9600	  355		  320

      * With a mouse driver that handles Mouse Systems properly.

    The estimated mouse rate are determined using the formula
    ( baud rate / 9 ) / 3 for Microsoft protocol and
    ( baud rate / 10 ) / 5 * 1.666666666666667 for Mouse Systems protocol.
    The multiply is to account the fact that Mouse Systems packets actually
    consist of 'one and a half' mouse events, with the second set of movement
    coordinates reporting how much the mouse has moved while the first half
    of the packet is being transmitted. The mouse converter handles this
    aspect properly.


Mouse Modes and Packet Formats

    The LameMouseConverter supports three protocol formats; the Three Byte
    Packed format, Mouse Systems compatible format, the Microsoft compatible
    format and the three byte packed format. Each of the protocol formats can
    be selected through software commands, or the RTS toggle for Microsoft
    compatible.

    Three Byte Packed Format (command: 'T')

      The following table describes the packet format of the Three Byte
      Packed mode. Packets are reported at 1200 baud (unless changed),
      8 data bits, 1 stop bit and no parity. Mouse button bits are set when
      pressed and movement values are positive right, positive down as signed
      two's complement values.

      Byte b7  b6  b5  b4  b3  b2  b1  b0
      -----------------------------------    
       1st  0   0   0   0   0  LB  MB  RB
       2nd x7  x6  x5  x4  x3  x2  x1  x0
       3rd y7  y6  y5  y5  y3  y2  y1  y0


    Mouse Systems Compatible Format (command: 'U')

      The following table describes the packet format of the Mouse Systems
      compatible mode. Packets are reported at 1200 baud (unless changed),
      8 data bits, 1 stop bit and no parity. Mouse button bits are clear when
      pressed and movement values are positive right, negative down as signed
      two's complement values.

      Byte b7  b6  b5  b4  b3  b2  b1  b0
      -----------------------------------    
       1st  1   0   0   0   0  LB  MB  RB
       2nd x7  x6  x5  x4  x3  x2  x1  x0
       3rd y7  y6  y5  y5  y3  y2  y1  y0
       4th x7  x6  x5  x4  x3  x2  x1  x0
       5th y7  y6  y5  y5  y3  y2  y1  y0

      The 4th and 5th bytes are not a duplicate, but rather a "half packet"
      of the amount the mouse has moved while the first half of the packet
      was being transmitted. A properly written Mouse Systems driver must
      interpret this second half as another mouse event if the coordinates
      are non-zero.


    Microsoft Compatible Format (send 'V' or toggle RTS)

      The following table describes the packet format of the Microsoft
      compatible mode. Packets are reported at 1200 baud (unless changed),
      7 data bits, 1 stop bit and no parity. Mouse button bits are set when
      pressed and mouse movement values are positive right, positive down as
      signed 8-bit values.

      Byte b6  b5  b4  b3  b2  b1  b0
      -------------------------------
       1st  1  LB  RB  y7  y6  x7  x6
       2nd  0  x5  x4  x3  x2  x1  x0
       3rd  0  y5  y5  y3  y2  y1  y0

      Unique to the LameMouseConverter compared to the reference Logitech
      Logimouse C7 is middle button support for Microsoft format mode. The
      middle button is reported as a "toggle" by reporting a duplicate of the
      last mouse button states with zero movement, which should be impossible
      to transmit on a well programmed mouse controller. Compatible drivers
      will interpret this as a toggle of a middle button press, while older
      drivers that only support two buttons will simply do nothing.


    Logitech Extended Microsoft Format (to be supported soon)
    
      The Logitech format is identical to the Microsoft format, only an
      additional byte is reported whenever the middle button is pressed or
      held down. Because of the additional byte the mouse report rate is
      reduced on slower baud rates whenever the middle button is held down.
      
      The Logitech Extended Microsoft Format is identified by receiving
      characters 'M3' after toggling the RTS line.

      Byte b6  b5  b4  b3  b2  b1  b0
      -------------------------------
       1st  1  LB  RB  y7  y6  x7  x6
       2nd  0  x5  x4  x3  x2  x1  x0
       3rd  0  y5  y5  y3  y2  y1  y0
       4th  0  MB   0   0   0   0   0


Supported Mouse Commands Summary

    The following commands are derived from the Logitech Logimouse C7 mouse.
    Only a subset of the commands are implemented and the Logitech MouseWare
    drivers may not be able to recognize the extended mouse features as a
    result, moreso if they check the copyright string or misc commands not
    yet supported.

    Command	Hex Digit	Description

      J		  4Ah		Set mouse to 10 reports per second

      K		  4Bh		Set mouse to 20 reports per second

      L		  4Ch		Set mouse to 40 reports per second

      R		  52h		Set mouse to 40 reports per second

      M		  4Dh		Set mouse to 60 reports per second

      Q		  51h		Set mouse to 100 reports per second

      N		  4Eh		Set mouse to 200 reports per second

      T		  54h		Set Three Byte Packed mode (C7 native mode?)

      U		  55h		Set Mouse Systems compatible mode

      V		  56h		Set Microsoft compatible mode

      t		  74h		Get current mode and revision number in hex

      f		  66h		Get current mode and revision number byte
      
      c		  63h		Get copyright and revision string

      m		  6Dh		Force Mouse Systems (disables RTS detection)*      
				Also sets mode to Mouse Systems at 1200 baud

      *n	  6Eh		Set 1200 baud rate

      *o	  6Fh		Set 2400 baud rate

      *p	  70h		Set 4800 baud rate

      *q	  71h		Set 9600 baud rate

      * LameMouseConverter specific command.
    
    MODE and ECHO commands may be used to send the above commands to
    configure the mouse before loading a mouse driver. (ie. send 'm' to force
    Mouse Systems). The command bytes may be sent at 1200 baud, 7 data bits
    and 2 stop bits so that the mouse converter can receive the command bytes
    regardless of frame size (the 8th bit is ignored).
    
    In order for piping to COMx devices to work properly the CTS and DSR pins
    must be held high from pin 2 of the MAX232 chip, otherwise MS-DOS will
    throw a write error when trying to send command bytes using ECHO and
    piping the output to COMx.


Credits & References

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