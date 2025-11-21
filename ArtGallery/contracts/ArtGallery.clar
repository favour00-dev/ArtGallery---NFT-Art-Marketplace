;; ArtGallery - NFT Art Marketplace with Royalties
;; Artist royalties, auction system, and provenance tracking

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-bid (err u103))
(define-constant err-auction-ended (err u104))
(define-constant err-not-artist (err u105))
(define-constant err-already-listed (err u106))
(define-constant err-invalid-price (err u107))

(define-data-var next-artwork-id uint u1)
(define-data-var next-auction-id uint u1)
(define-data-var next-sale-id uint u1)
(define-data-var next-collection-id uint u1)
(define-data-var total-sales-volume uint u0)
(define-data-var platform-fee uint u5)

(define-map artworks
  uint
  {
    artist: principal,
    title: (string-ascii 128),
    description: (string-ascii 512),
    ipfs-hash: (string-ascii 64),
    owner: principal,
    royalty-percent: uint,
    sale-count: uint,
    created-at: uint
  }
)

(define-map auctions
  uint
  {
    artwork-id: uint,
    seller: principal,
    starting-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    end-block: uint,
    active: bool
  }
)

(define-map artist-profiles
  principal
  {
    name: (string-ascii 64),
    total-artworks: uint,
    total-earnings: uint,
    verified: bool
  }
)

(define-map fixed-price-listings
  uint
  {
    artwork-id: uint,
    seller: principal,
    price: uint,
    listed-at: uint,
    active: bool
  }
)

(define-map collections
  uint
  {
    creator: principal,
    name: (string-ascii 128),
    description: (string-ascii 512),
    artwork-count: uint,
    floor-price: uint,
    created-at: uint
  }
)

(define-map artwork-collections
  {artwork-id: uint}
  uint
)

(define-map sale-history
  uint
  {
    artwork-id: uint,
    seller: principal,
    buyer: principal,
    price: uint,
    timestamp: uint
  }
)

(define-public (mint-artwork
    (title (string-ascii 128))
    (description (string-ascii 512))
    (ipfs-hash (string-ascii 64))
    (royalty-percent uint))
  (let ((artwork-id (var-get next-artwork-id)))
    (asserts! (<= royalty-percent u25) err-invalid-bid)

    (map-set artworks artwork-id {
      artist: tx-sender,
      title: title,
      description: description,
      ipfs-hash: ipfs-hash,
      owner: tx-sender,
      royalty-percent: royalty-percent,
      sale-count: u0,
      created-at: block-height
    })

    (var-set next-artwork-id (+ artwork-id u1))
    (print {event: "artwork-minted", artwork-id: artwork-id, artist: tx-sender})
    (ok artwork-id)
  )
)

(define-public (create-auction (artwork-id uint) (starting-price uint) (duration uint))
  (let (
    (artwork (unwrap! (map-get? artworks artwork-id) err-not-found))
    (auction-id (var-get next-auction-id))
  )
    (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)

    (map-set auctions auction-id {
      artwork-id: artwork-id,
      seller: tx-sender,
      starting-price: starting-price,
      current-bid: starting-price,
      highest-bidder: none,
      end-block: (+ block-height duration),
      active: true
    })

    (var-set next-auction-id (+ auction-id u1))
    (print {event: "auction-created", auction-id: auction-id, artwork-id: artwork-id})
    (ok auction-id)
  )
)

(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let ((auction (unwrap! (map-get? auctions auction-id) err-not-found)))
    (asserts! (get active auction) err-auction-ended)
    (asserts! (< block-height (get end-block auction)) err-auction-ended)
    (asserts! (> bid-amount (get current-bid auction)) err-invalid-bid)

    (map-set auctions auction-id
      (merge auction {
        current-bid: bid-amount,
        highest-bidder: (some tx-sender)
      }))

    (print {event: "bid-placed", auction-id: auction-id, bidder: tx-sender, amount: bid-amount})
    (ok true)
  )
)

(define-public (end-auction (auction-id uint))
  (let ((auction (unwrap! (map-get? auctions auction-id) err-not-found)))
    (asserts! (>= block-height (get end-block auction)) err-auction-ended)
    (asserts! (get active auction) err-unauthorized)

    (map-set auctions auction-id (merge auction {active: false}))

    (match (get highest-bidder auction)
      winner (let ((artwork (unwrap! (map-get? artworks (get artwork-id auction)) err-not-found)))
        (map-set artworks (get artwork-id auction)
          (merge artwork {
            owner: winner,
            sale-count: (+ (get sale-count artwork) u1)
          }))
        (var-set total-sales-volume (+ (var-get total-sales-volume) (get current-bid auction)))
      )
      true
    )

    (print {event: "auction-ended", auction-id: auction-id})
    (ok true)
  )
)

(define-read-only (get-artwork (artwork-id uint))
  (map-get? artworks artwork-id)
)

(define-read-only (get-auction (auction-id uint))
  (map-get? auctions auction-id)
)

(define-read-only (get-artist-profile (artist principal))
  (map-get? artist-profiles artist)
)

(define-public (list-for-sale (artwork-id uint) (price uint))
  (let (
    (artwork (unwrap! (map-get? artworks artwork-id) err-not-found))
    (listing-id (var-get next-sale-id))
  )
    (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)
    (asserts! (> price u0) err-invalid-price)

    (map-set fixed-price-listings listing-id {
      artwork-id: artwork-id,
      seller: tx-sender,
      price: price,
      listed-at: block-height,
      active: true
    })

    (var-set next-sale-id (+ listing-id u1))
    (print {event: "artwork-listed", listing-id: listing-id, artwork-id: artwork-id, price: price})
    (ok listing-id)
  )
)

(define-public (buy-artwork (listing-id uint))
  (let (
    (listing (unwrap! (map-get? fixed-price-listings listing-id) err-not-found))
    (artwork (unwrap! (map-get? artworks (get artwork-id listing)) err-not-found))
    (sale-id (var-get next-sale-id))
    (royalty-amount (/ (* (get price listing) (get royalty-percent artwork)) u100))
  )
    (asserts! (get active listing) err-unauthorized)

    (map-set artworks (get artwork-id listing)
      (merge artwork {
        owner: tx-sender,
        sale-count: (+ (get sale-count artwork) u1)
      }))

    (map-set fixed-price-listings listing-id
      (merge listing {active: false}))

    (map-set sale-history sale-id {
      artwork-id: (get artwork-id listing),
      seller: (get seller listing),
      buyer: tx-sender,
      price: (get price listing),
      timestamp: block-height
    })

    (var-set total-sales-volume (+ (var-get total-sales-volume) (get price listing)))

    (print {event: "artwork-sold", artwork-id: (get artwork-id listing), buyer: tx-sender, price: (get price listing)})
    (ok true)
  )
)

(define-public (transfer-artwork (artwork-id uint) (recipient principal))
  (let ((artwork (unwrap! (map-get? artworks artwork-id) err-not-found)))
    (asserts! (is-eq (get owner artwork) tx-sender) err-unauthorized)

    (map-set artworks artwork-id (merge artwork {owner: recipient}))

    (print {event: "artwork-transferred", artwork-id: artwork-id, from: tx-sender, to: recipient})
    (ok true)
  )
)

(define-public (create-collection
    (name (string-ascii 128))
    (description (string-ascii 512)))
  (let ((collection-id (var-get next-collection-id)))
    (map-set collections collection-id {
      creator: tx-sender,
      name: name,
      description: description,
      artwork-count: u0,
      floor-price: u0,
      created-at: block-height
    })

    (var-set next-collection-id (+ collection-id u1))
    (print {event: "collection-created", collection-id: collection-id, creator: tx-sender})
    (ok collection-id)
  )
)

(define-public (add-to-collection (artwork-id uint) (collection-id uint))
  (let (
    (artwork (unwrap! (map-get? artworks artwork-id) err-not-found))
    (collection (unwrap! (map-get? collections collection-id) err-not-found))
  )
    (asserts! (is-eq (get artist artwork) tx-sender) err-not-artist)
    (asserts! (is-eq (get creator collection) tx-sender) err-unauthorized)

    (map-set artwork-collections {artwork-id: artwork-id} collection-id)

    (map-set collections collection-id
      (merge collection {artwork-count: (+ (get artwork-count collection) u1)}))

    (print {event: "artwork-added-to-collection", artwork-id: artwork-id, collection-id: collection-id})
    (ok true)
  )
)

(define-public (register-artist (name (string-ascii 64)))
  (begin
    (map-set artist-profiles tx-sender {
      name: name,
      total-artworks: u0,
      total-earnings: u0,
      verified: false
    })

    (print {event: "artist-registered", artist: tx-sender})
    (ok true)
  )
)

(define-read-only (get-listing (listing-id uint))
  (map-get? fixed-price-listings listing-id)
)

(define-read-only (get-collection (collection-id uint))
  (map-get? collections collection-id)
)

(define-read-only (get-sale (sale-id uint))
  (map-get? sale-history sale-id)
)

(define-read-only (get-marketplace-stats)
  (ok {
    total-sales: (var-get total-sales-volume),
    platform-fee: (var-get platform-fee)
  })
)
