// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FuriousApeSociety is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    Pausable
{
    using Counters for Counters.Counter;
    string public _extendedBaseUri;
    mapping(address => uint256) public addressMintedBalance;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 20;
    uint256 public cost = 0.001 ether;
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;

    constructor() ERC721("nft", "knft") {
        _extendedBaseUri = "ipfs://QmNrepKFYKQsXZiFMq71nzHkG9Wb2tQQNLQsjhDZnnXRJW/";
    }

    function _baseURI() internal view override returns (string memory) {
        // "ipfs://QmNrepKFYKQsXZiFMq71nzHkG9Wb2tQQNLQsjhDZnnXRJW/"
        return _extendedBaseUri;
    }

    function setBaseUrl(string memory newBaseUrl) public onlyOwner {
        _extendedBaseUri = newBaseUrl;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function mint(uint256 _mintAmount) public payable whenNotPaused {
        if (onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
        } 

        if(!isWhitelisted(msg.sender) && msg.sender != owner()){
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal  {
        
        require(maxSupply >= totalSupply(), "No supply");

        require(msg.value >= cost, "Not enough ether sent");

        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
}
