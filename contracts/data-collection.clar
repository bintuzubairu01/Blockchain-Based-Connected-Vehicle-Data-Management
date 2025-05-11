;; Data Collection Contract
;; Manages gathering of vehicle information

(define-data-var contract-owner principal tx-sender)

;; Map of vehicle data entries
(define-map vehicle-data-entries
  {
    vehicle-id: (string-utf8 36),
    timestamp: uint
  }
  {
    location: (optional (tuple (latitude int) (longitude int))),
    speed: (optional uint),
    fuel-level: (optional uint),
    engine-status: (optional (string-utf8 20)),
    additional-data: (optional (string-utf8 256))
  }
)

;; Map of data providers
(define-map data-providers
  { provider-id: principal }
  { authorized: bool }
)

;; Initialize contract
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u200))
    (ok true)
  )
)

;; Authorize data provider
(define-public (authorize-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u201))
    (map-set data-providers { provider-id: provider-id } { authorized: true })
    (ok true)
  )
)

;; Check if provider is authorized
(define-read-only (is-authorized-provider (provider-id principal))
  (default-to false (get authorized (map-get? data-providers { provider-id: provider-id })))
)

;; Submit vehicle data
(define-public (submit-data
  (vehicle-id (string-utf8 36))
  (timestamp uint)
  (location (optional (tuple (latitude int) (longitude int))))
  (speed (optional uint))
  (fuel-level (optional uint))
  (engine-status (optional (string-utf8 20)))
  (additional-data (optional (string-utf8 256)))
)
  (begin
    (asserts! (is-authorized-provider tx-sender) (err u202))
    (map-set vehicle-data-entries
      {
        vehicle-id: vehicle-id,
        timestamp: timestamp
      }
      {
        location: location,
        speed: speed,
        fuel-level: fuel-level,
        engine-status: engine-status,
        additional-data: additional-data
      }
    )
    (ok true)
  )
)

;; Get vehicle data by ID and timestamp
(define-read-only (get-vehicle-data (vehicle-id (string-utf8 36)) (timestamp uint))
  (map-get? vehicle-data-entries { vehicle-id: vehicle-id, timestamp: timestamp })
)

;; Check if data exists
(define-read-only (data-exists (vehicle-id (string-utf8 36)) (timestamp uint))
  (is-some (map-get? vehicle-data-entries { vehicle-id: vehicle-id, timestamp: timestamp }))
)
