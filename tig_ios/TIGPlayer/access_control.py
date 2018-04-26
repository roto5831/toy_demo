import os
import sys

restore = False

def fild_all_files(directory):
  for root, dirs, files in os.walk(directory):
    yield root
    for file in files:
      yield os.path.join(root, file)


def check_access_control(file):
  modify = False

  f = open(file)
  line = f.readline()
  text = line

  while line:
    line = f.readline()
    text += line

    if restore:
      if "@ACCESS_PUBLIC" in line:
        line = f.readline()
        line = line.replace('internal', 'public')
        text += line
        modify = True
        print line
      elif "@ACCESS_OPEN" in line:
        line = f.readline()
        line = line.replace('internal', 'open')
        text += line
        modify = True
        print line
    else:
      if "@ACCESS_PUBLIC" in line:
        line = f.readline()
        line = line.replace('public', 'internal')
        text += line
        modify = True
        print line
      elif "@ACCESS_OPEN" in line:
        line = f.readline()
        line = line.replace('open', 'internal')
        text += line
        modify = True
        print line
  f.close()

  if modify:
    f = open(file, 'w')
    f.write(text)
    f.close()


arguments = sys.argv
options = [option for option in arguments if option.startswith('-')]

if '--internal' in options:
  restore = False
if '--restore' in options:
  restore = True

for file in fild_all_files('.'):
  _root, _ext = os.path.splitext(file)
  if _ext == ".swift":
    check_access_control(file)
    print file



