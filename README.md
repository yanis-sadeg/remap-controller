# Remap-controller
Remap Controller is a script that automates the installation and configuration of Makima on Linux, allowing you to control your system using a game controller. It includes a pre-configured setup that enables mouse control and system actions, making it compatible with handheld gaming consoles such as the Legion Go, Steam Deck, ROG Ally, and MSI Claw.

# Makima Installation Guide

## Prerequisites:
- Linux system (Debian, Ubuntu, Fedora)
- Root privileges (Run the script as sudo)

## Usage
Activate or deactivate Makima by pressing the right joystick button (BTN_THUMBR).  
  
If you are on another handheld console than Legion Go, then edit the name of your controller by yours:
```bash
Handheld Daemon Controller
```
  
Run with root privileges: 
```bash
install_makima_for_handled.sh
```
  
To check service status:  
```bash
systemctl status makima.service
```
  
To manually start or stop the service:  
```bash
systemctl start makima.service
systemctl stop makima.service
```  
  
To remove the installation, delete:
```bash
sudo systemctl stop makima.service
sudo systemctl disable makima.service
sudo rm -rf ~/makima ~/.config/makima /etc/systemd/system/makima.service
```
## What install_makima_for_handled.sh does
1. Check User Privileges and Linux Distribution
    - Ensures the script is executed with root privileges.
    - Detects the Linux distribution to install the required dependencies accordingly.
2. Verify Existing Installation
    - If Makima is already installed, the script aborts to prevent redundant installations.
3. Install Dependencies
    - Installs necessary packages based on the detected distribution:
        - git, cargo, python3, python3-pip, python3-evdev, systemd, zenity
        - Python package evdev via pip3.
4. Clone and Compile Makima
    - Clones the Makima repository from GitHub.
    - Builds the project using cargo build --release.
    - Sets execution permissions for the compiled binary.
5. Create the Python Script for Controller Integration
    - Generates a script controllerMakimaShortcut.py that:
    - Detects the connected controller.
    - Monitors button presses.
    - Starts or stops Makima when the right joystick button is pressed.
6. Generate the Configuration File (.toml)
    - Creates a configuration file (Handheld Daemon Controller.toml) inside ~/.config/makima/.
    - Defines button-to-key mappings and controller sensitivity settings.
7. Set Up a systemd Service
    - Creates a makima.service systemd unit to run the Python script on startup.
    - Configures the service to restart automatically in case of failure.
8. Enable and Start the systemd Service
    - Reloads systemd to recognize the new service.
    - Enables and starts the Makima service.
9. Confirm Installation
    - Creates a hidden file to mark installation as completed.
    - Displays a success message using zenity.

## Default configuration
The Handheld Daemon Controller.toml configuration file defines button-to-key mappings for a controller. Below is a description of each remapped action:

### Button Remaps
These mappings allow controller buttons to trigger keyboard keys.
  
- BTN_NORTH = ["KEY_ENTER"]
→ The X button acts as the Enter key, useful for confirming actions.

- BTN_EAST = ["KEY_BACKSPACE"]
→ The Y button acts as the Backspace key, allowing quick deletion of text.

- BTN_SOUTH = ["BTN_LEFT"]
→ The A button acts as a left mouse button click.

- BTN_WEST = ["KEY_SPACE"]
→ The B button functions as a spacebar press, often used for jumping or pausing.

- BTN_TR = ["BTN_RIGHT"]
→ The Right Bumper (RB) functions as a right mouse button click.

- BTN_TL = ["KEY_ESC"]
→ The Left Bumper (LB) functions as the Escape key, useful for canceling actions or exiting menus.

- BTN_START = ["KEY_LEFTMETA"]
→ The Start button acts as the Windows/Super key, used to open the system menu.

- BTN_SELECT = ["KEY_ESC"]
→ The Back/Select button acts as the Escape key, similar to BTN_TL.

- BTN_THUMBL = ["BTN_MIDDLE"]
→ The Left Stick Click (L3) functions as a middle mouse button click.

- BTN_MODE = ["KEY_SPACE"]
→ The Xbox/Guide button acts as the Spacebar, possibly for quick actions.

- Trigger and D-Pad Remaps
These mappings assign directional and trigger inputs to keyboard keys.

- BTN_TR2 = ["KEY_LEFTCTRL","KEY_V"]
→ The Right Trigger (RT) performs Ctrl + V, used for pasting text.

- BTN_TL2 = ["KEY_LEFTCTRL","KEY_C"]
→ The Left Trigger (LT) performs Ctrl + C, used for copying text.

- BTN_DPAD_UP = ["KEY_UP"]
→ The D-Pad Up functions as the Up Arrow Key, useful for navigating menus.

- BTN_DPAD_RIGHT = ["KEY_RIGHT"]
→ The D-Pad Right functions as the Right Arrow Key.

- BTN_DPAD_DOWN = ["KEY_DOWN"]
→ The D-Pad Down functions as the Down Arrow Key.

- BTN_DPAD_LEFT = ["KEY_LEFT"]
→ The D-Pad Left functions as the Left Arrow Key.

- Right Stick Remaps
The right stick is mapped to movement actions.

- RSTICK_UP = ["KEY_UP"]
→ Moving the Right Stick Up acts as pressing the Up Arrow Key.

- RSTICK_DOWN = ["KEY_DOWN"]
→ Moving the Right Stick Down acts as pressing the Down Arrow Key.

- RSTICK_LEFT & RSTICK_RIGHT are not mapped by default
→ These can be customized to left/right movement.

### Settings and Sensitivity Adjustments
Additional settings that modify behavior.

- LSTICK_SENSITIVITY = "20" & RSTICK_SENSITIVITY = "20"
→ Defines how sensitive the sticks are (lower values increase sensitivity).

- LSTICK_DEADZONE = "20" & RSTICK_DEADZONE = "20"
→ Prevents accidental movement by setting a dead zone (0–128, higher values reduce small movements).

- LSTICK = "cursor"
→ The left stick is set to control the mouse cursor.

- RSTICK = "bind"
→ The right stick is used for remapped key bindings.

- 16_BIT_AXIS = "true"
→ Required for Xbox controllers and Switch joy-cons to function properly.

- GRAB_DEVICE = "false"
→ Disabling exclusivity allows other programs to access the controller.

Thanks to cyber-sushi for Makima tool
