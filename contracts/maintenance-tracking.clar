;; Maintenance Tracking Contract
;; Handles cleaning and repair scheduling

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_NOZZLE_NOT_FOUND (err u401))
(define-constant ERR_TASK_NOT_FOUND (err u402))
(define-constant ERR_INVALID_PRIORITY (err u403))
(define-constant ERR_ALREADY_COMPLETED (err u404))

;; Data Variables
(define-data-var next-task-id uint u1)

;; Data Maps
(define-map nozzle-maintenance
  { nozzle-id: uint }
  {
    owner: principal,
    last-cleaning: uint,
    last-repair: uint,
    maintenance-score: uint,
    total-cleanings: uint,
    total-repairs: uint,
    next-scheduled-maintenance: uint
  }
)

(define-map maintenance-tasks
  { task-id: uint }
  {
    nozzle-id: uint,
    task-type: (string-ascii 20),
    priority: uint,
    assigned-to: (optional principal),
    created-at: uint,
    scheduled-for: uint,
    completed-at: (optional uint),
    completion-notes: (string-ascii 200),
    estimated-duration: uint
  }
)

(define-map maintenance-workers
  { worker: principal }
  {
    authorized: bool,
    specialties: (list 5 (string-ascii 20)),
    completed-tasks: uint,
    average-rating: uint,
    availability: bool
  }
)

(define-map task-completions
  { task-id: uint }
  {
    completed-by: principal,
    completion-time: uint,
    quality-rating: uint,
    parts-used: (list 10 (string-ascii 30)),
    cost: uint
  }
)

;; Public Functions

;; Register nozzle for maintenance tracking
(define-public (register-nozzle-maintenance (nozzle-id uint))
  (begin
    (map-set nozzle-maintenance
      { nozzle-id: nozzle-id }
      {
        owner: tx-sender,
        last-cleaning: u0,
        last-repair: u0,
        maintenance-score: u100,
        total-cleanings: u0,
        total-repairs: u0,
        next-scheduled-maintenance: (+ block-height u500)
      }
    )
    (ok true)
  )
)

;; Create maintenance task
(define-public (create-maintenance-task (nozzle-id uint) (task-type (string-ascii 20)) (priority uint) (scheduled-for uint) (estimated-duration uint))
  (let ((task-id (var-get next-task-id)))
    (asserts! (is-some (map-get? nozzle-maintenance { nozzle-id: nozzle-id })) ERR_NOZZLE_NOT_FOUND)
    (asserts! (and (>= priority u1) (<= priority u5)) ERR_INVALID_PRIORITY)

    (map-set maintenance-tasks
      { task-id: task-id }
      {
        nozzle-id: nozzle-id,
        task-type: task-type,
        priority: priority,
        assigned-to: none,
        created-at: block-height,
        scheduled-for: scheduled-for,
        completed-at: none,
        completion-notes: "",
        estimated-duration: estimated-duration
      }
    )

    (var-set next-task-id (+ task-id u1))
    (ok task-id)
  )
)

;; Assign task to worker
(define-public (assign-task (task-id uint) (worker principal))
  (let ((task-data (unwrap! (map-get? maintenance-tasks { task-id: task-id }) ERR_TASK_NOT_FOUND))
        (worker-data (unwrap! (map-get? maintenance-workers { worker: worker }) ERR_UNAUTHORIZED)))

    (asserts! (get authorized worker-data) ERR_UNAUTHORIZED)
    (asserts! (get availability worker-data) ERR_UNAUTHORIZED)
    (asserts! (is-none (get completed-at task-data)) ERR_ALREADY_COMPLETED)

    (map-set maintenance-tasks
      { task-id: task-id }
      (merge task-data { assigned-to: (some worker) })
    )
    (ok true)
  )
)

;; Complete maintenance task
(define-public (complete-task (task-id uint) (completion-notes (string-ascii 200)) (parts-used (list 10 (string-ascii 30))) (cost uint))
  (let ((task-data (unwrap! (map-get? maintenance-tasks { task-id: task-id }) ERR_TASK_NOT_FOUND))
        (maintenance-data (unwrap! (map-get? nozzle-maintenance { nozzle-id: (get nozzle-id task-data) }) ERR_NOZZLE_NOT_FOUND)))

    (asserts! (is-eq (some tx-sender) (get assigned-to task-data)) ERR_UNAUTHORIZED)
    (asserts! (is-none (get completed-at task-data)) ERR_ALREADY_COMPLETED)

    ;; Update task
    (map-set maintenance-tasks
      { task-id: task-id }
      (merge task-data {
        completed-at: (some block-height),
        completion-notes: completion-notes
      })
    )

    ;; Record completion details
    (map-set task-completions
      { task-id: task-id }
      {
        completed-by: tx-sender,
        completion-time: block-height,
        quality-rating: u5,
        parts-used: parts-used,
        cost: cost
      }
    )

    ;; Update nozzle maintenance record
    (let ((updated-maintenance
           (if (is-eq (get task-type task-data) "cleaning")
               (merge maintenance-data {
                 last-cleaning: block-height,
                 total-cleanings: (+ (get total-cleanings maintenance-data) u1),
                 next-scheduled-maintenance: (+ block-height u500)
               })
               (merge maintenance-data {
                 last-repair: block-height,
                 total-repairs: (+ (get total-repairs maintenance-data) u1),
                 next-scheduled-maintenance: (+ block-height u1000)
               }))))
      (map-set nozzle-maintenance
        { nozzle-id: (get nozzle-id task-data) }
        updated-maintenance
      )
    )

    (ok true)
  )
)

;; Register maintenance worker
(define-public (register-worker (specialties (list 5 (string-ascii 20))))
  (begin
    (map-set maintenance-workers
      { worker: tx-sender }
      {
        authorized: true,
        specialties: specialties,
        completed-tasks: u0,
        average-rating: u5,
        availability: true
      }
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get nozzle maintenance info
(define-read-only (get-maintenance-info (nozzle-id uint))
  (map-get? nozzle-maintenance { nozzle-id: nozzle-id })
)

;; Get maintenance task
(define-read-only (get-maintenance-task (task-id uint))
  (map-get? maintenance-tasks { task-id: task-id })
)

;; Get worker info
(define-read-only (get-worker-info (worker principal))
  (map-get? maintenance-workers { worker: worker })
)

;; Check if maintenance is due
(define-read-only (is-maintenance-due (nozzle-id uint))
  (match (map-get? nozzle-maintenance { nozzle-id: nozzle-id })
    maintenance-data (some (>= block-height (get next-scheduled-maintenance maintenance-data)))
    none
  )
)
