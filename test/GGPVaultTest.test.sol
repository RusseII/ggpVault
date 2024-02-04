// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GGPVault.sol";
import "../src/Mocks/MockERC20.sol";
import "../src/Mocks/MockStakingContractGGP.sol";
import "../src/Mocks/MockStorageContractGGP.sol";

contract GGPVaultTest is Test {
    GGPVault vault;
    MockERC20 underlyingToken;
    MockStakingContractGGP stakingContract;
    MockStorageContractGGP storageContract;

    address owner = address(1);
    address nodeOperator = address(2);
    address randomUser = address(3);

    function setUp() public {
        // Deploy mock contracts
        underlyingToken = new MockERC20("Mock Token", "MTK", 18);
        storageContract = new MockStorageContractGGP();
        stakingContract = new MockStakingContractGGP(address(underlyingToken));

        // Set up GGPVault with the mock underlying token
        vault = new GGPVault();
        vm.startPrank(owner);
        vault.initialize(address(underlyingToken));
        vm.stopPrank();

        // Set mock addresses in storage contract
        bytes32 stakingContractKey = keccak256(abi.encodePacked("contract.address", "staking"));
        storageContract.setAddress(stakingContractKey, address(stakingContract));

        // Mint and approve tokens for tests
        underlyingToken.mint(owner, 1000 ether);
        underlyingToken.approve(address(vault), 1000 ether);
    }

    function testInitialization() public {
        assertEq(vault.owner(), owner, "Owner should be correctly set");
        assertEq(address(vault.asset()), address(underlyingToken), "Underlying token should be correctly set");
        assertEq(vault.totalAssets(), 0, "Total assets should initially be 0");
    }

    function testStakeOnValidator() public {
        uint256 amountToStake = 500 ether;

        vm.startPrank(owner);
        vault.stakeOnValidator(amountToStake, nodeOperator);
        vm.stopPrank();

        assertEq(vault.stakingTotalAssets(), amountToStake, "Staking total assets should be updated");
        assertEq(underlyingToken.balanceOf(address(stakingContract)), amountToStake, "Staking contract should receive the correct amount");
    }

    function testDepositFromStaking() public {
        uint256 initialStake = 500 ether;
        uint256 depositAmount = 200 ether;

        // First, simulate staking
        vm.startPrank(owner);
        vault.stakeOnValidator(initialStake, nodeOperator);
        vm.stopPrank();

        // Simulate earning from staking and depositing back to the vault
        underlyingToken.mint(address(vault), depositAmount);
        vault.depositFromStaking(depositAmount);

        assertEq(vault.stakingTotalAssets(), initialStake - depositAmount, "Staking total assets should decrease after deposit");
        assertEq(vault.totalAssets(), initialStake, "Total assets should reflect the deposit");
    }

    function testWithdrawForStaking() public {
        // Implement withdraw tests similar to deposit, adjusting for your contract's logic
    }

    function testTotalAssetsCalculation() public {
        uint256 stakeAmount = 300 ether;
        uint256 depositAmount = 200 ether;

        // Simulate staking
        vm.startPrank(owner);
        vault.stakeOnValidator(stakeAmount, nodeOperator);
        vm.stopPrank();

        // Simulate deposit from staking
        underlyingToken.mint(address(vault), depositAmount);
        vault.depositFromStaking(depositAmount);

        uint256 expectedTotalAssets = stakeAmount + depositAmount;
        assertEq(vault.totalAssets(), expectedTotalAssets, "Total assets should be correctly calculated");
    }

    function testUnauthorizedAccess() public {
        vm.startPrank(randomUser);

        vm.expectRevert("Ownable: caller is not the owner");
        vault.stakeOnValidator(100 ether, nodeOperator);

        vm.expectRevert("Ownable: caller is not the owner");
        vault.initialize(address(underlyingToken));

        vm.stopPrank();
    }

    // Add more tests for edge cases and other functionalities as needed
}
