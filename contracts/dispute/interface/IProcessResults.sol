interface IProcessResults {
   function getResults(bytes32 processId) public view override returns (uint32[][] memory tally, uint32 height);
}