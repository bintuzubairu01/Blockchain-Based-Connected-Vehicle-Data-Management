;; Consent Management Contract
;; Controls sharing permissions

(define-data-var contract-owner principal tx-sender)

;; Map of consent records
(define-map consent-records
  {
    vehicle-id: (string-utf8 36),
    data-consumer: principal
  }
  {
    owner: principal,
    granted: bool,
    data-types: (list 10 (string-utf8 20)),
    expiration: uint,
    last-updated: uint
  }
)

;; Map of vehicle owners
(define-map vehicle-owners
  { vehicle-id: (string-utf8 36) }
  { owner: principal }
)

;; Initialize contract
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u300))
    (ok true)
  )
)

;; Register vehicle ownership
(define-public (register-ownership (vehicle-id (string-utf8 36)))
  (begin
    (map-set vehicle-owners { vehicle-id: vehicle-id } { owner: tx-sender })
    (ok true)
  )
)

;; Check if caller is vehicle owner
(define-read-only (is-vehicle-owner (vehicle-id (string-utf8 36)) (caller principal))
  (let ((owner-data (map-get? vehicle-owners { vehicle-id: vehicle-id })))
    (if (is-some owner-data)
      (is-eq caller (get owner (unwrap-panic owner-data)))
      false
    )
  )
)

;; Grant consent
(define-public (grant-consent
  (vehicle-id (string-utf8 36))
  (data-consumer principal)
  (data-types (list 10 (string-utf8 20)))
  (expiration uint)
)
  (begin
    (asserts! (is-vehicle-owner vehicle-id tx-sender) (err u301))
    (map-set consent-records
      {
        vehicle-id: vehicle-id,
        data-consumer: data-consumer
      }
      {
        owner: tx-sender,
        granted: true,
        data-types: data-types,
        expiration: expiration,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Revoke consent
(define-public (revoke-consent (vehicle-id (string-utf8 36)) (data-consumer principal))
  (begin
    (asserts! (is-vehicle-owner vehicle-id tx-sender) (err u301))
    (let ((current-consent (map-get? consent-records { vehicle-id: vehicle-id, data-consumer: data-consumer })))
      (asserts! (is-some current-consent) (err u302))
      (map-set consent-records
        {
          vehicle-id: vehicle-id,
          data-consumer: data-consumer
        }
        (merge (unwrap-panic current-consent) { granted: false, last-updated: block-height })
      )
      (ok true)
    )
  )
)

;; Check if consent is granted
(define-read-only (has-consent (vehicle-id (string-utf8 36)) (data-consumer principal) (data-type (string-utf8 20)))
  (let ((consent-data (map-get? consent-records { vehicle-id: vehicle-id, data-consumer: data-consumer })))
    (if (is-some consent-data)
      (let ((consent (unwrap-panic consent-data)))
        (and
          (get granted consent)
          (> (get expiration consent) block-height)
          (is-some (index-of (get data-types consent) data-type))
        )
      )
      false
    )
  )
)

;; Get consent details
(define-read-only (get-consent-details (vehicle-id (string-utf8 36)) (data-consumer principal))
  (map-get? consent-records { vehicle-id: vehicle-id, data-consumer: data-consumer })
)
