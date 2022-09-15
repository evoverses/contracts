const { ethers } = require("hardhat")
require("dotenv").config()

const BobaTuringCredit = '0x4200000000000000000000000000000000000020';
const TuringHelper = '0x680e176b2bbdB2336063d0C82961BDB7a52CF13c';
async function main() {
  const account = (await ethers.getSigners())[0];
  const contract = await ethers.getContractAt("IBobaTuringCredit", BobaTuringCredit, account);

  const creditToAdd = "10.0";
  const prepaidBalance = await contract.prepaidBalance(TuringHelper);
  console.log(`BobaTuringCredit Prepaid Balance of EvoVerses TuringHelper (${TuringHelper}) -`, ethers.utils.formatEther(prepaidBalance));

  const turingToken = await contract.turingToken();
  console.log("Turing Token:", turingToken);

  const tokenContract = await ethers.getContractAt("ERC20", turingToken, account);
  const accountBalance = await tokenContract.balanceOf(account.address);
  console.log("Account Balance:", ethers.utils.formatEther(accountBalance));

  //const approveTx = await tokenContract.approve(contract.address, creditToAdd);
  //await approveTx.wait()

  console.log(`Adding ${creditToAdd} BOBA (${creditToAdd.toString()} wei) to BobaTuringCredit (${BobaTuringCredit}) for EvoVerses TuringHelper (${TuringHelper})`)
  const tx = await contract.addBalanceTo(ethers.utils.parseEther("10.0"), TuringHelper);
  await tx.wait(1);
  console.log("Added", ethers.utils.formatEther(creditToAdd), "BOBA to BobaTuringCredit for", TuringHelper);

  const turingPrice = await contract.turingPrice();
  console.log("Turing Price:", ethers.utils.formatEther(turingPrice));

  const getCreditAmount = await contract.getCreditAmount(TuringHelper);
  console.log("Credit amount of", TuringHelper, ":", ethers.utils.formatEther(getCreditAmount));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
