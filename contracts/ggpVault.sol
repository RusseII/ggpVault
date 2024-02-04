// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/GGPInterfaces.sol"; // Assuming these are external interfaces

contract GGPVault is
    Initializable,
    Ownable2StepUpgradeable,
    ERC4626Upgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant APPROVED_NODE_OPERATOR = keccak256("APPROVED_NODE_OPERATOR");

    IStorageContractGGP public ggpStorage;
    uint256 public stakingTotalAssets;
    uint256 public assetCap;

    event AssetCapUpdated(uint256 newCap);
    event WithdrawnForStaking(address indexed caller, uint256 assets);
    event DepositedFromStaking(address indexed caller, uint256 amount);

    function initialize(address _underlying, address _storageContract, address _initialOwner) external initializer {
        __ERC20_init("ggpVault", "ggGGP");
        __ERC4626_init(IERC20(_underlying));
        __UUPSUpgradeable_init();
        __Ownable2Step_init();
        __Ownable_init(_initialOwner);
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);

        ggpStorage = IStorageContractGGP(_storageContract);
        stakingTotalAssets = 0;
        assetCap = 10000e18;
    }

    function setAssetCap(uint256 _newCap) external onlyOwner {
        assetCap = _newCap;
        emit AssetCapUpdated(_newCap);
    }

    function stakeOnValidator(uint256 amount, address nodeOp) external onlyOwner {
        _checkRole(APPROVED_NODE_OPERATOR, nodeOp);
        stakingTotalAssets += amount;
        IStakingContractGGP stakingContract = getStakingContractAddress();
        IERC20(asset()).approve(address(stakingContract), amount);
        stakingContract.stakeGGPOnBehalfOf(nodeOp, amount);
        emit WithdrawnForStaking(nodeOp, amount);
    }

    function depositFromStaking(uint256 amount) public {
        stakingTotalAssets = amount >= stakingTotalAssets ? 0 : stakingTotalAssets - amount;
        emit DepositedFromStaking(msg.sender, amount);
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
    }

    function getStakingContractAddress() public view returns (IStakingContractGGP) {
        bytes32 args = keccak256(abi.encodePacked("contract.address", "staking"));
        return IStakingContractGGP(ggpStorage.getAddress(args));
    }

    function totalAssets() public view override returns (uint256) {
        return stakingTotalAssets + getUnderlyingBalance();
    }

    function maxDeposit(address receiver) public view override returns (uint256) {
        uint256 total = totalAssets();
        return assetCap > total ? assetCap - total : 0;
    }

    function getUnderlyingBalance() public view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
