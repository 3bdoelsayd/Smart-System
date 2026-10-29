import openpyxl

def process_file_sheets(filepath, sheet_configs):
    wb = openpyxl.load_workbook(filepath)
    for sheet_name, class_name, file_path in sheet_configs:
        sheet = wb[sheet_name]
        students = []
        for i in range(2, sheet.max_row + 1):
            row = [cell.value for cell in sheet[i]]
            if not any(row):
                continue
            _, code, name, level, division = row
            if code is not None and name is not None:
                c_str = str(code).strip()
                n_str = str(name).strip()
                d_str = str(division).strip() if division else ""
                students.append((c_str, n_str, d_str))
                
        dart_code = f"""// Generated automatically from official Excel sheet
class {class_name} {{
  static const List<Map<String, String>> list = [
"""
        for c, n, d in students:
            dart_code += f"    {{'id': '{c}', 'name': '{n}', 'division': '{d}'}},\n"
        dart_code += """  ];
}
"""
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(dart_code)
        print(f"Generated {file_path} with {len(students)} students.")

process_file_sheets(r'C:\Users\Disney\Downloads\الفرقة_الثانية.xlsx', [
    ('الثانية - نظم معلومات الأعمال', 'SecondYearNuzumStudents', r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/second_year_nuzum_students_data.dart'),
    ('الثانية - المحاسبة والمراجعة', 'SecondYearGeneralStudents', r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/second_year_general_students_data.dart')
])

process_file_sheets(r'C:\Users\Disney\Downloads\الفرقة_الثالثة.xlsx', [
    ('الثالثة - نظم معلومات الأعمال', 'ThirdYearNuzumStudents', r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/third_year_nuzum_students_data.dart'),
    ('الثالثة - المحاسبة والمراجعة', 'ThirdYearGeneralStudents', r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/third_year_general_students_data.dart')
])
