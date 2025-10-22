// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PredictionMarket
 * @dev Prediction market contract for LoopLens on Base Sepolia
 * Users can bet with or against AI predictions
 */
contract PredictionMarket is Ownable, ReentrancyGuard {
    
    // Structs
    struct Market {
        string title;
        uint256 createdAt;
        uint256 endsAt;
        uint8 aiConfidence; // 0-100
        bool resolved;
        bool aiWon;
        uint256 totalWithAI;
        uint256 totalAgainstAI;
        mapping(address => uint256) betsWithAI;
        mapping(address => uint256) betsAgainstAI;
    }
    
    // State variables
    mapping(uint256 => Market) public markets;
    uint256 public marketCount;
    IERC20 public bettingToken; // USDC or other ERC20
    uint256 public platformFee = 200; // 2% (basis points)
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    // Events
    event MarketCreated(
        uint256 indexed marketId,
        string title,
        uint256 endsAt,
        uint8 aiConfidence
    );
    
    event BetPlaced(
        uint256 indexed marketId,
        address indexed bettor,
        bool withAI,
        uint256 amount
    );
    
    event MarketResolved(
        uint256 indexed marketId,
        bool aiWon,
        uint256 totalWithAI,
        uint256 totalAgainstAI
    );
    
    event Claimed(
        uint256 indexed marketId,
        address indexed bettor,
        uint256 amount
    );
    
    // Constructor
    constructor(address _bettingToken) Ownable(msg.sender) {
        bettingToken = IERC20(_bettingToken);
    }
    
    /**
     * @dev Create a new prediction market
     * @param _title Market question/title
     * @param _duration Duration in seconds
     * @param _aiConfidence AI confidence level (0-100)
     */
    function createMarket(
        string memory _title,
        uint256 _duration,
        uint8 _aiConfidence
    ) external onlyOwner returns (uint256) {
        require(_aiConfidence <= 100, "Invalid confidence");
        require(_duration > 0, "Invalid duration");
        
        uint256 marketId = marketCount++;
        Market storage market = markets[marketId];
        
        market.title = _title;
        market.createdAt = block.timestamp;
        market.endsAt = block.timestamp + _duration;
        market.aiConfidence = _aiConfidence;
        market.resolved = false;
        
        emit MarketCreated(marketId, _title, market.endsAt, _aiConfidence);
        
        return marketId;
    }
    
    /**
     * @dev Place a bet on a market
     * @param _marketId Market ID
     * @param _withAI True if betting with AI, false if betting against
     * @param _amount Amount to bet (in token units)
     */
    function placeBet(
        uint256 _marketId,
        bool _withAI,
        uint256 _amount
    ) external nonReentrant {
        Market storage market = markets[_marketId];
        
        require(_marketId < marketCount, "Market does not exist");
        require(block.timestamp < market.endsAt, "Market expired");
        require(!market.resolved, "Market already resolved");
        require(_amount > 0, "Amount must be positive");
        
        // Transfer tokens from bettor
        require(
            bettingToken.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        
        if (_withAI) {
            market.betsWithAI[msg.sender] += _amount;
            market.totalWithAI += _amount;
        } else {
            market.betsAgainstAI[msg.sender] += _amount;
            market.totalAgainstAI += _amount;
        }
        
        emit BetPlaced(_marketId, msg.sender, _withAI, _amount);
    }
    
    /**
     * @dev Resolve a market (called by owner/oracle)
     * @param _marketId Market ID
     * @param _aiWon True if AI prediction was correct
     */
    function resolveMarket(
        uint256 _marketId,
        bool _aiWon
    ) external onlyOwner {
        Market storage market = markets[_marketId];
        
        require(_marketId < marketCount, "Market does not exist");
        require(block.timestamp >= market.endsAt, "Market not expired");
        require(!market.resolved, "Already resolved");
        
        market.resolved = true;
        market.aiWon = _aiWon;
        
        emit MarketResolved(
            _marketId,
            _aiWon,
            market.totalWithAI,
            market.totalAgainstAI
        );
    }
    
    /**
     * @dev Claim winnings from a resolved market
     * @param _marketId Market ID
     */
    function claim(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        
        require(_marketId < marketCount, "Market does not exist");
        require(market.resolved, "Market not resolved");
        
        uint256 userBet;
        uint256 winningPool;
        uint256 losingPool;
        
        if (market.aiWon) {
            userBet = market.betsWithAI[msg.sender];
            winningPool = market.totalWithAI;
            losingPool = market.totalAgainstAI;
            market.betsWithAI[msg.sender] = 0;
        } else {
            userBet = market.betsAgainstAI[msg.sender];
            winningPool = market.totalAgainstAI;
            losingPool = market.totalWithAI;
            market.betsAgainstAI[msg.sender] = 0;
        }
        
        require(userBet > 0, "No bet to claim");
        
        // Calculate payout
        uint256 winnings;
        if (winningPool > 0) {
            // Deduct platform fee from losing pool
            uint256 fee = (losingPool * platformFee) / FEE_DENOMINATOR;
            uint256 netLosingPool = losingPool - fee;
            
            // Proportional share of winnings
            winnings = userBet + ((userBet * netLosingPool) / winningPool);
        } else {
            // No winners, return bet
            winnings = userBet;
        }
        
        require(bettingToken.transfer(msg.sender, winnings), "Transfer failed");
        
        emit Claimed(_marketId, msg.sender, winnings);
    }
    
    /**
     * @dev Get market details
     */
    function getMarket(uint256 _marketId) external view returns (
        string memory title,
        uint256 createdAt,
        uint256 endsAt,
        uint8 aiConfidence,
        bool resolved,
        bool aiWon,
        uint256 totalWithAI,
        uint256 totalAgainstAI
    ) {
        Market storage market = markets[_marketId];
        return (
            market.title,
            market.createdAt,
            market.endsAt,
            market.aiConfidence,
            market.resolved,
            market.aiWon,
            market.totalWithAI,
            market.totalAgainstAI
        );
    }
    
    /**
     * @dev Get user's bets on a market
     */
    function getUserBets(uint256 _marketId, address _user) external view returns (
        uint256 withAI,
        uint256 againstAI
    ) {
        Market storage market = markets[_marketId];
        return (
            market.betsWithAI[_user],
            market.betsAgainstAI[_user]
        );
    }
    
    /**
     * @dev Update platform fee (only owner)
     */
    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee too high"); // Max 10%
        platformFee = _newFee;
    }
    
    /**
     * @dev Withdraw accumulated fees (only owner)
     */
    function withdrawFees(address _to) external onlyOwner {
        uint256 balance = bettingToken.balanceOf(address(this));
        require(bettingToken.transfer(_to, balance), "Transfer failed");
    }
}