;; RealtyVault: A Blockchain Escrow System for Property Transactions

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-TERM-DAYS u365)
(define-constant CONSTRUCTION-YEAR-MIN u1900)
(define-constant CONSTRUCTION-YEAR-MAX u2100)
(define-constant BLOCKS-PER-DAY u144)
(define-constant DEPOSIT-PERCENTAGE u10)
(define-constant MAX-UINT u340282366920938463463374607431768211455)

;; Error Constants
(define-constant ERROR-NOT-AUTHORIZED (err u100))
(define-constant ERROR-ESCROW-EXISTS (err u101))
(define-constant ERROR-NO-ESCROW (err u102))
(define-constant ERROR-INVALID-PRICE (err u103))
(define-constant ERROR-DEPOSIT-MADE (err u104))
(define-constant ERROR-NO-DEPOSIT (err u105))
(define-constant ERROR-INVALID-STATUS (err u106))
(define-constant ERROR-WRONG-SELLER (err u107))
(define-constant ERROR-WRONG-BUYER (err u108))
(define-constant ERROR-INVALID-USER (err u109))
(define-constant ERROR-DEADLINE-PASSED (err u110))
(define-constant ERROR-INSPECTION-FAILED (err u111))
(define-constant ERROR-INVALID-AMOUNT (err u112))
(define-constant ERROR-INVALID-TERM (err u113))
(define-constant ERROR-INVALID-PROPERTY-ID (err u114))
(define-constant ERROR-INVALID-SIZE (err u115))
(define-constant ERROR-INVALID-YEAR (err u116))
(define-constant ERROR-INVALID-ADDRESS (err u117))
(define-constant ERROR-ARITHMETIC-OVERFLOW (err u118))

;; Data Variables
(define-data-var contract-admin principal CONTRACT-OWNER)
(define-data-var property-seller principal CONTRACT-OWNER)
(define-data-var property-buyer (optional principal) none)
(define-data-var property-price uint u0)
(define-data-var deposit-amount uint u0)
(define-data-var escrow-initialized bool false)
(define-data-var deposit-received bool false)
(define-data-var transaction-completed bool false)
(define-data-var deadline uint u0)
(define-data-var inspection-passed bool false)
(define-data-var maintenance-fund uint u0)

;; Data Maps
(define-map approved-participants principal bool)
(define-map transaction-history
  { tx-id: uint }
  {
    amount: uint,
    timestamp: uint,
    status: (string-ascii 20)
  })

(define-map property-catalog
  { property-id: uint }
  {
    address: (string-ascii 50),
    area: uint,
    build-year: uint,
    inspection-date: uint
  })

;; Private Functions
(define-private (is-contract-admin)
  (is-eq tx-sender (var-get contract-admin)))

(define-private (is-seller)
  (is-eq tx-sender (var-get property-seller)))

(define-private (is-buyer)
  (match (var-get property-buyer)
    buyer-principal (is-eq tx-sender buyer-principal)
    false))

(define-private (validate-account (account-principal principal))
  (begin
    (asserts! (not (is-eq account-principal CONTRACT-OWNER)) ERROR-INVALID-USER)
    (asserts! (not (is-eq account-principal tx-sender)) ERROR-INVALID-USER)
    (ok account-principal)))

(define-private (add-participant (account-principal principal))
  (begin
    (try! (validate-account account-principal))
    (map-set approved-participants account-principal true)
    (ok account-principal)))

(define-private (check-deadline)
  (if (> block-height (var-get deadline))
    ERROR-DEADLINE-PASSED
    (ok true)))

(define-private (validate-term (term-days uint))
  (if (and (> term-days u0) (<= term-days MAX-TERM-DAYS))
    (ok term-days)
    ERROR-INVALID-TERM))

(define-private (validate-property-id (property-id uint))
  (if (and (> property-id u0) (< property-id MAX-UINT))
    (ok property-id)
    ERROR-INVALID-PROPERTY-ID))

(define-private (validate-area (area-size uint))
  (if (and (> area-size u0) (< area-size MAX-UINT))
    (ok area-size)
    ERROR-INVALID-SIZE))

(define-private (validate-year (year uint))
  (if (and (>= year CONSTRUCTION-YEAR-MIN) (<= year CONSTRUCTION-YEAR-MAX))
    (ok year)
    ERROR-INVALID-YEAR))

(define-private (validate-address (address (string-ascii 50)))
  (if (> (len address) u0)
    (ok address)
    ERROR-INVALID-ADDRESS))

(define-private (validate-inspection (result bool))
  (ok result))

(define-private (calculate-blocks (term-days uint))
  (let ((verified-term (try! (validate-term term-days))))
    (asserts! (< (* verified-term BLOCKS-PER-DAY) MAX-UINT) ERROR-ARITHMETIC-OVERFLOW)
    (ok (* verified-term BLOCKS-PER-DAY))))

(define-private (safe-add (num1 uint) (num2 uint))
  (let ((result (+ num1 num2)))
    (asserts! (>= result num1) ERROR-ARITHMETIC-OVERFLOW)
    (ok result)))

;; Public Functions
(define-public (initialize-escrow (seller principal) (buyer principal) (price uint) (term-days uint))
  (begin
    (asserts! (not (var-get escrow-initialized)) ERROR-ESCROW-EXISTS)
    (asserts! (is-contract-admin) ERROR-NOT-AUTHORIZED)
    (asserts! (> price u0) ERROR-INVALID-PRICE)
    (asserts! (not (is-eq seller buyer)) ERROR-INVALID-USER)
    
    (let ((verified-term (unwrap! (validate-term term-days) ERROR-INVALID-TERM))
          (total-blocks (try! (calculate-blocks verified-term))))
      
      (try! (add-participant seller))
      (try! (add-participant buyer))
      
      (var-set property-seller seller)
      (var-set property-buyer (some buyer))
      (var-set property-price price)
      (var-set deposit-amount (/ (* price DEPOSIT-PERCENTAGE) u100))
      (try! (safe-add block-height total-blocks))
      (var-set deadline (+ block-height total-blocks))
      (var-set escrow-initialized true)
      (ok true))))

(define-public (register-property (property-id uint) (address (string-ascii 50)) (area-size uint) (year uint))
  (begin
    (asserts! (is-seller) ERROR-NOT-AUTHORIZED)
    (asserts! (var-get escrow-initialized) ERROR-NO-ESCROW)
    
    (let ((verified-id (unwrap! (validate-property-id property-id) ERROR-INVALID-PROPERTY-ID))
          (verified-address (unwrap! (validate-address address) ERROR-INVALID-ADDRESS))
          (verified-area (unwrap! (validate-area area-size) ERROR-INVALID-SIZE))
          (verified-year (unwrap! (validate-year year) ERROR-INVALID-YEAR)))
      
      (map-set property-catalog
        { property-id: verified-id }
        {
          address: verified-address,
          area: verified-area,
          build-year: verified-year,
          inspection-date: u0
        })
      (ok true))))

(define-public (record-inspection (property-id uint) (result bool))
  (begin
    (asserts! (is-contract-admin) ERROR-NOT-AUTHORIZED)
    (asserts! (var-get escrow-initialized) ERROR-NO-ESCROW)
    
    (let ((verified-id (unwrap! (validate-property-id property-id) ERROR-INVALID-PROPERTY-ID))
          (verified-result (unwrap! (validate-inspection result) ERROR-INVALID-STATUS)))
      (var-set inspection-passed verified-result)
      (ok true))))

(define-public (send-deposit)
  (let ((deposit-value (var-get deposit-amount)))
    (begin
      (try! (check-deadline))
      (asserts! (var-get escrow-initialized) ERROR-NO-ESCROW)
      (asserts! (is-buyer) ERROR-NOT-AUTHORIZED)
      (asserts! (not (var-get deposit-received)) ERROR-DEPOSIT-MADE)
      
      (try! (stx-transfer? deposit-value tx-sender (as-contract tx-sender)))
      (var-set deposit-received true)
      (map-set transaction-history {tx-id: u1}
        {
          amount: deposit-value,
          timestamp: block-height,
          status: "DEPOSITED"
        })
      (ok true))))

(define-public (finalize-payment)
  (let ((remaining-balance (- (var-get property-price) (var-get deposit-amount))))
    (begin
      (try! (check-deadline))
      (asserts! (var-get escrow-initialized) ERROR-NO-ESCROW)
      (asserts! (is-buyer) ERROR-NOT-AUTHORIZED)
      (asserts! (var-get deposit-received) ERROR-NO-DEPOSIT)
      (asserts! (var-get inspection-passed) ERROR-INSPECTION-FAILED)
      
      (try! (stx-transfer? remaining-balance tx-sender (var-get property-seller)))
      (var-set transaction-completed true)
      (map-set transaction-history {tx-id: u2}
        {
          amount: remaining-balance,
          timestamp: block-height,
          status: "COMPLETED"
        })
      (ok true))))

(define-public (refund-deposit)
  (let ((buyer-principal (unwrap! (var-get property-buyer) ERROR-NO-ESCROW)))
    (begin
      (asserts! (var-get escrow-initialized) ERROR-NO-ESCROW)
      (asserts! (is-contract-admin) ERROR-NOT-AUTHORIZED)
      (asserts! (var-get deposit-received) ERROR-NO-DEPOSIT)
      (asserts! (not (var-get transaction-completed)) ERROR-INVALID-STATUS)
      
      (try! (as-contract (stx-transfer? (var-get deposit-amount) tx-sender buyer-principal)))
      (var-set deposit-received false)
      (map-set transaction-history {tx-id: u3}
        {
          amount: (var-get deposit-amount),
          timestamp: block-height,
          status: "REFUNDED"
        })
      (ok true))))

(define-public (add-maintenance-funds (amount uint))
  (begin
    (asserts! (var-get transaction-completed) ERROR-INVALID-STATUS)
    (asserts! (> amount u0) ERROR-INVALID-AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set maintenance-fund (+ (var-get maintenance-fund) amount))
    (ok true)))

;; Read-only Functions
(define-read-only (get-escrow-details)
  {
    seller: (var-get property-seller),
    buyer: (var-get property-buyer),
    price: (var-get property-price),
    deposit: (var-get deposit-amount),
    escrow-initialized: (var-get escrow-initialized),
    deposit-received: (var-get deposit-received),
    transaction-completed: (var-get transaction-completed),
    deadline: (var-get deadline),
    inspection-status: (var-get inspection-passed),
    maintenance-balance: (var-get maintenance-fund)
  })

(define-read-only (get-transaction-details (tx-id uint))
  (map-get? transaction-history {tx-id: tx-id}))

(define-read-only (get-property-details (property-id uint))
  (map-get? property-catalog {property-id: property-id}))

(define-read-only (is-approved-participant (user-principal principal))
  (default-to false (map-get? approved-participants user-principal)))

(define-read-only (get-time-remaining)
  (if (> (var-get deadline) block-height)
    (some (- (var-get deadline) block-height))
    none))