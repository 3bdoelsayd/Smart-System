import openpyxl

excel_path = r'C:\Users\Disney\Downloads\كشف_حضور_الفرقة_الرابعة_نظم_معلومات_الاعمال.xlsx'
wb = openpyxl.load_workbook(excel_path, data_only=True)

students = []

for sheet_name in ['المجموعة الأولى', 'المجموعة الثانية']:
    sheet = wb[sheet_name]
    for row in list(sheet.iter_rows(values_only=True))[8:]:
        if not row or len(row) < 3:
            continue
        idx = row[0]
        code = row[1]
        name = row[2]

        if code is not None and name is not None:
            s_code = str(code).strip()
            s_name = str(name).strip().replace("'", "\\'").replace('"', '\\"')
            if s_code.isdigit() and len(s_name) > 3 and s_code != 'كود الطالب':
                students.append({
                    'id': s_code,
                    'name': s_name,
                    'group': sheet_name
                })

dart_lines = []
dart_lines.append("// Generated automatically from official Excel sheet")
dart_lines.append("class FourthYearBisStudents {")
dart_lines.append("  static const List<Map<String, String>> list = [")
for s in students:
    dart_lines.append(f"    {{'id': '{s['id']}', 'name': '{s['name']}', 'group': '{s['group']}'}},")
dart_lines.append("  ];")
dart_lines.append("}")

out_path = r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/fourth_year_bis_students_data.dart'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(dart_lines))

print(f'Successfully updated {out_path} with {len(students)} students from Excel.')
