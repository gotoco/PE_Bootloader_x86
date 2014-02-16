#!/usr/bin/python
# coding=utf-8
import os
import struct

def ReadFile(fname):
  with open(fname, "rb") as f:
    data = f.read()
  return data

def WriteFile(fname, data):
  with open(fname, "wb") as f:
    f.write(data)

# Find DWORD value 
# and replace it.
def ChangeMagicDWORD(s, magic, val):
  mbytes = struct.pack("<I", magic)
  count = s.count(mbytes)

  if count == 0:
    print "error: Could not find magic %.8x!" % magic
    sys.exit(1)

  if count > 1:
    print "error: Ambiguous magic %.8x!" % magic
    sys.exit(1)

  idx = s.find(mbytes)

  vbytes = struct.pack("<I", val)

  return s[:idx] + vbytes + s[idx + len(vbytes):]

# Load Followed binary files.
img_stage1pxe = ReadFile("Stage1PXE")
img_stage1fdd = ReadFile("Stage1FDD")
img_stage2    = ReadFile("Stage2")
img_kernel    = ReadFile("kernel.exe")

# Make an image of a floppy disk.
part2_size = len(img_stage2) + len(img_kernel)
part2_size = (part2_size + 0x1ff) & ~0x1ff

img_stage1fdd = ChangeMagicDWORD(
    img_stage1fdd, 0xbaadc0d3, part2_size)

img_fdd = img_stage1fdd + img_stage2 + img_kernel
img_fdd += "\0" * (1440 * 1024 - len(img_fdd))
     
WriteFile("os_fdd.img", img_fdd)

# Combine the image for PXE.
part2_size = len(img_stage2) + len(img_kernel)

img_stage1pxe = ChangeMagicDWORD(
    img_stage1pxe, 0xbaadc0d3, part2_size)

img_pxe = img_stage1pxe + img_stage2 + img_kernel

WriteFile("os_pxe.img", img_pxe)

print "Done."

