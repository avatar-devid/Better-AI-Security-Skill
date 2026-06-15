# Security — Payment

## Scope

This module covers payment processing security: PCI-DSS compliance, payment gateway integration, tokenization, fraud prevention, and financial transaction security.

## Self-Contained Module

This module does not have sub-routers. It covers all payment security topics.

## Payment Security Rules

### 1. PCI-DSS Compliance

```
RULE: If you process, store, or transmit cardholder data, PCI-DSS applies.

Simplest path to compliance: NEVER handle card data directly.

Use a PCI-compliant payment processor:
- Stripe (Elements, Checkout, Payment Intents)
- Braintree (Drop-in UI, Hosted Fields)
- PayPal
- Adyen
- Square

With hosted payment forms:
- Card data goes directly from browser to payment processor
- Your server NEVER sees card numbers
- You handle only tokens/payment intent IDs
- This reduces your PCI scope to SAQ A (minimal)

NEVER:
- Build your own payment form that collects card numbers
- Store credit card numbers in your database
- Log credit card numbers anywhere
- Send credit card numbers via email, chat, or SMS
- Store CVV/CVC codes (ever, even encrypted)
- Store magnetic stripe data
```

### 2. Payment Flow Security

```
RULE: Use server-side payment confirmation. Never trust the client.

Secure payment flow:
1. Client selects items → server calculates total
2. Server creates payment intent (amount, currency, metadata)
3. Client submits payment details to payment processor (not your server)
4. Payment processor returns token/confirmation
5. Server verifies payment status via payment processor API
6. Server fulfills order ONLY after verified payment

NEVER:
- Calculate payment amount on client side
- Trust client-provided price or total
- Fulfill order before payment verification
- Use client-side payment status as source of truth
```

### 3. Webhook Verification

```
RULE: Verify ALL payment webhooks before processing.

Verification steps:
1. Validate webhook signature (HMAC-SHA256 with webhook secret)
2. Validate timestamp (reject webhooks older than 5 minutes)
3. Validate event is from expected payment processor (IP whitelist optional)
4. Process idempotently (handle duplicate webhooks)
5. Return 200 quickly, process asynchronously

NEVER:
- Process webhooks without signature verification
- Skip idempotency checks (double-charging risk)
- Expose webhook secret
- Process webhooks synchronously (timeout risk)
```

### 4. Price Integrity

```
RULE: Price MUST be calculated server-side.

Server-side price calculation:
- Fetch product price from database (never from client)
- Apply discounts/coupons server-side (verify coupon validity)
- Calculate tax server-side
- Calculate shipping server-side
- Verify total matches expected amount before charging

Race condition prevention:
- Use database locks or atomic operations for inventory check + payment
- Handle concurrent purchases (last-item scenarios)
- Prevent coupon reuse via atomic counter/flag
```

### 5. Fraud Prevention

```
RULE: Implement multiple fraud detection layers.

Technical measures:
- 3D Secure (3DS) for card authentication
- AVS (Address Verification System) checks
- CVV/CVC verification
- Device fingerprinting
- IP geolocation vs. billing address comparison
- Velocity checks (too many transactions in short time)
- Amount threshold alerts

Business rules:
- Flag first-time large purchases for manual review
- Flag shipping ≠ billing address
- Flag multiple cards from same device/IP
- Flag rapid successive transactions
- Implement chargeback prevention (clear descriptions, receipts)
```

### 6. Refund & Chargeback Security

```
RULE: Refund endpoints are as sensitive as payment endpoints.

Checklist:
- Require admin/authorized role for refunds
- Validate refund amount ≤ original payment amount
- Prevent duplicate refunds (idempotency)
- Log all refund actions with admin user, reason, amount
- Implement refund approval workflow for large amounts
- Track refund rate per customer (fraud indicator)
- Store refund evidence (for chargeback disputes)
```

### 7. Subscription Security

```
IF the application handles recurring payments:

- Store subscription status server-side (not client)
- Validate subscription status on every feature access
- Handle payment failure gracefully (grace period, retry, notify)
- Implement dunning management (automated retry with notification)
- Secure cancellation flow (prevent accidental, allow re-subscribe)
- Handle plan changes mid-cycle (proration)
- Audit trail for all subscription changes
- Webhook processing for subscription lifecycle events
```

### 8. Financial Data Display

```
RULE: Mask financial data in UI and logs.

Display rules:
- Card number: show last 4 digits only (**** **** **** 1234)
- Bank account: show last 4 digits
- Transaction amount: show full amount (not sensitive)
- Billing address: show city/country, hide street (depends on context)

Logging rules:
- Log transaction ID (safe)
- Log amount (safe)
- Log card last 4 digits (safe)
- Log payment status (safe)
- NEVER log full card numbers
- NEVER log CVV/CVC
- NEVER log full bank account numbers
- NEVER log payment processor API keys
```

### 9. Currency & Amount Handling

```
RULE: Handle money with precision. Floating point errors are unacceptable.

- Use integer cents/pips (1234 = $12.34) — NEVER floating point
- Or use decimal libraries (BigDecimal, Decimal.js, decimal)
- Store currency code with amount (ISO 4217)
- Validate currency matches payment processor configuration
- Handle multi-currency correctly (exchange rates server-side)
- Round consistently (banker's rounding recommended)
- Display with correct decimal places per currency (JPY has 0, USD has 2)
```

### 10. Compliance & Audit

```
RULE: Financial transactions require comprehensive audit trails.

Log for every transaction:
- Transaction ID (your system)
- Payment processor transaction ID
- Timestamp (UTC)
- Amount + currency
- Status (pending, success, failed, refunded)
- Customer ID
- Payment method (type + last 4)
- IP address
- Failure reason (if failed)
- Admin user (if manual action)

Retention:
- Transaction records: 7 years minimum (varies by jurisdiction)
- Audit logs: 7 years minimum
- PCI-DSS logs: 1 year minimum (3 months immediately accessible)

Compliance considerations:
- PCI-DSS (card data)
- PSD2/SCA (Europe: Strong Customer Authentication)
- GDPR (Europe: data protection for payment data)
- SOX (public companies: financial reporting)
```
