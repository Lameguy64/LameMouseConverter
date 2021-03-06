EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "LameMouseConverter Basic"
Date "2022-04-09"
Rev "1"
Comp "Meido-Tek KYS Hardware Division (John \"Lameguy\" Wilbert Villamor)"
Comment1 "This schematic is for reference purposes only for wiring the required support circuitry."
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L MCU_Module:Arduino_UNO_R3 A1
U 1 1 612985E0
P 2500 3600
F 0 "A1" H 2500 4778 50  0000 C CNN
F 1 "Arduino_UNO_R3" H 2500 4687 50  0000 C CNN
F 2 "Module:Arduino_UNO_R3" H 2650 2550 50  0001 L CNN
F 3 "https://www.arduino.cc/en/Main/arduinoBoardUno" H 2300 4650 50  0001 C CNN
	1    2500 3600
	-1   0    0    -1  
$EndComp
$Comp
L Interface_UART:MAX232 U1
U 1 1 612986C3
P 6500 3500
F 0 "U1" H 6500 4878 50  0000 C CNN
F 1 "MAX232" H 6500 4787 50  0000 C CNN
F 2 "" H 6550 2450 50  0001 L CNN
F 3 "http://www.ti.com/lit/ds/symlink/max232.pdf" H 6500 3600 50  0001 C CNN
	1    6500 3500
	1    0    0    -1  
$EndComp
Wire Wire Line
	3700 3100 3000 3100
$Comp
L Connector:Mini-DIN-6 J1
U 1 1 612988D0
P 4000 2400
F 0 "J1" H 4000 2767 50  0000 C CNN
F 1 "PS2_MOUSE" H 4000 2676 50  0000 C CNN
F 2 "" H 4000 2400 50  0001 C CNN
F 3 "http://service.powerdynamics.com/ec/Catalog17/Section%2011.pdf" H 4000 2400 50  0001 C CNN
	1    4000 2400
	1    0    0    -1  
$EndComp
Wire Wire Line
	4400 3400 4400 2500
Wire Wire Line
	4400 2500 4300 2500
Text Label 3800 3900 0    50   ~ 0
TTL_RX
Text Label 3800 3600 0    50   ~ 0
TTL_TX
Text Label 3800 3200 0    50   ~ 0
PS2_CLK
Text Label 3800 3400 0    50   ~ 0
PS2_DAT
Text Label 3800 4200 0    50   ~ 0
TTL_RTS
Wire Wire Line
	4600 3200 4600 2300
Wire Wire Line
	3000 3200 4600 3200
Wire Wire Line
	4300 2300 4600 2300
$Comp
L power:GND #PWR04
U 1 1 61299891
P 4800 2700
F 0 "#PWR04" H 4800 2450 50  0001 C CNN
F 1 "GND" H 4805 2527 50  0000 C CNN
F 2 "" H 4800 2700 50  0001 C CNN
F 3 "" H 4800 2700 50  0001 C CNN
	1    4800 2700
	1    0    0    -1  
$EndComp
Wire Wire Line
	4800 2700 4800 2400
Wire Wire Line
	4800 2400 4300 2400
$Comp
L power:+5V #PWR03
U 1 1 61299B0C
P 3200 2100
F 0 "#PWR03" H 3200 1950 50  0001 C CNN
F 1 "+5V" H 3215 2273 50  0000 C CNN
F 2 "" H 3200 2100 50  0001 C CNN
F 3 "" H 3200 2100 50  0001 C CNN
	1    3200 2100
	1    0    0    -1  
$EndComp
NoConn ~ 3700 2300
NoConn ~ 3700 2500
$Comp
L power:+5V #PWR01
U 1 1 6129A512
P 2000 2300
F 0 "#PWR01" H 2000 2150 50  0001 C CNN
F 1 "+5V" H 2015 2473 50  0000 C CNN
F 2 "" H 2000 2300 50  0001 C CNN
F 3 "" H 2000 2300 50  0001 C CNN
	1    2000 2300
	1    0    0    -1  
$EndComp
Wire Wire Line
	2000 2300 2000 2600
Wire Wire Line
	2000 2600 2300 2600
$Comp
L power:GND #PWR02
U 1 1 6129A865
P 2600 4900
F 0 "#PWR02" H 2600 4650 50  0001 C CNN
F 1 "GND" H 2605 4727 50  0000 C CNN
F 2 "" H 2600 4900 50  0001 C CNN
F 3 "" H 2600 4900 50  0001 C CNN
	1    2600 4900
	1    0    0    -1  
$EndComp
Wire Wire Line
	2600 4900 2600 4700
$Comp
L Device:CP_Small C1
U 1 1 6129AC3B
P 5300 2750
F 0 "C1" H 5388 2796 50  0000 L CNN
F 1 "16v 1uf" H 5388 2705 50  0000 L CNN
F 2 "" H 5300 2750 50  0001 C CNN
F 3 "~" H 5300 2750 50  0001 C CNN
	1    5300 2750
	1    0    0    -1  
$EndComp
Wire Wire Line
	5300 2650 5300 2600
Wire Wire Line
	5300 2600 5700 2600
Wire Wire Line
	5300 2850 5300 2900
Wire Wire Line
	5300 2900 5700 2900
Wire Wire Line
	7300 2600 7700 2600
Wire Wire Line
	7300 2900 7700 2900
$Comp
L Device:CP_Small C3
U 1 1 6129C40F
P 7700 2750
F 0 "C3" H 7788 2796 50  0000 L CNN
F 1 "16v 1uf" H 7788 2705 50  0000 L CNN
F 2 "" H 7700 2750 50  0001 C CNN
F 3 "~" H 7700 2750 50  0001 C CNN
	1    7700 2750
	1    0    0    -1  
$EndComp
Wire Wire Line
	7700 2650 7700 2600
Wire Wire Line
	7700 2850 7700 2900
$Comp
L Device:CP_Small C5
U 1 1 6129D6E7
P 8300 3100
F 0 "C5" V 8525 3100 50  0000 C CNN
F 1 "16v 1uf" V 8434 3100 50  0000 C CNN
F 2 "" H 8300 3100 50  0001 C CNN
F 3 "~" H 8300 3100 50  0001 C CNN
	1    8300 3100
	0    -1   -1   0   
$EndComp
$Comp
L Device:CP_Small C4
U 1 1 6129EA30
P 7950 3400
F 0 "C4" V 8175 3400 50  0000 C CNN
F 1 "16v 1uf" V 8084 3400 50  0000 C CNN
F 2 "" H 7950 3400 50  0001 C CNN
F 3 "~" H 7950 3400 50  0001 C CNN
	1    7950 3400
	0    1    -1   0   
$EndComp
Wire Wire Line
	7300 3400 7850 3400
Wire Wire Line
	8400 3100 8500 3100
Wire Wire Line
	8500 3100 8500 3400
Wire Wire Line
	8500 3400 8050 3400
$Comp
L power:GND #PWR08
U 1 1 612A04D6
P 8700 3200
F 0 "#PWR08" H 8700 2950 50  0001 C CNN
F 1 "GND" H 8705 3027 50  0000 C CNN
F 2 "" H 8700 3200 50  0001 C CNN
F 3 "" H 8700 3200 50  0001 C CNN
	1    8700 3200
	1    0    0    -1  
$EndComp
Wire Wire Line
	8700 3200 8700 3100
Wire Wire Line
	8700 3100 8500 3100
Connection ~ 8500 3100
Wire Wire Line
	3700 3100 3700 3600
NoConn ~ 5700 3800
NoConn ~ 7300 3800
NoConn ~ 3000 3500
NoConn ~ 3000 3600
NoConn ~ 3000 4300
NoConn ~ 3000 4200
NoConn ~ 3000 4100
NoConn ~ 3000 4000
NoConn ~ 3000 3900
NoConn ~ 3000 3800
NoConn ~ 2500 4700
NoConn ~ 2400 4700
NoConn ~ 2000 4400
NoConn ~ 2000 4300
NoConn ~ 2000 4100
NoConn ~ 2000 4000
NoConn ~ 2000 3900
NoConn ~ 2000 3800
NoConn ~ 2000 3700
NoConn ~ 2000 3600
NoConn ~ 2000 3400
NoConn ~ 2000 3200
NoConn ~ 2000 3000
NoConn ~ 2400 2600
NoConn ~ 2600 2600
$Comp
L Device:C_Small C2
U 1 1 612AE7F7
P 7000 1900
F 0 "C2" H 7092 1946 50  0000 L CNN
F 1 "100pf" H 7092 1855 50  0000 L CNN
F 2 "" H 7000 1900 50  0001 C CNN
F 3 "~" H 7000 1900 50  0001 C CNN
	1    7000 1900
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR06
U 1 1 612AF533
P 6800 1700
F 0 "#PWR06" H 6800 1550 50  0001 C CNN
F 1 "+5V" H 6815 1873 50  0000 C CNN
F 2 "" H 6800 1700 50  0001 C CNN
F 3 "" H 6800 1700 50  0001 C CNN
	1    6800 1700
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR07
U 1 1 612B0180
P 7000 2150
F 0 "#PWR07" H 7000 1900 50  0001 C CNN
F 1 "GND" H 7005 1977 50  0000 C CNN
F 2 "" H 7000 2150 50  0001 C CNN
F 3 "" H 7000 2150 50  0001 C CNN
	1    7000 2150
	1    0    0    -1  
$EndComp
Wire Wire Line
	7000 2150 7000 2000
Wire Wire Line
	7000 1800 6800 1800
Wire Wire Line
	6800 1800 6800 1700
Wire Wire Line
	6800 1800 6800 2300
Connection ~ 6800 1800
Wire Wire Line
	6500 2300 6800 2300
$Comp
L Connector:DB9_Female J2
U 1 1 612B3001
P 9600 3800
F 0 "J2" H 9779 3846 50  0000 L CNN
F 1 "DB9_Female" H 9779 3755 50  0000 L CNN
F 2 "" H 9600 3800 50  0001 C CNN
F 3 " ~" H 9600 3800 50  0001 C CNN
	1    9600 3800
	1    0    0    -1  
$EndComp
Wire Wire Line
	3700 3600 5700 3600
Wire Wire Line
	7300 3600 9300 3600
Wire Wire Line
	7600 4000 7600 3800
Wire Wire Line
	7600 4000 7300 4000
Wire Wire Line
	7600 3800 9300 3800
Text Label 8550 3600 0    50   ~ 0
RS232_RX
Text Label 8550 3800 0    50   ~ 0
RS232_TX
Text Label 8550 3700 0    50   ~ 0
RS232_RTS
$Comp
L power:GND #PWR09
U 1 1 612B7CF2
P 9200 4300
F 0 "#PWR09" H 9200 4050 50  0001 C CNN
F 1 "GND" H 9205 4127 50  0000 C CNN
F 2 "" H 9200 4300 50  0001 C CNN
F 3 "" H 9200 4300 50  0001 C CNN
	1    9200 4300
	1    0    0    -1  
$EndComp
Wire Wire Line
	9200 4300 9200 4200
Wire Wire Line
	9200 4200 9300 4200
NoConn ~ 9300 4100
Wire Wire Line
	3300 3700 3300 4200
Wire Wire Line
	3300 3700 3000 3700
Wire Wire Line
	3500 3000 3500 3900
Wire Wire Line
	3500 3900 4500 3900
Wire Wire Line
	3300 4200 4500 4200
$Comp
L power:GND #PWR05
U 1 1 6129E132
P 6500 4900
F 0 "#PWR05" H 6500 4650 50  0001 C CNN
F 1 "GND" H 6505 4727 50  0000 C CNN
F 2 "" H 6500 4900 50  0001 C CNN
F 3 "" H 6500 4900 50  0001 C CNN
	1    6500 4900
	1    0    0    -1  
$EndComp
Wire Wire Line
	6500 4700 6500 4900
Wire Wire Line
	3700 2400 3200 2400
Wire Wire Line
	3200 2400 3200 2100
$Comp
L Device:Jumper_NC_Small JP1
U 1 1 612A5054
P 4600 3900
F 0 "JP1" H 4600 4112 50  0000 C CNN
F 1 "RX_EN" H 4600 4021 50  0000 C CNN
F 2 "" H 4600 3900 50  0001 C CNN
F 3 "~" H 4600 3900 50  0001 C CNN
	1    4600 3900
	1    0    0    -1  
$EndComp
$Comp
L Device:Jumper_NO_Small JP3
U 1 1 612A7991
P 4900 3300
F 0 "JP3" H 4900 3485 50  0000 C CNN
F 1 "AUTOBAUD" H 4900 3394 50  0000 C CNN
F 2 "" H 4900 3300 50  0001 C CNN
F 3 "~" H 4900 3300 50  0001 C CNN
	1    4900 3300
	1    0    0    -1  
$EndComp
Wire Wire Line
	3000 3400 4400 3400
Wire Wire Line
	5200 4000 5200 3900
Wire Wire Line
	5200 4000 5700 4000
Wire Wire Line
	4700 3900 5200 3900
Wire Wire Line
	3000 3000 3500 3000
Wire Wire Line
	3000 3300 4800 3300
Wire Wire Line
	5000 3300 5200 3300
Connection ~ 5200 3900
Wire Wire Line
	5200 3900 5200 3300
$Comp
L Device:Jumper_NC_Small JP2
U 1 1 62525233
P 4600 4200
F 0 "JP2" H 4600 4412 50  0000 C CNN
F 1 "RTS_EN" H 4600 4321 50  0000 C CNN
F 2 "" H 4600 4200 50  0001 C CNN
F 3 "~" H 4600 4200 50  0001 C CNN
	1    4600 4200
	1    0    0    -1  
$EndComp
Wire Wire Line
	4700 4200 5700 4200
Wire Wire Line
	7300 3100 8200 3100
Wire Wire Line
	7450 4200 7450 3700
Wire Wire Line
	7450 4200 7300 4200
Wire Wire Line
	7450 3700 9300 3700
Wire Wire Line
	9300 3400 9200 3400
Wire Wire Line
	9200 3400 9200 3500
Wire Wire Line
	9200 4000 9300 4000
Wire Wire Line
	9300 3900 9200 3900
Connection ~ 9200 3900
Wire Wire Line
	9200 3900 9200 4000
Wire Wire Line
	9200 3500 9300 3500
Connection ~ 9200 3500
Wire Wire Line
	9200 3500 9200 3900
Text Notes 4000 4500 0    50   ~ 0
JP1=O JP2=S: Mouse Systems/Microsoft\nJP1=S JP2=O: Mouse Systems/C7
$EndSCHEMATC
