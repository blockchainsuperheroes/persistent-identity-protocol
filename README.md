# Persistent Identity Protocol

**Persistent Identity Protocol (PIP)** is a Web3 identity standard for creating persistent, human-readable identity objects mapped to EVM addresses.

It is designed for applications, games, communities, chains, and namespace operators that want to replace traditional usernames with programmable on-chain identities.

## Core Idea

Web2 username systems are platform-controlled and disposable. Web3 addresses are owned, but not human-readable.

Persistent Identity Protocol bridges both models:

```
username → identity token → EVM address → on-chain records → programmable identity
```

## Features

- **Human-readable IDs** mapped to EVM addresses
- **Identity NFTs or SBTs** — transferable when unbound, soulbound when bound
- **Persistent username binding** with governance-controlled unbinding
- **Ownership and change history** — all on-chain
- **On-chain URL forwarding** — canonical URL records per identity
- **Configurable namespace policies** — pricing, tiers, reserved names, moderation
- **Economic spam resistance** — configurable mint pricing prevents bot registration
- **Login system compatible** — identity name → wallet → existing account
- **White-label namespace support** — any app can launch its own identity namespace
- **Metadata extensible** — AI classification, rarity signals, social data

## Architecture

The standard defines three interface layers:

| Layer | Interface | Purpose |
|-------|-----------|---------|
| **Identity** | `IPersistentIdentity` | Name registration, address binding, URL records, soulbound locking |
| **Resolution** | `IPersistentIdentityResolver` | Convenience functions for name → address/URL/identity lookup |
| **Policy** | `IPersistentIdentityPolicy` | Governance: pricing, rename, unbind, purchase |

```
┌──────────────────────────────────────────────────┐
│              Applications / Wallets               │
│   (login, social, games, agents, marketplaces)    │
├──────────────────────────────────────────────────┤
│           IPersistentIdentityResolver             │
│        resolveAddress · resolveUrl · resolveId    │
├──────────────────────────────────────────────────┤
│             IPersistentIdentity (ERC-721)          │
│   nameOf · bind · boundAddress · urlRecord · tier  │
├──────────────────────────────────────────────────┤
│            IPersistentIdentityPolicy              │
│      unbind · rename · setPrice · purchaseMint    │
├──────────────────────────────────────────────────┤
│                 EVM (any chain)                    │
└──────────────────────────────────────────────────┘
```

## Identity Lifecycle

```
MINT (unbound, transferable)
  │
  ├─ User calls bind() → BOUND (soulbound, locked)
  │    ├─ Can set URL record
  │    ├─ Can use as login credential
  │    ├─ Name resolves to user's address
  │    └─ Cannot transfer
  │
  ├─ Policy calls unbind() → UNBOUND (transferable again)
  │    └─ URL record and binding cleared
  │
  └─ Transfer → New owner (unbound)
       └─ Binding and URL cleared automatically
```

## Reference Implementation

**PEG ID** at [id.peg.gg](https://id.peg.gg) is the first reference implementation, deployed on Pentagon Chain (chain ID 3344).

- Contract: `0xf97EB9f8293D1FD5587a809Eb74518c300738d07`
- 90+ identities minted
- AI-driven classification and pricing
- Pentagon.games login integration
- Metadata API with dynamic SVG identity cards

## Comparison

| Feature | Web2 Usernames | ENS | PIP |
|---------|---------------|-----|-----|
| Ownership | Platform-controlled | User-owned (lease) | User-linked (persistent) |
| Expiry | Can be deleted | Must renew | No expiry by default |
| Transferability | No | Yes (tradable) | SBT when bound, tradable when unbound |
| Login Compatible | Native | Not designed for login | Designed for login |
| URL Forwarding | DNS-based | Partial (resolver) | On-chain URL record |
| Bot Resistance | Weak | Weak | Economic pricing + persistence |
| Namespace Control | Centralized | Global public | Configurable per namespace |
| Social Graph | Platform-specific | Limited | Cross-app, identity-based |

## Documentation

| Document | Description |
|----------|-------------|
| [ERC Draft](EIPs/erc-persistent-identity.md) | Full EIP specification |
| [Related Standards](docs/related-standards.md) | Analysis of ERC-721, ERC-5192, ENS, ERC-6551, ERC-4337, ERC-725 |
| [URL Forwarding](docs/url-forwarding.md) | On-chain URL records vs DNS, resolver architecture |
| [Decentralized Resolution](docs/decentralized-resolution.md) | Why SBT names don't need centralized DNS |

## Getting Started

### Install

```bash
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

See [docs/deployment.md](docs/deployment.md) for deployment instructions.

## Repository Structure

```
persistent-identity-protocol/
├── README.md
├── LICENSE
├── foundry.toml
├── EIPs/
│   └── erc-persistent-identity.md      # ERC draft
├── contracts/
│   ├── interfaces/
│   │   ├── IPersistentIdentity.sol      # Core identity interface
│   │   ├── IPersistentIdentityResolver.sol  # Resolution interface
│   │   └── IPersistentIdentityPolicy.sol    # Policy/governance interface
│   └── examples/
│       └── SimplePersistentIdentity.sol # Minimal reference implementation
├── docs/
│   ├── overview.md
│   ├── architecture.md
│   └── deployment.md
├── test/
│   └── PersistentIdentity.t.sol
└── scripts/
    └── deploy.ts
```

## ERC Status

**Draft** — Preparing for Ethereum Magicians submission.

See [EIPs/erc-persistent-identity.md](EIPs/erc-persistent-identity.md) for the full specification.

## License

[CC0 1.0 Universal](LICENSE)
