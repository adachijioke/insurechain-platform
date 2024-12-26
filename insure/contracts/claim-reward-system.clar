;; Define the fungible token for rewards
(define-fungible-token claim-token u1000000000)

(define-constant contract-owner tx-sender)
(define-constant submission-window u86400) ;; 24 hours in seconds
(define-constant accuracy-threshold u90) ;; 90% accuracy required for reward

(define-data-var claim-counter u0)

;; Maps
(define-map claims { id: uint } { submitter: principal, timestamp: uint, accuracy: uint })
(define-map user-stats principal { total-claims: uint, accurate-claims: uint })

;; Error codes
(define-constant err-not-owner (err u100))
(define-constant err-claim-not-found (err u101))
(define-constant err-invalid-accuracy (err u102))


(define-public (submit-claim)
  (let
    (
      (claim-id (var-get claim-counter))
      (current-time block-height)
    )
    (map-set claims { id: claim-id }
      { submitter: tx-sender, timestamp: current-time, accuracy: u0 }
    )
    (var-set claim-counter (+ claim-id u1))
    (ok claim-id)
  )
)

;; Verify claim accuracy (only contract owner can do this)
(define-public (verify-claim (claim-id uint) (accuracy uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (asserts! (<= accuracy u100) err-invalid-accuracy)
    (match (map-get? claims { id: claim-id })
      claim-data (begin
        (map-set claims { id: claim-id }
          (merge claim-data { accuracy: accuracy })
        )
        (process-reward claim-id)
      )
      err-claim-not-found
    )
  )
)

;; Process reward based on timeliness and accuracy
(define-private (process-reward (claim-id uint))
  (match (map-get? claims { id: claim-id })
    claim-data (let
      (
        (submitter (get submitter claim-data))
        (timestamp (get timestamp claim-data))
        (accuracy (get accuracy claim-data))
        (current-time block-height)
        (time-difference (- current-time timestamp))
      )
      (if (and (<= time-difference submission-window) (>= accuracy accuracy-threshold))
        (begin
          (try! (ft-mint? claim-token u100 submitter))
          (update-user-stats submitter accuracy)
          (ok true)
        )
        (ok false)
      )
    )
    err-claim-not-found
  )
)

;; Update user statistics
(define-private (update-user-stats (user principal) (accuracy uint))
  (match (map-get? user-stats user)
    existing-stats (begin
      (map-set user-stats user
        {
          total-claims: (+ (get total-claims existing-stats) u1),
          accurate-claims: (+ (get accurate-claims existing-stats) (if (>= accuracy accuracy-threshold) u1 u0))
        }
      )
      (ok true)
    )
    (begin
      (map-set user-stats user
        {
          total-claims: u1,
          accurate-claims: (if (>= accuracy accuracy-threshold) u1 u0)
        }
      )
      (ok true)
    )
  )
)

;; Get user's token balance
(define-read-only (get-balance (user principal))
  (ok (ft-get-balance claim-token user))
)

;; Transfer tokens (for future use)
(define-public (transfer-tokens (amount uint) (recipient principal))
  (ft-transfer? claim-token amount tx-sender recipient)
)

(begin
  (try! (ft-mint? claim-token u1000000 contract-owner))
)