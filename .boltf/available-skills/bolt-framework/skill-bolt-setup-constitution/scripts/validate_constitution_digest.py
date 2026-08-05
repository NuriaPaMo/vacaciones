#!/usr/bin/env python3
"""
Bolt Framework - Validate Constitution Digest
=============================================
Completeness gate for `.boltf/memory/constitution.digest.md`.

The digest is a condensed, decision-only view of the constitution that downstream agents
read by default (Tier 1). Because the constitution is the SINGLE SOURCE OF TRUTH, the digest
must never silently drop a binding decision. This script enforces that: every article with
`decision` in {include, modified} in `merged-refinement.yaml` must be represented in the digest.

The distillation itself is semantic (agent-generated, like `constitution.md`); this script only
verifies coverage — it does not generate anything.

Usage:
    python validate_constitution_digest.py [PROJECT_PATH]

Arguments:
    PROJECT_PATH    Path to Bolt Framework project (default: current directory)

Exit codes:
    0  digest covers every include/modified decision
    1  one or more binding decisions are missing from the digest
    2  input files missing / parse error
"""

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("[ERR] PyYAML not installed. Install with: pip install pyyaml")
    sys.exit(2)


class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'


def log_info(msg: str) -> None:
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {msg}")


def log_ok(msg: str) -> None:
    print(f"{Colors.GREEN}[OK]  {Colors.NC} {msg}")


def log_warn(msg: str) -> None:
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")


def log_err(msg: str) -> None:
    print(f"{Colors.RED}[ERR] {Colors.NC} {msg}")


INCLUDED = {"include", "modified"}


def collect_decisions(node, path_key=None, out=None):
    """Recursively find every dict that carries a `decision` field.

    Returns a list of (label, decision) where label is the best available identifier
    (article number, title, or the YAML key under which the node lives). Robust to the
    two shapes seen in practice: `constitution.articles[]` (number/title) and the
    `shared_platform`/scope maps keyed by topic name.
    """
    if out is None:
        out = []
    if isinstance(node, dict):
        if "decision" in node and isinstance(node.get("decision"), (str, type(None))):
            decision = (node.get("decision") or "").strip().lower()
            label = (
                node.get("number")
                or node.get("title")
                or node.get("name")
                or path_key
                or "<unnamed>"
            )
            out.append((str(label), decision))
        for key, value in node.items():
            if key in ("content", "modified_content", "reason"):
                continue  # free-text bodies, not nested decisions
            collect_decisions(value, path_key=key, out=out)
    elif isinstance(node, list):
        for item in node:
            collect_decisions(item, path_key=path_key, out=out)
    return out


def label_present(label: str, digest_text: str, digest_lower: str) -> bool:
    """Heuristic coverage check: does the digest reference this decision?"""
    label = label.strip()
    if not label or label == "<unnamed>":
        return True  # cannot check an anonymous node; don't fail the gate on it
    # Article number, e.g. "III" or "VIII-B" → look for "Article III" or the token.
    if re.fullmatch(r"[IVXLC]+(?:-[A-Z0-9]+)?", label):
        return bool(re.search(rf"\b{re.escape(label)}\b", digest_text))
    # Topic key like "cicd" / "configuration_management" → match words (underscores→spaces).
    # Compact form ignores punctuation so "cicd" matches "CI/CD" and "otel" matches "OTel".
    digest_compact = re.sub(r"[^a-z0-9]", "", digest_lower)
    words = [w for w in re.split(r"[_\s]+", label.lower()) if w]

    def word_ok(w: str) -> bool:
        w2 = re.sub(r"[^a-z0-9]", "", w)
        return bool(w2) and (w in digest_lower or w2 in digest_compact)

    return all(word_ok(w) for w in words)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the constitution digest for completeness.")
    parser.add_argument("project_path", nargs="?", default=".", help="Project root (default: .)")
    args = parser.parse_args()

    root = Path(args.project_path).resolve()
    merged = root / ".boltf" / "memory" / "refinement-states" / "merged-refinement.yaml"
    digest = root / ".boltf" / "memory" / "constitution.digest.md"

    if not merged.is_file():
        log_err(f"Missing merged refinement: {merged}")
        return 2
    if not digest.is_file():
        log_err(f"Missing digest: {digest}")
        return 2

    try:
        data = yaml.safe_load(merged.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        log_err(f"Failed to parse {merged}: {exc}")
        return 2

    digest_text = digest.read_text(encoding="utf-8")
    digest_lower = digest_text.lower()

    decisions = collect_decisions(data)
    binding = [(label, d) for label, d in decisions if d in INCLUDED]
    if not binding:
        log_warn("No include/modified decisions found in merged-refinement.yaml — nothing to check.")
        return 0

    missing = [label for label, _ in binding if not label_present(label, digest_text, digest_lower)]

    log_info(f"Binding decisions (include/modified): {len(binding)}")
    if missing:
        log_err(f"{len(missing)} binding decision(s) NOT represented in the digest:")
        for label in missing:
            print(f"        - {label}")
        log_err("Digest is INCOMPLETE — do not ship. Add the missing decisions.")
        return 1

    log_ok(f"Digest covers all {len(binding)} binding decisions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
