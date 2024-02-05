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
        // address randomUser1 = address(0x777);
        // address randomUser2 = address(0x666);
        // address randomUser3 = address(0x555);

        address ggpVaultMultisig = address(0x69);
        vault = new GGPVault(); // Deploy the GGP Vault
        vault.initialize(address(ggpToken), address(mockStorage), ggpVaultMultisig); // initalize it and transfer ownership to our multisig

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
        assertEq(vault.getStakingContractAddress(), address(mockStaking)); // check that the owner is the multisig
    }
}

// Uncovered for contracts/GGPVault.sol:
// - Line (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Branch (branch: 0, path: 0) (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Branch (branch: 0, path: 1) (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Function "getUnderlyingBalance" (location: source ID 0, line 131, chars 6073-6199, hits: 0)
// - Function "_authorizeUpgrade" (location: source ID 0, line 137, chars 6377-6461, hits: 0)
