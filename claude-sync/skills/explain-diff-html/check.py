#!/usr/bin/env python3
"""Structural check for generated explanation pages.

Catches the two defects that silently kill the interactive quiz:
  1. A duplicate id -- getElementById returns the FIRST match in document
     order, so a TOC anchor <h2 id="quiz"> beats the mount <div id="quiz">
     and the questions render inside the heading.
  2. A script looking up an id no element has -- one null dereference at the
     top of an IIFE kills every feature below it.

Usage: python3 check.py <file.html>
"""
import re
import sys
from collections import Counter

# ponytail: static scan. Ids created at runtime by JS read as dangling.
# If that ever comes up, exempt them by giving the element a real id in markup.


def check(html):
    ids = re.findall(r'\bid=["\']([^"\']+)["\']', html)
    lookups = set(re.findall(r'getElementById\(\s*["\']([^"\']+)["\']', html))
    lookups |= set(re.findall(r'querySelector(?:All)?\(\s*["\']#([\w-]+)', html))

    problems = [
        'duplicate id="%s" -- give the JS mount its own id (e.g. "%s-app")' % (i, i)
        for i, n in sorted(Counter(ids).items())
        if n > 1
    ]
    problems += [
        "script looks up #%s, which no element has" % i
        for i in sorted(lookups - set(ids))
    ]
    if not re.search(r'<meta\s+charset', html, re.I):
        problems.append(
            'no <meta charset="utf-8"> -- em dashes and arrows render as mojibake'
        )
    return problems, len(set(ids)), len(lookups)


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[-1])
        return 2
    with open(sys.argv[1], encoding="utf-8") as f:
        problems, n_ids, n_lookups = check(f.read())
    for p in problems:
        print(p)
    if problems:
        return 1
    print("ok: %d unique ids, %d script lookups all resolve" % (n_ids, n_lookups))
    return 0


def _self_test():
    bad = '<h2 id="quiz">Q</h2><div id="quiz"></div><script>getElementById("gone")</script>'
    problems, _, _ = check(bad)
    assert len(problems) == 3, problems
    assert 'duplicate id="quiz"' in problems[0]
    assert "#gone" in problems[1]
    assert "meta charset" in problems[2]
    good = (
        '<meta charset="utf-8"><h2 id="quiz">Q</h2><div id="quiz-app"></div>'
        '<script>getElementById("quiz-app")</script>'
    )
    assert check(good)[0] == [], check(good)[0]
    print("self-test ok")


if __name__ == "__main__":
    sys.exit(_self_test() if "--self-test" in sys.argv else main())
