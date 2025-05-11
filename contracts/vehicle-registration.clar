;; Vehicle Verification Contract
;; Validates legitimate connected cars

(define-data-var contract-owner principal tx-sender)

;; Map of verified vehicles
(define-map verified-vehicles
  { vehicle-id: (string-utf8 36) }
  {
    manufacturer: principal,
    model: (string-utf8 64),
    year: uint,
    verified: bool
  }
)

;; Map of authorized manufacturers
(define-map authorized-manufacturers
  { manufacturer-id: principal }
  { authorized: bool }
)

;; Initialize contract owner
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (ok true)
  )
)

;; Add authorized manufacturer
(define-public (add-manufacturer (manufacturer-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u101))
    (map-set authorized-manufacturers { manufacturer-id: manufacturer-id } { authorized: true })
    (ok true)
  )
)

;; Remove authorized manufacturer
(define-public (remove-manufacturer (manufacturer-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u101))
    (map-delete authorized-manufacturers { manufacturer-id: manufacturer-id })
    (ok true)
  )
)

;; Check if manufacturer is authorized
(define-read-only (is-authorized-manufacturer (manufacturer-id principal))
  (default-to false (get authorized (map-get? authorized-manufacturers { manufacturer-id: manufacturer-id })))
)

;; Register a new vehicle
(define-public (register-vehicle (vehicle-id (string-utf8 36)) (model (string-utf8 64)) (year uint))
  (begin
    (asserts! (is-authorized-manufacturer tx-sender) (err u102))
    (map-set verified-vehicles
      { vehicle-id: vehicle-id }
      {
        manufacturer: tx-sender,
        model: model,
        year: year,
        verified: true
      }
    )
    (ok true)
  )
)

;; Check if vehicle is verified
(define-read-only (is-verified-vehicle (vehicle-id (string-utf8 36)))
  (default-to false (get verified (map-get? verified-vehicles { vehicle-id: vehicle-id })))
)

;; Get vehicle details
(define-read-only (get-vehicle-details (vehicle-id (string-utf8 36)))
  (map-get? verified-vehicles { vehicle-id: vehicle-id })
)
