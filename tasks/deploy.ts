import "@nomiclabs/hardhat-ethers";
import { task } from "hardhat/config";
import { setTimeout } from 'timers/promises';

task("deploy", "Deploy a contract")
  .addParam("name")
  .setAction(async ({ name }, hre) => {
    await hre.run("compile");
    const contractFactory = await hre.ethers.getContractFactory(name);
    console.log("Deploying", name);
    const contract = await contractFactory.deploy();
    await contract.deployed();
    console.log(name, "deployed!");
    console.log("Address:", contract.address);
    console.log("Waiting 5s...");
    await setTimeout(5000);
    console.log("Verifying contract...")
    await hre.run("verify:verify", { address: contract.address })
  });