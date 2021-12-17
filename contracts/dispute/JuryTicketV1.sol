pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract JuryTicketV1 is ERC1155 {
    event TickedIssued(string indexed ticketId, address indexed dispute, address juror);

    modifier onlyFromJuryOversight(sender) {
        require(sender == JURY_OVERSIGHT_ADDRESS, "Only the jury oversight can mint this token.");
        _;
    }

    uint8 public constant NUM_TICKET_ISSUANCE = 1;
    address public constant JURY_OVERSIGHT_ADDRESS = 0;
    address public immutable dispute;
    bool public minteable = true;
    uint8 constant NUM_JURY_MEMBERS = 5;
    address juryOversight;


    contructor(address _disputeAddress, address[] jurors, address _juryOversight) ERC721("") {
        require(_disputeAddress != address(0), "Dispute address cannot be 0");
        require(jurors.length != NUM_JURY_MEMBERS, "Invalid number of jury members");
        require(_juryOversight != address(0), "The address of the jury oversight cannot be set to 0.");

        dispute = _disputeAddress;
        juryOversight = _juryOversight;
        mint(jurors);
    }

    function mint(address[] jurors) 
        internal
        onlyFromJuryOversight(msg.sender)
    {
        require(minteable == true, "This ticket is no longer minteable.");

        for (let i = 0; i < jurors.length; i++) {
            _mint(jurors[i], abi.encodePacked(disputeAddress), NUM_TICKET_ISSUANCE, "");
            emit TicketIssued(abi.encodePacked(disputeAddress), dispute, juror[i]);
        }

        minteable = false;
    }
}