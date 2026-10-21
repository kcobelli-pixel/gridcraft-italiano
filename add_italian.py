"""Wire the Italian catalog (it.rs) into a GridCraft checkout's i18n.rs.

usage: python3 -I add_italian.py <gridcraft checkout> <it.rs>
exit: 0 wired, 3 upstream already ships Italian (nothing changed), 1 an anchor is missing (fail CI).
Anchors are the English entries, which upstream never removes; the switcher order comes from ALL.
Tests and help strings are left alone: keys missing from it.rs simply show in English.
"""
import re
import shutil
import sys
from pathlib import Path

UPSTREAM_HAS_IT = 3


def insert_after(src, anchor_re, line, what):
    """Insert `line` after the single line matching `anchor_re`, with the anchor's indent."""
    hits = list(re.finditer(r'^([ \t]*)' + anchor_re + r'[^\n]*\n', src, re.M))
    if len(hits) != 1:
        sys.exit(f'{what}: expected 1 anchor matching {anchor_re!r}, found {len(hits)}')
    m = hits[0]
    return src[:m.end()] + m.group(1) + line + '\n' + src[m.end():]


def wire(src):
    src = insert_after(src, r'mod fr;', 'mod it;', 'mod')
    enum = re.search(r'(pub enum Language \{.*?)(\n\})', src, re.S)
    if not enum:
        sys.exit('enum Language not found')
    body = enum.group(1).rstrip()
    sep = '' if body.endswith((',', '{')) else ','
    src = src[:enum.start(1)] + body + sep + '\n    It,' + src[enum.end(1):]
    all_ = re.search(r'pub const ALL: \[Self; (\d+)\] =(\s*)\[(.*?)\];', src, re.S)
    if not all_:
        sys.exit('Language::ALL not found')
    items = all_.group(3).rstrip().rstrip(',')
    src = src[:all_.start()] + f'pub const ALL: [Self; {int(all_.group(1)) + 1}] ={all_.group(2)}[{items}, Self::It];' + src[all_.end():]
    src = insert_after(src, r'Self::En => "English",', 'Self::It => "Italiano",', 'name()')
    src = insert_after(src, r'Self::En => "en",', 'Self::It => "it",', 'code()')
    src = insert_after(src, r'"en" => Some\(Self::En\),', '"it" => Some(Self::It),', 'from_tag()')
    src = insert_after(src, r'Self::En => None,', 'Self::It => it::translate(text),', 'tr()')
    return src


def main(repo, it_rs):
    i18n = Path(repo) / 'crates/ui-egui/src/i18n.rs'
    src = i18n.read_text(encoding='utf-8')
    if re.search(r'^\s*mod it;|"it" => Some\(', src, re.M):
        print('upstream already ships Italian: nothing to do')
        sys.exit(UPSTREAM_HAS_IT)
    if (i18n.parent / 'i18n/it.rs').exists():
        sys.exit('upstream has an i18n/it.rs that i18n.rs does not use yet: check it by hand')
    out = wire(src)
    if out.count('Self::It') != 5 or out.count('mod it;') != 1 or not re.search(r'^\s*It,$', out, re.M):
        sys.exit('self-check failed: every site must be wired exactly once')
    i18n.write_text(out, encoding='utf-8')
    shutil.copyfile(it_rs, i18n.parent / 'i18n/it.rs')
    print('Italian wired')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(*sys.argv[1:3])
