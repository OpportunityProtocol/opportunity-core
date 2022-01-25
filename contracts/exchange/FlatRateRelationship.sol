// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../user/UserSummary.sol";
import "../libraries/User.sol";
import "../libraries/Evaluation.sol";
import "../libraries/RelationshipLibrary.sol";
import "./interface/IDaiToken.sol";
import "../user/UserRegistration.sol";
import "hardhat/console.sol";

contract FlatRateRelationship is Relationship {
    constructor(
        address _registrar,
        Evaluation.ContractType _contractType,
        string memory _taskMetadataPointer,
        address _daiTokenAddress
    ) {
        require(
            _daiTokenAddress != address(0),
            "Dai token address cannot be 0 when creating escrow."
        );
        require(
            _registrar != address(0),
            "The address of the registrar for this contract cannot be set to 0."
        );
        daiToken = DaiToken(_daiTokenAddress);
        registrar = UserRegistration(_registrar);
        market = msg.sender;
        owner = tx.origin;

        contractOwnership = ContractOwnership.UNCLAIMED;
        contractState = ContractState.Uninitialized;
        contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        taskMetadataPointer = _taskMetadataPointer;

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    /**
     * initialize
     * Initializes the contract by pulling the dai from the employers account
     * @param nonce //
     * @param expiry //
     * @param v //
     * @param r //
     * @param s  //
     * @param vDeny //
     * @param rDeny //
     * @param sDeny  //
     */
    function initialize(
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 vDeny,
        bytes32 rDeny,
        bytes32 sDeny
    ) internal override {
        // Unlock buyer's Dai balance to transfer `wad` to this contract.
        daiToken.permit(owner, address(this), nonce, expiry, true, v, r, s);

        // Transfer Dai from `buyer` to this contract.
        daiToken.pull(owner, wad);

        // Relock Dai balance of `buyer`.
        daiToken.permit(
            owner,
            address(this),
            nonce + 1,
            expiry,
            false,
            vDeny,
            rDeny,
            sDeny
        );
        contractState = ContractState.Initialized;
    }

    /**
     * refundReward
     * Transfers the payout back to the employer
     */
    function refundReward() override internal {
        require(
            wad != uint256(0),
            "There is no DAI to transfer back to the owner"
        );
        bool success = daiToken.transfer(owner, wad);
        assert(success == true);
    }

    /**
     * refundUnclaimedContract
     * Returns the payout to the employer as long as no one has claimed the contract
     * and been made the worker
     */
    function refundUnclaimedContract()
        external
        override
        onlyOwner
        onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        refundReward();
    }

    /**
     * releaseJob
     * Returns the payout to the employer and releases the job.  Worker must have officially been
     * made the worker by calling work() to call this function.
     *
     */
    function releaseJob()
    override
        external
        onlyWorker
        onlyWhenOwnership(ContractOwnership.CLAIMED)
    {
        worker = address(0);
        //taskSolutionPointer = "";
        acceptanceTimestamp = 0;
        //numSubmissions = 0;

        contractState = ContractState.Uninitialized;
        contractOwnership = ContractOwnership.UNCLAIMED;
        contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        emit ContractStatusUpdated(address(this), uint8(contractStatus));
        refundReward();
    }

    /**
     * claimStalledContract
     * Allows the employer to reclaim the payout if 60 days
     * have passed and no submissions have been made.
     */
    function claimStalledContract()
    override
        external
        onlyOwner
        onlyWhenOwnership(ContractOwnership.CLAIMED)
    {
        //require(numSubmissions >= 1);
        require(acceptanceTimestamp >= (block.timestamp + 60 days));
        refundReward();
    }

    /**
     * resolve()
     * Resolves the contract and transfers the payout to the worker.
     */
    function resolve()
    override
        external
        onlyOwner
        onlyWhenStatus(RelationshipLibrary.ContractStatus.AwaitingReview)
    {
        require(worker != address(0));
        require(owner != address(0));

        bool success = daiToken.transfer(worker, wad);
        assert(success == true);

        contractStatus = RelationshipLibrary.ContractStatus.Approved;
        contractState = ContractState.Locked;

        emit ContractCompleted(owner, worker, address(this));
        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    /**
     * Allows the employer to update the task metadata as long as this contract is in the
     * unclaimed state
     */
    function updateTaskMetadataPointer(string memory newTaskPointerHash)
    override
        external
        onlyOwner
        onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        taskMetadataPointer = newTaskPointerHash;
    }
}
