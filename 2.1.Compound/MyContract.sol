// SPDX-License-Identifier: GPL-3.0
pragma solidity^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/interface.sol";

// supply
// borrow
// repay
// redeem

contract MyContract {
    IERC20 token;
    CErc20 ctoken; // from interface.sol

    constructor(address _token, address _ctoken) { // setting pointers 
        token = IERC20(_token);
        ctoken = CErc20(_ctoken);
    }

    ////////////// Supply and Redeem //////////////

    // To transfer token from user to Compound protocol (will be done via this contract's address)
    function supplyToken(uint amountToken) external {
        token.transferFrom(msg.sender, address(this), amountToken); // Transfering token from caller's address to this contract's address
        token.approve(address(ctoken), amountToken); // Approving ctoken to take amountToken of tokens from this contract address
        // ctoken.mint(amountToken) // calling the mint function of CToken contract to mint cTokens in exchange of amountToken tokens

        require(ctoken.mint(amountToken) == 0, "Mint failed"); // verifying if mint was succeful; mint function returns the error code        
    } // after calling this function(succefully), we can say that our tokens are lent to Compound Protocol, and cTokens in this contract address 
      // Note: cToken amount transfered = tokens tranfered / excahnge rate


    // To get the cToken balance holded by this contract address 
    function getCTokenBalance() external view returns(uint) {
        return ctoken.balanceOf(address(this));
    } // Note: ctoken.balanceOf() can get us cToken balance for any address


    // To get current exchange rate and supply rate
    function getRates() external returns(uint _exchangeRate, uint _supplyRate){
        uint exchangeRate = ctoken.exchangeRateCurrent(); // gets current exchange rate(CToken contract function)
        uint supplyRate = ctoken.supplyRatePerBlock(); // gets current supply rate(CToken contract function)
        return(exchangeRate, supplyRate); 
    } // Note: getRates() cannot be set as view, because exchangeRateCurrent() & supplyRatePerBlock() are not view funciton
      // Note: We can get these info(s) using static call, hence we might never use this getRates() function, as it will make caller do transaction everytime it's called


    // To get the status(or increased balance) of tokens lended to Compound Protocol
    // technically this is (cToken balance)*(current exchange rate)
    function myUnderlyingBalance() external returns(uint) {
        return(ctoken.balanceOfUnderlying(address(this)));
    } // Remember, the cTokens are currently in this contract address
      // Note: ctoken.balanceOf() can get us cToken balance for any address


    // To redeem amountCTokens of tokens from Compound Protocol by redeeming the cTokens in this contract address
    function redeemCTokens(uint amountCTokens) external {
        require(ctoken.redeem(amountCTokens) == 0, "Redeem failed"); // verifying if mint was redeem; redeem function returns the error code 
    }

    ////////////// Borrow and Repay //////////////

    // collateral (collateral factor- % of total amount which one can borrow against amount invested in Compound)
        // eg:- I invest 1 WBTC(worth 30k Dai) in Compound, if collateral factor is 65%, I can borrow 30k*0.6 Dai from Compound
    // account liquidity - calculate how much can I borrow?
    // open price feed USD price of token to borrow
    // enter market and borrow
    // borrowed balance (includes interest)
    //borrow rate
    // repay borrow

    Comptroller public comptroller = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B); // to be able to use Comptroller Interface 
    PriceFeed public pricefeed = PriceFeed(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1); // to be able to use PriceFeed Interface


    // To get collateral factor
    function getCollateralFactor() external view returns(uint) {
        (bool isListed, uint colFactor, bool isComped) = comptroller.markets(address(ctoken));
        // comptroller.markets(address(ctoken)) returns:
            // bool isListed -> is ctoken listed on Compound (true/false)
            // uint colFactor -> collateral factor (what we need). This is scalled up to 10^18
            // bool isComped -> wethere or not ctoken will recieve the CompoundToken (COMP)
        // Note: we can use (, uint colFactor, ) and not define the rest two variables
        return colFactor; // to get in % we need to divide it by le18
    }


    // To get account liquidity (calculate borrow limit)
    function getAccountLiquidity() external view returns(uint _liquidity, uint _shortfall) {
        (uint error, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(address(this)); // We can get liquidity of any address(used to know wether a account should be liquidated or not)
        require(error == 0, "Error");
        // comptroller.getAccountLiquidity(address(this)) returns:
            // uint error -> error code, if 0 then all good. Other than 0, some error is there
            // uint liquidity -> USD amount of asset we can borrow upto (scaled up by le18)
            // uint shortfall -> if this is >0, then given address is subject to liquidation (scaled up by le18)
        // Note: At most one of liquidity or shortfall shall be non-zero.
            // normal circumstance - liquidity > 0 and shortfall == 0
            // liquidity > 0 means account can borrow up to `liquidity`
            // shortfall > 0 is subject to liquidation, you borrowed over limit
        return(liquidity, shortfall);
    }


    //

}
