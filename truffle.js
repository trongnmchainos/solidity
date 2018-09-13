// Allows us to use ES6 in our migrations and tests.
require('babel-register')
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "present frame clown clog journey they tribe hold ready acoustic hat talk"
module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*' // Match any network id
    },
    // ropsten: {
    //   provider:function(){
    //     return new HDWalletProvider(mnemonic,"https://ropsten.infura.io/fed80d97623044e0992dcc506888384c")
    //   },
    //   network_id: 3,
    //   gas: 4700000
    // }
  }
}
