
;; title: StudentGov
;; version: 1.0.0
;; summary: A decentralized voting system for student government and university elections
;; description: This smart contract enables secure, transparent voting for student government positions,
;;              with features for election management, candidate registration, and vote tallying.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ELECTION_NOT_FOUND (err u101))
(define-constant ERR_ELECTION_NOT_ACTIVE (err u102))
(define-constant ERR_ALREADY_VOTED (err u103))
(define-constant ERR_CANDIDATE_NOT_FOUND (err u104))
(define-constant ERR_ELECTION_ENDED (err u105))
(define-constant ERR_INVALID_VOTER (err u106))
(define-constant ERR_ELECTION_ALREADY_EXISTS (err u107))

;; data vars
(define-data-var next-election-id uint u1)

;; data maps
;; Store election details
(define-map elections
  { election-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    start-block: uint,
    end-block: uint,
    is-active: bool,
    creator: principal
  }
)

;; Store candidates for each election
(define-map candidates
  { election-id: uint, candidate-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    vote-count: uint,
    candidate-address: principal
  }
)

;; Track candidate IDs for each election
(define-map election-candidate-count
  { election-id: uint }
  { count: uint }
)

;; Track votes to prevent double voting
(define-map votes
  { election-id: uint, voter: principal }
  { candidate-id: uint, block-height: uint }
)

;; Store eligible voters for each election
(define-map eligible-voters
  { election-id: uint, voter: principal }
  { is-eligible: bool }
)

;; public functions

;; Create a new election
(define-public (create-election (title (string-ascii 100)) (description (string-ascii 500)) (duration-blocks uint))
  (let
    (
      (election-id (var-get next-election-id))
      (start-block block-height)
      (end-block (+ block-height duration-blocks))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? elections { election-id: election-id })) ERR_ELECTION_ALREADY_EXISTS)
    
    ;; Store the election
    (map-set elections
      { election-id: election-id }
      {
        title: title,
        description: description,
        start-block: start-block,
        end-block: end-block,
        is-active: true,
        creator: tx-sender
      }
    )
    
    ;; Initialize candidate count
    (map-set election-candidate-count
      { election-id: election-id }
      { count: u0 }
    )
    
    ;; Increment next election ID
    (var-set next-election-id (+ election-id u1))
    
    (ok election-id)
  )
)

;; Add a candidate to an election
(define-public (add-candidate (election-id uint) (name (string-ascii 50)) (description (string-ascii 200)) (candidate-address principal))
  (let
    (
      (election (unwrap! (map-get? elections { election-id: election-id }) ERR_ELECTION_NOT_FOUND))
      (candidate-count-data (unwrap! (map-get? election-candidate-count { election-id: election-id }) ERR_ELECTION_NOT_FOUND))
      (candidate-id (+ (get count candidate-count-data) u1))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)
    (asserts! (< block-height (get start-block election)) ERR_ELECTION_ENDED)
    
    ;; Add the candidate
    (map-set candidates
      { election-id: election-id, candidate-id: candidate-id }
      {
        name: name,
        description: description,
        vote-count: u0,
        candidate-address: candidate-address
      }
    )
    
    ;; Update candidate count
    (map-set election-candidate-count
      { election-id: election-id }
      { count: candidate-id }
    )
    
    (ok candidate-id)
  )
)

;; Add eligible voter to an election
(define-public (add-eligible-voter (election-id uint) (voter principal))
  (let
    (
      (election (unwrap! (map-get? elections { election-id: election-id }) ERR_ELECTION_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)
    
    (map-set eligible-voters
      { election-id: election-id, voter: voter }
      { is-eligible: true }
    )
    
    (ok true)
  )
)

;; Cast a vote
(define-public (cast-vote (election-id uint) (candidate-id uint))
  (let
    (
      (election (unwrap! (map-get? elections { election-id: election-id }) ERR_ELECTION_NOT_FOUND))
      (candidate (unwrap! (map-get? candidates { election-id: election-id, candidate-id: candidate-id }) ERR_CANDIDATE_NOT_FOUND))
      (voter-eligibility (unwrap! (map-get? eligible-voters { election-id: election-id, voter: tx-sender }) ERR_INVALID_VOTER))
    )
    ;; Validate voting conditions
    (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)
    (asserts! (>= block-height (get start-block election)) ERR_ELECTION_NOT_ACTIVE)
    (asserts! (<= block-height (get end-block election)) ERR_ELECTION_ENDED)
    (asserts! (get is-eligible voter-eligibility) ERR_INVALID_VOTER)
    (asserts! (is-none (map-get? votes { election-id: election-id, voter: tx-sender })) ERR_ALREADY_VOTED)
    
    ;; Record the vote
    (map-set votes
      { election-id: election-id, voter: tx-sender }
      { candidate-id: candidate-id, block-height: block-height }
    )
    
    ;; Update candidate vote count
    (map-set candidates
      { election-id: election-id, candidate-id: candidate-id }
      {
        name: (get name candidate),
        description: (get description candidate),
        vote-count: (+ (get vote-count candidate) u1),
        candidate-address: (get candidate-address candidate)
      }
    )
    
    (ok true)
  )
)

;; End an election (only contract owner)
(define-public (end-election (election-id uint))
  (let
    (
      (election (unwrap! (map-get? elections { election-id: election-id }) ERR_ELECTION_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)
    
    ;; Deactivate the election
    (map-set elections
      { election-id: election-id }
      {
        title: (get title election),
        description: (get description election),
        start-block: (get start-block election),
        end-block: (get end-block election),
        is-active: false,
        creator: (get creator election)
      }
    )
    
    (ok true)
  )
)

;; read only functions

;; Get election details
(define-read-only (get-election (election-id uint))
  (map-get? elections { election-id: election-id })
)

;; Get candidate details
(define-read-only (get-candidate (election-id uint) (candidate-id uint))
  (map-get? candidates { election-id: election-id, candidate-id: candidate-id })
)

;; Get candidate count for an election
(define-read-only (get-candidate-count (election-id uint))
  (map-get? election-candidate-count { election-id: election-id })
)

;; Check if user has voted in an election
(define-read-only (has-voted (election-id uint) (voter principal))
  (is-some (map-get? votes { election-id: election-id, voter: voter }))
)

;; Get vote details for a voter in an election
(define-read-only (get-vote (election-id uint) (voter principal))
  (map-get? votes { election-id: election-id, voter: voter })
)

;; Check if voter is eligible for an election
(define-read-only (is-eligible-voter (election-id uint) (voter principal))
  (match (map-get? eligible-voters { election-id: election-id, voter: voter })
    voter-data (get is-eligible voter-data)
    false
  )
)

;; Get election status
(define-read-only (get-election-status (election-id uint))
  (match (map-get? elections { election-id: election-id })
    election
    (let
      (
        (is-active (get is-active election))
        (current-block block-height)
        (start-block (get start-block election))
        (end-block (get end-block election))
      )
      (some {
        is-active: is-active,
        has-started: (>= current-block start-block),
        has-ended: (> current-block end-block),
        current-block: current-block
      })
    )
    none
  )
)

;; Get next election ID
(define-read-only (get-next-election-id)
  (var-get next-election-id)
)

;; Get contract owner
(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)

;; private functions

;; Helper function to check if election is currently active for voting
(define-private (is-voting-period (election-id uint))
  (match (map-get? elections { election-id: election-id })
    election
    (let
      (
        (current-block block-height)
        (start-block (get start-block election))
        (end-block (get end-block election))
        (is-active (get is-active election))
      )
      (and 
        is-active
        (>= current-block start-block)
        (<= current-block end-block)
      )
    )
    false
  )
)
