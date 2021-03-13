#!/usr/bin/env python
import sys
from xml.dom import minidom
from urllib.parse import unquote

PLAYLIST = open(sys.argv[1:][0], 'rb')


XMLDOC = minidom.parse(PLAYLIST)
PATHS = XMLDOC.getElementsByTagName('location')

for path in PATHS:
  uri = path.firstChild.nodeValue.replace('file://', '')
  uri = uri.replace('file://', '')
  uri = unquote(uri)
  sys.stdout.buffer.write(bytes(uri, 'utf-8'))
  sys.stdout.buffer.write(bytes([0x00]))
