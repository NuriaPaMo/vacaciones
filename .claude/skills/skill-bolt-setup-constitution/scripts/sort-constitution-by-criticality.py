#!/usr/bin/env python3
"""
sort-constitution-by-criticality.py

Sorts constitution articles by criticality (high, medium, low)

Usage:
    python sort-constitution-by-criticality.py <input-file> [output-file]

Example:
    python sort-constitution-by-criticality.py refinement-state.yaml
    python sort-constitution-by-criticality.py state.yaml sorted.yaml
"""

import sys
import os
from pathlib import Path
from typing import Any, Dict, List

try:
    import yaml
except ImportError:
    print("\033[0;31mError: PyYAML is not installed\033[0m")
    print("\033[1;33mInstall with: pip install pyyaml\033[0m")
    sys.exit(1)


# ANSI color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    GRAY = '\033[0;90m'
    NC = '\033[0m'  # No Color


def print_colored(message: str, color: str = Colors.NC):
    """Print a colored message."""
    print(f"{color}{message}{Colors.NC}")


def get_criticality_order(criticality: Any) -> int:
    """Return sort order for criticality level."""
    if criticality is None or not isinstance(criticality, str):
        return 999  # Unknown criticality goes to the end
    
    criticality_map = {
        'high': 1,
        'medium': 2,
        'low': 3
    }
    
    return criticality_map.get(criticality.lower(), 999)


def sort_articles(data: Dict[str, Any]) -> Dict[str, Any]:
    """Sort articles by criticality in place."""
    if 'constitution' not in data:
        raise ValueError("No 'constitution' key found in YAML")
    
    constitution = data['constitution']
    
    if 'articles' not in constitution or not constitution['articles']:
        print_colored("Warning: No articles found in constitution", Colors.YELLOW)
        return data
    
    articles = constitution['articles']
    article_count = len(articles)
    
    print_colored(f"Sorting {article_count} articles by criticality...", Colors.CYAN)
    
    # Sort articles by criticality
    sorted_articles = sorted(
        articles,
        key=lambda x: get_criticality_order(x.get('criticallity'))
    )
    
    # Replace articles with sorted version
    constitution['articles'] = sorted_articles
    
    return data


def count_by_criticality(articles: List[Dict[str, Any]]) -> Dict[str, int]:
    """Count articles by criticality level."""
    counts = {
        'high': 0,
        'medium': 0,
        'low': 0,
        'unknown': 0
    }
    
    for article in articles:
        crit = article.get('criticallity')
        if crit and isinstance(crit, str):
            crit_lower = crit.lower()
            if crit_lower in counts:
                counts[crit_lower] += 1
            else:
                counts['unknown'] += 1
        else:
            counts['unknown'] += 1
    
    return counts


def main():
    """Main entry point."""
    # Check arguments
    if len(sys.argv) < 2:
        print_colored("Error: Missing input file", Colors.RED)
        print(f"Usage: {sys.argv[0]} <input-file> [output-file]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Verify input file exists
    if not os.path.isfile(input_file):
        print_colored(f"Error: Input file not found: {input_file}", Colors.RED)
        sys.exit(1)
    
    # Determine output file
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    else:
        input_path = Path(input_file)
        output_file = str(input_path.parent / f"{input_path.stem}.sorted.yaml")
    
    print_colored(f"Reading YAML from: {input_file}", Colors.CYAN)
    
    # Read the YAML file
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print_colored(f"Error: Failed to parse YAML: {e}", Colors.RED)
        sys.exit(1)
    except Exception as e:
        print_colored(f"Error: Failed to read file: {e}", Colors.RED)
        sys.exit(1)
    
    # Sort articles
    try:
        sorted_data = sort_articles(data)
    except ValueError as e:
        print_colored(f"Error: {e}", Colors.RED)
        sys.exit(1)
    
    # Write sorted YAML
    print_colored(f"Writing sorted YAML to: {output_file}", Colors.CYAN)
    
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            yaml.safe_dump(
                sorted_data,
                f,
                default_flow_style=False,
                allow_unicode=True,
                sort_keys=False,
                indent=2
            )
    except Exception as e:
        print_colored(f"Error: Failed to write file: {e}", Colors.RED)
        sys.exit(1)
    
    # Print summary
    articles = sorted_data.get('constitution', {}).get('articles', [])
    counts = count_by_criticality(articles)
    
    print_colored("\nSorting complete!", Colors.GREEN)
    print_colored(f"  High:    {counts['high']} articles", Colors.RED)
    print_colored(f"  Medium:  {counts['medium']} articles", Colors.YELLOW)
    print_colored(f"  Low:     {counts['low']} articles", Colors.GRAY)
    
    if counts['unknown'] > 0:
        print_colored(f"  Unknown: {counts['unknown']} articles", Colors.MAGENTA)
    
    print_colored(f"\nOutput file: {output_file}", Colors.GREEN)


if __name__ == '__main__':
    main()
