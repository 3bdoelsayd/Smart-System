import urllib.request, json, urllib.parse, time

college_id = 'المعهد العالي للعلوم الادارية ببلقاس'
encoded_id = urllib.parse.quote(college_id)

courses = [
    {
        "name": "الأساليب الكمية واتخاذ القرار",
        "doctor_name": "د. زينب المتولي / أ. ذكي رجائي",
        "division": "نظم معلومات الاعمال"
    },
    {
        "name": "تحليلات الأعمال والتنقيب في البيانات",
        "doctor_name": "د. محمد كاظم خليل",
        "division": "نظم معلومات الاعمال"
    },
    {
        "name": "مبادئ المالية العامة",
        "doctor_name": "د. نور الإسلام إبراهيم",
        "division": "نظم معلومات الاعمال"
    },
    {
        "name": "أنظمة معلومات المؤسسات",
        "doctor_name": "د. أحمد عبد البديع",
        "division": "نظم معلومات الاعمال"
    },
    {
        "name": "استراتيجية نظم المعلومات",
        "doctor_name": "د. أسماء محمد",
        "division": "نظم معلومات الاعمال"
    }
]

# We can use Firestore REST API to add courses
for i, c in enumerate(courses):
    doc_id = f"course_l4_{i+1}"
    url = f"https://firestore.googleapis.com/v1/projects/university-smart-system/databases/(default)/documents/colleges/{encoded_id}/levels/level_4/courses?documentId={doc_id}"

    body = {
        "fields": {
            "name": {"stringValue": c["name"]},
            "doctor_name": {"stringValue": c["doctor_name"]},
            "division": {"stringValue": c["division"]},
            "level_id": {"stringValue": "level_4"},
            "lecturesCount": {"integerValue": "12"}
        }
    }

    req_data = json.dumps(body).encode('utf-8')
    req = urllib.request.Request(url, data=req_data, headers={'Content-Type': 'application/json'}, method='POST')

    try:
        resp = urllib.request.urlopen(req)
        print(f"Added course: {c['name']} -> {c['doctor_name']}")
    except Exception as e:
        print(f"Failed to add {c['name']}: {e}")

print("Done adding Level 4 BIS courses!")
