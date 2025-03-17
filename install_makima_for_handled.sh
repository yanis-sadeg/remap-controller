#!/bin/bash

# Author: https://yanis-sadeg.fr
# Check superuser rights for installation
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with root privileges."
  exit 1
fi

# Variables
REPO_URL="https://github.com/yanis-sadeg/makima.git"
INSTALL_DIR="$HOME/makima"
CONFIG_DIR="$HOME/.config/makima"
TOML_FILE="$CONFIG_DIR/Handheld Daemon Controller.toml"
SERVICE_NAME="makima.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
PYTHON_SCRIPT="controllerMakimaShortcut.py"
USER_NAME=$(whoami)
USER_GROUP=$(id -gn)
EXEC_PATH="$INSTALL_DIR/target/release/makima"
MARKER_FILE="$INSTALL_DIR/.installed_marker"

# Function to check the Linux distribution
check_distribution() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  else
    echo "Unable to detect the Linux distribution."
    exit 1
  fi
}

# Check whether installation has already been carried out
check_existing_installation() {
  if [ -f "$MARKER_FILE" ]; then
    zenity --info --text="Existing installation, operation cancelled."
    exit 0
  fi
}

# Installing dependencies
install_dependencies() {
  echo "Installing the required dependencies..."
  if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    apt update
    apt install -y git cargo python3 python3-pip python3-evdev systemd zenity
  elif [[ "$DISTRO" == "fedora" ]]; then
    dnf install -y git cargo python3 python3-pip python3-evdev systemd zenity
  else
    echo "Distribution not supported. Please install the : git, cargo, python3, python3-pip, python3-evdev, systemd, zenity."
    exit 1
  fi
  pip3 install evdev
}

# Step 1: Install Makima
install_makima() {
  echo "Cloning Makima from the Git repository..."
  git clone $REPO_URL $INSTALL_DIR
  cd $INSTALL_DIR
  echo "Building Makima..."
  cargo build --release
  chmod +x $EXEC_PATH
  echo "Makima successfully installed."
}

# Step 2: Create the Python script for the shortcut
create_python_script() {
  echo "Creating a Python script $PYTHON_SCRIPT..."
  cat <<EOF > $INSTALL_DIR/$PYTHON_SCRIPT
import evdev
import subprocess
import os
import signal

# Find the device corresponding to the controller
devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
controller = None
for device in devices:
    if 'Handheld Daemon Controller' in device.name:  # Replace with the name of your controller
        controller = device
        break

if controller is None:
    print("Controller not found")
    exit()

print(f"Using the controller : {controller.name}")

def makima():
    try:
        # Search for the 'makima' process and kill it if it's already running
        processus = subprocess.run(['ps', '-A'], capture_output=True, text=True)
        if 'makima' in processus.stdout:
            lignes = processus.stdout.splitlines()
            for ligne in lignes:
                if 'makima' in ligne:
                    pid = int(ligne.split(None, 1)[0])
                    os.kill(pid, signal.SIGTERM)  # Kill the process cleanly
                    print(f"makima process (PID {pid}) terminated.")
        else:
            # Start the 'makima' process in the background
            commande = "$EXEC_PATH"
            subprocess.Popen(commande, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print("makima process started in background.")
    except Exception as e:
        print(f"An error has occurred: {e}")

# Listening for controller events with interrupt management
try:
    for event in controller.read_loop():
        if event.type == evdev.ecodes.EV_KEY:
            if event.code == evdev.ecodes.BTN_THUMBR and event.value == 1:  # BTN_THUMBR is the right click of the
                makima()
except KeyboardInterrupt:
    print("\\nScript interrupted by user.")
finally:
    controller.close()
EOF
  chmod +x $INSTALL_DIR/$PYTHON_SCRIPT
  echo "Python script successfully created."
}

# Step 3: Create the configuration TOML file
create_toml_config() {
  echo "Create TOML configuration file in $TOML_FILE..."
  mkdir -p $CONFIG_DIR
  cat <<EOF > $TOML_FILE
# SAMPLE CONFIG FILE FOR XBOX CONTROLLERS
# Put this in ~/.config/makima and rename it to the exact name of the device as shown by the 'evtest' command, including spaces and capitalization. Omit "/" if present.
# You can find all the available keycodes in /usr/include/linux/input-event-codes.h
# If you're not sure which keycode corresponds to which key, you can run 'evtest', select your device and press the corresponding key/button.
# Relative and absolute axis events are hard coded, for example use RSTICK_UP, RSTICK_DOWN etc to rebind your analog stick.
# This config file is tested for Xbox 360, Xbox One and Xbox Elite 2 controllers. When using a different controller, if no specific config file for your device is available, change the keycodes on the left according to those of your controller (evtest is your friend again). If your controller has a button to enable/disable analog sticks, make sure they're enabled.

[remap]
# Examples of Button => Key(s)
BTN_NORTH = ["KEY_ENTER"] # X
BTN_EAST = ["KEY_BACKSPACE"] # Y
BTN_SOUTH = ["BTN_LEFT"] # A
BTN_WEST = ["KEY_SPACE"] # B
BTN_TR = ["BTN_RIGHT"] # RB
BTN_TL = ["KEY_ESC"] # LB
BTN_START = ["KEY_LEFTMETA"] # start
BTN_SELECT = ["KEY_ESC"] # back
# BTN_THUMBR = ["KEY_LEFTMETA", "KEY_Q"] # RS
BTN_THUMBL = ["BTN_MIDDLE"] # LS
BTN_MODE = ["KEY_SPACE"] # Xbox button
# Examples of Axis events => Key(s)
BTN_TR2 = ["KEY_LEFTCTRL","KEY_V"] # RT
BTN_TL2 = ["KEY_LEFTCTRL","KEY_C"] # LT
BTN_DPAD_UP = ["KEY_UP"] # directional pad up
BTN_DPAD_RIGHT = ["KEY_RIGHT"] # directional pad right
BTN_DPAD_DOWN = ["KEY_DOWN"] # directional pad down
BTN_DPAD_LEFT = ["KEY_LEFT"] # directional pad left
RSTICK_UP = ["KEY_UP"] # right analog stick up
RSTICK_DOWN = ["KEY_DOWN"] # right analog stick down

[commands]
# RSTICK_LEFT = [] # right analog stick left
# RSTICK_RIGHT = [] # right analog stick right

[settings]
LSTICK_SENSITIVITY = "20" # sensitivity when scrolling or moving cursor, lower value is higher sensitivity, minimum 1
RSTICK_SENSITIVITY = "20" # sensitivity when scrolling or moving cursor, lower value is higher sensitivity, minimum 1
LSTICK = "cursor" # cursor, scroll, bind or disabled
RSTICK = "bind" # cursor, scroll, bind or disabled
LSTICK_DEADZONE = "20" # integer between 0 and 128, bigger number is wider deadzone, default 5
RSTICK_DEADZONE = "20" # integer between 0 and 128, bigger number is wider deadzone, default 5
16_BIT_AXIS = "true" # necessary for Xbox controllers and Switch joycons, use false for other controllers
GRAB_DEVICE = "false" # gain exclusivity on the device
EOF
  echo "Fichier de configuration TOML créé avec succès."
}

# Step 4: Create the systemd service
create_systemd_service() {
  echo "Création du service systemd $SERVICE_NAME..."
  cat <<EOF > $SERVICE_PATH
[Unit]
Description=Python script to execute makima using the joystick's right-click key
After=network.target  # Ensures that the service starts after the network (optional)

[Service]
Type=simple
ExecStart=/usr/bin/python3 $INSTALL_DIR/$PYTHON_SCRIPT
WorkingDirectory=$INSTALL_DIR
Restart=always
User=$USER_NAME
Group=$USER_GROUP

[Install]
WantedBy=default.target
EOF
}

# Step 5: Activate and start the service
enable_and_start_service() {
  echo "Service activation and startup $SERVICE_NAME..."
  systemctl daemon-reload
  systemctl enable $SERVICE_NAME
  systemctl start $SERVICE_NAME
  echo "Makima service successfully activated and started."
}

# Create an installation marker file to indicate that installation has been completed
create_installation_marker() {
  touch "$MARKER_FILE"
}

# Display a success message
show_success_message() {
  zenity --info --text="Installation successfully completed. Right-click to activate or deactivate Makima."
}

# Function execution
check_distribution
check_existing_installation
install_dependencies
install_makima
create_python_script
create_toml_config
create_systemd_service
enable_and_start_service
create_installation_marker
show_success_message
