// smart-contracts/governance/DisputeResolution.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IArbitrationCourt.sol";
import "./interfaces/IEvidenceStore.sol";

contract DisputeResolution is Pausable {
    struct Dispute {
        address initiator;
        address respondent;
        bytes32 disputeType;
        uint256 timestamp;
        DisputeState state;
        bytes32 evidenceRoot;
        address[] arbitrators;
        mapping(address => bool) hasVoted;
        mapping(address => Vote) votes;
        Resolution resolution;
    }

    struct Vote {
        bytes32 decision;
        string justification;
        uint256 timestamp;
    }

    struct Resolution {
        bytes32 decision;
        string explanation;
        uint256 timestamp;
        mapping(address => bool) hasExecuted;
    }

    enum DisputeState { Created, Evidence, Deliberation, Resolved, Executed }

    mapping(bytes32 => Dispute) public disputes;
    mapping(address => uint256) public arbitratorReputation;

    IArbitrationCourt public arbitrationCourt;
    IEvidenceStore public evidenceStore;

    event DisputeCreated(bytes32 indexed disputeId, address initiator, address respondent);
    event EvidenceSubmitted(bytes32 indexed disputeId, address submitter, bytes32 evidenceHash);
    event DisputeResolved(bytes32 indexed disputeId, bytes32 decision);

    constructor(address _arbitrationCourt, address _evidenceStore) {
        arbitrationCourt = IArbitrationCourt(_arbitrationCourt);
        evidenceStore = IEvidenceStore(_evidenceStore);
    }

    function createDispute(
        address respondent,
        bytes32 disputeType,
        string calldata initialEvidence
    ) external returns (bytes32) {
        bytes32 disputeId = keccak256(
            abi.encodePacked(
                msg.sender,
                respondent,
                disputeType,
                block.timestamp
            )
        );

        Dispute storage dispute = disputes[disputeId];
        dispute.initiator = msg.sender;
        dispute.respondent = respondent;
        dispute.disputeType = disputeType;
        dispute.timestamp = block.timestamp;
        dispute.state = DisputeState.Created;

        // Select arbitrators
        dispute.arbitrators = arbitrationCourt.selectArbitrators(disputeType);

        // Store initial evidence
        bytes32 evidenceHash = evidenceStore.submitEvidence(
            disputeId,
            msg.sender,
            initialEvidence
        );
        dispute.evidenceRoot = evidenceHash;

        emit DisputeCreated(disputeId, msg.sender, respondent);
        return disputeId;
    }

    function submitEvidence(
        bytes32 disputeId,
        string calldata evidence
    ) external {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.state == DisputeState.Evidence, "Not in evidence phase");
        require(
            msg.sender == dispute.initiator || msg.sender == dispute.respondent,
            "Not authorized"
        );

        bytes32 evidenceHash = evidenceStore.submitEvidence(
            disputeId,
            msg.sender,
            evidence
        );
        dispute.evidenceRoot = evidenceHash;

        emit EvidenceSubmitted(disputeId, msg.sender, evidenceHash);
    }

    function submitArbitrationVote(
        bytes32 disputeId,
        bytes32 decision,
        string calldata justification
    ) external {
        Dispute storage dispute = disputes[disputeId];
        require(
            isArbitrator(msg.sender, dispute.arbitrators),
            "Not an arbitrator"
        );
        require(!dispute.hasVoted[msg.sender], "Already voted");

        dispute.votes[msg.sender] = Vote({
            decision: decision,
            justification: justification,
            timestamp: block.timestamp
        });
        dispute.hasVoted[msg.sender] = true;

        if (allArbitratorsVoted(dispute)) {
            finalizeDispute(disputeId);
        }
    }

    function executeResolution(bytes32 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.state == DisputeState.Resolved, "Not resolved");
        require(!dispute.resolution.hasExecuted[msg.sender], "Already executed");

        // Execute resolution actions
        arbitrationCourt.executeResolution(
            disputeId,
            dispute.resolution.decision
        );

        dispute.resolution.hasExecuted[msg.sender] = true;
        if (allPartiesExecuted(dispute)) {
            dispute.state = DisputeState.Executed;
        }
    }

    // Internal functions...
}