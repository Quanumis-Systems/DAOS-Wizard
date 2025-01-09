// smart-contracts/collaboration/DAOCollaboration.sol
pragma solidity ^0.8.0;

contract DAOCollaboration {
    struct Collaboration {
        address[] participants;
        bytes32 purpose;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) hasVoted;
        mapping(bytes32 => uint256) resourceCommitments;
        CollaborationState state;
    }
    
    enum CollaborationState { Proposed, Active, Completed, Terminated }
    
    mapping(bytes32 => Collaboration) public collaborations;
    
    event CollaborationProposed(bytes32 indexed id, address[] participants);
    event CollaborationStarted(bytes32 indexed id);
    event ResourceCommitted(bytes32 indexed id, address dao, uint256 amount);
    
    function proposeCollaboration(
        address[] calldata participants,
        bytes32 purpose,
        uint256 duration
    ) external returns (bytes32) {
        bytes32 collaborationId = keccak256(
            abi.encodePacked(
                participants,
                purpose,
                block.timestamp
            )
        );
        
        Collaboration storage collab = collaborations[collaborationId];
        collab.participants = participants;
        collab.purpose = purpose;
        collab.startTime = block.timestamp;
        collab.endTime = block.timestamp + duration;
        collab.state = CollaborationState.Proposed;
        
        emit CollaborationProposed(collaborationId, participants);
        
        return collaborationId;
    }
    
    function commitResources(
        bytes32 collaborationId,
        bytes32 resourceType,
        uint256 amount
    ) external {
        Collaboration storage collab = collaborations[collaborationId];
        require(collab.state == CollaborationState.Active, "Collaboration not active");
        
        collab.resourceCommitments[resourceType] += amount;
        
        emit ResourceCommitted(collaborationId, msg.sender, amount);
    }
}