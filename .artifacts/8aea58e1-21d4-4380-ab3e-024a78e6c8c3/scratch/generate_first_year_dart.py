import openpyxl

wb = openpyxl.load_workbook(r'C:\Users\Disney\Downloads\الفرقة_الأولى.xlsx')

def process_sheet(sheet_name, class_name, file_path):
    sheet = wb[sheet_name]
    students = []
    for i in range(2, sheet.max_row + 1):
        row = [cell.value for cell in sheet[i]]
        if not any(row):
            continue
        # row: [م, الكود, الاسم, الفرقة, الشعبة]
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

process_sheet('الأولى - نظم معلومات الأعمال', 'FirstYearNuzumStudents', r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/first_year_nuzum_students_data.dart')
process_sheet('الأولى - المحاسبة والمراجعة', 'FirstYearGeneralStudents', r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/first_year_general_students_data.dart')
