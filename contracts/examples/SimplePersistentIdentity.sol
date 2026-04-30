// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPersistentIdentity.sol";
import "../interfaces/IPersistentIdentityResolver.sol";
import "../interfaces/IPersistentIdentityPolicy.sol";

/**
 * @title SimplePersistentIdentity
 * @notice Minimal reference implementation of the Persistent Identity Protocol.
 *         Demonstrates core identity lifecycle: mint → bind → soulbound → unbind → tradable.
 *
 *  This is a simplified example. Production implementations should add:
 *  - Upgradeability (UUPS or transparent proxy)
 *  - Batch operations
 *  - Metadata URI with classification data
 *  - Extended policy rules
 */
contract SimplePersistentIdentity is
    ERC721,
    AccessControl,
    IPersistentIdentity,
    IPersistentIdentityResolver,
    IPersistentIdentityPolicy
{
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    uint256 private _nextTokenId = 1;

    // Name ↔ Token mappings
    mapping(uint256 => string) private _tokenName;
    mapping(string => uint256) private _nameToToken;
    mapping(string => bool) private _nameRegistered;

    // Token state
    mapping(uint256 => Tier) private _tokenTier;
    mapping(uint256 => address) private _boundAddress;
    mapping(uint256 => bool) private _isBound;
    mapping(uint256 => string) private _urlRecord;

    // Policy: pricing
    mapping(string => uint256) private _namePrice;
    mapping(string => uint8) private _nameTier;
    address private _treasury;

    constructor(
        address admin,
        address moderator,
        address treasury_
    ) ERC721("Persistent Identity", "PID") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MODERATOR_ROLE, moderator);
        _treasury = treasury_;
    }

    // ═══════════════════════════════════════════════════════════════════
    //  IPersistentIdentity — Name Resolution
    // ═══════════════════════════════════════════════════════════════════

    function nameRegistered(string calldata name) external view override returns (bool) {
        return _nameRegistered[name];
    }

    function tokenOfName(string calldata name) external view override returns (uint256) {
        require(_nameRegistered[name], "name not registered");
        return _nameToToken[name];
    }

    function nameOf(uint256 tokenId) external view override returns (string memory) {
        return _tokenName[tokenId];
    }

    // ═══════════════════════════════════════════════════════════════════
    //  IPersistentIdentity — Address Binding
    // ═══════════════════════════════════════════════════════════════════

    function boundAddress(uint256 tokenId) external view override returns (address) {
        return _boundAddress[tokenId];
    }

    function isBound(uint256 tokenId) external view override returns (bool) {
        return _isBound[tokenId];
    }

    function bind(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        _boundAddress[tokenId] = msg.sender;
        _isBound[tokenId] = true;
        emit IdentityBound(tokenId, msg.sender);
    }

    // ═══════════════════════════════════════════════════════════════════
    //  IPersistentIdentity — URL Record
    // ═══════════════════════════════════════════════════════════════════

    function urlRecord(uint256 tokenId) external view override returns (string memory) {
        return _urlRecord[tokenId];
    }

    function setUrlRecord(uint256 tokenId, string calldata url) external override {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        if (!_isBound[tokenId]) revert IdentityNotBound();
        _urlRecord[tokenId] = url;
        emit UrlRecordSet(tokenId, url);
    }

    // ═══════════════════════════════════════════════════════════════════
    //  IPersistentIdentity — Metadata
    // ═══════════════════════════════════════════════════════════════════

    function tierOf(uint256 tokenId) external view override returns (Tier) {
        return _tokenTier[tokenId];
    }

    function totalMinted() external view override returns (uint256) {
        return _nextTokenId - 1;
    }

    // ═══════════════════════════════════════════════════════════════════
    //  IPersistentIdentityResolver
    // ═══════════════════════════════════════════════════════════════════

    function resolveAddress(string calldata name) external view override returns (address) {
        if (!_nameRegistered[name]) return address(0);
        return _boundAddress[_nameToToken[name]];
    }

    function resolveUrl(string calldata name) external view override returns (string memory) {
        if (!_nameRegistered[name]) return "";
        return _urlRecord[_nameToToken[name]];
    }

    function resolveIdentity(string calldata name) external view override returns (
        uint256 tokenId, address owner, address boundAddr, bool bound, string memory url, uint8 tier
    ) {
        require(_nameRegistered[name], "name not registered");
        tokenId = _nameToToken[name];
        owner = ownerOf(tokenId);
        boundAddr = _boundAddress[tokenId];
        bound = _isBound[tokenId];
        url = _urlRecord[tokenId];
        tier = uint8(_tokenTier[tokenId]);
    }

    // ═══════════════════════════════════════════════════════════════════
    //  IPersistentIdentityPolicy — Governance
    // ═══════════════════════════════════════════════════════════════════

    function unbind(uint256 tokenId) external override onlyRole(MODERATOR_ROLE) {
        delete _boundAddress[tokenId];
        delete _urlRecord[tokenId];
        _isBound[tokenId] = false;
        emit IdentityUnbound(tokenId);
    }

    function rename(uint256 tokenId, string calldata newName) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bytes(newName).length == 0) revert EmptyName();
        if (_nameRegistered[newName]) revert NameAlreadyRegistered(newName);

        string memory oldName = _tokenName[tokenId];
        delete _nameToToken[oldName];
        delete _nameRegistered[oldName];

        _tokenName[tokenId] = newName;
        _nameToToken[newName] = tokenId;
        _nameRegistered[newName] = true;

        emit IdentityRenamed(tokenId, oldName, newName);
    }

    function setNamePrice(string calldata name, uint256 priceInWei, uint8 tier) external override onlyRole(MODERATOR_ROLE) {
        require(!_nameRegistered[name], "already registered");
        require(priceInWei > 0, "price must be > 0");
        _namePrice[name] = priceInWei;
        _nameTier[name] = tier;
        emit NamePriceSet(name, priceInWei);
    }

    function purchaseMint(string calldata name) external payable override returns (uint256 tokenId) {
        uint256 price = _namePrice[name];
        require(price > 0, "not listed");
        require(msg.value == price, "incorrect payment");
        require(!_nameRegistered[name], "already registered");
        require(_treasury != address(0), "treasury not set");

        delete _namePrice[name];

        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _tokenName[tokenId] = name;
        _nameToToken[name] = tokenId;
        _nameRegistered[name] = true;
        _tokenTier[tokenId] = Tier(_nameTier[name]);
        delete _nameTier[name];

        (bool sent, ) = _treasury.call{value: msg.value}("");
        require(sent, "payment failed");

        emit IdentityMinted(tokenId, name, _tokenTier[tokenId], msg.sender, address(0));
    }

    function namePrice(string calldata name) external view override returns (uint256) {
        return _namePrice[name];
    }

    function treasury() external view override returns (address) {
        return _treasury;
    }

    // ═══════════════════════════════════════════════════════════════════
    //  Moderator Mint (not part of standard, namespace-specific)
    // ═══════════════════════════════════════════════════════════════════

    function mint(address to, string calldata name, Tier tier) external onlyRole(MODERATOR_ROLE) returns (uint256 tokenId) {
        if (bytes(name).length == 0) revert EmptyName();
        if (_nameRegistered[name]) revert NameAlreadyRegistered(name);

        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _tokenName[tokenId] = name;
        _nameToToken[name] = tokenId;
        _nameRegistered[name] = true;
        _tokenTier[tokenId] = tier;

        emit IdentityMinted(tokenId, name, tier, to, address(0));
    }

    // ═══════════════════════════════════════════════════════════════════
    //  Transfer Hook — enforce soulbound when bound
    // ═══════════════════════════════════════════════════════════════════

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Block transfers of bound identities
        if (from != address(0) && _isBound[tokenId]) {
            revert IdentityBoundLocked();
        }

        // Clear binding on transfer (safety net)
        if (from != address(0) && to != address(0)) {
            delete _boundAddress[tokenId];
            delete _urlRecord[tokenId];
            _isBound[tokenId] = false;
        }

        return super._update(to, tokenId, auth);
    }

    // ═══════════════════════════════════════════════════════════════════
    //  ERC-165 Support
    // ═══════════════════════════════════════════════════════════════════

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
