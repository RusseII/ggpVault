// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract ggpVault is ERC4626 {
    constructor() ERC4626("ggpVault", "xGGP") {
}
