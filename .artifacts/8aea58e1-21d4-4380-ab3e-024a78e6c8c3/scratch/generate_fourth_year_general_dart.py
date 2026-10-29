import openpyxl

wb = openpyxl.load_workbook(r'C:\Users\Disney\Downloads\الفرقة_الرابعة.xlsx')
sheet = wb['الرابعة - المحاسبة والمراجعة']
students = []
for i in range(2, sheet.max_row + 1):
    row = [cell.value for cell in sheet[i]]
    if not any(row):
        continue
    _, code, name, level, division = row
    if code is not None and name is not None:
        c_str = str(code).strip()
        n_str = str(name).strip()
        d_str = str(division).strip() if division else "المحاسبة والمراجعة"
        students.append((c_str, n_str, d_str))

dart_code = f"""// Generated automatically from official Excel sheet
class FourthYearGeneralStudents {{
  static const List<Map<String, String>> list = [
"""
for c, n, d in students:
    dart_code += f"    {{'id': '{c}', 'name': '{n}', 'division': '{d}'}},\n"
dart_code += """  ];
}
"""

file_path = r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/fourth_year_general_students_data.dart'
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(dart_code)
print(f"Generated {file_path} with {len(students)} students.")
