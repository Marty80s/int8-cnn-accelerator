#!/usr/bin/env python3
"""Create the project-local BUFX2 site correction from an installed GSCLIB LEF."""
import argparse
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
parser.add_argument("destination", type=Path)
args = parser.parse_args()
if args.source.resolve() == args.destination.resolve():
    parser.error("Source and destination must differ")
text = args.source.read_text()
match = re.search(r"(?ms)^MACRO BUFX2\s*\n.*?^END BUFX2\s*$", text)
if not match:
    parser.error("BUFX2 macro not found")
block = match.group()
if not re.search(r"SIZE\s+1\s+BY\s+1\.71\s*;", block):
    parser.error("Unexpected BUFX2 dimensions; review this library version")
if block.count("SITE CoreSiteDouble ;") != 1:
    parser.error("Expected exactly one BUFX2 CoreSiteDouble declaration")
fixed = block.replace("SITE CoreSiteDouble ;", "SITE CoreSite ;")
args.destination.parent.mkdir(parents=True, exist_ok=True)
with args.destination.open("x") as output:
    output.write(text[:match.start()] + fixed + text[match.end():])
print("Created", args.destination)
