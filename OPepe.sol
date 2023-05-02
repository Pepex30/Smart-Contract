// SPDX-License-Identifier: MIT

//$$$$$$\             $$\     $$\               $$\             $$\     $$\           $$$$$$$\                                
//$$  __$$\            $$ |    \__|              \__|            $$ |    \__|          $$  __$$\                               
//$$ /  $$ | $$$$$$\ $$$$$$\   $$\ $$$$$$\$$$$\  $$\  $$$$$$$\ $$$$$$\   $$\  $$$$$$$\ $$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$\  
//$$ |  $$ |$$  __$$\\_$$  _|  $$ |$$  _$$  _$$\ $$ |$$  _____|\_$$  _|  $$ |$$  _____|$$$$$$$  |$$  __$$\ $$  __$$\ $$  __$$\ 
//$$ |  $$ |$$ /  $$ | $$ |    $$ |$$ / $$ / $$ |$$ |\$$$$$$\    $$ |    $$ |$$ /      $$  ____/ $$$$$$$$ |$$ /  $$ |$$$$$$$$ |
//$$ |  $$ |$$ |  $$ | $$ |$$\ $$ |$$ | $$ | $$ |$$ | \____$$\   $$ |$$\ $$ |$$ |      $$ |      $$   ____|$$ |  $$ |$$   ____|
// $$$$$$  |$$$$$$$  | \$$$$  |$$ |$$ | $$ | $$ |$$ |$$$$$$$  |  \$$$$  |$$ |\$$$$$$$\ $$ |      \$$$$$$$\ $$$$$$$  |\$$$$$$$\ 
// \______/ $$  ____/   \____/ \__|\__| \__| \__|\__|\_______/    \____/ \__| \_______|\__|       \_______|$$  ____/  \_______|
//          $$ |                                                                                           $$ |                
//          $$ |                                                                                           $$ |                
//          \__|                                                                                           \__|                

// Respect https://www.pepe.vip/ 
// built with love

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract OptimisticPepe is ERC20, ReentrancyGuard {
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;
    uint256 public constant claimAmount = 2700000000 * 10**18;
    address payable public owner;

    uint256 public totalClaimed;
    uint256 public totalDonated;
    uint256 public constant maxSupply = 450000000000000 * 10**18;
    uint256 public constant opAirdrop = 135000000000000 * 10**18; // Airdrop for Optimisim
    uint256 public constant teamShare = 60000000000000 * 10**18; // Team
    uint256 public constant stakeShare = 40000000000000 * 10**18; // Stake Contract
    uint256 public constant nftAirdrop = 25000000000000 * 10**18; // Airdrop for Nft holder
    uint256 public constant pepeShare = 70000000000000 * 10**18; // Respect to Pepe Holder
    uint256 public cexShare = 60000000000000 * 10**18; // Cex Listing, MEXC Binance
    uint256 public constant uniswapShare = 60000000000000 * 10**18; // Uniswap Pairs

    //Status
    bool public teamTokensDistributed;
    bool public cexTokensDistributed;
    bool public nftTokensDistributed;
    bool public pepeTokensDistributed;
    bool public donateStatus;

    //Donate Rate
    uint256 public constant ethToTokenRate = 2700000000 * 750; // Nearly 30 ETH

    constructor(bytes32 _merkleRoot) ERC20("Optimistic Pepe", "OPepe") {
        merkleRoot = _merkleRoot;
        owner = payable(msg.sender);
        _mint(msg.sender, uniswapShare); // for uniswap
        _mint(msg.sender, stakeShare); // for stakeContract
    }

    function claim(bytes32[] calldata merkleProof, address _ref) external nonReentrant {
        require(!claimed[msg.sender], "Already claimed");

        uint256 tokensToMint = claimAmount;
        uint256 tokensToRef = claimAmount / 10;

        require(totalClaimed + tokensToMint + tokensToRef <= opAirdrop, "Max supply reached");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        (bool v,) = MerkleProof.verify(merkleProof, merkleRoot, node);
        require(v, "Invalid Merkle proof");

        claimed[msg.sender] = true;
        totalClaimed += tokensToMint;
        totalClaimed += tokensToRef;
        _mint(msg.sender, tokensToMint);
        _mint(_ref, tokensToRef);
    }

    function support() public payable nonReentrant {
        require(!donateStatus, "Donate is closed");
        require(msg.value > 0, "Amount 0");
        uint256 etherAmount = msg.value / 1 ether; 
        uint256 tokensToBuy = etherAmount * ethToTokenRate;
        require(totalDonated + tokensToBuy <= cexShare, "Max supply reached");

        address payable targetAddress = payable(0x272d005dF51A7d949CDd8fC0205f6305E4616D95);
        targetAddress.transfer(msg.value);


        _mint(msg.sender, tokensToBuy);
        totalDonated += tokensToBuy;
        cexShare -= tokensToBuy;
    }

    function closeDonate() external onlyOwner {
        donateStatus = !donateStatus;
    }



    //Another Shares
    function distributeTeamTokens(address teamAddress) external onlyOwner {
        require(!teamTokensDistributed, "Team tokens already distributed");
        require(teamAddress != address(0), "Invalid team address");

        teamTokensDistributed = true;
        _mint(teamAddress, teamShare);
    }

    function distributeCexTokens(address cexAddress) external onlyOwner {
        require(!cexTokensDistributed, "CEX tokens already distributed");
        require(cexAddress != address(0), "Invalid CEX address");

        cexTokensDistributed = true;
        _mint(cexAddress, cexShare);
    }
    function distributePepeTokens(address pepeAddress) external onlyOwner {
        require(!pepeTokensDistributed, "Pepe tokens already distributed");
        require(pepeAddress != address(0), "Invalid Pepe address");

        pepeTokensDistributed = true;
        _mint(pepeAddress, pepeShare);
    }
    function distributeNftTokens(address nftAddress) external onlyOwner {
        require(!nftTokensDistributed, "Nfts tokens already distributed");
        require(nftAddress != address(0), "Invalid Nfts address");

        nftTokensDistributed = true;
        _mint(nftAddress, nftAirdrop);
    }

    //modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
}
