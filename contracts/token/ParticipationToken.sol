import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract ParticipationToken is ERC20 {
    modifier onlyUserSummaryFactory() {
        require(summaryFactory == msg.sender, "Only the UserSummaryFactory can call this function.");
        _;
    }

    address immutable summaryFactory;

    constructor(string memory name_, string memory symbol_, address factory) ERC20(name_, symbol_) {
        summaryFactory = factory;
    }

    function mintJuryToken(address account, uint256 amount) external onlyUserSummaryFactory {
        _mint(account, amount);
    }
}