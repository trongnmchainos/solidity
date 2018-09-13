var WalletSimple = artifacts.require("./WalletSimple.sol");


module.exports = function(deployer) {
 deployer.deploy(WalletSimple,['0xcd3eb82c8b0f57118935fb7703ac44a7d1f7f062','0xdfe9945a22f710ee8ed672e019b269bb3d12a4c4','0x6f36ffb6b9e9d84ef21df48a582783194e1aab21']);
};
