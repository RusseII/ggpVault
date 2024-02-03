// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC4626Mock is Ownable, ERC4626, Initializable, BaseUpgradeable {
    using SafeERC20 for IERC20;
    uint256 public stakingTotalAssets;
    event WithdrawnForStaking(address indexed caller, uint256 assets);
    event DepositedFromStaking(address indexed caller, uint256 amount);

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		// The constructor is executed only when creating implementation contract
		// so prevent it's reinitialization
		_disableInitializers();
	}


    function withdrawForStaking(uint256 amount) external onlyOwner {
        stakingTotalAssets += amount;
        emit WithdrawnForStaking(msg.sender, amount);
        IERC20(asset()).safeTransfer(msg.sender, amount);
    }

    function depositFromStaking(uint256 amount) public {
        stakingTotalAssets -= amount;
        emit DepositedFromStaking(msg.sender, amount);
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
    }

    function initialize(
        address underlying
    ) public initializer {
        		__ERC4626Upgradeable_init(asset, "GoGoPool Liquid Staking Token", "ggAVAX");
		__BaseUpgradeable_init(storageAddress);
        // ERC20("ggpVault", "ggGGP");
        // ERC4626(IERC20(underlying))
        // Ownable(msg.sender)
        version = 1;
        stakingTotalAssets = 0;
    }
    // constructor(
    //     address underlying
    // )
    //     ERC20("ggpVault", "ggGGP")
    //     ERC4626(IERC20(underlying))
    //     Ownable(msg.sender)
    // {
    //     stakingTotalAssets = 0;
    // }

    function getUnderlyingBalance() public view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function totalAssets() public view override returns (uint256) {
        return stakingTotalAssets + getUnderlyingBalance();
    }
}
