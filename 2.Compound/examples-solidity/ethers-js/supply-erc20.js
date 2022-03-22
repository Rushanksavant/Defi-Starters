/**
 * Executes our contract's `supplyErc20ToCompound` function
 * 
 * ## run the localhost fork and deploy script prior to this one
 * npx hardhat run scripts/deploy.js --network localhost
 * 
 */
const ethers = require('ethers');
const myABIs = require('./abi.js');
const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');

// Set up a wallet using one of Ganache's key pairs.
// Don't use this key outside of your local test environment.
const privateKey = '0xb8c1b5c1d81f9475fdf2e334517d29f733bdfa40682207571b12fc1142cbf329';

const wallet = new ethers.Wallet(privateKey, provider);
const myWalletAddress = wallet.address;

// `myContractAddress` is logged when running the deploy script.
// Run the deploy script prior to running this one.
const myContractAddress = '0xEcA3eDfD09435C2C7D2583124ca9a44f82aF1e8b';
const myAbi = require('../../artifacts/contracts/MyContracts.sol/MyContract.json').abi;
const myContract = new ethers.Contract(myContractAddress, myAbi, wallet);

// Mainnet Contract for the underlying token https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f
const underlyingAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const erc20AbiJson = myABIs.erc20AbiJson;
const underlying = new ethers.Contract(underlyingAddress, erc20AbiJson, wallet);

// Mainnet Contract for cDAI (https://compound.finance/docs#networks)
const cTokenAddress = '0x5d3a536e4d6dbd6114cc1ead35777bab948e3643';
const cTokenAbi = myABIs.cTokenAbi;
const cToken = new ethers.Contract(cTokenAddress, cTokenAbi, wallet);

const assetName = 'DAI'; // for the log output lines
const underlyingDecimals = 18; // Number of decimals defined in this ERC20 token's contract

const main = async function () {
  const contractIsDeployed = (await provider.getCode(myContractAddress)) !== '0x';

  if (!contractIsDeployed) {
    throw Error('MyContract is not deployed! Deploy it by running the deploy script.');
  }

  console.log(`Now transferring ${assetName} from my wallet to MyContract...`);

  let tx = await underlying.transfer(
    myContractAddress,
    (10 * Math.pow(10, underlyingDecimals)).toString() // 10 tokens to send to MyContract
  );
  await tx.wait(1); // wait until the transaction has 1 confirmation on the blockchain

  console.log(`MyContract now has ${assetName} to supply to the Compound Protocol.`);

  // Mint some cDAI by sending DAI to the Compound Protocol
  console.log(`MyContract is now minting c${assetName}...`);
  tx = await myContract.supplyErc20ToCompound(
    underlyingAddress,
    cTokenAddress,
    (10 * Math.pow(10, underlyingDecimals)).toString() // 10 tokens to supply
  );
  let supplyResult = await tx.wait(1);

  console.log(`Supplied ${assetName} to Compound via MyContract`);
  // Uncomment this to see the solidity logs
  // console.log(supplyResult.events);

  let balanceOfUnderlying = await cToken.callStatic
    .balanceOfUnderlying(myContractAddress) / Math.pow(10, underlyingDecimals);
  console.log(`${assetName} supplied to the Compound Protocol:`, balanceOfUnderlying);

  let cTokenBalance = await cToken.callStatic.balanceOf(myContractAddress);
  console.log(`MyContract's c${assetName} Token Balance:`, +cTokenBalance / 1e8);

  // Call redeem based on a cToken amount
  const amount = cTokenBalance;
  const redeemType = true; // true for `redeem`

  // Call redeemUnderlying based on an underlying amount
  // const amount = balanceOfUnderlying;
  // const redeemType = false; //false for `redeemUnderlying`

  // Retrieve your asset by exchanging cTokens
  console.log(`Redeeming the c${assetName} for ${assetName}...`);
  tx = await myContract.redeemCErc20Tokens(
    amount,
    redeemType,
    cTokenAddress
  );
  let redeemResult = await tx.wait(1);

  if (redeemResult.events[5].args[1] != 0) {
    throw Error('Redeem Error Code: ' + redeemResult.events[5].args[1]);
  }

  cTokenBalance = await cToken.callStatic.balanceOf(myContractAddress);
  cTokenBalance = +cTokenBalance / 1e8;
  console.log(`MyContract's c${assetName} Token Balance:`, cTokenBalance);
}

main().catch((err) => {
  console.error(err);
});
