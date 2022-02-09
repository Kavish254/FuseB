// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FuriousApeSociety is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, Pausable {
    using Counters for Counters.Counter;
    string public _extendedBaseUri;
    mapping(address => uint256) public addressMintedBalance;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 20; 
    uint256 public cost = 0.001 ether;

    constructor() ERC721("nft", "knft") {
            _extendedBaseUri = "ipfs://QmNrepKFYKQsXZiFMq71nzHkG9Wb2tQQNLQsjhDZnnXRJW/";
    }
   
      
    function _baseURI() internal view override returns (string memory){
        // "ipfs://QmNrepKFYKQsXZiFMq71nzHkG9Wb2tQQNLQsjhDZnnXRJW/"
        return _extendedBaseUri;
    }
    
    function setBaseUrl(string memory newBaseUrl) public onlyOwner {
         _extendedBaseUri = newBaseUrl;
    }
    
    
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    return string(abi.encodePacked(
        _baseURI(),
        Strings.toString(_tokenId),
        ".json"
        ));
    
    }

        function mint(uint256 _mintAmount) public whenNotPaused payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function safeMint(address to) public payable {

        require(maxSupply >= totalSupply(), "No supply");

        require(msg.value >= cost, "Not enough ether sent");

        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
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

    function withdraw() public onlyOwner{
        require(address(this).balance > 0, "Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
   
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
       
}