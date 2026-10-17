import urllib.request, json, urllib.parse, hashlib

college_id = 'المعهد العالي للعلوم الادارية ببلقاس'
encoded_id = urllib.parse.quote(college_id)

def hash_pass(pwd):
    salt = "SystemSalt2026"
    return hashlib.sha256((pwd + salt).encode('utf-8')).hexdigest()

doctors = [
    {"id": "101", "name": "د. زينب المتولي / أ. ذكي رجائي", "levels": ["level_4"], "subjects": ["الأساليب الكمية واتخاذ القرار"]},
    {"id": "102", "name": "د. محمد كاظم خليل", "levels": ["level_4"], "subjects": ["تحليلات الأعمال والتنقيب في البيانات"]},
    {"id": "103", "name": "د. نور الإسلام إبراهيم", "levels": ["level_4"], "subjects": ["مبادئ المالية العامة"]},
    {"id": "104", "name": "د. أحمد عبد البديع", "levels": ["level_4"], "subjects": ["أنظمة معلومات المؤسسات"]},
    {"id": "105", "name": "د. أسماء محمد", "levels": ["level_4"], "subjects": ["استراتيجية نظم المعلومات"]}
]

for doc in doctors:
    doc_id = f"DOC_{doc['id']}"
    url = f"https://firestore.googleapis.com/v1/projects/university-smart-system/databases/(default)/documents/colleges/{encoded_id}/doctors/{doc_id}"

    body = {
        "fields": {
            "uid": {"stringValue": doc_id},
            "id": {"stringValue": doc['id']},
            "name": {"stringValue": doc['name']},
            "email": {"stringValue": f"{doc['id']}.college@smart.com"},
            "role": {"stringValue": "doctor"},
            "isActive": {"booleanValue": True},
            "password": {"stringValue": hash_pass("123456")},
            "teachingLevels": {"arrayValue": {"values": [{"stringValue": l} for l in doc['levels']]}},
            "subjects": {"arrayValue": {"values": [{"stringValue": s} for s in doc['subjects']]}},
            "instituteId": {"stringValue": college_id}
        }
    }

    req_data = json.dumps(body).encode('utf-8')
    req = urllib.request.Request(url, data=req_data, headers={'Content-Type': 'application/json'}, method='PATCH')

    try:
        resp = urllib.request.urlopen(req)
        print(f"Updated doctor hash: {doc['name']} (Code: {doc['id']})")
    except Exception as e:
        print(f"Failed to update {doc['name']}: {e}")

print("Done updating doctors with correct salt hash!")
