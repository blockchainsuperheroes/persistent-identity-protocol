# Related Standards Analysis

## Overview

Persistent Identity Protocol (PIP) builds upon and extends several existing Ethereum standards. This document maps the relationship between PIP and each relevant ERC, explaining what PIP borrows, extends, and introduces new.

---

## Standards Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Persistent Identity Protocol                      │
│         username · binding · URL record · policy · lifecycle         │
├──────────┬──────────┬──────────┬──────────┬────────────────────────┤
│ ERC-721  │ ERC-5192 │   ENS    │ ERC-6551 │      ERC-4337          │
│ (base)   │ (extend) │ (differ) │ (compat) │      (compat)          │
└──────────┴──────────┴──────────┴──────────┴────────────────────────┘
```

---

## ERC-721: Non-Fungible Token Standard

**Relationship:** PIP is built on ERC-721.

| Aspect | ERC-721 | PIP |
|--------|---------|-----|
| Token ownership | ✅ | ✅ Inherits |
| Transfer | ✅ Unrestricted | ✅ Conditional (blocked when bound) |
| Metadata | tokenURI | tokenURI + name resolution + URL record |
| Identity semantics | ❌ | ✅ Names, binding, lifecycle |

**What PIP adds:** Name-to-token mapping, address binding, soulbound locking, URL records, and policy-controlled governance. A PIP token IS an ERC-721 token with identity capabilities.

---

## ERC-5192: Minimal Soulbound Token

**Relationship:** PIP extends the soulbound concept.

| Aspect | ERC-5192 | PIP |
|--------|----------|-----|
| Non-transferable | Always (from mint) | Conditional (only when bound) |
| Lock mechanism | `locked()` returns bool | `isBound()` — binding triggers lock |
| Unlock | Not supported | Governance unbind unlocks |
| Use case | Permanent credentials | Active identity protection |

**What PIP adds:** ERC-5192 defines permanently non-transferable tokens. PIP introduces *conditionally* non-transferable tokens. An identity is tradable until the user binds it, at which point it becomes soulbound. Governance can unbind to re-enable trading. This enables a secondary market for unclaimed identities while protecting active ones.

```
ERC-5192: MINT ──── LOCKED (forever)

PIP:      MINT ── UNBOUND (tradable) ── BIND ── BOUND (soulbound) ── UNBIND ── UNBOUND (tradable)
                       ↑                                                  │
                       └──────────────────────────────────────────────────┘
```

---

## ENS: Ethereum Name Service

**Relationship:** PIP operates at a different layer than ENS.

| Aspect | ENS | PIP |
|--------|-----|-----|
| Purpose | Name → address resolution (like DNS) | Username → identity (like login) |
| Ownership | Lease-based (must renew) | Persistent (no expiry) |
| Transferability | Always tradable | SBT when bound |
| Login support | Not designed for login | Designed for login |
| URL forwarding | Via resolver (off-chain) | On-chain URL record |
| Namespace | Single global namespace | Multiple configurable namespaces |
| Bot resistance | Weak (cheap registration) | Economic pricing per namespace |
| Governance | DAO-based | Namespace-defined policy |
| Social graph | Limited | Cross-app, identity-based |

**Key philosophical difference:** ENS names *addresses*. PIP names *people* (and agents). ENS is infrastructure for the network. PIP is infrastructure for applications.

```
ENS:  "vitalik.eth" → 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045

PIP:  "vitalik" → Identity Token #42
                    ├─ Bound address: 0xd8dA...
                    ├─ URL record: https://vitalik.ca
                    ├─ Tier: Reserved
                    ├─ Bound: true (soulbound)
                    ├─ Owner: 0xd8dA...
                    └─ History: mint → bind → URL set
```

**Coexistence:** PIP and ENS can coexist. A user might have `vitalik.eth` (ENS) AND `@vitalik` (PIP). ENS resolves for blockchain transactions. PIP resolves for application identity.

---

## ERC-6551: Non-fungible Token Bound Accounts

**Relationship:** Complementary.

| Aspect | ERC-6551 | PIP |
|--------|----------|-----|
| Purpose | Give NFTs wallet capabilities | Give users persistent identity |
| Execution | NFT can own assets, sign txs | Identity resolves to address |
| Identity | Not defined | Core focus |
| Username | Not defined | Core feature |

**How they work together:**

```
┌─────────────────────────┐
│    PIP Identity Token    │
│    @username (ERC-721)   │
│                          │
│  ┌────────────────────┐  │
│  │   ERC-6551 TBA     │  │ ← Token-Bound Account
│  │   (smart wallet)   │  │
│  │   Owns assets      │  │
│  │   Signs messages   │  │
│  │   Executes txs     │  │
│  └────────────────────┘  │
│                          │
│  Bound Address: 0x...    │ ← PIP binding
│  URL Record: https://... │ ← PIP URL
│  Tier: Standard          │ ← PIP classification
└─────────────────────────┘
```

A PIP identity token MAY have an associated TBA (ERC-6551). This gives the identity a programmable wallet, enabling agent execution, asset custody, and autonomous actions — all tied to a human-readable name.

---

## ERC-4337: Account Abstraction

**Relationship:** Compatible.

| Aspect | ERC-4337 | PIP |
|--------|----------|-----|
| Purpose | Smart account UX | Identity naming |
| UserOps | Bundled transactions | Standard calls |
| Identity | Not defined | Core focus |

PIP identity resolution can be used within ERC-4337 smart accounts. A UserOperation could reference a PIP name instead of a raw address. The resolver translates name → address before execution.

---

## ERC-725: Proxy Identity

**Relationship:** Different scope.

| Aspect | ERC-725 | PIP |
|--------|---------|-----|
| Purpose | Enterprise identity + key management | User-facing identity + naming |
| Complexity | High (key types, execution) | Low (bind, resolve, URL) |
| Username | Not supported | Core feature |
| Social graph | Not supported | Supported |
| Login | Not designed for login | Designed for login |

ERC-725 is enterprise identity infrastructure. PIP is consumer/app identity. They solve different problems at different layers.

---

## The Gap PIP Fills

```
Layer 4: Applications     ← PIP lives here (identity for apps, games, social)
Layer 3: Account          ← ERC-4337 (smart accounts)
Layer 2: Execution        ← ERC-6551 (NFT wallets)
Layer 1: Naming           ← ENS (name → address)
Layer 0: Ownership        ← ERC-721 + ERC-5192 (token standards)
```

No existing standard provides a complete identity layer for applications. PIP fills this gap by combining:

1. **Human-readable names** (from ENS concept)
2. **Token ownership** (from ERC-721)
3. **Conditional soulbound** (extending ERC-5192)
4. **URL records** (new)
5. **Login compatibility** (new)
6. **Namespace policies** (new)
7. **Economic spam resistance** (new)
8. **Social graph primitives** (new)

---

## Summary Table

| Standard | What it does | Relationship to PIP |
|----------|-------------|-------------------|
| ERC-721 | NFT ownership | **Base** — PIP tokens are ERC-721 |
| ERC-5192 | Soulbound tokens | **Extended** — conditional SBT via binding |
| ENS | Name → address | **Different layer** — ENS names addresses, PIP names people |
| ERC-6551 | NFT wallets | **Complementary** — identity can have a TBA |
| ERC-4337 | Smart accounts | **Compatible** — PIP resolution in smart accounts |
| ERC-725 | Enterprise identity | **Different scope** — PIP is consumer/app identity |
