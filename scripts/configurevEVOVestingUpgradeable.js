const { ethers } = require("hardhat")
require("dotenv").config()

const wallets = [{"amount":28334,"address":"0x784ca853277fe20b17c06C63958ADd91b047c166"},{"amount":56667,"address":"0x5560ea6c7f764bC49688E168A19B035c99EfA2cE"},{"amount":11334,"address":"0x0e97D72a5f07e288AaB1aBe66F831bE64C7853B1"},{"amount":56667,"address":"0xe9E0f19A41B3972383B603B667950e8fa603600E"},{"amount":25513,"address":"0x50aE5984f31ea1cD581D9883E3BEa971A3754946"},{"amount":42501,"address":"0xe0AB50Bb4EeB58DD8D1F0D8B758f7D573d06BA26"},{"amount":51001,"address":"0x162d0A0f7290e8fc983698D53D3Efe4Ba7F4499f"},{"amount":15584,"address":"0x41f20d9B73b0c0A473a0804cfA90016e2D66C0F9"},{"amount":56724,"address":"0x2a74b4e05BB82C03c17FaDd73b13F5b651597E65"},{"amount":11447,"address":"0x366Ec35fe5f667762B4cC21Fcc65B55EFb39691E"},{"amount":36834,"address":"0xEC8D43b6982daC8DfFC1294d79e494aABEE743eA"},{"amount":566669,"address":"0x0767b2Bc858E6089EA52539842e649Ec88680721"},{"amount":56667,"address":"0x8F7464F8115E50b152d04c5Be35d25b5d7d3C3de"},{"amount":42501,"address":"0x0B509B48DD857a27811E97324F360b1d044077d6"},{"amount":56667,"address":"0xc045dc7d059ad101691C545c319a496c703894b3"},{"amount":113334,"address":"0x94B56330aE10dcf0463660Cc8A4ae06C1Fa13159"},{"amount":28334,"address":"0xcBCcA505aA6908cD6Fbd4e78064A0a68B7DC10Cc"},{"amount":5667,"address":"0xB61dfCb9379027254ba458eE18FFB0F9cE25D088"},{"amount":11334,"address":"0x37732d06BA9fC502fCC51069F9938Fc5E6BC781F"},{"amount":56667,"address":"0x8D661227A1e671780f71bFdbC83A2a9b80c3A1Fb"},{"amount":42501,"address":"0xcC852b08EF9bED533e63DE253D9d15cD865Bac5d"},{"amount":11334,"address":"0x989f4C3181a64aa7d52d400c7c245b6384cAb4EA"},{"amount":38961,"address":"0x2f4636D0DFFa872FF23eB48daD7843b349a2E711"},{"amount":30657,"address":"0xE54503E19133976141618b00Dfc894c35A73D5fd"},{"amount":28334,"address":"0x640F5fb43aEfcE2b4A3c22F204862723Bb08e6EB"},{"amount":59744,"address":"0x3352BC3BC7Ee9AF2B1c277aD90d5a2170D4904B6"},{"amount":5877,"address":"0x1b3cf414fdcD12B71Df6A9c6b1741A5128EA3dc8"},{"amount":13076,"address":"0x993beAFe52055532E95999ccEf6E8F226efD9809"},{"amount":28334,"address":"0x343f50d9C79a78008283A3b109DE97f3fd738F1C"},{"amount":34378,"address":"0x87e3C488D2183aCdb4e9b33D905E3086faeC33a8"},{"amount":56667,"address":"0x7b32fC6E42150b0316b2c7E6C913FFf944f873dB"},{"amount":8501,"address":"0xEaA91737c1F7Ee983FbC90177DDf4388f90a4BC3"},{"amount":28334,"address":"0x2F3059dbfbb208cD6027fd2ea7650179a138e1e4"},{"amount":6064,"address":"0xa29938d059664F7bCa45E2188E0B5604F3c16fa6"},{"amount":28334,"address":"0xCb67fEFFA39792fe2769796b2407d851faAff9ca"},{"amount":14167,"address":"0xA3bbd6478F9c5f8d940e1ccAD14c6335526E448a"},{"amount":34004,"address":"0xeadCe7a42F0A03A12AB599e4abE199abBe4F75eB"},{"amount":91976,"address":"0xc2893e25d477610db55A2806EB36a830fF520052"},{"amount":34001,"address":"0xef75137087a65F4fFB4FC9159E588Adbe5aEc4f6"},{"amount":85001,"address":"0xF96E38BcE53dbbaa6CB16E7A48c481CB7A97f61E"},{"amount":14167,"address":"0xb0268ea1b14941daF20B3b446f7Dc93b9Cef2b76"},{"amount":28334,"address":"0x5361dea02D6C759B89aA1ee92bA675CeDfa11ba6"},{"amount":90969,"address":"0xB43eDF919Ea51ae7Eae0AB7c7a28E530AabB6d65"},{"amount":42501,"address":"0x424d6e09C17898E5A7E22Fd1BA7428C3a4960d36"},{"amount":55924,"address":"0xA9BC50B12CaE600fEb52266C85E1bfDd94CA5713"},{"amount":17077,"address":"0x7076b74fE5C5D5d3a786B08208924C0d3bd77fA3"},{"amount":14167,"address":"0x7e3d993a8d63c25D1db5F7FF8a8d6C59091003b1"},{"amount":11334,"address":"0xa66e2A7BE720C52476c3765421c57860386bb31e"},{"amount":28334,"address":"0xB338f54a9406ae1d9ae3a71e2588aB9bf3F9624d"},{"amount":5705,"address":"0xC35D62CE9D648Fb2Fdc70E63e9Ef06B4eA2EA315"},{"amount":141668,"address":"0x3f0D41D25467e9d187B9ce9cB280d1b4665b4e5B"},{"amount":14167,"address":"0x43Fb8bC112fc097EA2C6208f4Ba0ba7eD236be36"},{"amount":42501,"address":"0x4E86F05a35Dddb0d8d81B66B8f1398DA392AABbc"},{"amount":8501,"address":"0x5134B770b0DaF559E231aB33Ebd7e5CB9Fc1837b"},{"amount":118856,"address":"0xCbBa166Af38118E61729e5dC105dBAf4F2948Cd0"},{"amount":46090,"address":"0x6322E80EA0e481Db7741bf21259EdD678250164a"},{"amount":16835,"address":"0xE49EC5d3991D69EC8D3e14Bee71cE5E11100583d"},{"amount":56667,"address":"0x9dF9589f197DACEC2f41E1844F44858C1C90D9a9"},{"amount":28334,"address":"0xC00Faf1EBcdEDae0C2a50892Aca58A028b9eefcB"},{"amount":56667,"address":"0x68B6388f57CF22d19F84e7e9BB85907005Ee80dA"},{"amount":31111,"address":"0xb51428EB18eE4504E2b084a6c16F27Dc2Fef3C58"},{"amount":48167,"address":"0x8a8FFf1B41583759b60c6aA2CB45cC4B7a546687"},{"amount":45334,"address":"0x2a574DA84838a051aC65ef69cA1381809B6077cE"},{"amount":28334,"address":"0x213dA5859dDfD7B0291DC27bC9A44482Eb494cFF"},{"amount":8501,"address":"0xB3Fa357917C25C3169c59865974330dADA76e5Bc"},{"amount":31167,"address":"0x9b110CCfC441bEdae0557eff13e2439B824046f7"},{"amount":28334,"address":"0xE1E639EB7Fe8a7C959085fA9536E6986889681C5"},{"amount":5667,"address":"0x3B6DC3415F527Fddfaade9756aEf4A9E50D80694"},{"amount":90667,"address":"0x2D6b080F8460aD3cA94447AFD3C5493c28b4D3e4"},{"amount":11334,"address":"0x7d0C0614086210352D019CeadeF49797735434B2"},{"amount":28334,"address":"0x876a6dA1059e003743c70772B706F30C9AdcF0F4"},{"amount":14167,"address":"0x91FABF1D77db0a69C46fda69A779ac7a801a9e83"},{"amount":14167,"address":"0xc6F6A387aFE4E5AA87e8f3b7EE708c8ED809A7DC"},{"amount":28334,"address":"0x1F9b46626b67Ae43A8eA52BE6AF8dBB5C3455AFe"},{"amount":32208,"address":"0x1085a4AB9053dE45F185490A0eCF3D3769509Be0"},{"amount":56667,"address":"0xEA0099779119773e19d144849556027Ec5d92e1D"},{"amount":42501,"address":"0x8722EcC4d654c566449Cc9ae2b06e2613DC1e8fD"},{"amount":14167,"address":"0xAc002B284Ed0eaC4c56Dc861128d39BEB8E550FA"},{"amount":56667,"address":"0x49eFE190DF1c6A4d0eb4a87cC7A19e7168697D4f"},{"amount":85001,"address":"0x035a3f409119aa2FD2Fac3973eC66dd12fbBAa3d"},{"amount":56667,"address":"0x12e350241C6a6D9926Ce8b64939cd5Fc7CA26ecc"},{"amount":56667,"address":"0x58533FaFbFc8164140724eC688275DE5aAFd5D84"},{"amount":19834,"address":"0x51e625291c9044cD4D57ab28916347b8EdC6afE2"},{"amount":28354,"address":"0x7D660eaCA94e0c51e308207d697d71CBBeC27aC9"},{"amount":56667,"address":"0xeAB6f230939b7478B8F439f3b852547b0590cF05"},{"amount":56667,"address":"0x5fFDFFa9a30B05afcfd5305475ac3F0a428ED488"},{"amount":28334,"address":"0x4b602C4883bd91C4d7bD81dCbf39fD16Bad97135"},{"amount":16842,"address":"0x48c997385113c6b3e483D56B1b7A566d5f19300a"},{"amount":28334,"address":"0x45CA80065B86A1bc905007Fc833bA43446c3Cfc0"},{"amount":28334,"address":"0x305d7517e75C492Da4729249aE21581ffAfa8036"},{"amount":70834,"address":"0xAF85D230901E10DD023C32c293E81C91BF508740"},{"amount":28334,"address":"0x7D9Cbe258cF00CB71F1d2727904d973f1D93Bef7"},{"amount":45334,"address":"0xb273EBA808DDFca3987C4784E4302AD4C9b5Fc34"},{"amount":58934,"address":"0x0FdB3699B949Afae1d800D6c75B47A6b7d953aCf"},{"amount":45772,"address":"0xe436427759511025AEbD01E03a3eC929B64BE12f"},{"amount":28334,"address":"0xD978ddF17Af78114Bd68fFea615577050BB632E3"},{"amount":4118,"address":"0x1Fa1387Ad3B74f0ED8d5312e22906f38bC71f9b0"},{"amount":11334,"address":"0x2504ecb0074F2Fa681DE512F9Ca758e3a1A82Df5"},{"amount":416492,"address":"0x5cFa4AbD4e01cA3A112313385F607CF616c2CCc2"},{"amount":14167,"address":"0xCA1F1f49501cae0F8307946ED76cBCDd6D455F62"},{"amount":38419,"address":"0xEa15AcC519B4ae874BE54fbb89085472d1bFf59b"},{"amount":56667,"address":"0x971aA0301F24F38221D57B10Ad7639E8e240C6b4"},{"amount":20250,"address":"0x483a791B3c628d3aeB46380fe35462CFad04effC"},{"amount":141668,"address":"0xaEa79CB822adae9E1a5D5B7fEd98847d773fd2fD"},{"amount":28334,"address":"0xeD166EaaF27cfF1cFFc9e7192e88392e85F02EaC"},{"amount":14167,"address":"0x9E3012FC1Ca7687a379a442C7BbcEE8835f2885a"},{"amount":6234,"address":"0x5700422b83686cC43ce0818ED070fb037aB70814"},{"amount":468920,"address":"0xb337c6372C0cd1feF25385C32c128404450f4871"},{"amount":170001,"address":"0xcC2B0320e322Ed9B13E049ACF4DdDC905C2f75A1"},{"amount":468920,"address":"0x3D510050fD08bD02C3C91baf5Ded5198F4b175fc"},{"amount":468920,"address":"0x19c9DE3665b7D4f17Cc59D87F62476E5aeD9076f"},{"amount":468920,"address":"0x13327AcA5c36fC27A466C7DAE72C2E5eF33E7fE5"},{"amount":301366,"address":"0x94c528E0e1FD41874EeDF09e2b7381D5eD011e03"},{"amount":468920,"address":"0x06fB8305ebD40D8c75825Ee484BEf312172a0D7F"},{"amount":468920,"address":"0x2a23Ee4D575499ec9AC58dCfD3960C5D3f1F0d3B"},{"amount":468920,"address":"0x80627F1b99D5C6D739e940E11914B152157DD1c2"},{"amount":113334,"address":"0xCFE8a0410Bc17B061005e4f1951C675e17f594f8"},{"amount":301366,"address":"0x0653441ab038D44E1D8C85f1d0D805e8270FFe4f"},{"amount":56667,"address":"0xB4eEBa989aD41A7fa47D345B39b72ecA3008E490"},{"amount":468920,"address":"0x233C30557DebEe2779ac6254D7caF0c523B38831"},{"amount":468920,"address":"0x3d83e3b60f569E2A8834FdAf6bd3e86147AB3e06"},{"amount":468920,"address":"0x0162295a8690ba499Aa34DEb38D50f8DD95C0Dcd"},{"amount":468920,"address":"0xE4bfB6B246CC2C70028827ba0f093CFb94be65Ba"},{"amount":113334,"address":"0x3D1B9b4bb59F0Cfb9dF472a5A484bF6C236cF4Af"},{"amount":468920,"address":"0xC1464d0922e95e1F8f19Fd3fDa6b9CB9BF681735"},{"amount":56667,"address":"0x1128aC0Fa232c6697427e3A235284bb81F38d32c"},{"amount":301366,"address":"0x0f18724c245cB15Ea4a1EFCcdfbcB23F8fc1FB79"},{"amount":468920,"address":"0x9f9F0fAdf9974252Ef624A68B23Ab1cc5A8b240c"},{"amount":468920,"address":"0xD20B976584bF506BAf5cC604D1f0A1B8D07138dA"},{"amount":430285,"address":"0x9A39A3A32a2726D5202da9b9Ac04c6125A29D1Ef"},{"amount":468920,"address":"0xDb1326AdEdf62A7DA0D6f0917c51148FE7Bda7Ca"},{"amount":283335,"address":"0xe2041dEF046f48c0c5b21D0aa80204e98287e7aa"},{"amount":468920,"address":"0xd7E0944b3166E0b7e4c3616d0c13A2fC5627cFA5"},{"amount":340002,"address":"0xAC9E75EB70CBDA1295c274A608Ee5129475ee7e4"},{"amount":468920,"address":"0x817a8f3faA84DFB8927b4E8cb5C606F19f5eDcc1"},{"amount":468920,"address":"0x71601eaeFCbD2E1885345CD326eB17d511EFAf29"},{"amount":301366,"address":"0x8bb8FC2aE445630485394929aECf09386cF68389"},{"amount":56667,"address":"0xE9e753172AB676E76b5F289B55B8B79CE922F066"},{"amount":301366,"address":"0x1d1653A4F05abC69EE1D995624AB5F004a0b38a2"},{"amount":588858,"address":"0x720BA4FBbdDb0A5281B4bb509905C03074E0386B"}]
async function update() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("vEVOUpgradeable", "0x53f0E805bDFa8418213aC7e306e1C0B6c9e44714", accounts[0])

  const addresses = [];
  const amounts = [];
  for (const wallet of wallets) {
    addresses.push(wallet.address);
    amounts.push(ethers.utils.parseEther(wallet.amount.toString() + ".0"));
  }
  const tx = await contract.batchAddInitialBalance(addresses, amounts);
  tx.wait(1);
}

update()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
