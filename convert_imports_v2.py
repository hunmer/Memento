#!/usr/bin/env python3
"""
Dart Import Converter - Convert relative imports to package imports
"""

import os
import re
import sys
import csv
from pathlib import Path
from typing import List, Tuple, Optional


class DartImportConverter:
    def __init__(self, package_name: str = "Memento"):
        self.package_name = package_name
        self.changes = []

    def convert_relative_to_package_import(self, import_line: str, current_file: str) -> Optional[Tuple[str, str]]:
        """Convert relative import to package import"""
        pattern = r"import\s+['\"]((\.\./)+[^'\"]+)['\"];"

        match = re.match(pattern, import_line.strip())
        if not match:
            return None

        relative_path = match.group(1)

        # Get current file path relative to lib/
        current_path = Path(current_file)
        try:
            lib_idx = current_path.parts.index('lib')
        except ValueError:
            return None

        # Current file directory parts relative to lib/ (exclude filename)
        file_parts = list(current_path.parts[lib_idx + 1:-1])  # Exclude the filename

        # Parse relative path
        remaining_parts = []
        temp_path = relative_path

        # Process ../ components
        while temp_path.startswith('../'):
            temp_path = temp_path[3:]  # Remove '../'
            if file_parts:
                file_parts.pop()  # Go up one level
            else:
                # Can't go up further
                return None

        # Add remaining path parts
        if temp_path:
            remaining_parts = temp_path.split('/')

        # Build final path
        final_parts = file_parts + remaining_parts
        package_path = '/'.join(final_parts)

        new_import = f"import 'package:{self.package_name}/{package_path}';"
        conversion_note = f"{import_line.strip()} -> {new_import}"

        return new_import, conversion_note

    def process_dart_file(self, file_path: str, dry_run: bool = True) -> bool:
        """Process a single Dart file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            lines = content.split('\n')
            new_lines = []
            modified = False

            for line_num, line in enumerate(lines, 1):
                result = self.convert_relative_to_package_import(line, file_path)
                if result:
                    new_import, conversion_note = result
                    self.changes.append({
                        'file': file_path,
                        'line': line_num,
                        'old': line.strip(),
                        'new': new_import,
                        'note': conversion_note
                    })

                    if not dry_run:
                        new_lines.append(new_import)
                    else:
                        new_lines.append(line)
                    modified = True
                else:
                    new_lines.append(line)

            if modified and not dry_run:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write('\n'.join(new_lines))

            return modified

        except Exception as e:
            print(f"Error processing {file_path}: {e}", file=sys.stderr)
            return False

    def find_dart_files(self, lib_dir: str = "lib") -> List[str]:
        """Find all Dart files"""
        dart_files = []
        if not os.path.exists(lib_dir):
            print(f"Directory {lib_dir} does not exist", file=sys.stderr)
            return dart_files

        for root, dirs, files in os.walk(lib_dir):
            for file in files:
                if file.endswith('.dart'):
                    dart_files.append(os.path.join(root, file))

        return dart_files

    def export_changes_to_csv(self, filename: str = "import_changes.csv"):
        """Export all changes to CSV file"""
        if not self.changes:
            print("No changes to export")
            return

        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['file', 'line', 'old_import', 'new_import', 'conversion_note']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

            writer.writeheader()
            for change in self.changes:
                writer.writerow({
                    'file': change['file'],
                    'line': change['line'],
                    'old_import': change['old'],
                    'new_import': change['new'],
                    'conversion_note': change['note']
                })

        print(f"Changes exported to: {filename}")

    def run(self, dry_run: bool = True, export_csv: bool = False):
        """Execute conversion"""
        print("=" * 70)
        print("Dart Import Converter")
        print(f"Package Name: {self.package_name}")
        print(f"Mode: {'DRY RUN (preview only)' if dry_run else 'APPLY CHANGES'}")
        print("=" * 70)
        print()

        dart_files = self.find_dart_files("lib")
        print(f"Found {len(dart_files)} Dart files\n")

        total_files_modified = 0
        for file_path in dart_files:
            if self.process_dart_file(file_path, dry_run):
                total_files_modified += 1

        print("\n" + "=" * 70)
        print("Summary:")
        print(f"  Files scanned: {len(dart_files)}")
        print(f"  Files to modify: {total_files_modified}")
        print(f"  Total conversions: {len(self.changes)}")

        if export_csv:
            self.export_changes_to_csv()

        if self.changes:
            print("\n" + "=" * 70)
            print("Sample conversions (first 20):")
            print("=" * 70)

            for i, change in enumerate(self.changes[:20], 1):
                print(f"\n[{i}] File: {change['file']}")
                print(f"    Line: {change['line']}")
                print(f"    {change['note']}")

            if len(self.changes) > 20:
                print(f"\n    ... and {len(self.changes) - 20} more conversions")
                print(f"    Use --export-csv to export all changes to CSV")

            print("\n" + "=" * 70)
            if dry_run:
                print("[WARN]  DRY RUN MODE - No files were modified")
                print("       Use --apply to actually modify files")
            else:
                print("[OK]    All files have been modified successfully")
        else:
            print("\n[OK]    All files already use correct package imports")


def print_help():
    print("""
Dart Import Converter
Usage:
  python convert_imports_v2.py [--help] [--apply] [--export-csv] [--package-name NAME]

Options:
  --help, -h          Show this help message
  --apply             Apply changes (default is preview only)
  --export-csv        Export all changes to CSV file
  --package-name NAME Specify package name (default: Memento)

Examples:
  python convert_imports_v2.py                    # Preview mode
  python convert_imports_v2.py --apply            # Apply changes
  python convert_imports_v2.py --export-csv       # Export to CSV
  python convert_imports_v2.py --package-name my_app  # Custom package name
""")


def main():
    dry_run = True
    export_csv = False
    package_name = "Memento"

    args = sys.argv[1:]
    if '--help' in args or '-h' in args:
        print_help()
        return

    if '--apply' in args:
        dry_run = False

    if '--export-csv' in args:
        export_csv = True

    try:
        idx = args.index('--package-name')
        if idx + 1 < len(args):
            package_name = args[idx + 1]
    except ValueError:
        pass

    converter = DartImportConverter(package_name=package_name)
    converter.run(dry_run=dry_run, export_csv=export_csv)


if __name__ == "__main__":
    main()
