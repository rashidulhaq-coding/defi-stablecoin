// SPDX-License-Identifier: MINT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
/**
 * @title DSCEngine
 * @author Rashid Ul Haq
 *
 * The System is designed to be as minimal as possible, and have the tokens maintain a 1 token ==1$ peg.
 * This stablecoin has the properties:
 *  -Exogenous Collateral
 *  -Dollar Pegged
 *  -Algorithmically Stable
 *
 * It is similiar to DAI if DAI had no governance. no fees, and was only backed by WETH and WBTC.
 * Our DSC system should always be "overcollateralized". At no point, should the value of all collateral <= the Dollar backed of value of all the DSC.
 *
 * @notice This contract is the core of the BSC System. It handles all the logic for minting and redeeming DSC, as well as
 * depositing & withdrawing collateral.
 * @notice This contract is verly loosely based on the MakerDAO DSS (DAI) system.
 */

contract DSCEngine is ReentrancyGuard {
    ////////////////////////
    //      Errors        //
    ////////////////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    ////////////////////////
    // State Variables    //
    ////////////////////////

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping (address user => uint256 amountDscMinted) private s_DSCMinted;

    DecentralizedStableCoin private immutable i_dsc;


    ////////////////////////
    // Events             //
    ////////////////////////
    event CollateralDeposited(address indexed user,address indexed token,uint256 indexed amount);
    ////////////////////////
    //      Modifiers     //
    ////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
    }

    ////////////////////////
    //      Functions     //
    ////////////////////////
    constructor(address[] memory tokenAdresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAdresses.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAdresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////
    // External Functions //
    ////////////////////////
    function depositCollateralAndMintDsc() external {}

    /**
     * @notice follows CEI
     * @param tokenCollateralAddress The address of token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit.
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender,tokenCollateralAddress,amountCollateral);
        bool successs = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this).amountCollateral);
        if (!successs) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}
    function redeemCollateral() external {}
    // Threshold to let's say 150$
    // $100 Eth -> $75
    // $50 DSC


    /**
     * @notice Follow CEI
     * @param amountDscToMint The amount of decentralized stablecoin to ming
     * @notice They must have more collateral than the minimum threshold.
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant{
        s_DSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much($150 DSC, $100 Eth)
        _revertIfHealthFactorIsBroken(msg.sender);
    }
    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}


    ////////////////////////////////////////
    // Private & Internal view Functions //
    //////////////////////////////////////
    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted, uint256 collateralValueInUsd){
        totalDscMinted = s_DSCMinted[user];
        collateralvalueInUsdd = getAccountCollateralValue(user);
    }
    /**
     * Returns how close to liquidation a user is
     * If a user goes below 1, then they can get liquidated.
     * @param user 
     */
    function _healthFactor(address user) private view returns(uint256){
        // Total DSC minted
        // Total Collateral Value
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
    }
    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. Check health factor (do they have enough collateral)
        // 2. Revert if they don't

    }
}


// 1:30