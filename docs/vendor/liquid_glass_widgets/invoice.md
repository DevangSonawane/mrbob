Customer Invoices
Mr Bob customer app - API guide
How the customer app shows the invoice for a completed booking: as data for an invoice screen, and as a PDF the
customer can open, download or share.
Base URL https://home-services-backend-7cyx.onrender.com/api/v1
Live reference (try any call) https://home-services-backend-7cyx.onrender.com/api-docs
Version 18 October 2026
CONTENTS
Before you start
Invoice endpoints
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 2
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 3
Mr Bob - Customer Invoice API Page 1
Before you start
Who can call these. The signed-in customer, for their own bookings. Send Authorization: Bearer
<accessToken> (the token from the customer's OTP sign-in). Paths are relative to the base URL, so GET
/customer/bookings/{id}/invoice means GET
https://home-services-backend-7cyx.onrender.com/api/v1/customer/bookings/{id}/invoice.
When there is an invoice. One invoice per booking, issued the moment the job is completed, whether the vendor
completes it with the customer's code or the team marks it completed. Bookings completed earlier have one too.
Show the invoice option on a booking once its status is COMPLETED; before that, and for someone else's booking,
both calls return 404.
Invoice number. Each invoice has a number like INV-000042, separate from the booking number (BK-000123). It
never changes.
Amounts. All amounts are in rupees (currency is INR). No tax is charged for now: tax is 0 and total equals
subtotal. payment.amountPaid is what the customer has paid so far; the balance due is total -
payment.amountPaid.
Paid or not. status is PAID once the customer has paid (online, or to the vendor after the service), UNPAID until then,
and REFUND_PENDING / REFUNDED after a refund. A pay-after-service booking can be completed before the vendor
records the payment, so its invoice may say UNPAID at first and turn PAID later; read it fresh each time the screen
opens.
The PDF. The invoice response's pdf field is the path of the PDF. Add it to the base URL and fetch it with the same
token; the response is application/pdf, one A4 page, suggested file name INV-000042.pdf. Download it to a file
and open it with the platform's viewer or share sheet; a plain link will not work because it needs the token.
Responses and errors. The invoice comes back as { "success": true, "data": { ... } }. A failure is {
"success": false, "message": "..." }: 401 means the token expired (refresh it with POST /auth/refresh and
retry), 404 means no invoice yet or not the customer's booking.
What the invoice contains
Field What to show
invoiceNumber, issuedAt,
status
Header: number, date issued, Paid / Payment due
business Who the invoice is from: name, and address / email / phone when set
billedTo The customer's name, phone, email and the address where the job was done
booking Booking number, service, service date, completion date, city
vendor The professional who did the job
items One line per item: description (the service), details (the problem described), quantity, unit
price, amount
subtotal, tax, total Totals (tax is 0)
payment mode (ONLINE or PAY_AFTER_SERVICE), method (e.g. UPI, CASH), paidAt,
amountPaid
pdf Path of the PDF for this invoice
Mr Bob - Customer Invoice API Page 2
Invoice endpoints
Two calls, both for the signed-in customer and one of their own bookings. Show an invoice option on a booking once
its status is COMPLETED.
Method Endpoint What it does
GET /customer/bookings/{id}/invoice Get the invoice for a completed booking
GET /customer/bookings/{id}/invoice/pdf Download the invoice as a PDF
GET /customer/bookings/{id}/invoice
Get the invoice for a completed booking | Customers only.
Returns 404 for someone else's booking, and while the booking is not completed yet (the invoice is issued when the
job is completed).
GET /customer/bookings/{id}/invoice/pdf
Download the invoice as a PDF | Customers only.
The same invoice as a one-page PDF named after the invoice number.
Mr Bob - Customer Invoice API Page 3
Example: GET /customer/bookings/{id}/invoice -> data
{
"id": "b7c6d5e4-1111-4a2b-9c3d-4e5f6a7b8c9d",
"invoiceNumber": "INV-000042",
"issuedAt": "2026-10-19T07:45:00.000Z",
"status": "PAID",
"currency": "INR",
"business": {
"name": "Mr Bob Home Services",
"address": null,
"email": null,
"phone": null
},
"billedTo": {
"id": "d4c3b2a1-9999-4f8e-8d7c-6b5a4f3e2d1c",
"name": "Aarav Mehta",
"phone": "+919898989898",
"email": "aarav@example.com",
"address": "22, Hill Road, Bandra West, Mumbai, Maharashtra 400050"
},
"booking": {
"id": "5e4d3c2b-4444-4a1b-8c9d-0e1f2a3b4c5d",
"bookingNumber": "BK-000123",
"service": {
"id": "3f2e1d0c-2222-4b3a-8c7d-6e5f4a3b2c1d",
"name": "Plumber"
},
"scheduledAt": "2026-10-19T05:30:00.000Z",
"completedAt": "2026-10-19T07:45:00.000Z",
"city": "Mumbai"
},
"vendor": {
"id": "a1b2c3d4-0000-4e5f-8a9b-0c1d2e3f4a5b",
"name": "Ravi Kumar"
},
"items": [
{
"description": "Plumber",
"details": "Kitchen tap is leaking",
"quantity": 1,
"unitPrice": 349,
"amount": 349
}
],
"subtotal": 349,
"tax": 0,
"total": 349,
"payment": {
"mode": "PAY_AFTER_SERVICE",
"method": "UPI",
"paidAt": "2026-10-19T07:50:00.000Z",
"amountPaid": 349
},
"pdf": "/customer/bookings/5e4d3c2b-4444-4a1b-8c9d-0e1f2a3b4c5d/invoice/pdf"
}
Mr Bob - Customer Invoice API Page 4