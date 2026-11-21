#!/usr/bin/env python3
"""
Script to fix Flutter 3.27+ deprecation: withOpacity() -> withValues()
Converts: Color.withOpacity(0.5)
To:       Color.withValues(alpha: 0.5)
"""
import re
import sys
from pathlib import Path

def fix_with_opacity(content: str) -> tuple[str, int]:
    """Replace withOpacity with withValues. Returns (new_content, changes_count)"""
    # Pattern matches: .withOpacity(any_expression)
    # Handles: numbers, variables, ternary operators, method calls
    pattern = r'\.withOpacity\(([^)]+)\)'

    def replacement(match):
        opacity_value = match.group(1)
        return f'.withValues(alpha: {opacity_value})'

    new_content, count = re.subn(pattern, replacement, content)
    return new_content, count

def process_file(file_path: Path) -> int:
    """Process a single Dart file. Returns number of changes."""
    try:
        content = file_path.read_text(encoding='utf-8')
        new_content, changes = fix_with_opacity(content)

        if changes > 0:
            file_path.write_text(new_content, encoding='utf-8')
            print(f"[OK] {file_path.name}: {changes} changes")
            return changes
        else:
            print(f"[SKIP] {file_path.name}: no changes needed")
            return 0
    except Exception as e:
        print(f"[ERROR] {file_path.name}: {e}", file=sys.stderr)
        return 0

def main():
    files = [
        "lib/widgets/modern_button.dart",
        "lib/widgets/dashboard_card.dart",
        "lib/widgets/app_drawer.dart",
        "lib/theme/app_theme.dart",
        "lib/Screens/attendance_management_screen.dart",
        "lib/Screens/exams/doctor_exams_list_screen.dart",
        "lib/Screens/exams/exam_editor_screen.dart",
        "lib/Screens/exams/exam_result_screen.dart",
        "lib/Screens/exams/exam_results_doctor_screen.dart",
        "lib/Screens/exams/manager_exams_screen.dart",
        "lib/Screens/exams/question_editor_screen.dart",
        "lib/Screens/exams/student_exams_list_screen.dart",
        "lib/Screens/exams/student_submission_detail_screen.dart",
        "lib/Screens/exams/take_exam_screen.dart",
        "lib/Screens/manager_dashboard.dart",
        "lib/Screens/notifications_screen.dart",
        "lib/Screens/student_home_screen.dart",
        "lib/Screens/student_profile_screen.dart",
        "lib/Screens/student_results_screen.dart",
        "lib/Screens/subjects_groups_screen.dart",
        "lib/Screens/super_admin_dashboard.dart",
    ]

    root = Path("C:/Users/Disney/AndroidStudioProjects/Smart System10")
    total_changes = 0

    for file_rel in files:
        file_path = root / file_rel
        if file_path.exists():
            total_changes += process_file(file_path)
        else:
            print(f"[WARN] File not found: {file_rel}")

    print(f"\nTotal: {total_changes} replacements across {len(files)} files")

if __name__ == "__main__":
    main()
