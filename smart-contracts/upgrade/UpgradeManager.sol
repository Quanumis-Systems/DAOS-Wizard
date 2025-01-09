// smart-contracts/upgrade/UpgradeManager.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract UpgradeManager is AccessControl {
    struct Upgrade {
        address newImplementation;
        uint256 proposedTime;
        uint256 scheduledTime;
        bytes32 upgradeType;
        bool executed;
        mapping(address => bool) hasApproved;
        uint256 approvalCount;
    }

    mapping(bytes32 => Upgrade) public upgrades;
    mapping(address => uint256) public contractVersions;
    
    uint256 public constant UPGRADE_DELAY = 2 days;
    uint256 public constant MIN_APPROVALS = 3;

    bytes32 public constant UPGRADE_ADMIN_ROLE = keccak256("UPGRADE_ADMIN_ROLE");
    bytes32 public constant UPGRADE_PROPOSER_ROLE = keccak256("UPGRADE_PROPOSER_ROLE");

    event UpgradeProposed(bytes32 indexed upgradeId, address newImplementation);
    event UpgradeApproved(bytes32 indexed upgradeId, address approver);
    event UpgradeExecuted(bytes32 indexed upgradeId, address newImplementation);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADE_ADMIN_ROLE, msg.sender);
    }

    function proposeUpgrade(
        address proxyAddress,
        address newImplementation,
        bytes32 upgradeType
    ) external returns (bytes32) {
        require(
            hasRole(UPGRADE_PROPOSER_ROLE, msg.sender),
            "Not authorized to propose upgrades"
        );

        bytes32 upgradeId = keccak256(
            abi.encodePacked(
                proxyAddress,
                newImplementation,
                block.timestamp
            )
        );

        Upgrade storage upgrade = upgrades[upgradeId];
        upgrade.newImplementation = newImplementation;
        upgrade.proposedTime = block.timestamp;
        upgrade.scheduledTime = block.timestamp + UPGRADE_DELAY;
        upgrade.upgradeType = upgradeType;

        emit UpgradeProposed(upgradeId, newImplementation);
        return upgradeId;
    }

    function approveUpgrade(bytes32 upgradeId) external {
        require(
            hasRole(UPGRADE_ADMIN_ROLE, msg.sender),
            "Not authorized to approve upgrades"
        );

        Upgrade storage upgrade = upgrades[upgradeId];
        require(!upgrade.executed, "Upgrade already executed");
        require(!upgrade.hasApproved[msg.sender], "Already approved");

        upgrade.hasApproved[msg.sender] = true;
        upgrade.approvalCount += 1;

        emit UpgradeApproved(upgradeId, msg.sender);
    }

    function executeUpgrade(
        bytes32 upgradeId,
        address proxyAddress
    ) external {
        require(
            hasRole(UPGRADE_ADMIN_ROLE, msg.sender),
            "Not authorized to execute upgrades"
        );

        Upgrade storage upgrade = upgrades[upgradeId];
        require(!upgrade.executed, "Upgrade already executed");
        require(
            upgrade.approvalCount >= MIN_APPROVALS,
            "Insufficient approvals"
        );
        require(
            block.timestamp >= upgrade.scheduledTime,
            "Upgrade delay not elapsed"
        );

        // Execute upgrade
        TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(
            payable(proxyAddress)
        );
        proxy.upgradeTo(upgrade.newImplementation);

        // Update version
        contractVersions[proxyAddress] += 1;
        upgrade.executed = true;

        emit UpgradeExecuted(upgradeId, upgrade.newImplementation);
    }
}