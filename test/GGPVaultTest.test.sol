// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {GGPVault} from "../contracts/GGPVault.sol";
import {MockTokenGGP} from "./mocks/MockTokenGGP.sol";
import {MockStaking} from "./mocks/MockStaking.sol";
import {MockStorage} from "./mocks/MockStorage.sol";

interface IStorageContractGGP {
    function getAddress(bytes32 _id) external view returns (address);
}

contract GGPVaultTest is Test {
    GGPVault vault;
    MockTokenGGP ggpToken;
    MockStaking mockStaking;
    MockStorage mockStorage;
    address owner;
    address nodeOp1 = address(0x9);

    function setUp() public {
        owner = address(this);
        ggpToken = new MockTokenGGP(address(this));
        mockStaking = new MockStaking(ggpToken);
        mockStorage = new MockStorage();
        mockStorage.setAddress(keccak256(abi.encodePacked("contract.address", "staking")), address(mockStaking));

        vault = new GGPVault();
        vault.initialize(address(ggpToken), address(mockStorage), address(this));
        vault.grantRole(vault.APPROVED_NODE_OPERATOR(), nodeOp1);
    }

    function testStakeOnValidator() public {
        uint256 amount = 10e18; // 10 GGP for simplicity
        ggpToken.approve(address(vault), amount);

        vault.deposit(amount, msg.sender);
        assertEq(vault.balanceOf(msg.sender), amount, "Depositor gets correct amount of shares");
        vault.stakeOnValidator(amount, nodeOp1);

        assertEq(vault.stakingTotalAssets(), amount, "The staking total assets should be updated");
        assertEq(vault.totalAssets(), amount, "The total assets should be equal to deposits");
    }

    // function testDepositFromStaking() public {
    //     uint256 stakeAmount = 1e18; // Assume already staked
    //     uint256 depositAmount = 1e18; // Deposit back into the vault

    //     // Simulate depositing from staking
    //     ggpToken.transfer(address(vault), depositAmount);
    //     vault.depositFromStaking(depositAmount);

    //     console.log(vault.balanceOf(address(this)));

    //     // Check if the stakingTotalAssets is updated correctly
    //     uint256 expectedAssets = vault.stakingTotalAssets() - depositAmount;
    //     assertEq(vault.stakingTotalAssets(), expectedAssets, "The staking total assets should decrease");

    //     // Verify the vault's ggpToken balance is updated
    //     assertEq(ggpToken.balanceOf(address(vault)), depositAmount, "Vault balance should reflect the deposited amount");
    // }

    function testTotalAssetsCalculation() public {
        uint256 assetsToDeposit = 1000e18; // Simulated staked amount
        ggpToken.approve(address(vault), type(uint256).max);
        assertEq(vault.stakingTotalAssets(), 0, "The staking total assets should be updated");
        assertEq(vault.totalAssets(), 0, "The total assets should be equal to deposits");
        vault.deposit(assetsToDeposit, msg.sender);
        assertEq(vault.stakingTotalAssets(), 0, "The staking total assets should be updated");
        assertEq(vault.totalAssets(), assetsToDeposit, "The total assets should be equal to deposits");

        vault.stakeOnValidator(assetsToDeposit / 2, nodeOp1);
        assertEq(vault.stakingTotalAssets(), assetsToDeposit / 2, "The staking total assets should be updated");
        assertEq(vault.totalAssets(), assetsToDeposit, "The total assets should be equal to deposits");

        vault.depositFromStaking(assetsToDeposit / 2);
        assertEq(vault.stakingTotalAssets(), 0, "The staking total assets should be updated");
        assertEq(vault.totalAssets(), assetsToDeposit, "The total assets should be equal to deposits");

        uint256 rewards = 100e18;
        vault.depositFromStaking(rewards);
        assertEq(vault.stakingTotalAssets(), 0, "The staking total assets should be updated");
        assertEq(vault.totalAssets(), assetsToDeposit + rewards, "The total assets should be equal to deposits");

        // Manually adjust the stakingTotalAssets to simulate staking
        // This requires direct interaction or simulation due to access control
        // vault.stakingTotalAssets = stakedAssets; // Hypothetical direct interaction, not possible without additional setup or mocking

        // The totalAssets should reflect both the staked assets and the vault balance
    }

    // function testOwnershipTransfer() public {
    //     address newOwner = address(0x1);

    //     // Initiate ownership transfer by the current owner
    //     vm.prank(owner);
    //     vault.transferOwnership(newOwner);

    //     // Attempt to accept the ownership transfer by the new owner
    //     vm.startPrank(newOwner);
    //     vault.acceptOwnership();
    //     vm.stopPrank();

    //     // Verify the ownership has been transferred
    //     assertEq(vault.owner(), newOwner, "Ownership was not transferred to the new owner");

    //     // Ensure that the old owner no longer has access
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     vm.prank(owner);
    //     vault.stakeOnValidator(1e18, owner);
    // }

    // function testPreventNonOwnerFromInitiatingTransfer() public {
    //     address nonOwner = address(0x2);
    //     address newOwner = address(0x3);

    //     vm.prank(nonOwner);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     vault.transferOwnership(newOwner);
    // }

    // function testStakeOnValidatorAccessControl() public {
    //     address nonOwner = address(0x1);
    //     uint256 amount = 1e18; // 1 ggpToken for simplicity
    //     address nodeOp = address(this); // Just an example address

    //     // Non-owner should not be able to call
    //     vm.prank(nonOwner);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     vault.stakeOnValidator(amount, nodeOp);

    //     // Owner should be able to call
    //     vm.prank(owner);
    //     // Assuming `stakeOnValidator` does not emit a specific event or have easily checkable effects,
    //     // otherwise, check for those effects here.
    //     vault.stakeOnValidator(amount, nodeOp);
    // }

    // // Example of testing an upgrade process, heavily dependent on your setup
    // function testUpgradeProcess() public {
    //     address newImplementation = address(new GGPVault()); // Assuming you have a new version ready

    //     // Simulate upgrade process initiated by the owner
    //     vm.prank(owner);
    //     // Replace the following with your actual upgrade initiation call, e.g.,
    //     // proxy.upgradeTo(newImplementation);

    //     // Post-upgrade checks to ensure upgrade was successful, e.g.,
    //     // assertEq(proxy.implementation(), newImplementation, "Upgrade did not set the new implementation correctly");
    // }

    // // function testTransferOwnershipAccessControl() public {
    // //     address nonOwner = address(0x1);
    // //     address newOwner = address(0x2);

    // //     // Non-owner should not be able to call
    // //     vm.prank(nonOwner);
    // //     vm.expectRevert("Ownable: caller is not the owner");
    // //     vault.transferOwnership(newOwner);

    // //     // Owner should be able to initiate transfer
    // //     vm.prank(owner);
    // //     vault.transferOwnership(newOwner);
    // //     // assertEq(vault.newOwner(), newOwner, "Transfer ownership did not set the new owner correctly");
    // // }

    // function testAcceptOwnershipAccessControl() public {
    //     address newOwner = address(0x2);

    //     // Initiate ownership transfer
    //     vm.prank(owner);
    //     vault.transferOwnership(newOwner);

    //     // Non-proposed owner should not be able to accept
    //     address nonProposedOwner = address(0x3);
    //     vm.prank(nonProposedOwner);
    //     vm.expectRevert("Ownable: caller is not the new owner");
    //     vault.acceptOwnership();

    //     // New owner accepts the transfer
    //     vm.prank(newOwner);
    //     vault.acceptOwnership();
    //     assertEq(vault.owner(), newOwner, "Ownership was not transferred to the new owner");
    // }

    // function testCancelOwnershipTransferAccessControl() public {
    //     address newOwner = address(0x2);

    //     // Initiate and cancel ownership transfer by the owner
    //     vm.prank(owner);
    //     vault.transferOwnership(newOwner);
    //     // Assuming there's a way to verify cancellation, e.g., `newOwner()` is reset
    //     // assertEq(vault.newOwner(), address(0), "Ownership transfer was not canceled correctly");
}
