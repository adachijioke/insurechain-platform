;; Define constants
(define-constant contract-owner tx-sender)
(define-constant dispute-fee u100) ;; Fee to raise a dispute (in claim-tokens)
(define-constant arbitrator-reward u50) ;; Reward for arbitrators (in claim-tokens)

;; Define data vars
(define-data-var dispute-counter u0)
(define-data-var arbitrator-counter u0)

;; Define maps
(define-map disputes 
  { id: uint } 
  { 
    claim-id: uint, 
    claimant: principal, 
    status: (string-ascii 20), 
    resolution: (optional (string-ascii 50)),
    arbitrator: (optional principal)
  }
)

(define-map arbitrators 
  { id: uint } 
  { address: principal, cases-resolved: uint }
)

;; Error codes
(define-constant err-not-owner (err u100))
(define-constant err-not-claimant (err u101))
(define-constant err-invalid-dispute (err u102))
(define-constant err-already-resolved (err u103))
(define-constant err-not-arbitrator (err u104))

;; External contracts
(use-trait claim-token-trait .claims-reward-system.claim-token)

;; Raise a dispute
(define-public (raise-dispute (claim-id uint) (claim-token <claim-token-trait>))
  (let
    (
      (dispute-id (var-get dispute-counter))
      (claimant tx-sender)
    )
    (asserts! (is-eq (contract-call? .claims-reward-system get-claim-submitter claim-id) (some claimant)) err-not-claimant)
    (try! (contract-call? claim-token transfer dispute-fee tx-sender (as-contract tx-sender)))
    (map-set disputes { id: dispute-id }
      {
        claim-id: claim-id,
        claimant: claimant,
        status: "PENDING",
        resolution: none,
        arbitrator: none
      }
    )
    (var-set dispute-counter (+ dispute-id u1))
    (ok dispute-id)
  )
)

;; Resolve dispute (only by assigned arbitrator)
(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 50)) (claim-token <claim-token-trait>))
  (let
    ((dispute (unwrap! (map-get? disputes { id: dispute-id }) err-invalid-dispute)))
    (asserts! (is-eq (some tx-sender) (get arbitrator dispute)) err-not-arbitrator)
    (asserts! (is-eq (get status dispute) "ASSIGNED") err-already-resolved)
    (try! (contract-call? claim-token transfer arbitrator-reward (as-contract tx-sender) tx-sender))
    (map-set disputes { id: dispute-id }
      (merge dispute { 
        status: "RESOLVED", 
        resolution: (some resolution) 
      })
    )
    (map-set arbitrators { id: (unwrap-panic (get arbitrator dispute)) }
      { 
        address: tx-sender, 
        cases-resolved: (+ (get cases-resolved (unwrap-panic (map-get? arbitrators { id: (unwrap-panic (get arbitrator dispute)) }))) u1) 
      }
    )
    (ok true)
  )
)

;; Assign arbitrator to a dispute (only contract owner)
(define-public (assign-arbitrator (dispute-id uint) (arbitrator-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (match (map-get? disputes { id: dispute-id })
      dispute (asserts! (is-eq (get status dispute) "PENDING") err-already-resolved)
      err-invalid-dispute
    )
    (match (map-get? arbitrators { id: arbitrator-id })
      arbitrator-data 
        (map-set disputes { id: dispute-id }
          (merge (unwrap-panic (map-get? disputes { id: dispute-id }))
            { 
              status: "ASSIGNED",
              arbitrator: (some arbitrator-id)
            }
          )
        )
      err-not-arbitrator
    )
    (ok true)
  )
)

;; Register as an arbitrator (only contract owner can add arbitrators)
(define-public (register-arbitrator (arbitrator-address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (let
      ((arbitrator-id (var-get arbitrator-counter)))
      (map-set arbitrators { id: arbitrator-id }
        { 
          address: arbitrator-address, 
          cases-resolved: u0 
        }
      )
      (var-set arbitrator-counter (+ arbitrator-id u1))
      (ok arbitrator-id)
    )
  )
)

;; Get dispute details
(define-read-only (get-dispute-details (dispute-id uint))
  (ok (unwrap! (map-get? disputes { id: dispute-id }) err-invalid-dispute))
)

;; Get arbitrator details
(define-read-only (get-arbitrator-details (arbitrator-id uint))
  (ok (unwrap! (map-get? arbitrators { id: arbitrator-id }) err-not-arbitrator))
)