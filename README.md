# DiscoFish Guppy

## Hardware setup 

Make sure Kenwood radio is

- plugged in to power or charged (note that power adapter can cause radio to reboot when plugged in or out)
- plugged in to computer over USB (ls /dev/ttyUSB*)
- in beacon mode (push the BCON button to get BCON lit up on the screen)

## Software setup

Use Ununtu 14.04 LTS as a base OS.

Create a user named 'fish', password 'otto'. Make sure you're connected to internet. Install dev tools,  
clone this repository, and install Guppy software:

    sudo apt-get install -y build-essential git make 
    git clone git@gitlab.com:dfguppy/dfguppy.git
    cd dfguppy
    make all install

Then install recent Chromium (or Midori - are we using Midori now?) version and set it up in kiosk mode (add instructions here). 
Configure it to run on startup and load http://localhost:8091

### Calibrating TT4 TNC

Most radios we have should already be pre-calibrated, do this only if you have problems.

- Turn on the radio 
- Set frequency to 144.39 
- Turn off squelching. Make sure you can hear modem buzzes clearly (it's extremely finicky indoors - e.g. moving the radio a couple of feet from one side of the table to another seems to make a big difference). 
- Plug in TT4
- Open terminal at 19200 bps, flow control off (sudo screen -fn /dev/ttyUSB0 19200,cs8, Ctrl-A k to exit)
- Power cycle TT4, press ESC three times to go to command mode
- Run MONITOR command to calibrate audio level. Set RXAMP so that the signal saturates around 80 (e.g. I set it to 10) and turn the volume knob so that static is somewhere in 50s. Output level is very, very sensitive to the volume knob position - turning it just a few degrees makes a huge difference. 80 max/50 avg levels seem to work ok, but we may want to fine tune the numbers.
- Press any key to exit monitor, make sure that AMODE is set to TEXT, set ABAUD to 9600 (so that we can switch between TT4 & Kenwood without reconfiguring software), and type QUIT to exit command mode

### Calibrating Kenwood Radios

Most radios we have should already be pre-calibrated, do this only if you have problems.

(add instructions here)
