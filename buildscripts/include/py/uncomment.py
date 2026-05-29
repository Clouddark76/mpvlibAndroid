import re
import sys

with open(sys.argv[1], "r") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if not line.startswith("#") or line[1] in " \t\n" or re.match(sys.argv[2], line[1:]):
        continue
    if line.startswith("#*shared*"):
        continue
    if line.startswith("#*disabled*"):
        break
    lines[i] = line.lstrip("#")
    while lines[i].strip().endswith("\\"):
        i += 1
        lines[i] = lines[i].lstrip("#")

with open(sys.argv[1], "w") as f:
    f.writelines(lines)
