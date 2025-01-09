// smart-contracts/reputation/ReputationSystem.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IReputationOracle.sol";

contract ReputationSystem is ERC721 {
    struct ReputationScore {
        uint256 score;
        uint256 lastUpdated;
        mapping(bytes32 => uint256) categoryScores;
        uint256[] contributionHistory;
    }
    
    mapping(address => ReputationScore) public reputationScores;
    mapping(bytes32 => uint256) public categoryWeights;
    
    IReputationOracle public reputationOracle;
    
    event ReputationUpdated(address indexed member, uint256 newScore);
    event ContributionRecorded(address indexed member, bytes32 category, uint256 value);
    
    constructor() ERC721("DAO Reputation", "DAOREP") {
        // Initialize reputation system
    }
    
    function recordContribution(
        address member,
        bytes32 category,
        uint256 value,
        bytes calldata proof
    ) external {
        require(_validateContribution(member, category, value, proof), "Invalid contribution");
        
        // Update reputation score
        _updateReputationScore(member, category, value);
        
        // Mint reputation NFT if qualified
        if (_qualifiesForNFT(member)) {
            _mintReputationNFT(member);
        }
        
        emit ContributionRecorded(member, category, value);
    }
    
    function calculateReputationScore(address member) public view returns (uint256) {
        ReputationScore storage rep = reputationScores[member];
        
        uint256 totalScore = 0;
        uint256 totalWeight = 0;
        
        for (bytes32 category : getCategories()) {
            totalScore += rep.categoryScores[category] * categoryWeights[category];
            totalWeight += categoryWeights[category];
        }
        
        return totalScore / totalWeight;
    }
}