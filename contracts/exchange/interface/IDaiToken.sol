interface DaiToken {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
    external;

    function pull(address usr, uint wad) external;
    function push(address usr, uint wad) external;
    function approve(address usr, uint wad) external returns (bool);
    function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}