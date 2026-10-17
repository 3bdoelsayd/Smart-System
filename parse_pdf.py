import pypdf, re

def parse_pdf(path, group_name):
    students = []
    reader = pypdf.PdfReader(path)
    for page in reader.pages:
        text = page.extract_text()
        lines = text.split('\n')
        for line in lines:
            line = line.strip()
            match = re.search(r'(\d{1,3})\s*(\d{6,7})\s+(.+)', line)
            if not match:
                match = re.search(r'(\d{1,3})(\d{6,7})\s*(.+)', line)
            if match:
                idx, sid, name = match.groups()
                name = name.strip().replace('\n', ' ')
                if 'المجموع' in name or 'ملاحظات' in name or 'مكود' in name:
                    continue
                students.append({'id': sid, 'name': name, 'group': group_name})
    return students

g1 = parse_pdf(r'C:/Users/Disney/Downloads/الفرقة الرابعة - شعبة نظم معلومات الاعمال المجموعة الاولي (2).pdf', 'المجموعة الأولى')
g2 = parse_pdf(r'C:/Users/Disney/Downloads/الفرقة الرابعة - شعبة نظم معلومات الاعمال المجموعة الثانية (2).pdf', 'المجموعة الثانية')
all_students = g1 + g2

dart_lines = []
dart_lines.append("// Generated automatically from PDF rosters")
dart_lines.append("class FourthYearBisStudents {")
dart_lines.append("  static const List<Map<String, String>> list = [")
for s in all_students:
    dart_lines.append(f"    {{'id': '{s['id']}', 'name': '{s['name']}', 'group': '{s['group']}'}},")
dart_lines.append("  ];")
dart_lines.append("}")

out_path = r'C:/Users/Disney/AndroidStudioProjects/Smart System10/lib/utils/fourth_year_bis_students_data.dart'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(dart_lines))

print(f'Generated Dart file with {len(all_students)} students at {out_path}')
