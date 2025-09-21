import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify, render_template
from datetime import datetime
import pytz

# -------------------------------
# Firebase initialization
# -------------------------------
if not firebase_admin._apps:
    cred = credentials.Certificate("track-pit-firebase-adminsdk-fbsvc-989e750375.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 👇 tell Flask to look for templates in current directory
app = Flask(__name__, template_folder=".")

# Malaysia timezone
MALAYSIA_TZ = pytz.timezone("Asia/Kuala_Lumpur")

def to_malaysia_str(dt):
    """Convert Firestore datetime/str/None into Malaysia time string"""
    if not dt:
        return "-"
    if not isinstance(dt, datetime):
        return str(dt)
    local = dt.astimezone(MALAYSIA_TZ)
    return local.strftime("%d %b %Y, %I:%M %p")

def to_input_value(dt):
    """Format datetime for <input type=datetime-local> (yyyy-MM-ddTHH:mm)"""
    if not dt:
        return ""
    if not isinstance(dt, datetime):
        return ""
    local = dt.astimezone(MALAYSIA_TZ)
    return local.strftime("%Y-%m-%dT%H:%M")


# -------------------------------
# Routes
# -------------------------------
@app.route("/")
def index():
    users_ref = db.collection("users").stream()
    services = []

    for u in users_ref:
        user = u.to_dict()
        uid = u.id
        services_ref = db.collection("users").document(uid).collection("services").stream()

        for s in services_ref:
            service = s.to_dict()
            service_id = s.id

            # fetch timeline
            timeline_ref = (
                db.collection("users")
                .document(uid)
                .collection("services")
                .document(service_id)
                .collection("statusTimeline")
                .stream()
            )
            timeline = {
                t.id: {
                    "status": t.get("status"),
                    "completedAt": to_input_value(t.get("completedAt")),
                    "display": to_malaysia_str(t.get("completedAt")),
                }
                for t in timeline_ref
            }

            # fetch vehicle info
            vehicle_info = {}
            vehicle_id = service.get("vehicleId")
            if vehicle_id:
                vdoc = (
                    db.collection("users")
                    .document(uid)
                    .collection("vehicles")
                    .document(vehicle_id)
                    .get()
                )
                if vdoc.exists:
                    vehicle_info = vdoc.to_dict()

            # fetch invoice (only one allowed per service)
            invoice = None
            invoice_ref = (
                db.collection("users")
                .document(uid)
                .collection("invoices")
                .where("serviceId", "==", service_id)
                .limit(1)
                .stream()
            )
            for inv in invoice_ref:
                inv_data = inv.to_dict()
                invoice = {
                    "id": inv.id,
                    "price": inv_data.get("price"),
                    "paid": inv_data.get("paid"),
                    "issuedAt": to_malaysia_str(inv_data.get("issuedAt")),
                }
                break

            # fetch feedbacks for this service
            feedbacks = []
            if service_id:  # only query if service_id is available
                feedback_ref = (
                    db.collection("feedback")
                    .where("serviceId", "==", service_id)
                    .stream()
                )
                for f in feedback_ref:
                    f_data = f.to_dict()
                    feedbacks.append({
                        "id": f.id,
                        "email": f_data.get("email"),
                        "rating": f_data.get("rating"),
                        "message": f_data.get("message"),
                        "createdAt": to_malaysia_str(f_data.get("createdAt")),
                    })

            services.append(
                {
                    "id": service_id,
                    "uid": uid,
                    "userName": user.get("fullName"),
                    "userEmail": user.get("email"),
                    "bookedDateTime": to_malaysia_str(service.get("bookedDateTime")),
                    "createdAt": to_malaysia_str(service.get("createdAt")),
                    "notes": service.get("notes"),
                    "timeline": timeline,
                    "vehicle": {
                        "id": vehicle_id,
                        "model": vehicle_info.get("model"),
                        "plateNumber": vehicle_info.get("plateNumber"),
                    },
                    "invoice": invoice,
                    "feedbacks": feedbacks,  # 👈 added feedbacks per service
                }
            )

    # 👇 now it loads index.html from the same folder as app.py
    return render_template("..index.html", services=services)


@app.route("/update/<uid>/<service_id>/<status_id>", methods=["POST"])
def update_status(uid, service_id, status_id):
    new_time = request.form.get("completedAt")
    if new_time:
        naive_time = datetime.fromisoformat(new_time)
        malaysia = pytz.timezone("Asia/Kuala_Lumpur")
        localized = malaysia.localize(naive_time)
        parsed_time = localized.astimezone(pytz.UTC)
    else:
        parsed_time = None

    status_ref = (
        db.collection("users")
        .document(uid)
        .collection("services")
        .document(service_id)
        .collection("statusTimeline")
        .document(status_id)
    )
    status_ref.update({"completedAt": parsed_time})

    return jsonify({"success": True, "message": "Saved successfully"})


# -------------------------------
# New route: Create Invoice
# -------------------------------
@app.route("/invoice/<uid>/<service_id>", methods=["POST"])
def create_invoice(uid, service_id):
    price = request.form.get("price")

    if not price:
        return jsonify({"success": False, "message": "Price required"}), 400

    # check if invoice already exists
    existing = (
        db.collection("users")
        .document(uid)
        .collection("invoices")
        .where("serviceId", "==", service_id)
        .limit(1)
        .stream()
    )
    if any(existing):
        return jsonify({"success": False, "message": "Invoice already exists"}), 400

    # fetch service
    service_doc = (
        db.collection("users")
        .document(uid)
        .collection("services")
        .document(service_id)
        .get()
    )
    service = service_doc.to_dict() if service_doc.exists else {}

    now = datetime.now(pytz.UTC)
    invoice_data = {
        "vehicleId": service.get("vehicleId"),
        "serviceId": service_id,
        "workshopId": service.get("workshopId"),
        "price": float(price),
        "paid": False,
        "issuedAt": now,
        "createdAt": now,
        "updatedAt": now,
    }

    # let Firestore generate invoiceId
    invoices_ref = db.collection("users").document(uid).collection("invoices")
    new_invoice_ref = invoices_ref.document()  # auto-ID
    new_invoice_ref.set(invoice_data)

    return jsonify({"success": True, "message": "Invoice created successfully"})



if __name__ == "__main__":
    app.run(debug=True)
