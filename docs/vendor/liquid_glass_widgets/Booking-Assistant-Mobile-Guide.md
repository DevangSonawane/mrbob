# Booking assistant — guide for the customer app

The customer explains their problem in their own words, by typing or by speaking, and the app turns it into a ready-to-confirm booking. This guide covers everything the customer app needs to build that flow.

- **Backend:** already live (`POST /bookings/draft`). No new backend work is needed.
- **Full API reference:** Swagger at `<server>/api-docs` → **Booking flow** → "Describe the problem, get a booking draft".
- **Server:** `https://home-services-backend-zvm2.onrender.com/api/v1` (local development: `http://localhost:4000/api/v1`). All paths below are relative to this.

---

## 1. The flow at a glance

```
┌──────────────┐   ┌───────────────┐   ┌────────────────┐   ┌──────────────┐
│ 1. Describe  │ → │ 2. Thinking…  │ → │ 3. Review the  │ → │ 4. Booked    │
│ type or speak│   │ POST /bookings│   │ draft, answer  │   │ POST         │
│              │   │ /draft        │   │ questions,     │   │ /bookings    │
│              │   │               │   │ pick address,  │   │              │
│              │   │               │   │ time, payment  │   │              │
└──────────────┘   └───────────────┘   └────────────────┘   └──────────────┘
        ▲                                     │
        └──── "Choose service yourself" ◄─────┘  (fallback at any point)
```

1. The customer **types** the problem, or taps the **mic** and speaks. The phone turns speech into text.
2. The app sends the text to `POST /bookings/draft` and shows a loader. It usually takes 2–6 seconds.
3. The app shows the **draft**: service, price, the problem description, a suggested time, and urgency. If the assistant needs more information, it shows up to 2 questions. The customer confirms or changes the details, picks the address and payment, and taps **Book**.
4. The app calls the existing `POST /bookings`. **Nothing is booked before this tap.**

At every step the customer can switch to the normal service picker. The assistant helps, but booking never depends on it.

---

## 2. Screen 1 — Describe the problem

**Entry points (suggested):** a prominent "Describe your problem" card or search bar on the home screen, with a mic icon.

**UI**
- A multi-line text box with a placeholder such as: *"e.g. Water is leaking under my kitchen sink since morning. Can someone come tomorrow evening?"*
- A **mic button**. While listening, show the live transcript in the text box so the customer sees what was heard.
- A **Continue** button, enabled at 3 characters or more. The maximum is 2000 characters.
- A secondary link: **"Choose a service yourself"**, which opens the normal service list.

**Tips to show (optional):** "Say what's wrong, where in the house, and when you'd like someone to come."

### Voice: speech-to-text on the phone

**Audio is never uploaded.** Use the phone's built-in speech recognition and send the resulting **text**. Set the language to **English (India), `en-IN`**.

| Platform | What to use | Permissions |
|---|---|---|
| Android (native) | `SpeechRecognizer` + `RecognizerIntent.ACTION_RECOGNIZE_SPEECH`, `EXTRA_LANGUAGE = "en-IN"`, `EXTRA_PARTIAL_RESULTS = true` | `RECORD_AUDIO` (runtime) |
| iOS (native) | `SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))` + `AVAudioEngine` | `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` in Info.plist |
| Flutter | [`speech_to_text`](https://pub.dev/packages/speech_to_text), `localeId: 'en_IN'` | the same permissions as above |
| React Native | [`@react-native-voice/voice`](https://github.com/react-native-voice/voice), `Voice.start('en-IN')` | the same permissions as above |

**Behaviour**
- Tap the mic to start, and tap again to stop. Also stop automatically after about 2 seconds of silence (the platforms do this).
- Show partial results live in the text box. Let the customer **edit the text** before continuing; mis-heard words are common.
- If the permission is denied or speech recognition is unavailable, hide the mic and keep typing.
- When the text came from voice, send `"source": "VOICE"`. The assistant then allows for transcription mistakes. If the customer edited it heavily afterwards, `"TEXT"` is fine.

---

## 3. Screen 2 — Get the draft

### Request

```http
POST /bookings/draft
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{
  "message": "the pipe under my kitchen sink is leaking since morning can someone come tomorrow evening",
  "source": "VOICE"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `message` | string, 3–2000 chars | yes | What the customer typed, or what the phone heard |
| `source` | `"TEXT"` or `"VOICE"` | no (default `TEXT`) | How it was entered |
| `answers` | array of `{ question, answer }`, max 4 | no | Only when re-asking after `NEEDS_INFO` (see §4.2) |

The customer must be signed in (customer account). Show a loader with text such as "Understanding your problem…". Use a **15-second** client timeout; if it runs out, treat it like a 503 (see §6).

### Response `200`

```json
{
  "success": true,
  "data": {
    "status": "READY",
    "service": { "id": "3f2e1d0c-…", "name": "Plumber", "tier": "REPAIR", "basePrice": 349, "image": "/categories/3f2e1d0c-…/image?v=1730000000000" },
    "alternatives": [],
    "description": "Pipe under the kitchen sink leaking since this morning.",
    "urgency": "SOON",
    "suggestedScheduledAt": "2026-11-04T12:30:00.000Z",
    "questions": [],
    "safetyAdvice": null,
    "price": 349
  }
}
```

| Field | Meaning | What the app does |
|---|---|---|
| `status` | `READY`, `NEEDS_INFO` or `NOT_OFFERED` | Decides which screen state to show (§4) |
| `service` | The chosen service, or `null` | Pre-select it on the review screen |
| `alternatives` | 0–2 other services that might fit | Show as chips to switch to |
| `description` | A clean description for the vendor | Pre-fill an editable "Problem" field; send it as `description` when booking |
| `urgency` | `EMERGENCY`, `SOON` or `FLEXIBLE` | Show a badge; for `EMERGENCY`, highlight the earliest slot |
| `suggestedScheduledAt` | ISO date-time (UTC), or `null` | Pre-select it in the date/time picker (show it in local time). `null` means the customer picks |
| `questions` | 0–2 short questions | Show with answer fields (§4.2) |
| `safetyAdvice` | One sentence, or `null` | **Show prominently** at the top, in red/amber |
| `price` | The service's base price (₹), or `null` | "From ₹349" |

`image` is a path relative to the server base URL (`<server>/api/v1` + `image`) and is public.

---

## 4. Screen 3 — Review and confirm

### 4.1 `status: "READY"`

Show a confirm screen with every value **editable**:

- **Service:** `service.name`, its image and "from ₹{price}". Offer a "Change" action, with the `alternatives` as quick options, then the full list (`GET /categories`).
- **Problem:** a text field pre-filled with `description`. The booking API needs 10–1000 characters.
- **When:** a date/time picker pre-filled with `suggestedScheduledAt`, or empty. Rules: at least **60 minutes from now**, at most **60 days ahead**. Use 15-minute steps.
- **Address:** the customer's saved addresses (`GET /users/me/addresses`), with the default pre-selected. Each address has `serviceable`; **disable or warn on addresses with `serviceable: false`** ("We're not in this area yet").
- **Payment:** "Pay after service" or "Pay online".
- An **urgency badge** (`EMERGENCY` → red "Emergency"; `SOON` → amber; `FLEXIBLE` → none).
- **`safetyAdvice`**, if present, in a banner at the top. For example: *"Switch off the main power switch until the electrician arrives."*
- A **Book** button.

### 4.2 `status: "NEEDS_INFO"`

The assistant isn't sure. The draft may have:
- `service`: its best guess, which may be `null`;
- `alternatives`: other likely services;
- `questions`: up to 2 questions.

Show the questions, each with a short answer field (and a mic button, optionally), plus the service options as selectable chips.

- If the customer **picks a service chip**, go straight to the confirm screen (§4.1) with that service. Keep the draft's `description` and time.
- If they **answer the questions**, call `POST /bookings/draft` again with the **same `message`** plus the answers:

```json
{
  "message": "my water pump is not working",
  "source": "TEXT",
  "answers": [
    { "question": "Is water coming out at all, or has the motor stopped?", "answer": "Motor makes noise but no water" }
  ]
}
```

Use the new draft. Usually it comes back `READY`. If it is still `NEEDS_INFO` after one round of answers, show the full service list rather than asking again.

### 4.3 `status: "NOT_OFFERED"`

None of the services fits (for example "wash my car"). Show *"We don't offer this yet"* with a button to browse services, and let the customer edit their message and try again.

---

## 5. Screen 4 — Book (existing API, unchanged)

When the customer taps **Book**, call the existing endpoint with the values from the confirm screen:

```http
POST /bookings
Authorization: Bearer <accessToken>
```

```json
{
  "categoryId": "<service.id the customer confirmed>",
  "scheduledAt": "2026-11-04T18:00:00+05:30",
  "description": "<the confirmed problem text>",
  "addressId": "<the chosen saved address>",
  "paymentMode": "PAY_AFTER_SERVICE"
}
```

- `scheduledAt` must be an ISO date-time **with a timezone** (`+05:30` or `Z`). You can send `suggestedScheduledAt` back exactly as received.
- The response is the full booking. For `paymentMode: "ONLINE"` it includes `checkout` for Razorpay, followed by `POST /bookings/{id}/payment/confirm`. This is the same as the existing booking flow.
- Possible errors are the same as today's booking flow:
  - **400** for a time out of range or a description that's too short;
  - **400** with `details.code: "PINCODE_NOT_SERVICEABLE"` when the address is outside the service area;
  - **503** if online payment isn't available (offer "Pay after service").

---

## 6. Errors and fallbacks

**Rule:** whatever goes wrong with the assistant, the customer can always continue by choosing the service themselves. Never leave them stuck.

| HTTP | `details.code` | When | App behaviour |
|---|---|---|---|
| 400 | — | `message` shorter than 3 or longer than 2000 characters, or a bad `source` | Show `message` from the response; keep the text box |
| 401 | `TOKEN_EXPIRED` etc. | Session | The usual refresh / sign-in handling |
| 403 | — | Not a customer account | Shouldn't happen in the customer app |
| 422 | `ASSISTANT_NO_DRAFT` | The assistant couldn't make sense of the message | *"Sorry, we couldn't understand that."* Offer **Try again** (edit the text) and **Choose a service yourself** |
| 429 | — | More than 20 drafts in 10 minutes from this account | *"Please wait a few minutes"*, plus **Choose a service yourself** |
| 503 | `ASSISTANT_UNAVAILABLE` | The assistant is switched off, busy or down | Go straight to the service picker with the typed text pre-filled as the description. Optionally hide the assistant entry point for the rest of the session |
| timeout / network | — | No response within 15 s | The same as 503 |

All errors have the shape `{ "success": false, "message": "…" }`, plus `details` where the table lists a code. `message` is written for customers and can be shown as is.

---

## 7. Checklist

- [ ] "Describe your problem" entry point on the home screen
- [ ] Text box (3–2000 chars) and mic button with live transcript, `en-IN`
- [ ] Microphone and speech permissions with clear explanations; mic hidden if denied or unavailable
- [ ] `source: "VOICE"` when the text came from speech
- [ ] Loader with a 15 s timeout
- [ ] `READY` → confirm screen pre-filled with service, description, time and price; everything editable
- [ ] `NEEDS_INFO` → questions with answers re-sent as `answers`, and service chips; after one round, fall back to the full list
- [ ] `NOT_OFFERED` → "We don't offer this yet" and browse services
- [ ] `safetyAdvice` shown prominently; urgency badge
- [ ] Addresses with `serviceable: false` disabled or warned
- [ ] Book with the existing `POST /bookings` (and Razorpay for online payment)
- [ ] Every error path leads to "Choose a service yourself"

## 8. Test messages

Try these while building. Results can vary a little between runs.

| Message | Expected |
|---|---|
| "kitchen sink pipe leaking since morning, come tomorrow evening" | `READY`, Plumber, a time tomorrow ~18:00 |
| "sparks from the switch board and burning smell" | `READY`, Electrician, `EMERGENCY`, `safetyAdvice` about switching off the mains |
| "my AC is not cooling" | `READY`, AC Repair |
| "water pump not working" | likely `NEEDS_INFO` (Plumber or Electrician) |
| "please wash my car" | `NOT_OFFERED` |
| "hi" | 400 (too short) |

The server needs its AI key set for real drafts. Without it, every call answers **503 `ASSISTANT_UNAVAILABLE`**, which is useful for testing the fallback path.
