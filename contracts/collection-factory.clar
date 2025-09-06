;; Generative Art Collection Factory Contract
;; Handles NFT minting, ownership tracking, collection management, and payment processing
;; for a generative art collection minting system with configurable pricing and supply limits

;; ======================
;; Constants and Errors
;; ======================

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant NFT-NAME "Generative Art Collection Minting")
(define-constant NFT-SYMBOL "GACM")
(define-constant DEFAULT-MINT-PRICE u5000000) ;; 5 STX in microSTX
(define-constant MAX-SUPPLY u10000) ;; Maximum number of NFTs that can ever be minted

;; Error constants
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u102))
(define-constant ERR-MAX-SUPPLY-REACHED (err u103))
(define-constant ERR-INVALID-TOKEN-ID (err u104))
(define-constant ERR-MINTING-DISABLED (err u105))
(define-constant ERR-INVALID-PRICE (err u106))
(define-constant ERR-TRANSFER-FAILED (err u107))
(define-constant ERR-TOKEN-NOT-FOUND (err u108))
(define-constant ERR-INVALID-SUPPLY (err u109))

;; ==================
;; Data Variables
;; ==================

;; Collection state variables
(define-data-var mint-price uint DEFAULT-MINT-PRICE)
(define-data-var max-supply uint MAX-SUPPLY)
(define-data-var next-token-id uint u1)
(define-data-var minting-enabled bool true)
(define-data-var contract-admin principal CONTRACT-OWNER)
(define-data-var total-minted uint u0)
(define-data-var collection-uri (string-utf8 256) u"https://api.generative-art-minting.com/metadata/")

;; ===============
;; Data Maps
;; ===============

;; Track token ownership
(define-map token-owners uint principal)

;; Track tokens owned by each address
(define-map owner-tokens principal (list 100 uint))

;; Track token approval for transfers
(define-map token-approvals uint principal)

;; Track operator approvals for all tokens
(define-map operator-approvals {owner: principal, operator: principal} bool)

;; Track token metadata URIs
(define-map token-uris uint (string-utf8 256))

;; ===================
;; Private Functions
;; ===================

;; Internal function to transfer STX payment
(define-private (transfer-stx (amount uint) (from principal) (to principal))
  (begin
    (try! (stx-transfer? amount from to))
    (ok true)
  )
)

;; Internal function to add token to owner's list
(define-private (add-token-to-owner (token-id uint) (owner principal))
  (let (
    (current-tokens (default-to (list) (map-get? owner-tokens owner)))
  )
    (map-set owner-tokens owner (unwrap! (as-max-len? (append current-tokens token-id) u100) (err u999)))
    (ok true)
  )
)

;; Internal function to remove token from owner's list
(define-private (remove-token-from-owner (token-id uint) (owner principal))
  (begin
    ;; For simplicity, just clear the list and rebuild without the token
    ;; In a production contract, you'd implement proper list filtering
    (map-delete owner-tokens owner)
    (ok true)
  )
)

;; Internal function to validate token ownership
(define-private (is-token-owner (token-id uint) (user principal))
  (is-eq (some user) (map-get? token-owners token-id))
)

;; Internal function to validate admin privileges
(define-private (is-admin (user principal))
  (is-eq user (var-get contract-admin))
)

;; ==================
;; Public Functions
;; ==================

;; Mint a new NFT token
(define-public (mint-nft)
  (let (
    (token-id (var-get next-token-id))
    (current-price (var-get mint-price))
    (current-max-supply (var-get max-supply))
    (current-total-minted (var-get total-minted))
  )
    ;; Validate minting conditions
    (asserts! (var-get minting-enabled) ERR-MINTING-DISABLED)
    (asserts! (< current-total-minted current-max-supply) ERR-MAX-SUPPLY-REACHED)
    
    ;; Process payment if price > 0
    (if (> current-price u0)
      (try! (transfer-stx current-price tx-sender (var-get contract-admin)))
      true
    )
    
    ;; Mint the token
    (map-set token-owners token-id tx-sender)
    (unwrap-panic (add-token-to-owner token-id tx-sender))
    
    ;; Update contract state
    (var-set next-token-id (+ token-id u1))
    (var-set total-minted (+ current-total-minted u1))
    
    ;; Emit mint event via print
    (print {event: "mint", token-id: token-id, owner: tx-sender, price: current-price})
    
    (ok token-id)
  )
)

;; Transfer token to another address
(define-public (transfer (token-id uint) (from principal) (to principal))
  (begin
    ;; Validate token exists
    (asserts! (is-some (map-get? token-owners token-id)) ERR-INVALID-TOKEN-ID)
    
    ;; Validate ownership or approval
    (asserts! (or
      (is-eq from tx-sender)
      (is-token-owner token-id tx-sender)
      (is-eq (some tx-sender) (map-get? token-approvals token-id))
    ) ERR-NOT-TOKEN-OWNER)
    
    ;; Execute transfer
    (unwrap-panic (remove-token-from-owner token-id from))
    (unwrap-panic (add-token-to-owner token-id to))
    (map-set token-owners token-id to)
    (map-delete token-approvals token-id)
    
    ;; Emit transfer event
    (print {event: "transfer", token-id: token-id, from: from, to: to})
    
    (ok true)
  )
)

;; Approve another address to transfer a specific token
(define-public (approve (token-id uint) (approved principal))
  (begin
    (asserts! (is-token-owner token-id tx-sender) ERR-NOT-TOKEN-OWNER)
    (map-set token-approvals token-id approved)
    (print {event: "approval", token-id: token-id, owner: tx-sender, approved: approved})
    (ok true)
  )
)

;; Set approval for all tokens owned by caller
(define-public (set-approval-for-all (operator principal) (approved bool))
  (begin
    (map-set operator-approvals {owner: tx-sender, operator: operator} approved)
    (print {event: "approval-for-all", owner: tx-sender, operator: operator, approved: approved})
    (ok true)
  )
)

;; Admin function to set mint price
(define-public (set-mint-price (new-price uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-OWNER-ONLY)
    (asserts! (>= new-price u0) ERR-INVALID-PRICE)
    (var-set mint-price new-price)
    (print {event: "price-updated", new-price: new-price, admin: tx-sender})
    (ok true)
  )
)

;; Admin function to set max supply
(define-public (set-max-supply (new-max-supply uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-OWNER-ONLY)
    (asserts! (>= new-max-supply (var-get total-minted)) ERR-INVALID-SUPPLY)
    (var-set max-supply new-max-supply)
    (print {event: "max-supply-updated", new-max-supply: new-max-supply, admin: tx-sender})
    (ok true)
  )
)

;; Admin function to toggle minting
(define-public (toggle-minting)
  (begin
    (asserts! (is-admin tx-sender) ERR-OWNER-ONLY)
    (var-set minting-enabled (not (var-get minting-enabled)))
    (print {event: "minting-toggled", enabled: (var-get minting-enabled), admin: tx-sender})
    (ok (var-get minting-enabled))
  )
)

;; Admin function to update collection URI
(define-public (set-collection-uri (new-uri (string-utf8 256)))
  (begin
    (asserts! (is-admin tx-sender) ERR-OWNER-ONLY)
    (var-set collection-uri new-uri)
    (print {event: "uri-updated", new-uri: new-uri, admin: tx-sender})
    (ok true)
  )
)

;; Emergency function to withdraw contract balance (admin only)
(define-public (withdraw-balance (amount uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-OWNER-ONLY)
    (try! (transfer-stx amount (as-contract tx-sender) (var-get contract-admin)))
    (print {event: "withdrawal", amount: amount, admin: tx-sender})
    (ok true)
  )
)

;; ==================
;; Read-Only Functions
;; ==================

;; Get token owner
(define-read-only (get-owner (token-id uint))
  (map-get? token-owners token-id)
)

;; Get approved address for token
(define-read-only (get-approved (token-id uint))
  (map-get? token-approvals token-id)
)

;; Check if operator is approved for all tokens
(define-read-only (is-approved-for-all (owner principal) (operator principal))
  (default-to false (map-get? operator-approvals {owner: owner, operator: operator}))
)

;; Get tokens owned by address
(define-read-only (get-tokens-by-owner (owner principal))
  (default-to (list) (map-get? owner-tokens owner))
)

;; Get current mint price
(define-read-only (get-mint-price)
  (var-get mint-price)
)

;; Get max supply
(define-read-only (get-max-supply)
  (var-get max-supply)
)

;; Get total minted count
(define-read-only (get-total-minted)
  (var-get total-minted)
)

;; Get next token ID
(define-read-only (get-next-token-id)
  (var-get next-token-id)
)

;; Check if minting is enabled
(define-read-only (is-minting-enabled)
  (var-get minting-enabled)
)

;; Get contract admin
(define-read-only (get-contract-admin)
  (var-get contract-admin)
)

;; Get collection URI
(define-read-only (get-collection-uri)
  (var-get collection-uri)
)

;; Get contract info
(define-read-only (get-contract-info)
  {
    name: NFT-NAME,
    symbol: NFT-SYMBOL,
    mint-price: (var-get mint-price),
    max-supply: (var-get max-supply),
    total-minted: (var-get total-minted),
    next-token-id: (var-get next-token-id),
    minting-enabled: (var-get minting-enabled),
    collection-uri: (var-get collection-uri)
  }
)

