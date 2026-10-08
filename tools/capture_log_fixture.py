#!/usr/bin/env python3
"""Normalize wand results from an advanced text log into a small test fixture.

The text log includes advanced unit data and originalAmount, which do not
appear at the same positions in CombatLogGetCurrentEventInfo's Lua payload.
Only event, actual damage school, amount, resisted amount and critical/miss
flags are retained. Shoot's spell school is not its actual damage school.
"""
import argparse
from collections import Counter
import csv
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('log', type=Path)
parser.add_argument('--character', default='Gabbaophant')
args = parser.parse_args()
lines = []
counts = Counter(hit=0, crit=0, resist=0, miss=0, absorb=0)
with args.log.open(errors='replace') as log:
    for line in log:
        if args.character.lower() not in line.lower() or '  ' not in line:
            continue
        fields = next(csv.reader([line.rstrip().split('  ', 1)[1]]))
        if len(fields) < 12 or fields[2].split('-')[0].lower() != args.character.lower() or fields[9] != '5019':
            continue
        if fields[0] == 'RANGE_DAMAGE':
            tail = fields[-11:]
            critical = tail[7] in ('1', 'true')
            counts['crit' if critical else 'hit'] += 1
            lines.append('        { event = "RANGE_DAMAGE", school = %s, amount = %s, resisted = %s, critical = %s },' % (int(tail[3], 0), int(tail[0]), int(tail[4]), 'true' if critical else 'false'))
        elif fields[0] == 'RANGE_MISSED':
            miss_type = fields[12]
            counts['resist' if miss_type == 'RESIST' else 'absorb' if miss_type == 'ABSORB' else 'miss'] += 1
            lines.append('        { event = "RANGE_MISSED", missType = "%s" },' % miss_type)
if not lines or not all(counts[key] > 0 for key in ('hit', 'crit', 'resist')):
    raise SystemExit('A useful fixture needs normal hits, critical hits and full resistance.')
output = Path(__file__).resolve().parents[1] / 'tests/fixtures/gabbaophant_wand.lua'
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text('-- Normalized from %s; character: %s.\nreturn {\n    expected = { hit = %d, crit = %d, resist = %d, miss = %d, absorb = %d },\n    events = {\n%s\n    },\n}\n' % (args.log.name, args.character, counts['hit'], counts['crit'], counts['resist'], counts['miss'], counts['absorb'], '\n'.join(lines)))
print('Captured', dict(counts), 'in', output)
