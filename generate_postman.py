import json
import uuid

collection = {
    "info": {
        "_postman_id": str(uuid.uuid4()),
        "name": "Wadini User App API Collection",
        "description": "Official Postman Collection for Wadini Ride Sharing & Parcel Delivery User App API endpoints. Includes request methods, query parameters, body payloads, headers, and authentication setup.",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    "variable": [
        {"key": "baseUrl", "value": "https://wadini.webbing-agency.com", "type": "string"},
        {"key": "token", "value": "YOUR_BEARER_TOKEN_HERE", "type": "string"},
        {"key": "zoneId", "value": "1", "type": "string"},
        {"key": "lang", "value": "en", "type": "string"}
    ],
    "item": []
}

def make_headers():
    return [
        {"key": "Content-Type", "value": "application/json; charset=UTF-8", "type": "text"},
        {"key": "Accept", "value": "application/json", "type": "text"},
        {"key": "X-Localization", "value": "{{lang}}", "type": "text"},
        {"key": "Authorization", "value": "Bearer {{token}}", "type": "text"},
        {"key": "zoneId", "value": "{{zoneId}}", "type": "text"}
    ]

def make_req(name, method, url_path, query_params=None, body_json=None, form_data=None, description=""):
    url_obj = {
        "raw": "{{baseUrl}}" + url_path,
        "host": ["{{baseUrl}}"],
        "path": [p for p in url_path.split("?")[0].split("/") if p]
    }
    if query_params:
        url_obj["query"] = query_params
        query_str = "&".join([f"{q['key']}={q['value']}" for q in query_params])
        url_obj["raw"] += ("?" if "?" not in url_path else "&") + query_str
    
    req = {
        "name": name,
        "request": {
            "method": method,
            "header": make_headers(),
            "url": url_obj,
            "description": description
        },
        "response": []
    }
    
    if body_json is not None:
        req["request"]["body"] = {
            "mode": "raw",
            "raw": json.dumps(body_json, indent=2),
            "options": {
                "raw": {
                    "language": "json"
                }
            }
        }
    elif form_data is not None:
        req["request"]["body"] = {
            "mode": "formdata",
            "formdata": form_data
        }
        
    return req

# Folders definition
folders = {}

def get_folder(folder_name):
    if folder_name not in folders:
        f = {"name": folder_name, "item": []}
        folders[folder_name] = f
        collection["item"].append(f)
    return folders[folder_name]

# 1. Auth & Account Management
auth = get_folder("1. Auth & Account Management")

auth["item"].append(make_req(
    "Customer Registration",
    "POST",
    "/api/customer/auth/registration",
    body_json={
        "first_name": "John",
        "last_name": "Doe",
        "phone": "+966500000000",
        "password": "password123",
        "confirm_password": "password123",
        "referral_code": "REF123"
    },
    description="Registers a new customer account."
))

auth["item"].append(make_req(
    "Customer Login",
    "POST",
    "/api/customer/auth/login",
    body_json={
        "phone_or_email": "+966500000000",
        "password": "password123"
    },
    description="Logs in customer using phone or email and password."
))

auth["item"].append(make_req(
    "External Login",
    "POST",
    "/api/customer/auth/external-login",
    body_json={
        "phone_or_email": "+966500000000",
        "token": "external_auth_token"
    },
    description="Logs in customer via external provider."
))

auth["item"].append(make_req(
    "Send OTP",
    "POST",
    "/api/customer/auth/send-otp",
    body_json={
        "phone_or_email": "+966500000000"
    },
    description="Sends an OTP to the customer's phone or email."
))

auth["item"].append(make_req(
    "Check User Registration",
    "POST",
    "/api/customer/auth/check",
    body_json={
        "phone_or_email": "+966500000000"
    },
    description="Checks if phone or email is registered."
))

auth["item"].append(make_req(
    "Verify OTP",
    "POST",
    "/api/customer/auth/otp-verification",
    body_json={
        "phone_or_email": "+966500000000",
        "otp": "123456"
    },
    description="Verifies the OTP sent to customer."
))

auth["item"].append(make_req(
    "Firebase OTP Verification",
    "POST",
    "/api/customer/auth/firebase-otp-verification",
    body_json={
        "phone_or_email": "+966500000000",
        "code": "123456",
        "session_info": "firebase_session_id"
    },
    description="Verifies Firebase OTP authentication."
))

auth["item"].append(make_req(
    "OTP Login",
    "POST",
    "/api/customer/auth/otp-login",
    body_json={
        "phone_or_email": "+966500000000",
        "otp": "123456"
    },
    description="Logs in customer using OTP."
))

auth["item"].append(make_req(
    "Reset Password",
    "POST",
    "/api/customer/auth/reset-password",
    body_json={
        "phone_or_email": "+966500000000",
        "password": "new_password123"
    },
    description="Resets customer password after OTP verification."
))

auth["item"].append(make_req(
    "Change Password",
    "POST",
    "/api/user/change-password",
    body_json={
        "password": "old_password123",
        "new_password": "new_password123"
    },
    description="Changes password for logged in user."
))

auth["item"].append(make_req(
    "Update FCM Token",
    "POST",
    "/api/customer/update/fcm-token",
    body_json={
        "_method": "put",
        "fcm_token": "sample_fcm_token"
    },
    description="Updates Firebase Cloud Messaging push notification token."
))

auth["item"].append(make_req(
    "Logout",
    "POST",
    "/api/user/logout",
    body_json={},
    description="Logs out the active user session."
))

auth["item"].append(make_req(
    "Delete Account",
    "POST",
    "/api/user/delete",
    body_json={},
    description="Permanently deletes the customer account."
))

# 2. Profile Management
profile = get_folder("2. Profile Management")

profile["item"].append(make_req(
    "Get Profile Info",
    "GET",
    "/api/customer/info",
    description="Retrieves profile information for the authenticated customer."
))

profile["item"].append(make_req(
    "Update Profile Info",
    "POST",
    "/api/customer/update/profile",
    form_data=[
        {"key": "_method", "value": "put", "type": "text"},
        {"key": "first_name", "value": "John", "type": "text"},
        {"key": "last_name", "value": "Doe", "type": "text"},
        {"key": "identification_number", "value": "1234567890", "type": "text"},
        {"key": "identification_type", "value": "national_id", "type": "text"},
        {"key": "profile_image", "type": "file", "src": ""},
        {"key": "identity_images[0]", "type": "file", "src": ""}
    ],
    description="Updates customer profile details and profile/identity images using multipart form-data."
))

profile["item"].append(make_req(
    "Get Profile Level",
    "GET",
    "/api/customer/level",
    description="Fetches loyalty/rewards level for the current customer."
))

# 3. Configuration & Location Services
config = get_folder("3. Configuration & Location Services")

config["item"].append(make_req(
    "Get App Configuration",
    "GET",
    "/api/customer/configuration",
    description="Retrieves app-wide settings, minimum versions, features, and policies."
))

config["item"].append(make_req(
    "Get Zone ID",
    "GET",
    "/api/customer/config/get-zone-id",
    query_params=[
        {"key": "lat", "value": "24.7136"},
        {"key": "lng", "value": "46.6753"}
    ],
    description="Returns Zone ID based on geographical latitude and longitude."
))

config["item"].append(make_req(
    "Reverse Geocode Location",
    "GET",
    "/api/customer/config/geocode-api",
    query_params=[
        {"key": "lat", "value": "24.7136"},
        {"key": "lng", "value": "46.6753"}
    ],
    description="Converts latitude and longitude into human-readable address details."
))

config["item"].append(make_req(
    "Search Location Autocomplete",
    "GET",
    "/api/customer/config/place-api-autocomplete",
    query_params=[
        {"key": "search_text", "value": "Riyadh"}
    ],
    description="Fetches address autocomplete predictions for location input."
))

config["item"].append(make_req(
    "Get Place Details",
    "GET",
    "/api/customer/config/place-api-details",
    query_params=[
        {"key": "placeid", "value": "ChIJ3S-g4Ei3Lz4R4eR8v01_5-Y"}
    ],
    description="Retrieves exact coordinates and details for a Google Place ID."
))

config["item"].append(make_req(
    "Store Live Location",
    "POST",
    "/api/user/store-live-location",
    body_json={
        "user_id": "123",
        "type": "customer",
        "latitude": "24.7136",
        "longitude": "46.6753",
        "zone_id": "1"
    },
    description="Stores background live location of customer."
))

# 4. Address Book
address = get_folder("4. Address Book")

address["item"].append(make_req(
    "Add Saved Address",
    "POST",
    "/api/customer/address/add",
    body_json={
        "address": "King Fahd Road, Riyadh",
        "address_label": "home",
        "latitude": 24.7136,
        "longitude": 46.6753,
        "street": "10th Street",
        "contact_person_name": "John Doe",
        "contact_person_phone": "+966500000000",
        "zone_id": "1"
    },
    description="Saves a new user address."
))

address["item"].append(make_req(
    "Get Saved Address List",
    "GET",
    "/api/customer/address/all-address",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Retrieves paginated list of saved user addresses."
))

address["item"].append(make_req(
    "Update Saved Address",
    "POST",
    "/api/customer/address/update",
    body_json={
        "_method": "put",
        "id": 1,
        "address": "Olaya Street, Riyadh",
        "address_label": "work",
        "latitude": 24.7136,
        "longitude": 46.6753,
        "street": "Main Boulevard",
        "contact_person_name": "John Doe",
        "contact_person_phone": "+966500000000",
        "zone_id": "1"
    },
    description="Updates existing saved address."
))

address["item"].append(make_req(
    "Delete Saved Address",
    "POST",
    "/api/customer/address/delete",
    body_json={
        "_method": "delete",
        "address_id": "1"
    },
    description="Deletes saved address by ID."
))

address["item"].append(make_req(
    "Get Recent Address List",
    "GET",
    "/api/customer/recent-address",
    description="Fetches recent addresses visited or searched by user."
))

# 5. Rides & Booking
rides = get_folder("5. Rides & Booking")

rides["item"].append(make_req(
    "Get Estimated Fare",
    "POST",
    "/api/customer/ride/get-estimated-fare",
    body_json={
        "pickup_coordinates": "[24.7136,46.6753]",
        "destination_coordinates": "[24.7500,46.7000]",
        "type": "ride",
        "ride_request_type": "regular",
        "pickup_address": "Point A, Riyadh",
        "destination_address": "Point B, Riyadh",
        "intermediate_coordinates": "",
        "parcel_weight": "",
        "parcel_category_id": "",
        "scheduled_at": ""
    },
    description="Calculates trip fare estimates based on pickup, destination, and vehicle category."
))

rides["item"].append(make_req(
    "Create Ride / Parcel Request",
    "POST",
    "/api/customer/ride/create",
    body_json={
        "pickup_coordinates": "[24.7136,46.6753]",
        "destination_coordinates": "[24.7500,46.7000]",
        "customer_coordinates": "[24.7136,46.6753]",
        "customer_request_coordinates": "[24.7136,46.6753]",
        "vehicle_category_id": "cat_123",
        "estimated_distance": "8.5",
        "estimated_time": "18",
        "estimated_fare": "45.00",
        "actual_fare": "45.00",
        "note": "Gate 3 pickup",
        "payment_method": "cash",
        "type": "ride",
        "bid": False,
        "pickup_address": "Point A",
        "destination_address": "Point B",
        "intermediate_addresses": "[]",
        "entrance": "Gate 3",
        "encoded_polyline": "sample_polyline_string",
        "zone_id": "1",
        "scheduled_at": None,
        "ride_request_type": "regular"
    },
    description="Creates a new ride or parcel delivery request."
))

rides["item"].append(make_req(
    "Get Trip Details",
    "GET",
    "/api/customer/ride/details/TRIP_123",
    description="Retrieves full details for a specified trip ID."
))

rides["item"].append(make_req(
    "Update Trip Status",
    "POST",
    "/api/customer/ride/update-status/TRIP_123",
    body_json={
        "_method": "put",
        "status": "cancelled",
        "cancel_reason": "Driver taking too long"
    },
    description="Updates ride status (e.g., cancel trip with reason)."
))

rides["item"].append(make_req(
    "Track Location & Remaining Distance",
    "POST",
    "/api/customer/ride/track-location",
    body_json={
        "trip_request_id": "TRIP_123"
    },
    description="Tracks active trip location and remaining distance."
))

rides["item"].append(make_req(
    "Get Bidding List",
    "GET",
    "/api/customer/ride/bidding-list/TRIP_123",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Fetches driver bids for a specific trip."
))

rides["item"].append(make_req(
    "Ignore Driver Bid",
    "POST",
    "/api/customer/ride/ignore-bidding",
    body_json={
        "_method": "put",
        "bidding_id": "BID_123"
    },
    description="Declines/ignores a specific driver's bid."
))

rides["item"].append(make_req(
    "Get Nearest Drivers",
    "GET",
    "/api/customer/drivers-near-me",
    query_params=[
        {"key": "latitude", "value": "24.7136"},
        {"key": "longitude", "value": "46.6753"}
    ],
    description="Finds active drivers currently near customer location."
))

rides["item"].append(make_req(
    "Trip Action (Accept/Reject Bid)",
    "POST",
    "/api/customer/ride/trip-action",
    body_json={
        "trip_request_id": "TRIP_123",
        "action": "accept",
        "driver_id": "DRIVER_456"
    },
    description="Accepts or rejects a driver offer for a trip."
))

rides["item"].append(make_req(
    "Get Current Ride Status (Resume)",
    "GET",
    "/api/customer/ride/ride-resume-status",
    description="Checks ongoing ride state to resume UI flow upon app open."
))

rides["item"].append(make_req(
    "Get Final Fare",
    "GET",
    "/api/customer/ride/final-fare",
    query_params=[
        {"key": "trip_request_id", "value": "TRIP_123"}
    ],
    description="Calculates final trip fare after ride completion."
))

rides["item"].append(make_req(
    "Get Driver Arrival Time & Pickup Location",
    "GET",
    "/api/customer/ride/arrival-time",
    query_params=[
        {"key": "trip_request_id", "value": "TRIP_123"}
    ],
    description="Fetches estimated driver arrival time at pickup point."
))

rides["item"].append(make_req(
    "Get Running / Pending Ride List",
    "GET",
    "/api/customer/ride/pending-ride-list",
    description="Lists all active and pending rides for user."
))

rides["item"].append(make_req(
    "Get Ride History List",
    "GET",
    "/api/customer/ride/list",
    query_params=[
        {"key": "type", "value": "ride_request"},
        {"key": "limit", "value": "20"},
        {"key": "offset", "value": "1"},
        {"key": "filter", "value": "all"},
        {"key": "start", "value": "2026-01-01"},
        {"key": "end", "value": "2026-12-31"},
        {"key": "status", "value": "completed"}
    ],
    description="Retrieves filtered trip history (completed, cancelled, etc.)."
))

rides["item"].append(make_req(
    "Edit Scheduled Trip Time",
    "PUT",
    "/api/customer/ride/edit-scheduled-trip/TRIP_123",
    body_json={
        "scheduled_at": "2026-08-10 14:30:00"
    },
    description="Updates execution time for scheduled future trip."
))

rides["item"].append(make_req(
    "Confirm Received Returning Parcel",
    "POST",
    "/api/customer/ride/received-returning-parcel/TRIP_123",
    body_json={
        "_method": "put"
    },
    description="Confirms receipt of parcel being returned by driver."
))

rides["item"].append(make_req(
    "Get Ride Cancellation Reasons",
    "GET",
    "/api/customer/config/cancellation-reason-list",
    description="Fetches predefined cancellation reason options."
))

# 6. Parcel Services
parcel = get_folder("6. Parcel Services")

parcel["item"].append(make_req(
    "Get Parcel Categories",
    "GET",
    "/api/customer/parcel/category",
    query_params=[
        {"key": "limit", "value": "100"},
        {"key": "offset", "value": "1"}
    ],
    description="Gets list of parcel categories available for selection."
))

parcel["item"].append(make_req(
    "Get Suggested Vehicle for Parcel",
    "GET",
    "/api/customer/parcel/suggested-vehicle-category",
    query_params=[
        {"key": "parcel_weight", "value": "10"}
    ],
    description="Suggests vehicle type depending on parcel weight in kg."
))

parcel["item"].append(make_req(
    "Get Ongoing Parcel List",
    "GET",
    "/api/customer/ride/ongoing-parcel-list",
    query_params=[
        {"key": "limit", "value": "100"},
        {"key": "offset", "value": "1"}
    ],
    description="Lists currently active parcel deliveries."
))

parcel["item"].append(make_req(
    "Get Unpaid Parcel List",
    "GET",
    "/api/customer/ride/unpaid-parcel-list",
    query_params=[
        {"key": "limit", "value": "100"},
        {"key": "offset", "value": "1"}
    ],
    description="Lists completed parcel deliveries awaiting payment."
))

parcel["item"].append(make_req(
    "Get Parcel Cancellation Reasons",
    "GET",
    "/api/customer/config/parcel-cancellation-reason-list",
    description="Gets cancellation reasons specific to parcel deliveries."
))

parcel["item"].append(make_req(
    "Get Parcel Refund Reasons",
    "GET",
    "/api/customer/config/parcel-refund-reason-list",
    description="Gets valid reason list for requesting a parcel refund."
))

parcel["item"].append(make_req(
    "Create Parcel Refund Request",
    "POST",
    "/api/customer/parcel/refund/create",
    form_data=[
        {"key": "trip_request_id", "value": "TRIP_123", "type": "text"},
        {"key": "reason", "value": "Damaged goods", "type": "text"},
        {"key": "parcel_approximate_price", "value": "150.0", "type": "text"},
        {"key": "customer_note", "value": "Package arrived torn", "type": "text"},
        {"key": "proof_image[0]", "type": "file", "src": ""}
    ],
    description="Submits refund request with optional proof image attachments."
))

# 7. Payments & Wallet
payment = get_folder("7. Payments & Wallet")

payment["item"].append(make_req(
    "Get Payment Methods",
    "GET",
    "/api/customer/config/get-payment-methods",
    description="Lists enabled payment gateways (cash, digital, wallet)."
))

payment["item"].append(make_req(
    "Submit Trip Payment",
    "GET",
    "/api/customer/ride/payment",
    query_params=[
        {"key": "trip_request_id", "value": "TRIP_123"},
        {"key": "payment_method", "value": "wallet"},
        {"key": "tips", "value": "10"}
    ],
    description="Submits payment and tips for a completed ride."
))

payment["item"].append(make_req(
    "Submit Driver / Trip Review",
    "POST",
    "/api/customer/review/store",
    body_json={
        "ride_request_id": "TRIP_123",
        "rating": 5,
        "feedback": "Excellent service and safe driving!"
    },
    description="Stores rating and written review for a trip."
))

payment["item"].append(make_req(
    "Get Wallet Transaction List",
    "GET",
    "/api/customer/transaction/list",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Retrieves customer wallet transaction history."
))

payment["item"].append(make_req(
    "Get Loyalty Points List",
    "GET",
    "/api/customer/loyalty-points/list",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Retrieves earned loyalty points breakdown."
))

payment["item"].append(make_req(
    "Convert Loyalty Points to Wallet",
    "POST",
    "/api/customer/loyalty-points/convert",
    body_json={
        "points": "500"
    },
    description="Converts loyalty points into wallet balance credit."
))

payment["item"].append(make_req(
    "Transfer Drivemond Wallet to Mart",
    "POST",
    "/api/customer/wallet/transfer-drivemond-to-mart",
    body_json={
        "amount": "50.0"
    },
    description="Transfers funds from ride app wallet to integrated mart app."
))

payment["item"].append(make_req(
    "Get Add Fund Bonus List",
    "GET",
    "/api/customer/wallet/bonus-list",
    description="Retrieves active promotional bonuses for wallet top-ups."
))

payment["item"].append(make_req(
    "Digital Add Fund to Wallet",
    "GET",
    "/api/customer/wallet/add-fund-digitally",
    query_params=[
        {"key": "user_id", "value": "USER_123"},
        {"key": "amount", "value": "100.0"},
        {"key": "payment_method", "value": "myfatoorah"}
    ],
    description="Initiates digital wallet top-up via payment gateway webview."
))

# 8. Chat & Communication
chat = get_folder("8. Chat & Communication")

chat["item"].append(make_req(
    "Create Chat Channel",
    "POST",
    "/api/customer/chat/create-channel",
    body_json={
        "_method": "put",
        "to": "DRIVER_123",
        "trip_id": "TRIP_456"
    },
    description="Establishes chat channel between customer and driver/support."
))

chat["item"].append(make_req(
    "Get Chat Channel List",
    "GET",
    "/api/customer/chat/channel-list",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Fetches active chat channels."
))

chat["item"].append(make_req(
    "Get Conversation Messages",
    "GET",
    "/api/customer/chat/conversation",
    query_params=[
        {"key": "channel_id", "value": "CHAN_123"},
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Retrieves messages inside a chat channel."
))

chat["item"].append(make_req(
    "Find Channel Ride Status",
    "GET",
    "/api/customer/chat/find-channel",
    query_params=[
        {"key": "channel_id", "value": "CHAN_123"}
    ],
    description="Finds channel details and linked ride status."
))

chat["item"].append(make_req(
    "Send Chat Message",
    "POST",
    "/api/customer/chat/send-message",
    form_data=[
        {"key": "_method", "value": "put", "type": "text"},
        {"key": "message", "value": "I am waiting at main entrance", "type": "text"},
        {"key": "channel_id", "value": "CHAN_123", "type": "text"},
        {"key": "trip_id", "value": "TRIP_456", "type": "text"},
        {"key": "files[0]", "type": "file", "src": ""}
    ],
    description="Sends text message and optional attachment images to chat channel."
))

# 9. Offers & Referrals
offers = get_folder("9. Offers & Referrals")

offers["item"].append(make_req(
    "Get Available Coupon List",
    "GET",
    "/api/customer/coupon/list",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"},
        {"key": "category_type", "value": "ride"}
    ],
    description="Retrieves active discount coupons for rides or parcels."
))

offers["item"].append(make_req(
    "Apply Coupon",
    "POST",
    "/api/customer/applied-coupon",
    body_json={
        "_method": "post",
        "coupon_id": "COUPON_123"
    },
    description="Applies promo coupon to active checkout session."
))

offers["item"].append(make_req(
    "Get Best Offer Discounts",
    "GET",
    "/api/customer/discount/list",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Fetches best promotional discount list."
))

offers["item"].append(make_req(
    "Get Referral Program Details",
    "GET",
    "/api/customer/referral-details",
    description="Gets customer referral code and program bonus rules."
))

offers["item"].append(make_req(
    "Get Referral Earnings History",
    "GET",
    "/api/customer/transaction/referral-earning-list",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Lists earnings gained from referred users."
))

# 10. Banners & Vehicle Categories
banners = get_folder("10. Banners & Categories")

banners["item"].append(make_req(
    "Get Banner List",
    "GET",
    "/api/customer/banner/list",
    query_params=[
        {"key": "limit", "value": "100"},
        {"key": "offset", "value": "1"}
    ],
    description="Fetches home screen promotional banners."
))

banners["item"].append(make_req(
    "Update Banner Click Count",
    "POST",
    "/api/customer/banner/update-redirection-count",
    body_json={},
    description="Increments banner redirection count on click."
))

banners["item"].append(make_req(
    "Get Vehicle Categories",
    "GET",
    "/api/customer/vehicle/category",
    query_params=[
        {"key": "limit", "value": "100"},
        {"key": "offset", "value": "1"}
    ],
    description="Fetches available ride vehicle categories."
))

# 11. Safety & Emergency Alerts
safety = get_folder("11. Safety & Emergency Alerts")

safety["item"].append(make_req(
    "Get Emergency Contacts List",
    "GET",
    "/api/customer/config/other-emergency-contact-list",
    description="Gets list of emergency phone numbers configured by platform."
))

safety["item"].append(make_req(
    "Get Safety Alert Reasons",
    "GET",
    "/api/customer/config/safety-alert-reason-list",
    description="Gets predefined list of reasons for triggering safety SOS."
))

safety["item"].append(make_req(
    "Get Safety Precautions",
    "GET",
    "/api/customer/config/safety-precaution-list",
    description="Gets safety tips and guidelines for riders."
))

safety["item"].append(make_req(
    "Store Safety SOS Alert",
    "POST",
    "/api/customer/safety-alert/store",
    body_json={
        "trip_request_id": "TRIP_123",
        "lat": "24.7136",
        "lng": "46.6753",
        "comment": "Unsafe driving behavior",
        "reason": "[\"rash_driving\",\"verbal_abuse\"]"
    },
    description="Triggers emergency SOS safety alert for an ongoing trip."
))

safety["item"].append(make_req(
    "Mark Safety Alert Solved",
    "POST",
    "/api/customer/safety-alert/mark-as-solved/TRIP_123",
    body_json={
        "_method": "put",
        "lat": "24.7136",
        "lng": "46.6753"
    },
    description="Resolves an active safety alert."
))

safety["item"].append(make_req(
    "Resend Safety Alert",
    "POST",
    "/api/customer/safety-alert/resend/TRIP_123",
    body_json={
        "_method": "put"
    },
    description="Resends emergency SOS notification to emergency contacts."
))

safety["item"].append(make_req(
    "Undo Safety Alert",
    "POST",
    "/api/customer/safety-alert/undo/TRIP_123",
    body_json={
        "_method": "delete"
    },
    description="Cancels accidental safety SOS alert."
))

safety["item"].append(make_req(
    "Get Safety Alert Details",
    "GET",
    "/api/customer/safety-alert/show/TRIP_123",
    description="Gets status and details of safety alert for a trip."
))

# 12. Notifications & Settings
notif = get_folder("12. Notifications & Settings")

notif["item"].append(make_req(
    "Get Notification List",
    "GET",
    "/api/customer/notification-list",
    query_params=[
        {"key": "limit", "value": "10"},
        {"key": "offset", "value": "1"}
    ],
    description="Fetches paginated user notifications."
))

notif["item"].append(make_req(
    "Mark Notification as Read",
    "PUT",
    "/api/user/read-notification",
    body_json={
        "notification_id": 1
    },
    description="Marks notification ID as read."
))

notif["item"].append(make_req(
    "Change Language Preference",
    "POST",
    "/api/customer/change-language",
    body_json={},
    description="Updates server-side user language setting (uses X-Localization header)."
))

out_path = r"d:\Apps\wadiliy app\MaakUserApp-main\userApp\wadini_user_app.postman_collection.json"
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(collection, f, indent=2)

print(f"Successfully generated Postman Collection at {out_path}")
