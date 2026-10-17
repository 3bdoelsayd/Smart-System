import urllib.request, json, urllib.parse, time

api_key = "AIzaSyBUEfN3YRyAV0zwnFb3mXG2hyl7msjGmfY"
url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={api_key}"

students = []
with open('lib/utils/fourth_year_bis_students_data.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for line in lines:
    if "'id':" in line and "'name':" in line:
        try:
            parts = line.split(":")
            s_id = parts[1].split(",")[0].strip().replace("'", "").replace('"', '')
            students.append(s_id)
        except Exception as e:
            pass

doctors = ["101", "102", "103", "104", "105"]
all_accounts = [f"{s}.college@smart.com" for s in students] + [f"{d}.college@smart.com" for d in doctors]

success_count = 0
existing_count = 0
fail_count = 0

for email in all_accounts:
    body = {
        "email": email,
        "password": "123456",
        "returnSecureToken": True
    }
    req_data = json.dumps(body).encode('utf-8')
    req = urllib.request.Request(url, data=req_data, headers={'Content-Type': 'application/json'}, method='POST')

    try:
        resp = urllib.request.urlopen(req)
        success_count += 1
    except urllib.error.HTTPError as e:
        err_body = e.read().decode('utf-8')
        if "EMAIL_EXISTS" in err_body:
            existing_count += 1
        else:
            fail_count += 1
            print(f"Retry failed {email}: {err_body}")
    except Exception as e:
        fail_count += 1

    time.sleep(0.2)

print(f"Retry done! Success: {success_count}, Already Exists: {existing_count}, Failed: {fail_count}")
