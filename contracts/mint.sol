// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFT is ERC721URIStorage, Ownable { 
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

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
    bool public locked = true;

    NFTType[] public NFTTypes;

    mapping(uint256 => uint256) public TokenTypes;
    mapping(address => bool) public blacklisted;

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

        NFTTypes.push(NFTType("legendary", 10, "tier0.json")); //10 20 40 30
        NFTTypes.push(NFTType("epic", 20, "tier1.json"));
        NFTTypes.push(NFTType("rare", 30, "tier2.json"));
        NFTTypes.push(NFTType("normal", 40, "tier3.json"));
    }

    function setBlacklist(address[] calldata bAddresses) public onlyOwner {
        for (uint i = 0; i < bAddresses.length; i++) {
            blacklisted[bAddresses[i]] = true;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(
        address recipient,
        uint256 mintAmount
    ) public payable notPaused {
        uint256 currentId = _tokenIdCounter.current();
        require(mintAmount > 0);
        require(mintAmount <= maxMintAmount);
        require(currentId + mintAmount <= MAX_SUPPLY, "Exceeding recruit max supply");

        if (msg.sender != owner()) require(msg.value >= cost * mintAmount, "Insufficient BNB");

        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 typeId = getPickId();
            while (counts[typeId] >=  NFTTypes[typeId].maxSupply) {
                typeId = getPickId();
            }
            counts[typeId] ++;

            TokenTypes[currentId + i] = typeId;

            _safeMint(recipient, currentId + i);
            _tokenIdCounter.increment();
            
            _setTokenURI(currentId + i, string(abi.encodePacked(typeId.toString(), '', string(abi.encodePacked('/', counts[typeId].toString(), baseExtension)))));
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal view override {
        if(blacklisted[from]){
            require(!locked, "Cannot transfer - you are blacklisted!");
        }
        
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


