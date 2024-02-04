// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "erc4626-tests/ERC4626.test.sol";

import {ERC20Mock} from "../src/ERC20Mock.sol";
import {GGPVault} from "../src/ggpVault.sol";

contract ERC4626StdTest is ERC4626Test {
    function setUp() public override {
        _underlying_ = address(new ERC20Mock());
        _vault_ = address(new GGPVault());
        GGPVault(_vault_).initialize(_underlying_);
        _delta_ = 0;
        _vaultMayBeEmpty = false;
        _unlimitedAmount = false;
    }
}
