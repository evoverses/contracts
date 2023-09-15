const { ethers } = require("hardhat")
require("dotenv").config()

const originalDisbursements = [{"amount":28334,"address":"0x784ca853277fe20b17c06C63958ADd91b047c166"},{"amount":56667,"address":"0x5560ea6c7f764bC49688E168A19B035c99EfA2cE"},{"amount":11334,"address":"0x0e97D72a5f07e288AaB1aBe66F831bE64C7853B1"},{"amount":56667,"address":"0xe9E0f19A41B3972383B603B667950e8fa603600E"},{"amount":25513,"address":"0x50aE5984f31ea1cD581D9883E3BEa971A3754946"},{"amount":42501,"address":"0xe0AB50Bb4EeB58DD8D1F0D8B758f7D573d06BA26"},{"amount":51001,"address":"0x162d0A0f7290e8fc983698D53D3Efe4Ba7F4499f"},{"amount":15584,"address":"0x41f20d9B73b0c0A473a0804cfA90016e2D66C0F9"},{"amount":56724,"address":"0x2a74b4e05BB82C03c17FaDd73b13F5b651597E65"},{"amount":11447,"address":"0x366Ec35fe5f667762B4cC21Fcc65B55EFb39691E"},{"amount":36834,"address":"0xEC8D43b6982daC8DfFC1294d79e494aABEE743eA"},{"amount":566669,"address":"0x0767b2Bc858E6089EA52539842e649Ec88680721"},{"amount":56667,"address":"0x8F7464F8115E50b152d04c5Be35d25b5d7d3C3de"},{"amount":42501,"address":"0x0B509B48DD857a27811E97324F360b1d044077d6"},{"amount":56667,"address":"0xc045dc7d059ad101691C545c319a496c703894b3"},{"amount":113334,"address":"0x94B56330aE10dcf0463660Cc8A4ae06C1Fa13159"},{"amount":28334,"address":"0xcBCcA505aA6908cD6Fbd4e78064A0a68B7DC10Cc"},{"amount":5667,"address":"0xB61dfCb9379027254ba458eE18FFB0F9cE25D088"},{"amount":11334,"address":"0x37732d06BA9fC502fCC51069F9938Fc5E6BC781F"},{"amount":56667,"address":"0x8D661227A1e671780f71bFdbC83A2a9b80c3A1Fb"},{"amount":42501,"address":"0xcC852b08EF9bED533e63DE253D9d15cD865Bac5d"},{"amount":11334,"address":"0x989f4C3181a64aa7d52d400c7c245b6384cAb4EA"},{"amount":38961,"address":"0x2f4636D0DFFa872FF23eB48daD7843b349a2E711"},{"amount":30657,"address":"0xE54503E19133976141618b00Dfc894c35A73D5fd"},{"amount":28334,"address":"0x640F5fb43aEfcE2b4A3c22F204862723Bb08e6EB"},{"amount":59744,"address":"0x3352BC3BC7Ee9AF2B1c277aD90d5a2170D4904B6"},{"amount":5877,"address":"0x1b3cf414fdcD12B71Df6A9c6b1741A5128EA3dc8"},{"amount":13076,"address":"0x993beAFe52055532E95999ccEf6E8F226efD9809"},{"amount":28334,"address":"0x343f50d9C79a78008283A3b109DE97f3fd738F1C"},{"amount":34378,"address":"0x87e3C488D2183aCdb4e9b33D905E3086faeC33a8"},{"amount":56667,"address":"0x7b32fC6E42150b0316b2c7E6C913FFf944f873dB"},{"amount":8501,"address":"0xEaA91737c1F7Ee983FbC90177DDf4388f90a4BC3"},{"amount":28334,"address":"0x2F3059dbfbb208cD6027fd2ea7650179a138e1e4"},{"amount":6064,"address":"0xa29938d059664F7bCa45E2188E0B5604F3c16fa6"},{"amount":28334,"address":"0xCb67fEFFA39792fe2769796b2407d851faAff9ca"},{"amount":14167,"address":"0xA3bbd6478F9c5f8d940e1ccAD14c6335526E448a"},{"amount":34004,"address":"0xeadCe7a42F0A03A12AB599e4abE199abBe4F75eB"},{"amount":91976,"address":"0xc2893e25d477610db55A2806EB36a830fF520052"},{"amount":34001,"address":"0xef75137087a65F4fFB4FC9159E588Adbe5aEc4f6"},{"amount":85001,"address":"0xF96E38BcE53dbbaa6CB16E7A48c481CB7A97f61E"},{"amount":14167,"address":"0xb0268ea1b14941daF20B3b446f7Dc93b9Cef2b76"},{"amount":28334,"address":"0x5361dea02D6C759B89aA1ee92bA675CeDfa11ba6"},{"amount":90969,"address":"0xB43eDF919Ea51ae7Eae0AB7c7a28E530AabB6d65"},{"amount":42501,"address":"0x424d6e09C17898E5A7E22Fd1BA7428C3a4960d36"},{"amount":55924,"address":"0xA9BC50B12CaE600fEb52266C85E1bfDd94CA5713"},{"amount":17077,"address":"0x7076b74fE5C5D5d3a786B08208924C0d3bd77fA3"},{"amount":14167,"address":"0x7e3d993a8d63c25D1db5F7FF8a8d6C59091003b1"},{"amount":11334,"address":"0xa66e2A7BE720C52476c3765421c57860386bb31e"},{"amount":28334,"address":"0xB338f54a9406ae1d9ae3a71e2588aB9bf3F9624d"},{"amount":5705,"address":"0xC35D62CE9D648Fb2Fdc70E63e9Ef06B4eA2EA315"},{"amount":141668,"address":"0x3f0D41D25467e9d187B9ce9cB280d1b4665b4e5B"},{"amount":14167,"address":"0x43Fb8bC112fc097EA2C6208f4Ba0ba7eD236be36"},{"amount":42501,"address":"0x4E86F05a35Dddb0d8d81B66B8f1398DA392AABbc"},{"amount":8501,"address":"0x5134B770b0DaF559E231aB33Ebd7e5CB9Fc1837b"},{"amount":118856,"address":"0xCbBa166Af38118E61729e5dC105dBAf4F2948Cd0"},{"amount":46090,"address":"0x6322E80EA0e481Db7741bf21259EdD678250164a"},{"amount":16835,"address":"0xE49EC5d3991D69EC8D3e14Bee71cE5E11100583d"},{"amount":56667,"address":"0x9dF9589f197DACEC2f41E1844F44858C1C90D9a9"},{"amount":28334,"address":"0xC00Faf1EBcdEDae0C2a50892Aca58A028b9eefcB"},{"amount":56667,"address":"0x68B6388f57CF22d19F84e7e9BB85907005Ee80dA"},{"amount":31111,"address":"0xb51428EB18eE4504E2b084a6c16F27Dc2Fef3C58"},{"amount":48167,"address":"0x8a8FFf1B41583759b60c6aA2CB45cC4B7a546687"},{"amount":45334,"address":"0x2a574DA84838a051aC65ef69cA1381809B6077cE"},{"amount":28334,"address":"0x213dA5859dDfD7B0291DC27bC9A44482Eb494cFF"},{"amount":8501,"address":"0xB3Fa357917C25C3169c59865974330dADA76e5Bc"},{"amount":31167,"address":"0x9b110CCfC441bEdae0557eff13e2439B824046f7"},{"amount":28334,"address":"0xE1E639EB7Fe8a7C959085fA9536E6986889681C5"},{"amount":5667,"address":"0x3B6DC3415F527Fddfaade9756aEf4A9E50D80694"},{"amount":90667,"address":"0x2D6b080F8460aD3cA94447AFD3C5493c28b4D3e4"},{"amount":11334,"address":"0x7d0C0614086210352D019CeadeF49797735434B2"},{"amount":28334,"address":"0x876a6dA1059e003743c70772B706F30C9AdcF0F4"},{"amount":14167,"address":"0x91FABF1D77db0a69C46fda69A779ac7a801a9e83"},{"amount":14167,"address":"0xc6F6A387aFE4E5AA87e8f3b7EE708c8ED809A7DC"},{"amount":28334,"address":"0x1F9b46626b67Ae43A8eA52BE6AF8dBB5C3455AFe"},{"amount":32208,"address":"0x1085a4AB9053dE45F185490A0eCF3D3769509Be0"},{"amount":56667,"address":"0xEA0099779119773e19d144849556027Ec5d92e1D"},{"amount":42501,"address":"0x8722EcC4d654c566449Cc9ae2b06e2613DC1e8fD"},{"amount":14167,"address":"0xAc002B284Ed0eaC4c56Dc861128d39BEB8E550FA"},{"amount":56667,"address":"0x49eFE190DF1c6A4d0eb4a87cC7A19e7168697D4f"},{"amount":85001,"address":"0x035a3f409119aa2FD2Fac3973eC66dd12fbBAa3d"},{"amount":56667,"address":"0x12e350241C6a6D9926Ce8b64939cd5Fc7CA26ecc"},{"amount":56667,"address":"0x58533FaFbFc8164140724eC688275DE5aAFd5D84"},{"amount":19834,"address":"0x51e625291c9044cD4D57ab28916347b8EdC6afE2"},{"amount":28354,"address":"0x7D660eaCA94e0c51e308207d697d71CBBeC27aC9"},{"amount":56667,"address":"0xeAB6f230939b7478B8F439f3b852547b0590cF05"},{"amount":56667,"address":"0x5fFDFFa9a30B05afcfd5305475ac3F0a428ED488"},{"amount":28334,"address":"0x4b602C4883bd91C4d7bD81dCbf39fD16Bad97135"},{"amount":16842,"address":"0x48c997385113c6b3e483D56B1b7A566d5f19300a"},{"amount":28334,"address":"0x45CA80065B86A1bc905007Fc833bA43446c3Cfc0"},{"amount":28334,"address":"0x305d7517e75C492Da4729249aE21581ffAfa8036"},{"amount":70834,"address":"0xAF85D230901E10DD023C32c293E81C91BF508740"},{"amount":28334,"address":"0x7D9Cbe258cF00CB71F1d2727904d973f1D93Bef7"},{"amount":45334,"address":"0xb273EBA808DDFca3987C4784E4302AD4C9b5Fc34"},{"amount":58934,"address":"0x0FdB3699B949Afae1d800D6c75B47A6b7d953aCf"},{"amount":45772,"address":"0xe436427759511025AEbD01E03a3eC929B64BE12f"},{"amount":28334,"address":"0xD978ddF17Af78114Bd68fFea615577050BB632E3"},{"amount":4118,"address":"0x1Fa1387Ad3B74f0ED8d5312e22906f38bC71f9b0"},{"amount":11334,"address":"0x2504ecb0074F2Fa681DE512F9Ca758e3a1A82Df5"},{"amount":416492,"address":"0x5cFa4AbD4e01cA3A112313385F607CF616c2CCc2"},{"amount":14167,"address":"0xCA1F1f49501cae0F8307946ED76cBCDd6D455F62"},{"amount":38419,"address":"0xEa15AcC519B4ae874BE54fbb89085472d1bFf59b"},{"amount":56667,"address":"0x971aA0301F24F38221D57B10Ad7639E8e240C6b4"},{"amount":20250,"address":"0x483a791B3c628d3aeB46380fe35462CFad04effC"},{"amount":141668,"address":"0xaEa79CB822adae9E1a5D5B7fEd98847d773fd2fD"},{"amount":28334,"address":"0xeD166EaaF27cfF1cFFc9e7192e88392e85F02EaC"},{"amount":14167,"address":"0x9E3012FC1Ca7687a379a442C7BbcEE8835f2885a"},{"amount":6234,"address":"0x5700422b83686cC43ce0818ED070fb037aB70814"},{"amount":468920,"address":"0xb337c6372C0cd1feF25385C32c128404450f4871"},{"amount":170001,"address":"0xcC2B0320e322Ed9B13E049ACF4DdDC905C2f75A1"},{"amount":468920,"address":"0x3D510050fD08bD02C3C91baf5Ded5198F4b175fc"},{"amount":468920,"address":"0x19c9DE3665b7D4f17Cc59D87F62476E5aeD9076f"},{"amount":468920,"address":"0x13327AcA5c36fC27A466C7DAE72C2E5eF33E7fE5"},{"amount":301366,"address":"0x94c528E0e1FD41874EeDF09e2b7381D5eD011e03"},{"amount":468920,"address":"0x06fB8305ebD40D8c75825Ee484BEf312172a0D7F"},{"amount":468920,"address":"0x2a23Ee4D575499ec9AC58dCfD3960C5D3f1F0d3B"},{"amount":468920,"address":"0x80627F1b99D5C6D739e940E11914B152157DD1c2"},{"amount":113334,"address":"0xCFE8a0410Bc17B061005e4f1951C675e17f594f8"},{"amount":301366,"address":"0x0653441ab038D44E1D8C85f1d0D805e8270FFe4f"},{"amount":56667,"address":"0xB4eEBa989aD41A7fa47D345B39b72ecA3008E490"},{"amount":468920,"address":"0x233C30557DebEe2779ac6254D7caF0c523B38831"},{"amount":468920,"address":"0x3d83e3b60f569E2A8834FdAf6bd3e86147AB3e06"},{"amount":468920,"address":"0x0162295a8690ba499Aa34DEb38D50f8DD95C0Dcd"},{"amount":468920,"address":"0xE4bfB6B246CC2C70028827ba0f093CFb94be65Ba"},{"amount":113334,"address":"0x3D1B9b4bb59F0Cfb9dF472a5A484bF6C236cF4Af"},{"amount":468920,"address":"0xC1464d0922e95e1F8f19Fd3fDa6b9CB9BF681735"},{"amount":56667,"address":"0x1128aC0Fa232c6697427e3A235284bb81F38d32c"},{"amount":301366,"address":"0x0f18724c245cB15Ea4a1EFCcdfbcB23F8fc1FB79"},{"amount":468920,"address":"0x9f9F0fAdf9974252Ef624A68B23Ab1cc5A8b240c"},{"amount":468920,"address":"0xD20B976584bF506BAf5cC604D1f0A1B8D07138dA"},{"amount":430285,"address":"0x9A39A3A32a2726D5202da9b9Ac04c6125A29D1Ef"},{"amount":468920,"address":"0xDb1326AdEdf62A7DA0D6f0917c51148FE7Bda7Ca"},{"amount":283335,"address":"0xe2041dEF046f48c0c5b21D0aa80204e98287e7aa"},{"amount":468920,"address":"0xd7E0944b3166E0b7e4c3616d0c13A2fC5627cFA5"},{"amount":340002,"address":"0xAC9E75EB70CBDA1295c274A608Ee5129475ee7e4"},{"amount":468920,"address":"0x817a8f3faA84DFB8927b4E8cb5C606F19f5eDcc1"},{"amount":468920,"address":"0x71601eaeFCbD2E1885345CD326eB17d511EFAf29"},{"amount":301366,"address":"0x8bb8FC2aE445630485394929aECf09386cF68389"},{"amount":56667,"address":"0xE9e753172AB676E76b5F289B55B8B79CE922F066"},{"amount":301366,"address":"0x1d1653A4F05abC69EE1D995624AB5F004a0b38a2"},{"amount":588858,"address":"0x720BA4FBbdDb0A5281B4bb509905C03074E0386B"}]
const remainingWallets = [
  "0x4082e997ec720a4894efec53b0d9aabfeea44cbe", "0xb43edf919ea51ae7eae0ab7c7a28e530aabb6d65",
  "0x7b32fc6e42150b0316b2c7e6c913fff944f873db", "0x0162295a8690ba499aa34deb38d50f8dd95c0dcd",
  "0xe49ec5d3991d69ec8d3e14bee71ce5e11100583d", "0xb338f54a9406ae1d9ae3a71e2588ab9bf3f9624d",
  "0xdb1326adedf62a7da0d6f0917c51148fe7bda7ca", "0x424d6e09c17898e5a7e22fd1ba7428c3a4960d36",
  "0x989f4c3181a64aa7d52d400c7c245b6384cab4ea", "0xea15acc519b4ae874be54fbb89085472d1bff59b",
  "0x720ba4fbbddb0a5281b4bb509905c03074e0386b", "0x7d0c0614086210352d019ceadef49797735434b2",
  "0x7d660eaca94e0c51e308207d697d71cbbec27ac9", "0xc045dc7d059ad101691c545c319a496c703894b3",
  "0x640f5fb43aefce2b4a3c22f204862723bb08e6eb", "0xcbcca505aa6908cd6fbd4e78064a0a68b7dc10cc",
  "0x1128ac0fa232c6697427e3a235284bb81f38d32c", "0xed166eaaf27cff1cffc9e7192e88392e85f02eac",
  "0x9a39a3a32a2726d5202da9b9ac04c6125a29d1ef", "0x8722ecc4d654c566449cc9ae2b06e2613dc1e8fd",
  "0xe436427759511025aebd01e03a3ec929b64be12f", "0xef75137087a65f4ffb4fc9159e588adbe5aec4f6",
  "0xeab6f230939b7478b8f439f3b852547b0590cf05", "0x51e625291c9044cd4d57ab28916347b8edc6afe2",
  "0x41f20d9b73b0c0a473a0804cfa90016e2d66c0f9", "0xe9e0f19a41b3972383b603b667950e8fa603600e",
  "0xf96e38bce53dbbaa6cb16e7a48c481cb7a97f61e", "0x3f0d41d25467e9d187b9ce9cb280d1b4665b4e5b",
  "0xd7e0944b3166e0b7e4c3616d0c13a2fc5627cfa5", "0x2d6b080f8460ad3ca94447afd3c5493c28b4d3e4",
  "0x4e86f05a35dddb0d8d81b66b8f1398da392aabbc", "0xa66e2a7be720c52476c3765421c57860386bb31e",
  "0x1f9b46626b67ae43a8ea52be6af8dbb5c3455afe", "0x162d0a0f7290e8fc983698d53d3efe4ba7f4499f",
  "0x5134b770b0daf559e231ab33ebd7e5cb9fc1837b", "0x2f3059dbfbb208cd6027fd2ea7650179a138e1e4",
  "0x8a8fff1b41583759b60c6aa2cb45cc4b7a546687", "0x45ca80065b86a1bc905007fc833ba43446c3cfc0",
  "0x1085a4ab9053de45f185490a0ecf3d3769509be0", "0xe0ab50bb4eeb58dd8d1f0d8b758f7d573d06ba26",
  "0xb61dfcb9379027254ba458ee18ffb0f9ce25d088", "0xa9bc50b12cae600feb52266c85e1bfdd94ca5713",
  "0x8bb8fc2ae445630485394929aecf09386cf68389", "0x5560ea6c7f764bc49688e168a19b035c99efa2ce",
  "0xb4eeba989ad41a7fa47d345b39b72eca3008e490", "0x0653441ab038d44e1d8c85f1d0d805e8270ffe4f",
  "0x94c528e0e1fd41874eedf09e2b7381d5ed011e03", "0xe4bfb6b246cc2c70028827ba0f093cfb94be65ba",
  "0xa3bbd6478f9c5f8d940e1ccad14c6335526e448a", "0x5ffdffa9a30b05afcfd5305475ac3f0a428ed488",
  "0x876a6da1059e003743c70772b706f30c9adcf0f4", "0xb273eba808ddfca3987c4784e4302ad4c9b5fc34",
  "0x2a23ee4d575499ec9ac58dcfd3960c5d3f1f0d3b", "0xc00faf1ebcdedae0c2a50892aca58a028b9eefcb",
  "0x37732d06ba9fc502fcc51069f9938fc5e6bc781f", "0xcb67feffa39792fe2769796b2407d851faaff9ca",
  "0xd978ddf17af78114bd68ffea615577050bb632e3", "0x784ca853277fe20b17c06c63958add91b047c166",
  "0x0fdb3699b949afae1d800d6c75b47a6b7d953acf", "0x817a8f3faa84dfb8927b4e8cb5c606f19f5edcc1",
  "0x71601eaefcbd2e1885345cd326eb17d511efaf29", "0x9b110ccfc441bedae0557eff13e2439b824046f7",
  "0xeaa91737c1f7ee983fbc90177ddf4388f90a4bc3", "0xec8d43b6982dac8dffc1294d79e494aabee743ea",
  "0x19c9de3665b7d4f17cc59d87f62476e5aed9076f", "0x9df9589f197dacec2f41e1844f44858c1c90d9a9",
  "0x0b509b48dd857a27811e97324f360b1d044077d6", "0xaf85d230901e10dd023c32c293e81c91bf508740",
  "0x5361dea02d6c759b89aa1ee92ba675cedfa11ba6", "0xcbba166af38118e61729e5dc105dbaf4f2948cd0",
  "0xeadce7a42f0a03a12ab599e4abe199abbe4f75eb", "0x213da5859ddfd7b0291dc27bc9a44482eb494cff",
  "0xe2041def046f48c0c5b21d0aa80204e98287e7aa", "0x87e3c488d2183acdb4e9b33d905e3086faec33a8",
  "0x06fb8305ebd40d8c75825ee484bef312172a0d7f", "0x2a74b4e05bb82c03c17fadd73b13f5b651597e65",
  "0x5cfa4abd4e01ca3a112313385f607cf616c2ccc2", "0xc2893e25d477610db55a2806eb36a830ff520052",
  "0x94b56330ae10dcf0463660cc8a4ae06c1fa13159", "0x0f18724c245cb15ea4a1efccdfbcb23f8fc1fb79",
  "0x12e350241c6a6d9926ce8b64939cd5fc7ca26ecc", "0x2a574da84838a051ac65ef69ca1381809b6077ce",
  "0xe1e639eb7fe8a7c959085fa9536e6986889681c5", "0xcfe8a0410bc17b061005e4f1951c675e17f594f8",
  "0xe54503e19133976141618b00dfc894c35a73d5fd", "0xb337c6372c0cd1fef25385c32c128404450f4871",
  "0x13327aca5c36fc27a466c7dae72c2e5ef33e7fe5", "0xa29938d059664f7bca45e2188e0b5604f3c16fa6",
  "0x68b6388f57cf22d19f84e7e9bb85907005ee80da", "0xea0099779119773e19d144849556027ec5d92e1d",
  "0x035a3f409119aa2fd2fac3973ec66dd12fbbaa3d", "0x7076b74fe5c5d5d3a786b08208924c0d3bd77fa3",
  "0x3d510050fd08bd02c3c91baf5ded5198f4b175fc", "0x233c30557debee2779ac6254d7caf0c523b38831",
  "0xcc2b0320e322ed9b13e049acf4dddc905c2f75a1", "0x343f50d9c79a78008283a3b109de97f3fd738f1c",
  "0x3d83e3b60f569e2a8834fdaf6bd3e86147ab3e06", "0x2504ecb0074f2fa681de512f9ca758e3a1a82df5",
  "0x9f9f0fadf9974252ef624a68b23ab1cc5a8b240c", "0x0767b2bc858e6089ea52539842e649ec88680721",
  "0x41c40f04b11e0d324be8d3adfff4ee9d5e0e3c08", "0x49efe190df1c6a4d0eb4a87cc7a19e7168697d4f",
]
async function update() {
  const accounts = await ethers.getSigners()

  const contract = await ethers.getContractAt("vEVOUpgradeable", "0x53f0E805bDFa8418213aC7e306e1C0B6c9e44714", accounts[0])

  const total = remainingWallets.length;
  const failedWallets = [];
  const emptyWallets = [];
  let i = 0;
  while (i < total) {
    try {
      console.log(`Vesting wallet (${i+1}/${total})`, remainingWallets[i]);
      const gas = await contract.estimateGas.adminVestWallet(remainingWallets[i]);
      const tx = await contract.adminVestWallet(remainingWallets[i]);
      await tx.wait(1);
      i++;
    } catch (e) {
      if (e.reason === "execution reverted: No vEVO in wallet") {
        console.error(`No vEVO in ${remainingWallets[i]}`);
        emptyWallets.push(remainingWallets[i]);
        i++;
      } else {
        console.error(`Failed to vest ${remainingWallets[i]}`, e);
        failedWallets.push(remainingWallets[i]);
      }

    }
  }
  console.log("FailedWallets:", JSON.stringify(failedWallets));
}

update()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
