pragma solidity 0.8.7;

import "./IDaiToken.sol";
import "../../user/UserSummary.sol";
import "../../libraries/User.sol";
import "../../libraries/Evaluation.sol";
import "../../libraries/RelationshipLibrary.sol";
import "../../user/UserRegistration.sol";
import "hardhat/console.sol";

abstract contract Relationship {
    event EnteredContract(
        address indexed owner,
        address indexed worker,
        address indexed relationship
    );
    event ContractCompleted(
        address indexed owner,
        address indexed worker,
        address indexed relationship
    );
    event ContractStatusUpdated(
        address indexed relationship,
        uint8 indexed status
    );

    address public worker;
    address public owner;
    address public market;
    uint256 public wad;
    string public taskMetadataPointer;
    uint256 acceptanceTimestamp;

    DaiToken public daiToken;

    RelationshipLibrary.ContractStatus public contractStatus;
    ContractState public contractState;
    ContractOwnership public contractOwnership;
    Evaluation.ContractType public contractType;

    UserRegistration registrar;

    enum ContractState {
        Uninitialized,
        Initialized,
        Locked
    }

    enum ContractOwnership {
        UNCLAIMED,
        PENDING,
        CLAIMED
    }

    modifier onlyContractParticipants() virtual {
        require(
            msg.sender == worker || msg.sender == owner,
            "Only the contract participants may call this function."
        );
        _;
    }

    modifier onlyWorker() virtual {
        require(
            msg.sender == worker,
            "Only the worker of this contract may call this function."
        );
        _;
    }

    modifier onlyOwner() virtual {
        require(
            msg.sender == owner,
            "Only the owner of this contract may call this function."
        );
        _;
    }

    modifier onlyWhenStatus(RelationshipLibrary.ContractStatus _statusOptionOne)
        virtual {
        require(
            contractStatus == _statusOptionOne,
            "This action cannot be carried out under the current contract status."
        );
        _;
    }

    modifier onlyWhenEitherStatus(
        RelationshipLibrary.ContractStatus _statusOptionOne,
        RelationshipLibrary.ContractStatus _statusOptionTwo
    ) virtual {
        require(
            contractStatus == _statusOptionOne ||
                contractStatus == _statusOptionTwo,
            "This action cannot be carried out under the current contract status."
        );
        _;
    }

    modifier onlyWhenType(Evaluation.ContractType currentContractType) virtual {
        require(
            contractType == currentContractType,
            "This action cannot be carried out under this contract type"
        );
        _;
    }

    modifier onlyWhenOwnership(ContractOwnership _ownership) virtual {
        require(
            contractOwnership == _ownership,
            "Cannot invoke this escrow function with the current contract status."
        );
        _;
    }

    modifier onlyWhenState(ContractState _state) virtual {
        require(
            contractState == _state,
            "Cannot invoke this escrow function with the current contract state."
        );
        _;
    }

    function assignNewWorker(
        address _newWorker,
        uint256 _wad,
        uint256 nonce,
        uint256 expiry,
        uint8 eV,
        bytes32 eR,
        bytes32 eS,
        uint8 vDeny,
        bytes32 rDeny,
        bytes32 sDeny
    ) external {
        require(
            _newWorker != address(0),
            "Worker address must not be 0 when assigning new worker."
        );
        //require(_newWorker != owner, "You cannot work your own contract."); //COMMENTED FOR DEBUGGING
        require(_wad != 0, "The payout amount for this contract cannot be 0.");
        require(
            daiToken.balanceOf(owner) >= _wad,
            "You do not have enough DAI to pay the specified amount."
        );

        wad = _wad;
        initialize(nonce, expiry, eV, eR, eS, vDeny, rDeny, sDeny);

        worker = _newWorker;

        contractOwnership = ContractOwnership.PENDING;
        contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingWorkerApproval;
        acceptanceTimestamp = block.timestamp;

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    function work(
        bool _accepted,
        uint8 wV,
        bytes32 wR,
        bytes32 wS
    )
        external
        onlyWorker
        onlyWhenState(ContractState.Initialized)
        onlyWhenStatus(
            RelationshipLibrary.ContractStatus.AwaitingWorkerApproval
        )
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
            worker = address(0);
            refundReward();
            contractOwnership = ContractOwnership.UNCLAIMED;
            contractStatus = RelationshipLibrary.ContractStatus.AwaitingWorker;
        }

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    function refundReward() internal virtual;

    function refundUnclaimedContract() external virtual;

    function releaseJob() external virtual;

    function claimStalledContract() external virtual;

    function resolve() external virtual;

    function updateTaskMetadataPointer(string memory newTaskPointerHash)
        external
        virtual;

    function initialize(
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 vDeny,
        bytes32 rDeny,
        bytes32 sDeny
    ) internal virtual;
}
