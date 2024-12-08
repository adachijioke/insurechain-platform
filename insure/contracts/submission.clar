;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u401))
(define-constant err-not-found (err u404))
(define-constant err-already-exists (err u409))

;; Define data maps
(define-map claims
  uint
  {
    patient: principal,
    service-date: uint,
    service-description: (string-utf8 100),
    cost: uint,
    status: (string-utf8 20)
  }
)

(define-map patient-claims principal (list 50 uint))

(define-map providers
  principal
  {
    name: (string-utf8 50),
    license-number: (string-utf8 20)
  }
)

;; Define data variables
(define-data-var claim-id-nonce uint u0)

;; Private functions
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-provider (provider principal))
  (is-some (map-get? providers provider))
)

(define-private (increment-and-get-claim-id)
  (begin
    (var-set claim-id-nonce (+ (var-get claim-id-nonce) u1))
    (var-get claim-id-nonce)
  )
)


;; Register a new healthcare provider
(define-public (register-provider (name (string-utf8 50)) (license-number (string-utf8 20)))
  (begin
    (asserts! (is-contract-owner) err-unauthorized)
    (asserts! (is-none (map-get? providers tx-sender)) err-already-exists)
    (map-set providers tx-sender { name: name, license-number: license-number })
    (ok true)
  )
)

;; Submit a new health insurance claim
(define-public (submit-claim 
    (patient principal)
    (service-date uint)
    (service-description (string-utf8 100))
    (cost uint))
  (let
    (
      (new-id (increment-and-get-claim-id))
      (provider tx-sender)
      (initial-status u"Submitted")
    )
    
    (asserts! (is-provider provider) err-unauthorized)
    (map-set claims
      new-id
      {
        patient: patient,
        service-date: service-date,
        service-description: service-description,
        cost: cost,
        status: initial-status
      }
    )
    (map-set patient-claims
      patient
      (unwrap-panic (as-max-len? 
        (append 
          (default-to (list) (map-get? patient-claims patient))
          new-id
        )
        u50
      ))
    )
    (print { type: "new-claim-submitted", claim-id: new-id, patient: patient, provider: provider })
    (ok new-id)
  )
)

;; Get claim details
(define-read-only (get-claim (claim-id uint))
  (match (map-get? claims claim-id)
    claim (ok claim)
    (err u404)
  )
)

;; Get all claim IDs for a patient
(define-read-only (get-patient-claims (patient principal))
  (ok (default-to (list) (map-get? patient-claims patient)))
)

;; Update claim status (only by contract owner)
(define-public (update-claim-status (claim-id uint) (new-status (string-utf8 20)))
  (let
    (
      (claim (unwrap! (map-get? claims claim-id) err-not-found))
    )
    (asserts! (is-contract-owner) err-unauthorized)
    (map-set claims claim-id (merge claim { status: new-status }))
    (ok true)
  )
)

;; Get provider details
(define-read-only (get-provider-details (provider principal))
  (match (map-get? providers provider)
    details (ok details)
    (err u404)
  )
)