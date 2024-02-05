// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {GGPVault} from "../contracts/GGPVault.sol";
import {MockTokenGGP} from "./mocks/MockTokenGGP.sol";
import {MockStaking} from "./mocks/MockStaking.sol";
import {MockStorage} from "./mocks/MockStorage.sol";

contract GGPVaultTest is Test {
    GGPVault vault;
    MockTokenGGP ggpToken;
    MockStaking mockStaking;
    MockStorage mockStorage;
    address owner;
    address nodeOp1 = address(0x9);

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

        vault = new GGPVault();
        vault.initialize(address(ggpToken), address(mockStorage), address(this));
        vault.grantRole(vault.APPROVED_NODE_OPERATOR(), nodeOp1);
        ggpToken.approve(address(vault), type(uint256).max);

        ggpToken.transfer(nodeOp1, 100000e18);
        ggpToken.approve(address(vault), type(uint256).max);
        vm.prank(nodeOp1);
        ggpToken.approve(address(vault), type(uint256).max);
    }
}

// Uncovered for contracts/GGPVault.sol:
// - Line (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Branch (branch: 0, path: 0) (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Branch (branch: 0, path: 1) (location: source ID 0, line 122, chars 5798-5843, hits: 0)
// - Function "getUnderlyingBalance" (location: source ID 0, line 131, chars 6073-6199, hits: 0)
// - Function "_authorizeUpgrade" (location: source ID 0, line 137, chars 6377-6461, hits: 0)
