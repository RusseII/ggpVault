// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GGPVault.sol"; // Update this path to the actual path of your GGPVault contract
import "./mocks/MockTokenGGP.sol"; // Update this path to the actual path of your MockTokenGGP contract

contract GGPVaultTest is Test {
    GGPVault vault;
    MockTokenGGP mockGGP;
    address owner;

    function setUp() public {
        owner = address(this);
        mockGGP = new MockTokenGGP(owner); // Assuming MockTokenGGP's constructor takes an address to mint the initial supply to
        vault = new GGPVault();
        vault.initialize(address(mockGGP));
        vault.transferOwnership(owner);
    }

    // function testInitialBalance() public {
    //     assertEq(vault.totalAssets(), 0, "Initial total assets should be 0");
    // }

    // function testDepositFromStaking() public {
    //     uint256 depositAmount = 1000 * 10**18; // Adjust based on the decimals of MockTokenGGP
    //     (address(vault), depositAmount); // Ensure MockTokenGGP has a mint function or adjust accordingly
    //     vault.depositFromStaking(depositAmount);
    //     assertEq(vault.totalAssets(), depositAmount, "Total assets should match the deposited amount");
    // }

    // function testStakeOnValidator() public {
    //     uint256 stakeAmount = 500 * 10**18; // Adjust based on the decimals of MockTokenGGP
    //     mockGGP.mint(address(this), stakeAmount);
    //     mockGGP.approve(address(vault), stakeAmount);
    //     vault.stakeOnValidator(stakeAmount, address(this)); // Assuming stakeOnValidator is executable by the owner and the vault has been approved to spend tokens
    //     // This test needs to be adapted based on how stakeOnValidator interacts with the staking contract and the MockTokenGGP
    // }

    // Additional tests can be written to cover other functionalities of GGPVault.
}