# DNS Updater

## License and Disclaimer:

DNS Updater is Copyright (C) 2016, Arturo Espinosa Aldama

arturoea@gmail.com
Licensed under the GNU GPLv3, see the LICENSE file for licensing terms.

This software is provided as-is, with no guarantees over its usefulness,
performance or adequacy. Use at our own risk.

Source code available at https://github.com/pupitetris/DNS-Updater

## About the software.

DNS  Updater is  made using  the  great scripting  language and  tool,
AutoIt version 3.3.14. You can get a copy of AutoIt from

https://www.autoitscript.com/site/autoit/

DNS Updater  works with Windows only.  So far, tested with  Windows 10
with no  problems at all. If  you have trouble running  it under other
versions, please  report. And also  report if you  are able to  run it
successfully under  other Windows versions, since  this program relies
on the netsh command (available since Windows Vista).

## Operation.

At less than  300 lines of code, DNS Updater  is a medium-sized script
that renders a  Windows GUI so you  can easily set your  DNS entry for
your different network interfaces.

It remembers the last static DNS IP  value you entered with it and the
last Network Interface you selected for convenience, and allows you to
easily switch  between "Automatic"  DNS setting  (DHCP) or  a "Manual"
configuration (Static).

DNS Updater always shows you the current status of the DNS settings of
the interface and the changes you make are applied immediately.

The program remains running even if  you close the window, but creates
a Tray Icon where  you can really exit if you click  the icon with the
right (secondary) mouse button.

If you  launch a  second instance  of the program,  it will  detect if
another instance  is already running  and just invoke the  windows for
that instance, to avoid duplicity.

Settings and  the single  instance feature make  use of  the following
Windows registry location:

HKEY_CURRENT_USER\SOFTWARE\DNSUpdater

The  program   does  not  require  installation;   just  download  the
executable located  on this  repository and run  it from  wherever you
like.

Administrator privileges  are required since the  program changes your
global NIC settings (through the netsh command).

All modifications to this program are welcome!
