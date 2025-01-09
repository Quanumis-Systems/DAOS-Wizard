// smart-contracts/federation/DAOFederation.sol
pragma solidity ^0.8.0;

import "../bridge/CrossChainBridge.sol";
import "../governance/FederatedGovernance.sol";

contract DAOFederation {
    struct FederatedDAO {
        bytes32 federationId;
        address[] memberDAOs;
        mapping(address => uint256) votingPower;
        mapping(bytes32 => FederatedProposal) proposals;
        FederationConfig config;
    }

    struct FederatedProposal {
        bytes32 proposalId;
        address proposingDAO;
        bytes32[] targetChains;
        bytes[] actions;
        uint256 timestamp;
        mapping(address => bool) hasVoted;
        uint256 approvalCount;
        ProposalStatus status;
    }

    struct FederationConfig {
        uint256 minimumMemberCount;
        uint256 votingThreshold;
        uint256 executionDelay;
        bytes32 federationType;
    }

    enum ProposalStatus { 
        Active,
        Approved,
        Executed,
        Rejected
    }

    mapping(bytes32 => FederatedDAO) public federations;
    mapping(address => bytes32[]) public daoFederations;

    CrossChainBridge public bridge;
    FederatedGovernance public governance;

    event FederationCreated(
        bytes32 indexed federationId,
        address[] memberDAOs
    );
    event FederatedProposalCreated(
        bytes32 indexed federationId,
        bytes32 indexed proposalId
    );

    constructor(
        address _bridge,
        address _governance
    ) {
        bridge = CrossChainBridge(_bridge);
        governance = FederatedGovernance(_governance);
    }

    function createFederation(
        address[] calldata memberDAOs,
        FederationConfig calldata config
    ) external returns (bytes32) {
        require(
            memberDAOs.length >= config.minimumMemberCount,
            "Insufficient members"
        );

        bytes32 federationId = keccak256(
            abi.encodePacked(
                memberDAOs,
                block.timestamp
            )
        );

        FederatedDAO storage federation = federations[federationId];
        federation.federationId = federationId;
        federation.memberDAOs = memberDAOs;
        federation.config = config;

        // Register DAOs in federation
        for (uint i = 0; i < memberDAOs.length; i++) {
            daoFederations[memberDAOs[i]].push(federationId);
        }

        emit FederationCreated(federationId, memberDAOs);
        return federationId;
    }

    function createFederatedProposal(
        bytes32 federationId,
        bytes32[] calldata targetChains,
        bytes[] calldata actions
    ) external returns (bytes32) {
        FederatedDAO storage federation = federations[federationId];
        require(
            isMemberDAO(msg.sender, federation),
            "Not a federation member"
        );

        bytes32 proposalId = keccak256(
            abi.encodePacked(
                federationId,
                msg.sender,
                block.timestamp
            )
        );

        FederatedProposal storage proposal = federation.proposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.proposingDAO = msg.sender;
        proposal.targetChains = targetChains;
        proposal.actions = actions;
        proposal.timestamp = block.timestamp;
        proposal.status = ProposalStatus.Active;

        emit FederatedProposalCreated(federationId, proposalId);
        return proposalId;
    }
}