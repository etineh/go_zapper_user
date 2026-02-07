    # Automated Delivery Creation Flow
    ---
    📋 Overview:
    
    This flow automates the process of creating a
    delivery order by handling API credential
    creation and payment method verification
    seamlessly in the background. It ensures that
    users can quickly accept quotes and create
    deliveries without manual setup.
    
    ---
    🚀 Flow Steps:
 User creates delivery order
    ↓
  Fills order details & gets quote
    ↓
  Clicks "Accept & Create Delivery"
    ↓
  ══════════════════════════════════════
  STEP 1: Check Credentials
  ══════════════════════════════════════
    ↓
  Both sandboxCredential & productionCredential
   are false?
    ├─ YES → Auto-create sandbox credential ⚡
    │         ↓
    │   POST /api/v1/credential/sandbox
    │   Body: { "name": "Auto-generated Sandbox
   Credential" }
    │         ↓
    │   Credential created & stored
    │         ↓
    │   User profile refreshed
    │         ↓
    │   Show success message
    │
    └─ NO → User already has credentials ✅

    ↓
  ══════════════════════════════════════
  STEP 2: Check Payment Method
  ══════════════════════════════════════
    ↓
  User has paymentId?
    ├─ NO → Show "Add Payment Method" dialog
    │         ↓
    │   User navigates to /add-payment-method
    │         ↓
    │   Adds payment method
    │         ↓
    │   Returns & auto-retries acceptance
    │
    └─ YES → User has payment method ✅

    ↓
  ══════════════════════════════════════
  STEP 3: Accept Quote & Create Delivery
  ══════════════════════════════════════
    ↓
  Backend automatically:
    1. Uses sandbox/production API key
    2. Charges default payment method
    3. Creates delivery
    ↓
  Success! 🎉

  ---
  🧪 Testing the Flow:

  # Run the app
  flutter run

  Test Scenario:

  1. Login to the app
  2. Navigate to "Create Order"
  3. Fill in delivery details
  4. Click "Get Quote"
  5. Click "Accept & Create Delivery"

  Expected Behavior:

  First Time User (no credentials, no payment):
  1. ✅ Sandbox credential auto-created (silent
   background process)
  2. ✅ Shows message: "Sandbox API credential
  created automatically!"
  3. ✅ Shows dialog: "Payment Method Required"
  4. ✅ User adds payment method
  5. ✅ Quote accepted, delivery created!

  User with Credentials (no payment):
  1. ✅ Skips credential creation
  2. ✅ Shows dialog: "Payment Method Required"
  3. ✅ User adds payment method
  4. ✅ Quote accepted, delivery created!

  User with Everything:
  1. ✅ Skips credential creation
  2. ✅ Skips payment dialog
  3. ✅ Quote accepted immediately, delivery
  created!

  ---
  🎯 API Endpoints Used:

  | Endpoint               | Method | Purpose
                      | Auth Required
            |
  |------------------------|--------|----------
  --------------------|------------------------
  ----------|
  | /credential/sandbox    | POST   | Create
  sandbox credential    | JWT Bearer ✅
               |
  | /credential/production | POST   | Create
  production credential | JWT Bearer ✅ +
  Payment Method ⚠️ |
  | /payment               | POST   | Save
  payment method          | JWT Bearer ✅
                 |
  | /quote/{id}/accept     | POST   | Accept
  quote & charge        | API Key ✅
               |

  ---
  💡 Key Features:

  ✅ Automatic Sandbox Creation - No manual
  setup needed for testing
  ✅ Seamless UX - User doesn't need to
  understand credentials
  ✅ Production Upgrade - Can be added later as
   a separate feature
  ✅ Error Handling - Clear error messages if
  creation fails
  ✅ Profile Refresh - User credentials updated
   after creation
  ✅ Clean Architecture - Follows existing
  patterns
