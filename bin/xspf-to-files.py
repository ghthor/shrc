#!/usr/bin/env python
import os
import sys
import shutil
from xml.dom import minidom
from urllib.parse import unquote

playlist = open(sys.argv[1:][0], 'rb')


xmldoc = minidom.parse(playlist)
paths = xmldoc.getElementsByTagName('location')

for path in paths:
  uri = path.firstChild.nodeValue.replace('file://', '')
  uri = uri.replace('file://', '')
  uri = unquote(uri)
  sys.stdout.buffer.write(bytes(uri, 'utf-8'))
  sys.stdout.buffer.write(bytes([0x00]))
