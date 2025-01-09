// smart-contracts/tokenization/TokenFactory.sol
pragma solidity ^0.8.0;

import "./interfaces/ITokenModule.sol";
import "./tokens/DAOToken.sol";
import "./tokens/VestingToken.sol";
import "./tokens/MultiTierToken.sol";
import "./tokens/BoundToken.sol";

contract TokenFactory {
    mapping(string => address) public tokenImplementations;
    
    event TokenCreated(address tokenAddress, string tokenType);
    
    constructor() {
        // Register default token implementations
        tokenImplementations["standard"] = address(new DAOToken());
        tokenImplementations["vesting"] = address(new VestingToken());
        tokenImplementations["multiTier"] = address(new MultiTierToken());
        tokenImplementations["bound"] = address(new BoundToken());
    }
    
    function createToken(
        string memory tokenType,
        bytes memory constructorData
    ) external returns (address) {
        require(tokenImplementations[tokenType] != address(0), "Invalid token type");
        
        address implementation = tokenImplementations[tokenType];
        address newToken;
        
        assembly {
            newToken := create2(0, add(constructorData, 0x20), mload(constructorData), 0)
        }
        
        emit TokenCreated(newToken, tokenType);
        return newToken;
    }
    
    function registerTokenImplementation(string memory tokenType, address implementation) external {
        require(implementation != address(0), "Invalid implementation");
        tokenImplementations[tokenType] = implementation;
    }
}