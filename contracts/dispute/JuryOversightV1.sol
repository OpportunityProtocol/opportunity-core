pragma solidity 0.8.7;

import "./JuryTicketV1.sol";

contract JuryOversightV1 {
    modifier onlyFromValidDispute() {
        //dispute has a relationship that is registered in the jury oversight
         require(relationshipsToDisputes[disputeSender.relationship()] == msg.sender);

        //dispute has a relationship and that relationship is in disputed states
        Dispute disputeSender = Dispute(msg.sender);
        WorkRelationship workRelationship = WorkRelationship(disputeSender.relationship());
        require(workRelationship.contractStatus == Relationship.ContractStatus.Disputed);
        _;
    }

    enum TicketStatus {
        EXPIRED,
        VALID
    }

    mapping(address => address) expiredDisputesToTickets;
    mapping(address => TicketStatus) tokensToStatus;
    mapping(address => address) disputesToJuryProofTicketAddress;

    function setupJuryProof(address[] jurors, address relationship) external returns(address) {
        Dispute disputeSender = Dispute(msg.sender);
        WorkRelationship workRelationship = WorkRelationship(disputeSender.relationship());

        //require the relationship has a dispute that is this dispute calling
        require(workRelationship.dispute() == msg.sender);
        
        //require relationship is currently disputed
        require(workRelationship.contractStatus() == Relationship.ContractStatus.Disputed);

        //issue ticket
        address ticketAddress = issueJuryTicket(jurors);
        disputesToJuryProofTicketAddress[ticketAddress] = msg.sender;
        
        //store in tokensToStatus
        tokensToStatus[ticketAddress] = TicketStatus.VALID;

        //store in relationshipstodispute
        relationshipsToDisputes[relationship] = dispute;

        return ticketAddress;
    }

    function issueJuryTicket(address _dispute, address jurors) internal returns(address) {
        //create new token for jury
        JuryTicketV1 ticket = new JuryTicket(dispute, jurors, address(this));
        return address(ticket);
    }

    function expireTicket(address dispute, address ticket) external {
        Dispute currDispute = Dispute(dispute);

        //require the dispute has a relationship that is in our mapping with it
        require(relationshipsToDisputes[currDispute.relationship()] == dispute);

        //require the dispute has a jury proof ticket address that matches the one mapped
        require(disputesToJuryProofTicketAddress[msg.sender] == currDispute.juryProof(), "The sender does not have a jury proof mapped to it.");


        //require the ticket is not expired
        require(tokensToStatus[ticket] != TicketStatus.EXPIRED);

        //expire the ticket
        expiredDisputesToTickets[dispute] = ticket;
        tokensToStatus[ticket] = TicketStatus.EXPIRED;
    }

    function getTicketStatus(address ticket) external {
        return tokensToStatus[ticket];
    }
}