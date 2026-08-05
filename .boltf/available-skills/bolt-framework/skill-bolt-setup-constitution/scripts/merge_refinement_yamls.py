#!/usr/bin/env python3
"""
Bolt Framework - Merge Refinement YAMLs
========================================
Merge all scope refinement YAML files into a single merged-refinement.yaml

Usage:
    python merge_refinement_yamls.py [PROJECT_PATH] [--force]

Arguments:
    PROJECT_PATH    Path to Bolt Framework project (default: current directory)
    --force, -f     Overwrite existing merged-refinement.yaml without prompting
"""

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List

try:
    import yaml
except ImportError:
    print("[ERR] PyYAML not installed. Install with: pip install pyyaml")
    sys.exit(1)


# === Color Output ============================================================

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color


def log_info(msg: str) -> None:
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {msg}")


def log_success(msg: str) -> None:
    print(f"{Colors.GREEN}[OK]  {Colors.NC} {msg}")


def log_warn(msg: str) -> None:
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")


def log_error(msg: str) -> None:
    print(f"{Colors.RED}[ERR] {Colors.NC} {msg}")


# === YAML Utilities ==========================================================

def load_yaml_file(file_path: Path) -> Dict[str, Any]:
    """Load and parse a YAML file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        log_error(f"Failed to load {file_path.name}: {e}")
        return {}


def save_yaml_file(file_path: Path, data: Dict[str, Any]) -> None:
    """Save data to a YAML file with custom formatting."""
    separator = f"# {'=' * 77}\n"
    with open(file_path, 'w', encoding='utf-8') as f:
        # Write header
        f.write(separator)
        f.write("# Bolt Framework - Merged Refinement State\n")
        f.write(f"# Generated: {data['merge_timestamp']}\n")
        f.write(separator)
        f.write("# This file contains the merged refinement decisions from all active scopes.\n")
        f.write("# Used by constitution generation phase to create the final constitution.md\n")
        f.write(f"{separator}\n")

        # Write summary statistics
        f.write("# Summary Statistics\n")
        f.write(f"total_scopes: {data['total_scopes']}\n")
        f.write(f"total_articles: {data['total_articles']}\n")
        f.write(f"total_decisions: {data['total_decisions']}\n")
        f.write(f"merge_timestamp: {data['merge_timestamp']}\n")
        f.write(f"has_conflicts: {str(data['has_conflicts']).lower()}\n\n")

        # Write scopes
        f.write("# Scopes\n")
        f.write("scopes:\n")
        for scope in data['scopes']:
            f.write(f"\n  - scope: {scope['scope']}\n")
            f.write(f"    articles_count: {scope['articles_count']}\n")
            f.write(f"    decisions_count: {scope['decisions_count']}\n")
            f.write(f"    source_file: {scope['source_file']}\n")

        # Write conflicts if any
        if data.get('conflicts'):
            f.write("\n# Conflicts (articles appearing in multiple scopes)\n")
            f.write("conflicts:\n")
            for conflict in data['conflicts']:
                f.write(f"  - article: \"{conflict['article']}\"\n")
                f.write(f"    scopes: [{', '.join(conflict['scopes'])}]\n")
                f.write(f"    resolution: {conflict['resolution']}\n")

        # Write detailed scope data
        f.write(f"\n{separator}")
        f.write("# Detailed Scope Data\n")
        f.write(separator)
        f.write("# Each scope's full refinement data is preserved below for reference.\n")
        f.write("# The constitution generator will merge these based on the summary above.\n")
        f.write(f"{separator}\n")
        f.write("scope_data:\n")

        for scope_name, scope_content in data.get('scope_data', {}).items():
            f.write(f"\n  # Scope: {scope_name}\n")
            f.write(f"  {scope_name}:\n")

            # Write indented YAML content
            yaml_str = yaml.dump(scope_content, default_flow_style=False, allow_unicode=True)
            for line in yaml_str.split('\n'):
                if line.strip():  # Skip empty lines
                    f.write(f"    {line}\n")


# === Article Conflict Detection ==============================================

def extract_articles(data: Dict[str, Any]) -> List[str]:
    """Extract article IDs from refinement data."""
    articles = []

    if not data:
        return articles

    # Navigate structure: constitution -> articles
    constitution = data.get('constitution', {})
    if isinstance(constitution, dict):
        articles_list = constitution.get('articles', [])
        if isinstance(articles_list, list):
            for article in articles_list:
                if isinstance(article, dict) and 'article' in article:
                    articles.append(article['article'])

    return articles


def detect_conflicts(scope_data: Dict[str, Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Detect articles that appear in multiple scopes."""
    article_registry = {}

    # Build registry of articles and their scopes
    for scope_name, data in scope_data.items():
        articles = extract_articles(data)
        for article_id in articles:
            if article_id not in article_registry:
                article_registry[article_id] = []
            article_registry[article_id].append(scope_name)

    # Identify conflicts
    conflicts = []
    for article_id, scopes in article_registry.items():
        if len(scopes) > 1:
            conflicts.append({
                'article': article_id,
                'scopes': scopes,
                'resolution': 'pending'
            })

    return conflicts


# === Main Merge Logic ========================================================

def merge_refinement_files(project_path: Path, force: bool = False) -> int:
    """
    Merge all scope refinement YAML files.

    Returns:
        0 on success, non-zero on error
    """
    log_info("Bolt Framework - Merge Refinement YAMLs v1.0.0")
    log_info(f"Project path: {project_path}")
    print()

    # Validate project path
    if not project_path.exists():
        log_error(f"Project path does not exist: {project_path}")
        return 1

    refinement_dir = project_path / ".boltf" / "memory" / "refinement-states"

    if not refinement_dir.exists():
        log_error(f"Refinement states directory not found: {refinement_dir}")
        log_error("Run constitution refinement first")
        return 1

    # Find all scope refinement files (exclude merged-refinement.yaml)
    refinement_files = [
        f for f in refinement_dir.glob("*-refinement.yaml")
        if f.name != "merged-refinement.yaml"
    ]

    if not refinement_files:
        log_error(f"No refinement YAML files found in: {refinement_dir}")
        return 1

    log_info(f"Found {len(refinement_files)} scope refinement file(s):")
    for file in refinement_files:
        log_info(f"  • {file.name}")
    print()

    # Check if merged file already exists
    merged_path = refinement_dir / "merged-refinement.yaml"
    if merged_path.exists() and not force:
        log_warn("merged-refinement.yaml already exists")
        response = input("Overwrite? (y/N) ").strip().lower()
        if response != 'y':
            log_info("Merge cancelled")
            return 0

    # === Load and merge all refinement files =================================

    log_info("Loading and merging refinement files...")

    merged_data = {
        'scopes': [],
        'total_scopes': 0,
        'total_articles': 0,
        'total_decisions': 0,
        'merge_timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'has_conflicts': False,
        'conflicts': [],
        'scope_data': {}
    }

    for file in refinement_files:
        scope_name = file.stem.replace('-refinement', '')
        log_info(f"Processing scope: {scope_name}")

        # Load scope data
        scope_data = load_yaml_file(file)

        if not scope_data:
            log_warn(f"  Skipping empty or invalid file: {file.name}")
            continue

        # Count articles and decisions
        articles = extract_articles(scope_data)
        article_count = len(articles)

        # Count decisions (articles with non-null decisions field)
        decision_count = 0
        constitution = scope_data.get('constitution', {})
        if isinstance(constitution, dict):
            articles_list = constitution.get('articles', [])
            if isinstance(articles_list, list):
                decision_count = sum(
                    1 for a in articles_list
                    if isinstance(a, dict) and a.get('decisions')
                )

        # Add scope entry
        scope_entry = {
            'scope': scope_name,
            'articles_count': article_count,
            'decisions_count': decision_count,
            'source_file': f"{scope_name}-refinement.yaml"
        }

        merged_data['scopes'].append(scope_entry)
        merged_data['total_articles'] += article_count
        merged_data['total_decisions'] += decision_count
        merged_data['scope_data'][scope_name] = scope_data

        log_success(f"  Added {article_count} articles, {decision_count} decisions")

    merged_data['total_scopes'] = len(merged_data['scopes'])

    # === Detect conflicts ====================================================

    print()
    log_info("Detecting conflicts...")

    conflicts = detect_conflicts(merged_data['scope_data'])
    merged_data['conflicts'] = conflicts
    merged_data['has_conflicts'] = len(conflicts) > 0

    if conflicts:
        for conflict in conflicts:
            scopes_str = ', '.join(conflict['scopes'])
            log_warn(f"  Conflict: {conflict['article']} appears in: {scopes_str}")
    else:
        log_success("No conflicts detected")

    # === Write merged YAML ===================================================

    print()
    log_info("Writing merged-refinement.yaml...")

    try:
        save_yaml_file(merged_path, merged_data)
        log_success("Merged refinement file created: merged-refinement.yaml")
    except Exception as e:
        log_error(f"Failed to write merged file: {e}")
        return 1

    print()
    log_info("Summary:")
    log_info(f"  • Scopes merged: {merged_data['total_scopes']}")
    log_info(f"  • Total articles: {merged_data['total_articles']}")
    log_info(f"  • Total decisions: {merged_data['total_decisions']}")
    log_info(f"  • Conflicts detected: {len(conflicts)}")
    print()
    log_success("Merge complete!")

    return 0


# === CLI Entry Point =========================================================

def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Merge all scope refinement YAML files into merged-refinement.yaml'
    )
    parser.add_argument(
        'project_path',
        nargs='?',
        default='.',
        help='Path to Bolt Framework project (default: current directory)'
    )
    parser.add_argument(
        '--force', '-f',
        action='store_true',
        help='Overwrite existing merged-refinement.yaml without prompting'
    )

    args = parser.parse_args()
    # Type assertion to help type checker
    project_path_str: str = args.project_path
    force_flag: bool = args.force
    project_path = Path(project_path_str).resolve()

    return merge_refinement_files(project_path, force_flag)


if __name__ == '__main__':
    sys.exit(main())
