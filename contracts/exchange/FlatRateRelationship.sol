// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interface/Relationship.sol";
import "../libraries/RelationshipLibrary.sol";
import "./interface/IDaiToken.sol";
import "hardhat/console.sol";

contract FlatRateRelationship is Relationship {
    error InvalidStatus();

    bytes32 public immutable domain_separator;

    constructor(
        uint256 _relationshipID,
        address _daiTokenAddress,
        address _relationshipEscrow,
        string memory _taskMetadataPointer
    ) {
        require(
            _daiTokenAddress != address(0),
            "Dai token address cannot be 0 when creating escrow."
        );

        relationshipID = _relationshipID;
        daiToken = DaiToken(_daiTokenAddress);
        relationshipEscrow = _relationshipEscrow;
        market = msg.sender;
        owner = tx.origin;


        uint8 chain_id;
        assembly {
            chain_id := chainid()
        }

        domain_separator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("FlatRateRelationship")),
                keccak256(bytes("1")),
                chain_id,
                address(this)
            )
        );

        contractType = ContractType.FlatRate;
        contractOwnership = ContractOwnership.UNCLAIMED;
        contractState = ContractState.Uninitialized;
        contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        taskMetadataPointer = _taskMetadataPointer;

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    function initialize(
        uint256 _nonce,
        uint256 _expiry,
        uint8 _vAllow,
        bytes32 _rAllow,
        bytes32 _sAllow,
        uint8 _vDeny,
        bytes32 _rDeny,
        bytes32 _sDeny,
        string memory _extraData
    ) internal override {
        RelationshipEscrow escrow = RelationshipEscrow(relationshipEscrow);
        escrow.initialize(
            owner,
            worker,
            _extraData,
            wad,
            _nonce,
            _expiry,
            _vAllow,
            _rAllow,
            _sAllow,
            _vDeny,
            _rDeny,
            _sDeny
        );

        contractState = ContractState.Initialized;
    }

    function assignNewWorker(
        address _newWorker,
        uint256 _wad,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _vAllow,
        bytes32 _rAllow,
        bytes32 _sAllow,
        uint8 _vDeny,
        bytes32 _rDeny,
        bytes32 _sDeny,
        string memory _extraData
    ) external override {
        require(
            _newWorker != address(0),
            "Worker address must not be 0 when assigning new worker."
        );
        require(_newWorker != owner, "You cannot work your own contract."); //COMMENTED FOR DEBUGGING
        require(_wad != 0, "The payout amount for this contract cannot be 0.");
        require(
            daiToken.balanceOf(owner) >= _wad,
            "You do not have enough DAI to pay the specified amount."
        );

        wad = _wad;
        worker = _newWorker;

        initialize(
            _nonce,
            _expiry,
            _vAllow,
            _rAllow,
            _sAllow,
            _vDeny,
            _rDeny,
            _sDeny,
            _extraData
        );

        contractOwnership = ContractOwnership.PENDING;
        contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingWorkerApproval;
        acceptanceTimestamp = block.timestamp;

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    function releaseJob()
        external
        override
        onlyWorker
        onlyWhenOwnership(ContractOwnership.CLAIMED)
    {
        worker = address(0);
        acceptanceTimestamp = 0;

        contractState = ContractState.Uninitialized;
        contractOwnership = ContractOwnership.UNCLAIMED;
        contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        emit ContractStatusUpdated(address(this), uint8(contractStatus));

        RelationshipEscrow escrow = RelationshipEscrow(relationshipEscrow);
        escrow.surrenderFunds();
    }

    function resolve()
        external
        override
        onlyOwner
        onlyWhenStatus(RelationshipLibrary.ContractStatus.AwaitingReview)
    {
        require(owner != address(0));
        require(worker != address(0));

        RelationshipEscrow escrow = RelationshipEscrow(relationshipEscrow);
        escrow.releaseFunds(wad);

        contractStatus = RelationshipLibrary.ContractStatus.Approved;
        contractState = ContractState.Locked;

        emit ContractCompleted(owner, worker, address(this));
        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    function updateTaskMetadataPointer(string memory _newTaskPointerHash)
        external
        override
        onlyOwner
        onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        taskMetadataPointer = _newTaskPointerHash;
    }

    function notifyContract(uint256 _data) external override onlyFromRelationshipEscrow {
        if (_data == 0) {
            contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        } else if (_data == 1) {
            contractStatus = RelationshipLibrary
                .ContractStatus
                .AwaitingWorkerApproval;
        } else if (_data == 2) {
            contractStatus = RelationshipLibrary.ContractStatus.AwaitingReview;
        } else if (_data == 3) {
            contractStatus = RelationshipLibrary.ContractStatus.Approved;
        } else if (_data == 4) {
            contractStatus = RelationshipLibrary.ContractStatus.Reclaimed;
        } else if (_data == 5) {
            contractStatus = RelationshipLibrary.ContractStatus.Disputed;
        } else revert InvalidStatus();
    }

function work(bool _accepted)
    override
    external
    onlyWorker
    onlyWhenState(ContractState.Initialized)
    onlyWhenStatus(RelationshipLibrary.ContractStatus.AwaitingWorkerApproval)
    onlyWhenOwnership(ContractOwnership.PENDING)
{
    require(
        msg.sender == worker,
        "Only the address designated to be the worker may call this function."
    );

    if (_accepted == true) {
        //set contract to claimed
        contractOwnership = ContractOwnership.CLAIMED;
        contractStatus = RelationshipLibrary.ContractStatus.AwaitingReview;

        emit EnteredContract(owner, worker, address(this));
    } else {
        contractOwnership = ContractOwnership.UNCLAIMED;
        contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;

        worker = address(0);

        RelationshipEscrow escrow = RelationshipEscrow(relationshipEscrow);
        escrow.surrenderFunds();
    }

    emit ContractStatusUpdated(address(this), uint8(contractStatus));
}

}