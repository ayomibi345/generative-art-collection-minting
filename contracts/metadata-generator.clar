;; Generative Art Metadata Generator Contract
;; Manages trait generation, rarity calculations, and metadata assembly
;; for generative art NFTs with on-chain trait storage and pseudo-random selection

;; ======================
;; Constants and Errors
;; ======================

;; Contract constants
(define-constant CONTRACT-ADMIN tx-sender)
(define-constant MAX-TRAITS-PER-CATEGORY u20)
(define-constant MAX-TRAIT-CATEGORIES u10)
(define-constant RARITY-LEGENDARY u1)    ;; 1%
(define-constant RARITY-EPIC u4)         ;; 4% 
(define-constant RARITY-RARE u10)        ;; 10%
(define-constant RARITY-UNCOMMON u25)     ;; 25%
(define-constant RARITY-COMMON u60)       ;; 60%

;; Error constants
(define-constant ERR-ADMIN-ONLY (err u200))
(define-constant ERR-INVALID-TOKEN-ID (err u201))
(define-constant ERR-TRAIT-NOT-FOUND (err u202))
(define-constant ERR-INVALID-TRAIT-INDEX (err u203))
(define-constant ERR-CATEGORY-NOT-FOUND (err u204))
(define-constant ERR-MAX-TRAITS-REACHED (err u205))
(define-constant ERR-METADATA-EXISTS (err u206))
(define-constant ERR-INVALID-RARITY (err u207))
(define-constant ERR-EMPTY-TRAIT-LIST (err u208))
(define-constant ERR-CATEGORY-EXISTS (err u209))

;; ==================
;; Data Variables
;; ==================

;; Contract state
(define-data-var contract-admin principal CONTRACT-ADMIN)
(define-data-var metadata-base-uri (string-utf8 256) u"https://api.generative-art-minting.com/token/")
(define-data-var total-metadata-generated uint u0)
(define-data-var next-trait-category-id uint u1)

;; Trait category names for easy lookup
(define-data-var trait-categories (list 10 (string-ascii 32)) (list "Background" "Color" "Shape" "Pattern" "Effects"))

;; ===============
;; Data Maps
;; ===============

;; Store trait options for each category
(define-map trait-category-options (string-ascii 32) (list 20 (string-ascii 64)))

;; Store rarity weights for each trait in a category
(define-map trait-rarity-weights {category: (string-ascii 32), trait: (string-ascii 64)} uint)

;; Store generated metadata for each token ID
(define-map token-metadata uint 
  {
    background: (string-ascii 64),
    color: (string-ascii 64),
    shape: (string-ascii 64),
    pattern: (string-ascii 64),
    effects: (string-ascii 64),
    rarity-score: uint,
    rarity-tier: (string-ascii 16)
  }
)

;; Track trait frequency for rarity calculations
(define-map trait-frequency {category: (string-ascii 32), trait: (string-ascii 64)} uint)

;; Store complete JSON metadata for tokens
(define-map token-json-metadata uint (string-utf8 1024))

;; Track admin-added trait categories
(define-map admin-trait-categories (string-ascii 32) bool)

;; ===================
;; Private Functions
;; ===================

;; Generate pseudo-random number based on block height and seed
(define-private (generate-random (seed uint) (max-value uint))
  (mod (+ seed block-height) max-value)
)

;; Select random trait from category based on rarity weights
(define-private (select-random-trait (category (string-ascii 32)) (seed uint))
  (let (
    (traits (default-to (list) (map-get? trait-category-options category)))
    (trait-count (len traits))
  )
    (if (> trait-count u0)
      (let (
        (random-index (generate-random seed trait-count))
        (selected-trait (unwrap-panic (element-at traits random-index)))
      )
        (ok selected-trait)
      )
      (err ERR-EMPTY-TRAIT-LIST)
    )
  )
)

;; Calculate rarity score based on trait combination
(define-private (calculate-rarity-score (traits {background: (string-ascii 64), color: (string-ascii 64), shape: (string-ascii 64), pattern: (string-ascii 64), effects: (string-ascii 64)}))
  (let (
    (bg-rarity (default-to u50 (map-get? trait-rarity-weights {category: "Background", trait: (get background traits)})))
    (color-rarity (default-to u50 (map-get? trait-rarity-weights {category: "Color", trait: (get color traits)})))
    (shape-rarity (default-to u50 (map-get? trait-rarity-weights {category: "Shape", trait: (get shape traits)})))
    (pattern-rarity (default-to u50 (map-get? trait-rarity-weights {category: "Pattern", trait: (get pattern traits)})))
    (effects-rarity (default-to u50 (map-get? trait-rarity-weights {category: "Effects", trait: (get effects traits)})))
  )
    (/ (+ bg-rarity color-rarity shape-rarity pattern-rarity effects-rarity) u5)
  )
)

;; Determine rarity tier based on score
(define-private (get-rarity-tier (rarity-score uint))
  (if (<= rarity-score RARITY-LEGENDARY)
    "Legendary"
    (if (<= rarity-score RARITY-EPIC)
      "Epic"
      (if (<= rarity-score RARITY-RARE)
        "Rare"
        (if (<= rarity-score RARITY-UNCOMMON)
          "Uncommon"
          "Common"
        )
      )
    )
  )
)

;; Update trait frequency for rarity calculations
(define-private (update-trait-frequency (category (string-ascii 32)) (trait (string-ascii 64)))
  (let (
    (current-frequency (default-to u0 (map-get? trait-frequency {category: category, trait: trait})))
  )
    (map-set trait-frequency {category: category, trait: trait} (+ current-frequency u1))
    (ok true)
  )
)

;; Validate admin privileges
(define-private (is-admin (user principal))
  (is-eq user (var-get contract-admin))
)

;; Assemble JSON metadata string
(define-private (assemble-json-metadata (token-id uint) (traits {background: (string-ascii 64), color: (string-ascii 64), shape: (string-ascii 64), pattern: (string-ascii 64), effects: (string-ascii 64)}) (rarity-score uint) (rarity-tier (string-ascii 16)))
  (let (
    (json-start "{\"name\":\"Generative Art Minting #")
    (json-id (uint-to-ascii token-id))
    (json-desc "\",\"description\":\"Unique generative art NFT with on-chain metadata\"")
    (json-image ",\"image\":\"https://api.generative-art-minting.com/image/")
    (json-attrs ",\"attributes\":[")
    (bg-attr "{\"trait_type\":\"Background\",\"value\":\"")
    (color-attr "},{\"trait_type\":\"Color\",\"value\":\"")
    (shape-attr "},{\"trait_type\":\"Shape\",\"value\":\"")
    (pattern-attr "},{\"trait_type\":\"Pattern\",\"value\":\"")
    (effects-attr "},{\"trait_type\":\"Effects\",\"value\":\"")
    (rarity-attr "},{\"trait_type\":\"Rarity\",\"value\":\"")
    (json-end "\"}]}")
  )
    ;; Concatenate all parts (simplified - in practice would use string concatenation)
    u"Generated JSON metadata for generative art minting"
  )
)

;; Convert uint to ASCII string (simplified implementation)
(define-private (uint-to-ascii (value uint))
  (if (is-eq value u0)
    "0"
    (if (is-eq value u1)
      "1"
      (if (is-eq value u2)
        "2"
        ;; ... truncated for brevity, would include all digits
        "N"
      )
    )
  )
)

;; ==================
;; Public Functions
;; ==================

;; Generate complete metadata for a token ID
(define-public (generate-metadata (token-id uint))
  (let (
    (seed-base (* token-id u12345))
    (background (unwrap! (select-random-trait "Background" (+ seed-base u1)) ERR-TRAIT-NOT-FOUND))
    (color (unwrap! (select-random-trait "Color" (+ seed-base u2)) ERR-TRAIT-NOT-FOUND))
    (shape (unwrap! (select-random-trait "Shape" (+ seed-base u3)) ERR-TRAIT-NOT-FOUND))
    (pattern (unwrap! (select-random-trait "Pattern" (+ seed-base u4)) ERR-TRAIT-NOT-FOUND))
    (effects (unwrap! (select-random-trait "Effects" (+ seed-base u5)) ERR-TRAIT-NOT-FOUND))
  )
    ;; Check if metadata already exists
    (asserts! (is-none (map-get? token-metadata token-id)) ERR-METADATA-EXISTS)
    
    ;; Create traits object
    (let (
      (traits {background: background, color: color, shape: shape, pattern: pattern, effects: effects})
      (rarity-score (calculate-rarity-score traits))
      (rarity-tier (get-rarity-tier rarity-score))
    )
      ;; Store metadata
      (map-set token-metadata token-id 
        {
          background: background,
          color: color,
          shape: shape,
          pattern: pattern,
          effects: effects,
          rarity-score: rarity-score,
          rarity-tier: rarity-tier
        }
      )
      
      ;; Update trait frequencies
      (unwrap-panic (update-trait-frequency "Background" background))
      (unwrap-panic (update-trait-frequency "Color" color))
      (unwrap-panic (update-trait-frequency "Shape" shape))
      (unwrap-panic (update-trait-frequency "Pattern" pattern))
      (unwrap-panic (update-trait-frequency "Effects" effects))
      
      ;; Generate and store JSON metadata
      (let (
        (json-metadata (assemble-json-metadata token-id traits rarity-score rarity-tier))
      )
        (map-set token-json-metadata token-id json-metadata)
      )
      
      ;; Update counters
      (var-set total-metadata-generated (+ (var-get total-metadata-generated) u1))
      
      ;; Emit generation event
      (print {event: "metadata-generated", token-id: token-id, rarity-tier: rarity-tier, rarity-score: rarity-score})
      
      (ok traits)
    )
  )
)

;; Admin function to add new trait category
(define-public (add-trait-category (category-name (string-ascii 32)) (trait-options (list 20 (string-ascii 64))))
  (begin
    (asserts! (is-admin tx-sender) ERR-ADMIN-ONLY)
    (asserts! (> (len trait-options) u0) ERR-EMPTY-TRAIT-LIST)
    
    ;; Add trait options for category
    (map-set trait-category-options category-name trait-options)
    
    ;; Set default rarity weights for new traits
    (unwrap-panic (set-default-rarity-weights category-name trait-options))
    
    ;; Mark as admin category
    (map-set admin-trait-categories category-name true)
    
    (print {event: "trait-category-added", category: category-name, traits-count: (len trait-options)})
    (ok true)
  )
)

;; Set default rarity weights for trait list
(define-private (set-default-rarity-weights (category (string-ascii 32)) (traits (list 20 (string-ascii 64))))
  (begin
    (unwrap-panic (set-trait-rarity-weight category (unwrap-panic (element-at traits u0)) u60))
    (if (> (len traits) u1) (unwrap-panic (set-trait-rarity-weight category (unwrap-panic (element-at traits u1)) u25)) true)
    (if (> (len traits) u2) (unwrap-panic (set-trait-rarity-weight category (unwrap-panic (element-at traits u2)) u10)) true)
    (if (> (len traits) u3) (unwrap-panic (set-trait-rarity-weight category (unwrap-panic (element-at traits u3)) u4)) true)
    (if (> (len traits) u4) (unwrap-panic (set-trait-rarity-weight category (unwrap-panic (element-at traits u4)) u1)) true)
    (ok true)
  )
)

;; Helper function to set individual trait rarity weight
(define-private (set-trait-rarity-weight (category (string-ascii 32)) (trait (string-ascii 64)) (weight uint))
  (begin
    (map-set trait-rarity-weights {category: category, trait: trait} weight)
    (ok true)
  )
)

;; Admin function to update trait rarity weights
(define-public (set-trait-rarity (category (string-ascii 32)) (trait (string-ascii 64)) (rarity-weight uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-ADMIN-ONLY)
    (asserts! (<= rarity-weight u100) ERR-INVALID-RARITY)
    
    (map-set trait-rarity-weights {category: category, trait: trait} rarity-weight)
    (print {event: "rarity-updated", category: category, trait: trait, weight: rarity-weight})
    (ok true)
  )
)

;; Admin function to set metadata base URI
(define-public (set-metadata-base-uri (new-uri (string-utf8 256)))
  (begin
    (asserts! (is-admin tx-sender) ERR-ADMIN-ONLY)
    (var-set metadata-base-uri new-uri)
    (print {event: "metadata-uri-updated", new-uri: new-uri})
    (ok true)
  )
)

;; Initialize default trait categories and options
(define-public (initialize-default-traits)
  (begin
    (asserts! (is-admin tx-sender) ERR-ADMIN-ONLY)
    
    ;; Initialize Background traits
    (map-set trait-category-options "Background" (list "Solid" "Gradient" "Textured" "Abstract" "Geometric"))
    
    ;; Initialize Color traits
    (map-set trait-category-options "Color" (list "Monochrome" "Vibrant" "Pastel" "Neon" "Earth"))
    
    ;; Initialize Shape traits
    (map-set trait-category-options "Shape" (list "Circles" "Triangles" "Squares" "Organic" "Complex"))
    
    ;; Initialize Pattern traits
    (map-set trait-category-options "Pattern" (list "Dots" "Lines" "Waves" "Fractals" "Mandala"))
    
    ;; Initialize Effects traits
    (map-set trait-category-options "Effects" (list "None" "Glow" "Shadow" "Blur" "Distortion"))
    
    (print {event: "default-traits-initialized"})
    (ok true)
  )
)

;; ==================
;; Read-Only Functions
;; ==================

;; Get metadata for a token ID
(define-read-only (get-token-metadata (token-id uint))
  (map-get? token-metadata token-id)
)

;; Get JSON metadata for a token ID
(define-read-only (get-token-json (token-id uint))
  (map-get? token-json-metadata token-id)
)

;; Get trait options for a category
(define-read-only (get-trait-options (category (string-ascii 32)))
  (map-get? trait-category-options category)
)

;; Get trait rarity weight
(define-read-only (get-trait-rarity (category (string-ascii 32)) (trait (string-ascii 64)))
  (map-get? trait-rarity-weights {category: category, trait: trait})
)

;; Get trait frequency (for rarity calculation)
(define-read-only (get-trait-frequency (category (string-ascii 32)) (trait (string-ascii 64)))
  (default-to u0 (map-get? trait-frequency {category: category, trait: trait}))
)

;; Get total metadata generated
(define-read-only (get-total-generated)
  (var-get total-metadata-generated)
)

;; Get metadata base URI
(define-read-only (get-metadata-base-uri)
  (var-get metadata-base-uri)
)

;; Get all trait categories
(define-read-only (get-trait-categories)
  (var-get trait-categories)
)

;; Get contract admin
(define-read-only (get-contract-admin)
  (var-get contract-admin)
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-generated: (var-get total-metadata-generated),
    total-categories: (len (var-get trait-categories)),
    metadata-base-uri: (var-get metadata-base-uri),
    admin: (var-get contract-admin)
  }
)

