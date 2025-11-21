# ArtGallery - NFT Art Marketplace

A comprehensive NFT marketplace smart contract built on Stacks blockchain with artist royalties, auction system, fixed-price sales, and collection management.

## Features

### Core Functionality
- **NFT Minting**: Artists can mint unique artworks with metadata stored on IPFS
- **Artist Royalties**: Configurable royalty percentages (up to 25%) for secondary sales
- **Auction System**: Time-based auctions with bidding functionality
- **Fixed-Price Sales**: Direct purchase listings for instant transactions
- **Collection Management**: Organize artworks into curated collections
- **Provenance Tracking**: Complete sale history for every artwork
- **Artist Profiles**: Registration and verification system for artists

### Key Features
- ✅ Artist royalty enforcement on all sales
- ✅ Platform fee management (default 5%)
- ✅ Auction bidding with automatic highest bidder tracking
- ✅ Transfer and ownership management
- ✅ Marketplace statistics and analytics
- ✅ Multi-sale type support (auctions and fixed-price)

## Contract Architecture

### Data Structures

#### Artworks
Stores NFT metadata and ownership information:
- Artist principal
- Title and description
- IPFS hash for artwork storage
- Current owner
- Royalty percentage
- Sale count and creation timestamp

#### Auctions
Manages time-based auction listings:
- Starting price and current bid
- Highest bidder tracking
- End block height
- Active status

#### Fixed-Price Listings
Direct sale listings with set prices:
- Artwork ID and seller
- Fixed price
- Listing timestamp
- Active/inactive status

#### Collections
Curated groups of artworks:
- Creator information
- Collection metadata
- Artwork count
- Floor price tracking

#### Artist Profiles
Artist registration and statistics:
- Artist name
- Total artworks and earnings
- Verification status

## Public Functions

### Minting & Creation

#### `mint-artwork`
```clarity
(mint-artwork 
  (title (string-ascii 128))
  (description (string-ascii 512))
  (ipfs-hash (string-ascii 64))
  (royalty-percent uint))
```
Mint a new artwork NFT with specified royalty percentage (max 25%).

**Returns**: `(ok artwork-id)`

#### `create-collection`
```clarity
(create-collection
  (name (string-ascii 128))
  (description (string-ascii 512)))
```
Create a new collection for organizing artworks.

**Returns**: `(ok collection-id)`

#### `register-artist`
```clarity
(register-artist (name (string-ascii 64)))
```
Register as an artist on the platform.

**Returns**: `(ok true)`

### Auction Functions

#### `create-auction`
```clarity
(create-auction 
  (artwork-id uint)
  (starting-price uint)
  (duration uint))
```
List an artwork for auction. Only the owner can create an auction.

**Returns**: `(ok auction-id)`

#### `place-bid`
```clarity
(place-bid 
  (auction-id uint)
  (bid-amount uint))
```
Place a bid on an active auction. Bid must exceed current highest bid.

**Returns**: `(ok true)`

#### `end-auction`
```clarity
(end-auction (auction-id uint))
```
End an auction after the duration expires. Transfers ownership to highest bidder.

**Returns**: `(ok true)`

### Fixed-Price Sales

#### `list-for-sale`
```clarity
(list-for-sale 
  (artwork-id uint)
  (price uint))
```
List an artwork at a fixed price. Only the owner can list.

**Returns**: `(ok listing-id)`

#### `buy-artwork`
```clarity
(buy-artwork (listing-id uint))
```
Purchase an artwork at the listed price. Automatically handles royalty distribution.

**Returns**: `(ok true)`

### Transfers & Management

#### `transfer-artwork`
```clarity
(transfer-artwork 
  (artwork-id uint)
  (recipient principal))
```
Transfer artwork ownership to another principal.

**Returns**: `(ok true)`

#### `add-to-collection`
```clarity
(add-to-collection 
  (artwork-id uint)
  (collection-id uint))
```
Add an artwork to a collection. Both artwork and collection must be owned by caller.

**Returns**: `(ok true)`

## Read-Only Functions

### `get-artwork`
Retrieve artwork details by ID.

### `get-auction`
Retrieve auction details by auction ID.

### `get-listing`
Retrieve fixed-price listing details.

### `get-collection`
Retrieve collection information.

### `get-artist-profile`
Retrieve artist profile by principal.

### `get-sale`
Retrieve historical sale information.

### `get-marketplace-stats`
Get total sales volume and platform fee percentage.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Action restricted to contract owner |
| u101 | `err-not-found` | Resource not found |
| u102 | `err-unauthorized` | Caller not authorized |
| u103 | `err-invalid-bid` | Bid amount invalid |
| u104 | `err-auction-ended` | Auction already ended |
| u105 | `err-not-artist` | Caller is not the artist |
| u106 | `err-already-listed` | Artwork already listed |
| u107 | `err-invalid-price` | Price must be greater than 0 |

## Events

The contract emits events for all major actions:
- `artwork-minted`
- `auction-created`
- `bid-placed`
- `auction-ended`
- `artwork-listed`
- `artwork-sold`
- `artwork-transferred`
- `collection-created`
- `artwork-added-to-collection`
- `artist-registered`

## Usage Examples

### Minting an Artwork
```clarity
(contract-call? .artgallery mint-artwork
  "Digital Sunset"
  "A beautiful digital sunset over mountains"
  "QmXy...abc123"
  u10) ;; 10% royalty
```

### Creating an Auction
```clarity
(contract-call? .artgallery create-auction
  u1        ;; artwork-id
  u1000000  ;; starting price (1 STX in micro-STX)
  u144)     ;; duration in blocks (~24 hours)
```

### Buying Artwork
```clarity
(contract-call? .artgallery buy-artwork u1) ;; listing-id
```

## Security Considerations

- Only artwork owners can create listings or auctions
- Royalty percentages capped at 25%
- Auction bids must exceed current highest bid
- Auctions can only be ended after duration expires
- All ownership transfers are validated

## Platform Economics

- **Platform Fee**: 5% (configurable)
- **Artist Royalties**: Up to 25% (set per artwork)
- **Total Sales Volume**: Tracked globally across all transactions

## Development

### Prerequisites
- Clarinet CLI
- Stacks blockchain node (for deployment)

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## Future Enhancements

- [ ] Batch minting functionality
- [ ] Dutch auction support
- [ ] Lazy minting
- [ ] Edition support (multiple copies)
- [ ] Offer system for artworks not listed
- [ ] Artist verification process
- [ ] Collection floor price automation
- [ ] Revenue split for collaborative works

## License

MIT License

## Contributing

Contributions welcome! Please submit pull requests or open issues for bugs and feature requests.

---

**Contract Version**: 1.0.0  
**Network**: Stacks Blockchain  
**Language**: Clarity
