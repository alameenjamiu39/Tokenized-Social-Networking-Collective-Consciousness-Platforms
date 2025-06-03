;; Consciousness Integration Contract
;; Manages collective consciousness social interactions

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_ALREADY_EXISTS (err u202))
(define-constant ERR_INVALID_INPUT (err u203))

;; Data structures
(define-map consciousness-nodes
  { node-id: uint }
  {
    owner: principal,
    platform-id: uint,
    consciousness-level: uint,
    connection-count: uint,
    energy-balance: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map node-connections
  { from-node: uint, to-node: uint }
  {
    connection-strength: uint,
    interaction-count: uint,
    last-interaction: uint,
    connection-type: (string-ascii 32)
  }
)

(define-map consciousness-interactions
  { interaction-id: uint }
  {
    from-node: uint,
    to-node: uint,
    interaction-type: (string-ascii 32),
    energy-transfer: uint,
    timestamp: uint,
    metadata: (string-ascii 256)
  }
)

(define-data-var next-node-id uint u1)
(define-data-var next-interaction-id uint u1)
(define-data-var base-consciousness-energy uint u100)

;; Public functions
(define-public (create-consciousness-node (platform-id uint))
  (let ((node-id (var-get next-node-id)))
    (map-set consciousness-nodes
      { node-id: node-id }
      {
        owner: tx-sender,
        platform-id: platform-id,
        consciousness-level: u1,
        connection-count: u0,
        energy-balance: (var-get base-consciousness-energy),
        created-at: block-height,
        is-active: true
      }
    )
    (var-set next-node-id (+ node-id u1))
    (ok node-id)
  )
)

(define-public (connect-nodes (from-node uint) (to-node uint) (connection-type (string-ascii 32)))
  (let (
    (from-node-data (unwrap! (map-get? consciousness-nodes { node-id: from-node }) ERR_NOT_FOUND))
    (to-node-data (unwrap! (map-get? consciousness-nodes { node-id: to-node }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq (get owner from-node-data) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq from-node to-node)) ERR_INVALID_INPUT)

    (map-set node-connections
      { from-node: from-node, to-node: to-node }
      {
        connection-strength: u1,
        interaction-count: u0,
        last-interaction: block-height,
        connection-type: connection-type
      }
    )

    ;; Update connection counts
    (map-set consciousness-nodes
      { node-id: from-node }
      (merge from-node-data { connection-count: (+ (get connection-count from-node-data) u1) })
    )

    (ok true)
  )
)

(define-public (interact-with-node (from-node uint) (to-node uint) (interaction-type (string-ascii 32)) (energy-amount uint) (metadata (string-ascii 256)))
  (let (
    (interaction-id (var-get next-interaction-id))
    (from-node-data (unwrap! (map-get? consciousness-nodes { node-id: from-node }) ERR_NOT_FOUND))
    (connection (map-get? node-connections { from-node: from-node, to-node: to-node }))
  )
    (asserts! (is-eq (get owner from-node-data) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (>= (get energy-balance from-node-data) energy-amount) ERR_INVALID_INPUT)

    ;; Record interaction
    (map-set consciousness-interactions
      { interaction-id: interaction-id }
      {
        from-node: from-node,
        to-node: to-node,
        interaction-type: interaction-type,
        energy-transfer: energy-amount,
        timestamp: block-height,
        metadata: metadata
      }
    )

    ;; Update energy balances
    (map-set consciousness-nodes
      { node-id: from-node }
      (merge from-node-data { energy-balance: (- (get energy-balance from-node-data) energy-amount) })
    )

    ;; Update connection if exists
    (match connection
      conn (map-set node-connections
        { from-node: from-node, to-node: to-node }
        (merge conn {
          interaction-count: (+ (get interaction-count conn) u1),
          last-interaction: block-height
        })
      )
      true
    )

    (var-set next-interaction-id (+ interaction-id u1))
    (ok interaction-id)
  )
)

;; Read-only functions
(define-read-only (get-consciousness-node (node-id uint))
  (map-get? consciousness-nodes { node-id: node-id })
)

(define-read-only (get-node-connection (from-node uint) (to-node uint))
  (map-get? node-connections { from-node: from-node, to-node: to-node })
)

(define-read-only (get-interaction (interaction-id uint))
  (map-get? consciousness-interactions { interaction-id: interaction-id })
)

(define-read-only (calculate-consciousness-level (node-id uint))
  (match (map-get? consciousness-nodes { node-id: node-id })
    node (+ u1 (/ (get connection-count node) u10))
    u0
  )
)
