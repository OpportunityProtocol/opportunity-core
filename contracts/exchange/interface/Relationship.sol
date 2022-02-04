pragma solidity 0.8.7;

import "./IDaiToken.sol";
import "../../user/UserSummary.sol";
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
    uint256 public acceptanceTimestamp;
    uint256 public relationshipID;
    string public taskMetadataPointer;
    bytes32 public immutable domain_separator;

    DaiToken public daiToken;

    RelationshipLibrary.ContractStatus public contractStatus;
    ContractState public contractState;
    ContractOwnership public contractOwnership;
    Evaluation.ContractType public contractType;

    UserRegistration registrar;
    RelationshipEscrow relationshipEscrow;

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

    modifier onlyWorker() {
        require(
            msg.sender == worker,
            "Only the worker of this contract may call this function."
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of this contract may call this function."
        );
        _;
    }

    modifier onlyWhenStatus(RelationshipLibrary.ContractStatus _statusOptionOne) {
        require(
            contractStatus == _statusOptionOne,
            "This action cannot be carried out under the current contract status."
        );
        _;
    }

    modifier onlyWhenEitherStatus(
        RelationshipLibrary.ContractStatus _statusOptionOne,
        RelationshipLibrary.ContractStatus _statusOptionTwo
    ) {
        require(
            contractStatus == _statusOptionOne ||
                contractStatus == _statusOptionTwo,
            "This action cannot be carried out under the current contract status."
        );
        _;
    }

    modifier onlyWhenType(Evaluation.ContractType _currentContractType) {
        require(
            contractType == _currentContractType,
            "This action cannot be carried out under this contract type"
        );
        _;
    }

    modifier onlyWhenOwnership(ContractOwnership _ownership) {
        require(
            contractOwnership == _ownership,
            "Cannot invoke this escrow function with the current contract status."
        );
        _;
    }

    modifier onlyWhenState(ContractState _state) {
        require(
            contractState == _state,
            "Cannot invoke this escrow function with the current contract state."
        );
        _;
    }

    function work(bool _accepted) external virtual;
    function resolve() external virtual;
    function refundUnclaimedContract() external virtual;
    function reclaimClaimedFunds() external virtual;
    function releaseJob() external virtual;
    function notifyContract(uint256 _data) external virtual;

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
    ) internal virtual;

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
        bytes32 _sDeny
    ) external virtual {
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
        worker = _newWorker;
        
        initialize(_nonce, _expiry, _vAllow, _rAllow, _sAllow, _vDeny, _rDeny, _sDeny);

        contractOwnership = ContractOwnership.PENDING;
        contractStatus = RelationshipLibrary
            .ContractStatus
            .AwaitingWorkerApproval;
        acceptanceTimestamp = block.timestamp;

        emit ContractStatusUpdated(address(this), uint8(contractStatus));
    }

    function updateTaskMetadataPointer(string memory _newTaskPointerHash)
        external
        onlyOwner
        onlyWhenOwnership(ContractOwnership.UNCLAIMED)
    {
        taskMetadataPointer = _newTaskPointerHash;
    }
}
