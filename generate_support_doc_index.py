"""
generate_support_doc_index.py
Scans all Lua files in the repository and generates/updates support-doc-index.csv
with one row per function found.

Columns: num | uid | filepath | filename | line-start | line-end | name | parameters | returns | description
"""

import os
import re
import csv

REPO_ROOT = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(REPO_ROOT, "support-doc-index.csv")
CSV_COLUMNS = ["num", "uid", "filepath", "filename", "line-start", "line-end",
               "name", "parameters", "returns", "description"]

# Matches all common Lua function declaration forms:
#   function Name(params)
#   local function Name(params)
#   function Table.Name(params)
#   function Table:Name(params)
#   function ENT:Name(params)
FUNC_RE = re.compile(
    r'^[ \t]*(?:local\s+)?function\s+([\w.:]+)\s*\(([^)]*)\)',
    re.MULTILINE
)

# Block-opening keywords that consume one matching `end`
BLOCK_OPEN_RE = re.compile(
    r'\bfunction\b|\bif\b|\bfor\b|\bwhile\b|\bdo\b'
)
BLOCK_CLOSE_RE = re.compile(r'\bend\b')
REPEAT_OPEN_RE = re.compile(r'\brepeat\b')
UNTIL_RE = re.compile(r'^\s*until\b')

# ZDEV UID comment: -- ZDEV_UID: ZDEV_FUNC_XXXXXXXX | Path: ...
UID_RE = re.compile(r'ZDEV_UID:\s*(ZDEV_FUNC_[0-9A-Fa-f]+)')

# @return / @param comment
RETURN_RE = re.compile(r'--\s*@return\s+(.*)')
PARAM_RE = re.compile(r'--\s*@param\b')

# Strip Lua string/comment tokens to avoid false-positive keyword matches
STRING_RE = re.compile(r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'|--.*')


def strip_strings_and_comments(line):
    """Remove string literals and line comments so keyword regexes don't match inside them."""
    return STRING_RE.sub('', line)


def find_function_end(lines, start_idx):
    """
    Given that lines[start_idx] contains a function declaration, return the
    0-based index of the line containing the matching `end`.
    """
    depth = 0
    for i, raw_line in enumerate(lines[start_idx:], start=start_idx):
        line = strip_strings_and_comments(raw_line)

        # Count block openers on this line
        opens = len(BLOCK_OPEN_RE.findall(line))
        closes = len(BLOCK_CLOSE_RE.findall(line))
        repeats = len(REPEAT_OPEN_RE.findall(line))
        untils = 1 if UNTIL_RE.match(line) else 0

        # `repeat` blocks close with `until` instead of `end`
        depth += opens + repeats - closes - untils

        if i == start_idx:
            # depth must be at least 1 after the function line itself
            if depth < 1:
                depth = 1
            continue

        if depth <= 0:
            return i

    # Fallback: end of file
    return len(lines) - 1


def collect_preceding_comments(lines, func_idx):
    """
    Walk backwards from func_idx to collect consecutive comment lines that
    immediately precede the function declaration.
    Returns (uid, description, returns).
    """
    uid = ""
    description_parts = []
    returns_parts = []

    idx = func_idx - 1
    comment_lines = []
    while idx >= 0:
        stripped = lines[idx].strip()
        if stripped.startswith("--"):
            comment_lines.insert(0, (idx, stripped))
            idx -= 1
        else:
            break

    for _, text in comment_lines:
        uid_match = UID_RE.search(text)
        if uid_match:
            uid = uid_match.group(1)
            continue

        ret_match = RETURN_RE.search(text)
        if ret_match:
            returns_parts.append(ret_match.group(1).strip())
            continue

        # Skip @param lines (don't bleed into description)
        if PARAM_RE.search(text):
            continue

        # Skip divider lines like ----- or ====
        if re.match(r'^-{3,}$|^={3,}$', text.lstrip('-').strip()):
            continue

        # Treat as description; strip leading -- and whitespace
        desc_text = re.sub(r'^---?\s*', '', text).strip()
        if desc_text:
            description_parts.append(desc_text)

    description = " ".join(description_parts)
    returns = "; ".join(returns_parts)
    return uid, description, returns


def parse_lua_file(filepath):
    """
    Parse a single Lua file and return a list of dicts, one per function.
    """
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    lines = content.splitlines()
    results = []

    for match in FUNC_RE.finditer(content):
        func_name = match.group(1)
        params_raw = match.group(2).strip()
        # Normalize params: collapse whitespace
        params = re.sub(r'\s+', ' ', params_raw)

        # Determine which line (0-based) the function starts on
        line_start_0 = content[:match.start()].count('\n')
        line_end_0 = find_function_end(lines, line_start_0)

        uid, description, returns = collect_preceding_comments(lines, line_start_0)

        results.append({
            "uid": uid,
            "name": func_name,
            "parameters": params,
            "returns": returns,
            "description": description,
            "line_start": line_start_0 + 1,   # 1-based for humans
            "line_end": line_end_0 + 1,
        })

    return results


def load_existing_csv():
    """Load existing CSV rows keyed by (filepath, line-start)."""
    existing = {}
    if not os.path.exists(CSV_PATH):
        return existing
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="|")
        for row in reader:
            key = (row.get("filepath", "").strip(), row.get("line-start", "").strip())
            existing[key] = row
    return existing


def find_lua_files(root):
    """Recursively yield all .lua files under root."""
    for dirpath, _, filenames in os.walk(root):
        # Skip hidden directories (e.g. .git)
        dirpath_parts = dirpath.replace(root, "").split(os.sep)
        if any(part.startswith(".") for part in dirpath_parts):
            continue
        for fname in filenames:
            if fname.endswith(".lua"):
                yield os.path.join(dirpath, fname)


def main():
    lua_files = sorted(find_lua_files(REPO_ROOT))
    existing = load_existing_csv()

    # Collect all new rows (keyed to avoid duplicates within this run)
    new_rows = {}  # key: (rel_filepath, line_start) -> row dict

    for abs_path in lua_files:
        rel_path = os.path.relpath(abs_path, REPO_ROOT).replace(os.sep, "/")
        filename = os.path.basename(abs_path)

        try:
            funcs = parse_lua_file(abs_path)
        except Exception as exc:
            print(f"  [WARN] Could not parse {rel_path}: {exc}")
            continue

        for func in funcs:
            key = (rel_path, str(func["line_start"]))
            new_rows[key] = {
                "filepath": rel_path,
                "filename": filename,
                "line-start": func["line_start"],
                "line-end": func["line_end"],
                "name": func["name"],
                "parameters": func["parameters"],
                "returns": func["returns"],
                "description": func["description"],
                "uid": func["uid"],
            }

    # Merge: existing rows that are still valid get updated; truly new ones are added
    merged = {}
    for key, row in existing.items():
        if key in new_rows:
            # Update with freshly parsed data but preserve num
            updated = new_rows[key].copy()
            updated["num"] = row.get("num", "")
            merged[key] = updated
        else:
            # Keep rows from old files that may no longer exist (or that we couldn't parse)
            merged[key] = row

    for key, row in new_rows.items():
        if key not in merged:
            merged[key] = row

    # Sort rows: by filepath then line-start
    def sort_key(item):
        fp, ls = item[0]
        try:
            ls_int = int(ls)
        except (ValueError, TypeError):
            ls_int = 0
        return (fp, ls_int)

    sorted_rows = sorted(merged.items(), key=sort_key)

    # Assign sequential row numbers
    final_rows = []
    for num, (_, row) in enumerate(sorted_rows, start=1):
        row["num"] = num
        final_rows.append(row)

    # Write CSV
    with open(CSV_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS, delimiter="|",
                                extrasaction="ignore")
        writer.writeheader()
        writer.writerows(final_rows)

    print(f"Done. Wrote {len(final_rows)} function entries to {CSV_PATH}")


if __name__ == "__main__":
    main()
