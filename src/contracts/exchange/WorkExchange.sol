pragma solidity 0.8.4;

import "../test/Dai.sol";
import "./Escrow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILendingPool.sol";

// Adding only the ERC-20 function we need
interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract WorkExchange is Escrow {
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    constructor(ILendingPool poolsAddress, IERC20 aDaiAddress, IERC20 daiAddress, 
    address payable worker, uint value)  {
        super(poolsAddress, aDaiAddress, daiAddress, worker, msg.sender, value);
       // Deposit(msg.sender, address(super));
        //this.approve();
    }

    function approve() external {
        super.approve();
        Approved();
        Deposit(msg.sender, this.initialDeposit);
    }

    function withdraw() external {
        super.withdrawal();
        emit Withdrawal(this.beneficiary, this.getBalance());
    }


}