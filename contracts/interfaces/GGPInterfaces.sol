interface IStakingContractGGP {
    function stakeGGPOnBehalfOf(address stakerAddr, uint256 amount) external;
}

interface IStorageContractGGP {
    function getAddress(bytes32 _id) external view returns (address);
}
