// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Nft is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, Pausable {
    using Counters for Counters.Counter;
    string public _extendedBaseUri;
    mapping(address => uint256) public addressMintedBalance;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 20;
    uint256 public cost = 0.001 ether;
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    address[] public whitelistedDiscountAddresses;

    constructor() ERC721("nft", "knft") {
        _extendedBaseUri = "ipfs://ipfsHash/";
    }

    function _baseURI() internal view override returns (string memory) {
        // "ipfs://ipfsHash/"
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
            require(
                isWhitelisted(msg.sender) || isWhitelistedDiscount(msg.sender),
                "user is not whitelisted"
            );
        }

        if (!isWhitelisted(msg.sender)  && !isWhitelistedDiscount(msg.sender) && msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
             safeMint(msg.sender, _mintAmount);
        }

        if (isWhitelistedDiscount(msg.sender)) {
                require(_mintAmount == 2, "you can only mint 2 nfts with discount");
                require(
                    msg.value >= ((cost * _mintAmount) * 80) / 100,
                    "insufficient funds"
                );

    	        deleteFromWhitelistedDiscountAddresses(msg.sender);
                safeMint(msg.sender, _mintAmount);
        }

        if (isWhitelisted(msg.sender)) {
            require(_mintAmount == 1, "you can only mint 1 nfts");
            deleteFromWhitelistedAddresses(msg.sender);
            safeMint(msg.sender, _mintAmount);
        }

         if (msg.sender == owner()) {
            safeMint(msg.sender, _mintAmount);
         }


    }

    function safeMint(address to, uint256 _mintAmount) internal {
        require(maxSupply >= totalSupply(), "No supply");

        require(msg.value >= cost, "Not enough ether sent");

        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenId);
        }
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

    function isWhitelistedDiscount(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedDiscountAddresses.length; i++) {
            if (whitelistedDiscountAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function whitelistDiscountUsers(address[] calldata _users)
        public
        onlyOwner
    {
        delete whitelistedDiscountAddresses;
        whitelistedDiscountAddresses = _users;
    }

    function getIndexWhitelistedAddresses(address item)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (item == whitelistedAddresses[i]) return i;
        }
    }

    function deleteFromWhitelistedAddresses(address _item) internal {
        uint256 index = getIndexWhitelistedAddresses(_item);
        for (uint256 i = index; i < whitelistedAddresses.length - 1; i++) {
            whitelistedAddresses[i] = whitelistedAddresses[i + 1];
        }
        whitelistedAddresses.pop();
    }

    function getIndexWhitelistedDiscountAddresses(address item)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < whitelistedDiscountAddresses.length; i++) {
            if (item == whitelistedDiscountAddresses[i]) return i;
        }
    }

    function deleteFromWhitelistedDiscountAddresses(address _item) internal  {
        uint256 index = getIndexWhitelistedDiscountAddresses(_item);
        for (
            uint256 i = index;
            i < whitelistedDiscountAddresses.length - 1;
            i++
        ) {
            whitelistedDiscountAddresses[i] = whitelistedDiscountAddresses[
                i + 1
            ];
        }
        whitelistedDiscountAddresses.pop();
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
}
