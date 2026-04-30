# Decentralized Resolution: Why SBT Names Don't Need DNS

## The Key Insight

Because PIP identity names are on-chain and soulbound when active, **anyone can build a reverse lookup registry** without depending on a single DNS provider. If a centralized resolver is compromised, other resolvers continue serving correct data from the same on-chain source.

## How DNS Resolution Works (centralized)

```
         User types: username.example.com
                        │
                        ▼
                ┌───────────────┐
                │  DNS Root      │
                │  Servers       │
                └───────┬───────┘
                        │
                        ▼
                ┌───────────────┐
                │  .com TLD      │
                │  Nameservers   │
                └───────┬───────┘
                        │
                        ▼
                ┌───────────────┐
                │  Registrar     │  ← SINGLE POINT OF FAILURE
                │  (GoDaddy etc) │  ← If hacked, ALL records change
                └───────┬───────┘  ← If seized, domain is gone
                        │
                        ▼
                ┌───────────────┐
                │  IP Address    │
                │  Response      │
                └───────────────┘
```

**Problem:** A single compromised registrar can redirect ALL traffic. Users have no way to verify the record independently.

## How PIP Resolution Works (decentralized)

```
         User wants to find: @username
                        │
              ┌─────────┼─────────┐
              │         │         │
              ▼         ▼         ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │Resolver A│ │Resolver B│ │Resolver C│  ← Multiple independent
        │(peg.gg)  │ │(myapp)   │ │(wallet)  │     resolvers
        └────┬─────┘ └────┬─────┘ └────┬─────┘
             │            │            │
             └──────┬─────┘────────────┘
                    │
                    ▼
            ┌──────────────┐
            │ PIP Contract  │  ← IMMUTABLE SOURCE OF TRUTH
            │ On-Chain      │  ← No single entity can change
            │               │  ← Verified by consensus
            │ tokenOfName() │
            │ boundAddress()│
            │ urlRecord()   │
            └──────────────┘
```

**Advantage:** Even if Resolver A is compromised, Resolver B and C serve correct data. Anyone can run a resolver. The smart contract's data is protected by blockchain consensus.

## Why SBT Matters for Trust

If identity names were freely tradable (like ENS domains), a compromised resolver could:
1. Show a fake "transfer" to make a name appear to belong to an attacker
2. Cache stale data after a rapid buy-sell-transfer attack
3. Front-run lookups during a transfer window

With PIP's soulbound model:
- **Bound names can't transfer** — no fake transfer attacks
- **Unbinding requires governance** — public, auditable, slow
- **History is immutable** — resolvers can verify binding state
- **Name squatting is economically costly** — pricing prevents mass registration

```
Attack on DNS:
  Hacker compromises registrar → changes A record → ALL users affected → immediate

Attack on PIP:
  Hacker compromises resolver → serves wrong data → users verify on-chain → caught
  Hacker compromises contract owner → must go through governance → visible, slow → caught
```

## Building Your Own Resolver

Because the data is on-chain, building a resolver is trivial:

```javascript
const pip = new ethers.Contract(PIP_ADDRESS, ABI, provider);

// Full resolution in 3 calls
async function resolve(name) {
    const registered = await pip.nameRegistered(name);
    if (!registered) return null;

    const tokenId = await pip.tokenOfName(name);
    const [owner, boundAddr, bound, url, tier] = await Promise.all([
        pip.ownerOf(tokenId),
        pip.boundAddress(tokenId),
        pip.isBound(tokenId),
        pip.urlRecord(tokenId),
        pip.tierOf(tokenId)
    ]);

    return { name, tokenId, owner, boundAddr, bound, url, tier };
}
```

Any app, wallet, or service can implement this. No API keys, no registration, no permission needed. Just read from the public blockchain.

## Resolution Trust Model

| Model | Trust Required | Failure Mode | Recovery |
|-------|---------------|-------------|----------|
| DNS | Trust registrar + ISP | Single point failure, mass redirect | Wait for registrar fix |
| ENS | Trust ENS resolver + Ethereum | Resolver can be swapped | Use different resolver |
| PIP | Trust Ethereum consensus only | Individual resolver failure | Use any other resolver |

PIP achieves the strongest trust model because:
1. Source of truth is on-chain (consensus-protected)
2. Bound identities can't be transferred (no transfer attacks)
3. Anyone can verify independently (permissionless reads)
4. Anyone can build a resolver (no centralized dependency)
