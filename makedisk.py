#!/usr/bin/env python3

# Overview
# ========
#
# makedisk.py [-w WIDTH] [-h HEIGHT] [-l] [-u]
#
# Assembles a set of regular files with special comments into a DCPU-friendly
# disk image for the Forth system.
#
# The Forth system uses "screens", which are 32x32 characters in size. That's
# 1024 characters per screen. Storing two characters per word, that's one block
# (512 words) per screen, for convenient matching of disk blocks to screens. In
# unpacked mode, that's 1024 words (2 disk blocks) per screen.
#
# The Forth screens are numbered from 0 upward, just like the disk blocks.
# By convention, screen 0 is a comments-only header, and screen 1 is the main
# loading screen. Note that these are Forth conventions, and this tool doesn't
# care what's on the screens.

# Operation of this tool
# ======================
#
# A list of file names is given on the command line. These are read in order,
# but the order doesn't really matter.
#
# When reading a file, no output is produced until a comment of the following
# form is seen:
#
# \ NNN: ...
#
# The tool reads that number, and considers that comment line as the first of 16
# lines in that screen.
# It keeps reading and outputting lines to that screen. It will error if a
# screen is longer than 32 lines.
#
# If there are two definitions of a given screen, the tool exits with an error.
#
# Each line is written out by extending it to 32 characters by padding with
# spaces. No newlines are written to the screen. If a line longer than 32
# characters is found, the tool exits with an error.

# Customization and Output
# ========================
#
# For flexibility, there are several options to control this tool's input and
# output. The dimensions of each screen can be adjusted, and so can the output
# format.
#
# The width and height are straightforward: both default to 32, but can be
# changed with a command-line argument.
#
# There are two output formats:
# - Unpacked: Each character is written as a 16-bit word. (-u)
# - Packed: Two characters are packed into a 16-bit word. (default)
#
# Then there are two orders of output: big-endian and little-endian.
# Supposing that the final Forth system expects to unpack 0xabcd to 0xab, 0xcd,
# we may need to reverse the byte order so that the disk image will be read
# correctly.
#
# If you want disks to be written in the natural order (a big-endian disk
# image), that is the default.
# To flip the byte order and allow for little-endian disk reading, use the -l
# flag.

import argparse
import re
import struct
import sys

screenWidth = 32
screenHeight = 32
screenSize = screenWidth * screenHeight

screensSeen = {}

screenRegex = re.compile(r'^\\ (\d+):', re.IGNORECASE)
emptyRegex = re.compile(r'^\s*$')

masterOutput = {}


def error(name, line, msg):
  print('Error %s line %d: %s' % (name, line + 1, msg))
  sys.exit(1)

def readLine(name, lineNum, screen, i, line):
  offset = (screenSize * screen) + (i * screenWidth)
  if len(line) > screenWidth:
    error(name, lineNum, 'Line too long (%d): %s' % (len(line), line))

  # Otherwise, stream the line to masterOutput, padding with spaces.
  i = 0
  while i < len(line):
    masterOutput[offset + i] = ord(line[i])
    i += 1

  while i < screenWidth:
    masterOutput[offset + i] = ord(' ')
    i += 1


# Returns the number of lines loaded for this screen.
def readScreen(name, screen, lines, index):
  if screen in screensSeen:
    error(name, index, 'Duplicate screen: %d' % (screen))

  for i in range(0, min(screenHeight, len(lines) - index)):
    line = lines[index+i]
    if i > 0 and re.search(screenRegex, line):
      return i # Bail if we find another screen header.
    readLine(name, index+i, screen, i, line)

  return screenHeight


def readFile(f, name):
  lines = list(map(lambda s: s.rstrip(), list(f)))
  i = 0
  while i < len(lines):
    line = lines[i]
    match = re.search(screenRegex, line)
    if match:
      number = int(match.group(1))
      i += readScreen(name, number, lines, i)
    elif re.search(emptyRegex, line):
      # Do nothing for empty lines outside of screens.
      i += 1
    else:
      error(name, i, 'Unexpected screenless text: %s' % (line))
  f.close()


def at(i):
  if i in masterOutput:
    return masterOutput[i]
  else:
    return 0

def main():
  parser = argparse.ArgumentParser(add_help=False)
  parser.add_argument("--help", action="help")
  parser.add_argument("-w", "--width",
      help="Width of a screen in characters", type=int)
  parser.add_argument("-h", "--height",
      help="Height of a screen in characters", type=int)
  parser.add_argument("-l", "--little-endian",
      help="Little-endian output", action="store_true")
  parser.add_argument("-u", "--unpacked",
      help="Unpacked output", action="store_true")
  parser.add_argument("input_files",
      help="Files to convert to screens", nargs="*")
  parser.set_defaults(width=32, height=32)

  args = parser.parse_args()

  screenWidth = args.width
  screenHeight = args.height
  littleEndian = args.little_endian
  unpackedOutput = args.unpacked

  print('Output format: {:d}x{:d}, {}-endian, {}'.format(screenWidth,
      screenHeight, 'little' if littleEndian else 'big',
      'unpacked' if unpackedOutput else 'packed'))

  # Read the input files.
  for name in args.input_files:
    print('Reading ' + name)
    readFile(open(name), name)

  # If we made it this far without erroring out, then we're good to dump the
  # actual disk image. masterOutput contains numbers, which I need to write out
  # as big-endian 16-bit values. Gaps in the array should be converted to 0s.
  out = open('disk.img', 'wb')
  i = 0
  topKey = 0;
  # Find the largest key in masterOutput.
  for k in masterOutput.keys():
    topKey = max(topKey, k)

  while i <= topKey:
    # Construct the value based on the unpacked vs. packed flag.
    if unpackedOutput:
      val = at(i)
      i += 1
    else:
      val = (at(i) << 8) | at(i + 1)
      i += 2

    out.write(struct.pack('<H' if littleEndian else '>H', val))

  out.close()

if __name__ == "__main__":
  main()
