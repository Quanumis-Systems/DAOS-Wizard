// smart-contracts/governance/GovernanceFactory.sol
pragma solidity ^0.8.0;

import "./modules/QuadraticVoting.sol";
import "./modules/HolographicConsensus.sol";
import "./modules/LiquidDemocracy.sol";
import "./modules/ConvictionVoting.sol";

contract GovernanceFactory {
    struct GovernanceConfig {
        string governanceType;
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThreshold;
        uint256 quorumPercentage;
        address tokenAddress;
        bool enableDelegation;
        bool enableEmergencyPause;
    }
    
    mapping(address => GovernanceConfig) public daoConfigs;
    mapping(string => address) public governanceImplementations;
    
    event GovernanceCreated(address indexed daoAddress, string governanceType);
    
    constructor() {
        // Register governance implementations
        governanceImplementations["quadratic"] = address(new QuadraticVoting());
        governanceImplementations["holographic"] = address(new HolographicConsensus());
        governanceImplementations["liquid"] = address(new LiquidDemocracy());
        governanceImplementations["conviction"] = address(new ConvictionVoting());
    }
    
    function createGovernance(
        GovernanceConfig memory config,
        bytes memory initData
    ) external returns (address) {
        address implementation = governanceImplementations[config.governanceType];
        require(implementation != address(0), "Invalid governance type");
        
        // Clone the implementation
        address newGovernance = _cloneGovernance(implementation);
        
        // Initialize the governance contract
        (bool success, ) = newGovernance.call(initData);
        require(success, "Governance initialization failed");
        
        daoConfigs[newGovernance] = config;
        emit GovernanceCreated(newGovernance, config.governanceType);
        
        return newGovernance;
    }
    
    function _cloneGovernance(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "Create failed");
    }
}