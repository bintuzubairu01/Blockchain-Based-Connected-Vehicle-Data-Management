;; Anonymization Contract
;; Removes personally identifiable information

(define-data-var contract-owner principal tx-sender)

;; Map of anonymization settings
(define-map anonymization-settings
  { vehicle-id: (string-utf8 36) }
  {
    anonymize-location: bool,
    location-precision: uint,  ;; Precision reduction (higher = less precise)
    anonymize-timestamps: bool,
    timestamp-precision: uint, ;; Precision in minutes (higher = less precise)
    additional-settings: (optional (string-utf8 256))
  }
)

;; Map of anonymized data
(define-map anonymized-data
  {
    data-id: (string-utf8 64)
  }
  {
    original-vehicle-id-hash: (buff 32),
    anonymized-data: (string-utf8 1024),
    anonymization-level: uint,
    created-at: uint
  }
)

;; Initialize contract
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u400))
    (ok true)
  )
)

;; Set anonymization settings
(define-public (set-anonymization-settings
  (vehicle-id (string-utf8 36))
  (anonymize-location bool)
  (location-precision uint)
  (anonymize-timestamps bool)
  (timestamp-precision uint)
  (additional-settings (optional (string-utf8 256)))
)
  (begin
    ;; Only vehicle owner or contract owner can set settings
    (map-set anonymization-settings
      { vehicle-id: vehicle-id }
      {
        anonymize-location: anonymize-location,
        location-precision: location-precision,
        anonymize-timestamps: anonymize-timestamps,
        timestamp-precision: timestamp-precision,
        additional-settings: additional-settings
      }
    )
    (ok true)
  )
)

;; Get anonymization settings
(define-read-only (get-anonymization-settings (vehicle-id (string-utf8 36)))
  (map-get? anonymization-settings { vehicle-id: vehicle-id })
)

;; Store anonymized data
(define-public (store-anonymized-data
  (data-id (string-utf8 64))
  (original-vehicle-id-hash (buff 32))
  (anonymized-data (string-utf8 1024))
  (anonymization-level uint)
)
  (begin
    (map-set anonymized-data
      { data-id: data-id }
      {
        original-vehicle-id-hash: original-vehicle-id-hash,
        anonymized-data: anonymized-data,
        anonymization-level: anonymization-level,
        created-at: block-height
      }
    )
    (ok true)
  )
)

;; Get anonymized data
(define-read-only (get-anonymized-data (data-id (string-utf8 64)))
  (map-get? anonymized-data { data-id: data-id })
)

;; Check if data is anonymized
(define-read-only (is-data-anonymized (data-id (string-utf8 64)))
  (is-some (map-get? anonymized-data { data-id: data-id }))
)
