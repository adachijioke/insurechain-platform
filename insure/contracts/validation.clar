;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-invalid-provider (err u102))
(define-constant err-duplicate-claim (err u103))

;; Define data maps
(define-map claims 
  { claim-id: (string-ascii 36) } 
  { 
    patient-id: (string-ascii 36), 
    provider-id: (string-ascii 36), 
    service-code: (string-ascii 10), 
    amount: uint,
    status: (string-ascii 20)
  }
)

(define-map healthcare-providers 
  { provider-id: (string-ascii 36) } 
  { 
    name: (string-ascii 100), 
    license-number: (string-ascii 20), 
    verified: bool 
  }
)


;; Function to add a healthcare provider
(define-public (add-healthcare-provider (provider-id (string-ascii 36)) (name (string-ascii 100)) (license-number (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-none (map-get? healthcare-providers { provider-id: provider-id })) err-already-exists)
    (ok (map-set healthcare-providers 
      { provider-id: provider-id }
      { name: name, license-number: license-number, verified: false }
    ))
  )
)

;; Function to verify a healthcare provider
(define-public (verify-healthcare-provider (provider-id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (match (map-get? healthcare-providers { provider-id: provider-id })
      provider (ok (map-set healthcare-providers 
        { provider-id: provider-id }
        (merge provider { verified: true })
      ))
      err-invalid-provider
    )
  )
)

;; Function to submit a claim
(define-public (submit-claim (claim-id (string-ascii 36)) (patient-id (string-ascii 36)) (provider-id (string-ascii 36)) (service-code (string-ascii 10)) (amount uint))
  (begin
    (asserts! (is-some (map-get? healthcare-providers { provider-id: provider-id })) err-invalid-provider)
    (asserts! (is-none (map-get? claims { claim-id: claim-id })) err-duplicate-claim)
    (ok (map-set claims
      { claim-id: claim-id }
      { 
        patient-id: patient-id, 
        provider-id: provider-id, 
        service-code: service-code, 
        amount: amount,
        status: "pending"
      }
    ))
  )
)

;; Function to validate a claim
(define-public (validate-claim (claim-id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (match (map-get? claims { claim-id: claim-id })
      claim (begin
        (asserts! (is-valid-provider (get provider-id claim)) err-invalid-provider)
        (asserts! (not (is-duplicate-claim claim-id)) err-duplicate-claim)
        (ok (map-set claims
          { claim-id: claim-id }
          (merge claim { status: "validated" })
        ))
      )
      err-invalid-provider
    )
  )
)

;; Helper function to check if a provider is valid
(define-private (is-valid-provider (provider-id (string-ascii 36)))
  (match (map-get? healthcare-providers { provider-id: provider-id })
    provider (get verified provider)
    false
  )
)

;; Helper function to check for duplicate claims
(define-private (is-duplicate-claim (claim-id (string-ascii 36)))
  (is-some (map-get? claims { claim-id: claim-id }))
)

;; Function to get claim details
(define-read-only (get-claim (claim-id (string-ascii 36)))
  (map-get? claims { claim-id: claim-id })
)

;; Function to get healthcare provider details
(define-read-only (get-healthcare-provider (provider-id (string-ascii 36)))
  (map-get? healthcare-providers { provider-id: provider-id })
)