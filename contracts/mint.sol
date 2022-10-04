// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Prk is ERC721Enumerable, Ownable { 
    using Strings for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 200;
    uint256 public constant PRICE_PER_PRK = 1e17;

    string baseURI;
    string baseExtension = ".json";
    bool public paused = false;

    mapping(uint256 => uint256) private _lastRewardClaimed; 

    modifier notPaused {
        require(paused == false);
        _;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        // mint(0xcf9b1f007f246c1D86735941Aeb4eddBc8C0016F, 104);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(
        address recipient, 
        uint256 amount
    ) public payable notPaused {
        uint256 totalSupply = totalSupply();
        require(amount > 0, "Mint amount is invalid");
        require(totalSupply + amount <= MAX_SUPPLY, "Exceeding recruit max supply");

        if (msg.sender != owner()) require(msg.value >= amount * PRICE_PER_PRK, "Insufficient BNB");
        
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(recipient, totalSupply + i);
        }
    }

    // Airdrop NFTs
    function airdropNfts(address[] calldata wAddresses) public onlyOwner {
        uint256 totalSupply = totalSupply();
        
        for (uint i = 0; i < wAddresses.length; i++) {
            _safeMint(wAddresses[i], totalSupply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

}


