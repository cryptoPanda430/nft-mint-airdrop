// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop is ERC721Enumerable, Ownable { 
    using Strings for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 200;
    uint256 public constant cost = 0.1 ether;
    
    uint256 public maxMintAmount = 1000; //need to fix
    
    uint256 seed = 100;
    uint256 constant INVERSE_BASIS_POINT = 100;
    uint256[] public probabilities = [15, 20, 25, 40];
    uint256[] public counts = [0, 0, 0, 0];

    string baseURI;
    string baseExtension = ".json";
    bool public paused = false;
    NFTType[] public NFTTypes;

    mapping(uint256 => uint256) public TokenTypes;
    // mapping(address => bool) public whitelisted;

    struct NFTType {
        string name; // Name for each NFT
        uint256 maxSupply;
        string baseExtension; // Path for nft attributes/image
        // uint256 cost;
    }

    enum Class {
        legendary,
        epic,
        rare,
        Normal
    }

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

        NFTTypes.push(NFTType("legendary", 30, "tier0.json"));
        NFTTypes.push(NFTType("epic", 40, "tier1.json"));
        NFTTypes.push(NFTType("rare", 50, "tier2.json"));
        NFTTypes.push(NFTType("normal", 80, "tier3.json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(
        address recipient,
        uint256 mintAmount
    ) public payable notPaused {
        uint256 totalSupply = totalSupply();
        require(mintAmount > 0);
        require(mintAmount <= maxMintAmount);
        require(totalSupply + mintAmount <= MAX_SUPPLY, "Exceeding recruit max supply");

        if (msg.sender != owner()) require(msg.value >= cost * mintAmount, "Insufficient BNB");

        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 typeId = getPickId();
            while (counts[typeId] >=  NFTTypes[typeId].maxSupply) {
                typeId = getPickId();
            }
            counts[typeId] ++;
        
            TokenTypes[totalSupply + i] = typeId;
            _safeMint(recipient, totalSupply + i);
        }
    }

    // Airdrop NFTs
    function airdropNfts(address[] calldata wAddresses) public onlyOwner {
        uint256 totalSupply = totalSupply();

        for (uint i = 0; i < wAddresses.length; i++) {
            if(i < 5 ){
                counts[0] ++;
                TokenTypes[totalSupply + i] = 0;
            }else if(i < 15){
                counts[1] ++;
                TokenTypes[totalSupply + i] = 1;
            }else if(i < 35){
                counts[2] ++;
                TokenTypes[totalSupply + i] = 2;
            }else{
                counts[3] ++;
                TokenTypes[totalSupply + i] = 3;
            }
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

    function getPickId() internal returns(uint256){ 
        uint256 value = uint256(_random() % (INVERSE_BASIS_POINT));

        for (uint256 i = probabilities.length - 1; i > 0; i--) {
            uint256 probability = probabilities[i];
            if (value < probability) {
                return  i;
            } else {
                value = value - probability;
            }
        }
        return 0;
    }

    function _random() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, seed)));
        seed = randomNumber;
        return randomNumber;
    }

}


