#!/bin/bash

echo "=== Setting up C64 development environment with MSYS2 ==="

# Working directory
WORKING_DIR=$(pwd)
C64_DEV_DIR="$WORKING_DIR/c64dev"

# Create development directory
mkdir -p "$C64_DEV_DIR"
cd "$C64_DEV_DIR"

# Install required MSYS2 base tools
echo "Installing required MSYS2 packages..."
pacman -S --noconfirm --needed base-devel mingw-w64-x86_64-toolchain git

# Download and compile CC65
echo "Downloading and compiling CC65..."
if [ ! -d "cc65" ]; then
    git clone https://github.com/cc65/cc65.git
    cd cc65
    make
    make install PREFIX=/usr/local
    cd ..
else
    echo "CC65 already present."
fi

# Download VICE (C64 emulator)
echo "Downloading VICE (C64 emulator)..."
if [ ! -d "vice" ]; then
    # On MSYS2 we can try installing VICE via pacman if available
    pacman -S --noconfirm --needed mingw-w64-x86_64-vice || {
        echo "VICE not available via pacman, downloading manually..."
        
        # Otherwise, download manually
        VICE_VERSION="3.6.0"
        VICE_URL="https://sourceforge.net/projects/vice-emu/files/releases/vice-${VICE_VERSION}-win64.7z"
        
        # Install 7z if needed
        pacman -S --noconfirm --needed p7zip
        
        # Download and extract VICE
        wget -O vice.7z "$VICE_URL"
        7z x vice.7z -ovice
        rm vice.7z
    }
else
    echo "VICE already present."
fi

# Create a simple C64 project example
echo "Creating a simple C64 project example..."
mkdir -p "$C64_DEV_DIR/hello-c64"
cd "$C64_DEV_DIR/hello-c64"

# Create a sample C file
cat > hello.c << 'EOL'
/*
 * A simple Hello World program for Commodore 64
 * Compiled with CC65
 */

#include <stdio.h>
#include <conio.h>

int main(void) {
    // Clear the screen
    clrscr();
    
    // Change text color
    textcolor(COLOR_CYAN);
    
    // Move cursor
    gotoxy(0, 0);
    
    // Print message
    printf("*** HELLO FROM MSYS2 TO C64! ***\n\n");
    printf("COMMODORE 64 BASIC V2\n");
    printf("64K RAM SYSTEM\n\n");
    printf("READY.\n");
    
    // Blinking effect
    while(!kbhit()) {
        unsigned char i;
        for(i = 1; i <= 15; i++) {
            textcolor(i);
            gotoxy(0, 8);
            printf("MSYS2 + C64 = AWESOME!");
            
            // Small delay loop
            for(unsigned int j = 0; j < 10000; j++) {
                // Empty loop for delay
            }
        }
    }
    
    // Reset color and clear screen
    textcolor(COLOR_WHITE);
    clrscr();
    
    // Final message
    printf("PROGRAM ENDED. PRESS A KEY...");
    cgetc();
    
    return 0;
}
EOL

# Create a Makefile
cat > Makefile << 'EOL'
# Makefile for C64 program

# Configuration
CC = cl65
CFLAGS = -t c64 -O
LDFLAGS = -t c64

# Source file
SRC = hello.c

# Final program name
PROGRAM = hello

# Default rule
all: $(PROGRAM)

# Compile
$(PROGRAM): $(SRC)
	$(CC) $(CFLAGS) -o $(PROGRAM) $(SRC) $(LDFLAGS)

# Clean compiled files
clean:
	rm -f $(PROGRAM)

# Run program in emulator
run: $(PROGRAM)
	x64 $(PROGRAM)

.PHONY: all clean run
EOL

# Create a build and test script
cat > build-and-run.sh << 'EOL'
#!/bin/bash

# Compile the C64 program
make clean
make

# Check if compilation succeeded
if [ $? -eq 0 ]; then
    echo "Compilation successful! File 'hello' created."
    echo "Starting VICE emulator..."
    
    # Run the program in the C64 emulator
    make run
else
    echo "Compilation error."
fi
EOL

# Make the script executable
chmod +x build-and-run.sh

echo -e "\n=== C64 development environment set up successfully! ==="
echo "Development directory: $C64_DEV_DIR"
echo "To compile and run the example, go to the directory:"
echo "  cd $C64_DEV_DIR/hello-c64"
echo "And run:"
echo "  ./build-and-run.sh"
echo ""
echo "Note: Make sure CC65 and VICE are in your system PATH."
echo "If not, add them to your .bashrc like this:"
echo '  export PATH=$PATH:/path/to/cc65/bin:/path/to/vice'
