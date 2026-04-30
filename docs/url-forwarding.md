# On-Chain URL Forwarding

## How It Works

Every bound identity can store a canonical URL record on-chain. This creates a decentralized forwarding system that doesn't depend on DNS.

```
User visits: username.peg.gg
                │
                ▼
         ┌─────────────┐
         │  DNS Lookup  │  ← Standard DNS (any provider)
         │  *.peg.gg    │
         └──────┬──────┘
                │
                ▼
         ┌─────────────┐
         │ Web Server   │  ← Reads from chain or cache
         │ (Resolver)   │
         └──────┬──────┘
                │
                ▼
         ┌─────────────────────────┐
         │ On-Chain URL Record     │  ← Source of truth
         │ tokenOfName("username") │
         │ urlRecord(tokenId)      │
         │ → "https://mysite.com"  │
         └──────┬──────────────────┘
                │
                ▼
         ┌─────────────┐
         │ 302 Redirect │
         │ → mysite.com │
         └─────────────┘
```

## Why On-Chain Beats DNS

### Traditional DNS Forwarding
```
username.example.com
     │
     ▼
┌──────────────┐
│ DNS Registrar │ ← Single point of failure
│ (centralized) │ ← Can be seized, hacked, expired
│ A Record →    │ ← Mutable without user consent
│ CNAME →       │
└──────────────┘
```

**Risks:**
- Registrar can change records without user consent
- Domain can expire and be taken over
- DNS hijacking redirects users to malicious sites
- Centralized control over forwarding destination

### PIP On-Chain URL Record
```
username (PIP identity)
     │
     ▼
┌──────────────────────┐
│ Smart Contract        │ ← Immutable logic
│ urlRecord(tokenId)    │ ← Only owner can change
│ setUrlRecord() needs: │
│   - ownerOf == caller │ ← Ownership verified
│   - isBound == true   │ ← Must be active identity
└──────────────────────┘
```

**Advantages:**
- Only the token owner can change the URL (cryptographic proof)
- URL history is on-chain and auditable
- No registrar can seize or modify the record
- Anyone can build a resolver (no single DNS dependency)
- URL change emits an event (verifiable change log)

## Decentralized Resolution

Because the URL record is on-chain, **anyone** can build a resolver service:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Resolver A   │     │ Resolver B   │     │ Resolver C   │
│ (peg.gg)     │     │ (myapp.com)  │     │ (wallet.xyz) │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                    │                    │
       └────────────┬───────┘────────────────────┘
                    │
                    ▼
            ┌──────────────┐
            │ PIP Contract  │  ← Single source of truth
            │ (any chain)   │
            └──────────────┘
```

No single resolver is authoritative. If one goes down, others continue serving. The contract is the source of truth. This is fundamentally different from DNS, where the registrar IS the authority.

## URL Use Cases

| Use Case | URL Record | Example |
|----------|-----------|---------|
| Personal profile | Portfolio/social | https://twitter.com/username |
| Creator page | Content platform | https://youtube.com/@username |
| Game identity | Game profile | https://mygame.com/player/username |
| Agent landing | AI agent page | https://agent.ai/username |
| Brand page | Company website | https://brand.com |
| DApp entry | Application link | https://defi-app.com/dashboard |
| NFT gallery | Collection view | https://opensea.io/username |

## Implementation

### Setting a URL (on-chain)
```solidity
// User must own the token AND it must be bound
function setUrlRecord(uint256 tokenId, string calldata url) external {
    require(ownerOf(tokenId) == msg.sender, "not owner");
    require(isBound(tokenId), "must bind first");
    _urlRecord[tokenId] = url;
    emit UrlRecordSet(tokenId, url);
}
```

### Resolving a URL (read-only)
```solidity
function resolveUrl(string calldata name) external view returns (string memory) {
    if (!nameRegistered(name)) return "";
    return _urlRecord[tokenOfName(name)];
}
```

### Building a Resolver (off-chain)
```javascript
// Any service can resolve PIP URLs
const provider = new ethers.JsonRpcProvider(RPC_URL);
const pip = new ethers.Contract(PIP_ADDRESS, PIP_ABI, provider);

async function resolve(name) {
    const tokenId = await pip.tokenOfName(name);
    const url = await pip.urlRecord(tokenId);
    if (url) return { redirect: url };
    return { profile: await buildProfilePage(name, tokenId) };
}
```
