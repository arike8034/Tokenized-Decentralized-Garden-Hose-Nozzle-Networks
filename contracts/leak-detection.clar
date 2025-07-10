;; Leak Detection Contract
;; Identifies connection issues and seal deterioration

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOZZLE_NOT_FOUND (err u201))
(define-constant ERR_INVALID_SEVERITY (err u202))
(define-constant ERR_LEAK_NOT_FOUND (err u203))

;; Data Variables
(define-data-var next-leak-id uint u1)

;; Data Maps
(define-map nozzle-health
  { nozzle-id: uint }
  {
    owner: principal,
    health-score: uint,
    last-inspection: uint,
    total-leaks: uint,
    connection-integrity: uint,
    seal-condition: uint
  }
)

(define-map leak-reports
  { leak-id: uint }
  {
    nozzle-id: uint,
    reporter: principal,
    severity: uint,
    leak-type: (string-ascii 30),
    reported-at: uint,
    resolved: bool,
    resolution-notes: (string-ascii 100)
  }
)

(define-map inspection-records
  { nozzle-id: uint, inspection-date: uint }
  {
    inspector: principal,
    connection-score: uint,
    seal-score: uint,
    overall-health: uint,
    notes: (string-ascii 150)
  }
)

;; Public Functions

;; Register nozzle for health monitoring
(define-public (register-nozzle-health (nozzle-id uint))
  (begin
    (map-set nozzle-health
      { nozzle-id: nozzle-id }
      {
        owner: tx-sender,
        health-score: u100,
        last-inspection: block-height,
        total-leaks: u0,
        connection-integrity: u100,
        seal-condition: u100
      }
    )
    (ok true)
  )
)

;; Report a leak
(define-public (report-leak (nozzle-id uint) (severity uint) (leak-type (string-ascii 30)))
  (let ((leak-id (var-get next-leak-id)))
    (asserts! (and (>= severity u1) (<= severity u5)) ERR_INVALID_SEVERITY)
    (asserts! (is-some (map-get? nozzle-health { nozzle-id: nozzle-id })) ERR_NOZZLE_NOT_FOUND)

    (map-set leak-reports
      { leak-id: leak-id }
      {
        nozzle-id: nozzle-id,
        reporter: tx-sender,
        severity: severity,
        leak-type: leak-type,
        reported-at: block-height,
        resolved: false,
        resolution-notes: ""
      }
    )

    ;; Update nozzle health
    (let ((health-data (unwrap! (map-get? nozzle-health { nozzle-id: nozzle-id }) ERR_NOZZLE_NOT_FOUND)))
      (map-set nozzle-health
        { nozzle-id: nozzle-id }
        (merge health-data {
          total-leaks: (+ (get total-leaks health-data) u1),
          health-score: (if (> (get health-score health-data) (* severity u5))
                           (- (get health-score health-data) (* severity u5))
                           u0)
        })
      )
    )

    (var-set next-leak-id (+ leak-id u1))
    (ok leak-id)
  )
)

;; Conduct inspection
(define-public (conduct-inspection (nozzle-id uint) (connection-score uint) (seal-score uint) (notes (string-ascii 150)))
  (let ((health-data (unwrap! (map-get? nozzle-health { nozzle-id: nozzle-id }) ERR_NOZZLE_NOT_FOUND))
        (overall-health (/ (+ connection-score seal-score) u2)))

    (map-set inspection-records
      { nozzle-id: nozzle-id, inspection-date: block-height }
      {
        inspector: tx-sender,
        connection-score: connection-score,
        seal-score: seal-score,
        overall-health: overall-health,
        notes: notes
      }
    )

    (map-set nozzle-health
      { nozzle-id: nozzle-id }
      (merge health-data {
        health-score: overall-health,
        last-inspection: block-height,
        connection-integrity: connection-score,
        seal-condition: seal-score
      })
    )
    (ok true)
  )
)

;; Resolve leak
(define-public (resolve-leak (leak-id uint) (resolution-notes (string-ascii 100)))
  (let ((leak-data (unwrap! (map-get? leak-reports { leak-id: leak-id }) ERR_LEAK_NOT_FOUND)))
    (map-set leak-reports
      { leak-id: leak-id }
      (merge leak-data {
        resolved: true,
        resolution-notes: resolution-notes
      })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get nozzle health status
(define-read-only (get-nozzle-health (nozzle-id uint))
  (map-get? nozzle-health { nozzle-id: nozzle-id })
)

;; Get leak report
(define-read-only (get-leak-report (leak-id uint))
  (map-get? leak-reports { leak-id: leak-id })
)

;; Get inspection record
(define-read-only (get-inspection-record (nozzle-id uint) (inspection-date uint))
  (map-get? inspection-records { nozzle-id: nozzle-id, inspection-date: inspection-date })
)

;; Check if nozzle needs inspection
(define-read-only (needs-inspection (nozzle-id uint))
  (match (map-get? nozzle-health { nozzle-id: nozzle-id })
    health-data (some (> (- block-height (get last-inspection health-data)) u1000))
    none
  )
)
