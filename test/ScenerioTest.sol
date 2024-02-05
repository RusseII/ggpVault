// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {GGPVault} from "../contracts/GGPVault.sol";
import {MockTokenGGP} from "./mocks/MockTokenGGP.sol";
import {MockStaking} from "./mocks/MockStaking.sol";
import {MockStorage} from "./mocks/MockStorage.sol";

contract GGPVaultTest2 is Test {
    GGPVault vault;
    MockTokenGGP ggpToken;
    MockStaking mockStaking;
    MockStorage mockStorage;
    address owner;

    event AssetCapUpdated(uint256 newCap);
    event DepositedFromStaking(address indexed caller, uint256 amount);

    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        owner = address(this);
        ggpToken = new MockTokenGGP(address(this));
        mockStaking = new MockStaking(ggpToken);
        mockStorage = new MockStorage();
        mockStorage.setAddress(keccak256(abi.encodePacked("contract.address", "staking")), address(mockStaking));

        // vault = new GGPVault();
        // vault.initialize(address(ggpToken), address(mockStorage), address(this));
        // vault.grantRole(vault.APPROVED_NODE_OPERATOR(), nodeOp1);
        // ggpToken.approve(address(vault), type(uint256).max);

        // ggpToken.transfer(nodeOp1, 100000e18);
        // ggpToken.approve(address(vault), type(uint256).max);
        // vm.prank(nodeOp1);
        // ggpToken.approve(address(vault), type(uint256).max);
    }

    function testWalkThroughEntireScenerio() public {
        address nodeOp1 = address(0x999);
        address nodeOp2 = address(0x888);
        address randomUser1 = address(0x777);
        address randomUser2 = address(0x666);
        // address randomUser3 = address(0x555);

        ggpToken.transfer(randomUser1, 10000e18);
        ggpToken.transfer(randomUser2, 10000e18);

        address ggpVaultMultisig = address(0x69);
        vault = new GGPVault(); // Deploy the GGP Vault
        vault.initialize(address(ggpToken), address(mockStorage), ggpVaultMultisig); // initalize it and transfer ownership to our multisig

        vm.expectRevert();
        vault.initialize(address(ggpToken), address(mockStorage), ggpVaultMultisig); // can not initialize again

        bytes32 nodeOpRole = vault.APPROVED_NODE_OPERATOR();
        bytes32 defaultAdminRole = vault.DEFAULT_ADMIN_ROLE();

        vm.expectRevert();
        vault.grantRole(nodeOpRole, ggpVaultMultisig); // make sure deployer can't grant nodeOp role
        vm.expectRevert();
        vault.grantRole(defaultAdminRole, ggpVaultMultisig); // make sure deployer can't grant admin role

        vm.expectRevert();
        vault.transferOwnership(address(0x5)); // make sure deployer can't transfer ownership of contract

        assertEq(vault.owner(), ggpVaultMultisig); // check that the owner is the multisig
        assertEq(vault.hasRole(defaultAdminRole, ggpVaultMultisig), true); // check that the owner is the multisig

        vm.startPrank(ggpVaultMultisig); // start behalving as the multisig
        vault.grantRole(nodeOpRole, nodeOp1); // grant roles to the both node operators so GGP can be staked on thier behalf
        vault.grantRole(nodeOpRole, nodeOp2); // grant roles to the both node operators so GGP can be staked on thier behalf

        assertEq(vault.totalAssets(), 0); // check that the owner is the multisig
        assertEq(vault.getUnderlyingBalance(), 0); // check that the owner is the multisig
        assertEq(vault.stakingTotalAssets(), 0); // check that the owner is the multisig
        assertEq(vault.getStakingContractAddress(), address(mockStaking)); // make sure can fetch staking contract correctly
        assertEq(vault.ggpStorage(), address(mockStorage)); // make sure can fetch staking contract correctly
        assertEq(vault.assetCap(), 33000e18); // make sure can fetch staking contract correctly
        assertEq(vault.maxDeposit(ggpVaultMultisig), vault.assetCap()); // make sure can fetch staking contract correctly
        vm.stopPrank();

        // Vault seems to be in the expectd state, now lets's get going!

        vm.startPrank(randomUser1); // start behalving as a depositor
        uint256 randomUser1InitialDeposit = 10e18;
        ggpToken.approve(address(vault), randomUser1InitialDeposit);
        vault.deposit(randomUser1InitialDeposit, randomUser1);
        assertEq(vault.balanceOf(randomUser1), randomUser1InitialDeposit); // make sure user is minted share tokens 1:1

        assertEq(vault.totalAssets(), randomUser1InitialDeposit); // retest
        assertEq(vault.getUnderlyingBalance(), randomUser1InitialDeposit); // retest
        assertEq(vault.stakingTotalAssets(), 0); // retest
        assertEq(vault.maxDeposit(ggpVaultMultisig), vault.assetCap() - randomUser1InitialDeposit); // retest
        vm.stopPrank();

        vm.startPrank(randomUser2);

        uint256 randomUser2InitialDeposit = 10000e18;
        ggpToken.approve(address(vault), randomUser2InitialDeposit);

        vault.deposit(randomUser2InitialDeposit, randomUser2);
        assertEq(vault.balanceOf(randomUser2), randomUser2InitialDeposit); // make sure user is minted share tokens 1:1

        uint256 totalDeposits = randomUser1InitialDeposit + randomUser2InitialDeposit;

        assertEq(vault.totalAssets(), totalDeposits); // retest
        assertEq(vault.getUnderlyingBalance(), totalDeposits); // retest
        assertEq(vault.stakingTotalAssets(), 0); // retest
        assertEq(vault.maxDeposit(ggpVaultMultisig), vault.assetCap() - totalDeposits); // retest

        // now test that users can burn some of their shares correctly.
        uint256 randomUser2Withdrawal = 100e18; // rounding causes errors
        vault.withdraw(randomUser2Withdrawal, randomUser2, randomUser2);

        uint256 totalDepositsAfterWithdraw1 = totalDeposits - randomUser2Withdrawal;

        // assertEq(vault.balanceOf(randomUser2), totalDepositsAfterWithdraw1); // make sure user is minted share tokens 1:1

        // assertEq(vault.totalAssets(), totalDepositsAfterWithdraw1); // retest
        // assertEq(vault.getUnderlyingBalance(), totalDepositsAfterWithdraw1); // retest
        // assertEq(vault.stakingTotalAssets(), 0); // retest
        // assertEq(vault.maxDeposit(ggpVaultMultisig), vault.assetCap() - totalDepositsAfterWithdraw1); // retest
    }
}

// Uncovered for contracts/GGPVault.sol:
// - Line (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Branch (branch: 0, path: 0) (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Branch (branch: 0, path: 1) (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Function "getUnderlyingBalance" (location: source ID 0, line 131, chars 6073-6199, hits: 0)
// - Function "_authorizeUpgrade" (location: source ID 0, line 137, chars 6377-6461, hits: 0)