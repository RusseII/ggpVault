// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ERC20Upgradeable, IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

interface Staking {
	function stakeGGPOnBehalfOf(address stakerAddr, uint256 amount) external;
}
interface IStorageContract {
    function getAddress(bytes32 _id) external view returns (address);
}

contract GGPVault is Initializable, Ownable2StepUpgradeable, ERC4626Upgradeable  {
    IStorageContract public constant ggpStorage = IStorageContract(0x1cEa17F9dE4De28FeB6A102988E12D4B90DfF1a9);

    using SafeERC20 for IERC20;
    uint256 public stakingTotalAssets;
    event WithdrawnForStaking(address indexed caller, uint256 assets);
    event DepositedFromStaking(address indexed caller, uint256 amount);

	constructor() {
		// The constructor is executed only when creating implementation contract
		// so prevent it's reinitialization
		_disableInitializers();
	}


    // function withdrawForStaking(uint256 amount) external onlyOwner {
    //     stakingTotalAssets += amount;
    //     emit WithdrawnForStaking(msg.sender, amount);
    //     IERC20(asset()).safeTransfer(msg.sender, amount);
    // }

   function stakeOnValidator(uint256 amount, address nodeOp) external onlyOwner {
    stakingTotalAssets += amount;
    Staking stakingContract = Staking(getStakingContractAddress());
    stakingContract.stakeGGPOnBehalfOf(nodeOp, amount);
    emit WithdrawnForStaking(nodeOp, amount);
    }

    function depositFromStaking(uint256 amount) public {
        stakingTotalAssets -= amount;
        emit DepositedFromStaking(msg.sender, amount);
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
    }

    function getStakingContractAddress() public view returns (address) {
        bytes32 args = keccak256(abi.encodePacked("contract.address", 'staking'));
        return ggpStorage.getAddress(args);
    }

    function initialize(
        address underlying
    ) public initializer {
        __ERC4626_init(IERC20(underlying));
        // __ERC4626_init_unchained(IERC20(underlying));
        // which of the above should this be???? they use the unchained in their mock for some reason ?? https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/mocks/token/GGPVaultUpgradeable.sol
        __ERC20_init("ggpVault", "ggGGP");
        stakingTotalAssets = 0;
    }
 

    function getUnderlyingBalance() public view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function totalAssets() public view override returns (uint256) {
        return stakingTotalAssets + getUnderlyingBalance();
    }
}

