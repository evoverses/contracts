import "@nomiclabs/hardhat-ethers";
import '@openzeppelin/hardhat-upgrades';
import { task } from 'hardhat/config';
import { setTimeout } from "timers/promises";

task("upgrade", "Upgrade a transparent proxy contract")
  .addParam("name")
  .addParam("address")
  .setAction(async ({ name, address }, hre) => {
    await hre.run("compile")
    const Contract = await hre.ethers.getContractFactory(name)

    // hre.upgrades.forceImport("0x680e176b2bbdB2336063d0C82961BDB7a52CF13c", Contract, { kind: 'transparent' })
    console.log("Upgrading", name)
    const contract = await hre.upgrades.upgradeProxy(address, Contract, {
      unsafeAllowRenames: true
    })
    console.log(name, "upgraded!")
    const impl = await hre.upgrades.erc1967.getImplementationAddress(contract.address)
    const admin = await hre.upgrades.erc1967.getAdminAddress(contract.address)
    console.log("Proxy:", contract.address)
    console.log("Admin:", admin)
    console.log("Impl:", impl)
    console.log("Waiting 5s...")
    await setTimeout(5000);
    console.log("Verifying implementation contract...")
    await hre.run("verify:verify", { address: impl })
  });