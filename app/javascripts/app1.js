// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3 } from 'web3';
import { default as contract } from 'truffle-contract'

import wallet_artifacts from '../../build/contracts/WalletSimple.json'


var Wallet = contract(wallet_artifacts);
var Web3EthAccounts = require('web3-eth-accounts');
var account = new Web3EthAccounts('ws://localhost:8080');

// var candidates = {};

// var tokenPrice = null;

window.App = {
  
  start: function () {
    var self = this;

    // Bootstrap the MetaCoin abstraction for Use.
    Wallet.setProvider(web3.currentProvider);
    
    self.getAddress();
    self.getIndex();
    self.getAddressphu();
  },
  getAddress: function () {
    // Wallet.deployed().then(function (contractInstance) {
    //   $("#address").html(contractInstance.address);
    //   web3.eth.getBalance(contractInstance.address, function (error, result) {
    //     $("#balance").html(web3.fromWei(result.toString()) + " Ether");
    //   });
    // });
    Wallet.at('0x826417e95e0c81fd0cd9711a244626cc71d8354d').then(function(instance) {
        instance.getNextSequenceId().then(function (i){
          alert(i.toString())
        })
    })
  },
  getIndex: function () {
    //alert(Wallet.deployed().getNextSequenceId);
    Wallet.deployed().then(function (contractInstance) {
      contractInstance.getNextSequenceId().then(function (i) {
        $("#index").val(i.toString());
      })
    })
  },
  //---------send coin from contract center-------------------
  Send: function () {
    var self = this;
    let coin = $("#coin").val();
    let data = $("#data").val();
    let address = $("#to_address").val();
    let index = $("#index").val();
    let account = $("#account").val();
    $("#buy-msg").html("Purchase order has been submitted. Please wait.");
    Wallet.deployed().then(function (contractInstance) {
      contractInstance.sendMultiSig(address, web3.toWei(coin, 'ether'), data,
        Math.floor((new Date().getTime()) / 1000) + 60, index,
        web3.sha3('\x19Ethereum Signed Message:\n14trong ngon zai'),
        web3.eth.sign(account, '0x74726f6e67206e676f6e207a6169'),
        { from: web3.eth.accounts[2] }).then(function (v) {
          $("#buy-msg").html("");
        })
    });
    self.start();
  },
  create: function () {
    var a = account.create();
    $("#text").val(a.address);
  },
  //---------------------send coin smart contract extra--------------

  getAddressphu: function () {
    Wallet.deployed().then(function (contractInstance) {
      contractInstance.createForwarder.call().then(function (i) {
        $("#address_phu").val(i.toString());
        web3.eth.getBalance(i.toString(), function (error, result) {
          $("#coin_phu").val(web3.fromWei(result.toString()) + " Ether");
        });
      });

    });
  },
  //-----------------------------------------------------------------
  //-----------------------------Add-----------------------------------
  Add: function () {
    
    var self = this;
    
  //   Wallet.new(['0xa28108a739ed3b2483a6aeca6de98f0066860ef8', '0xd0cec31eb8e85f8b2656c6e2ebfff1e9c4764fb1', '0xb3a2afcc68c40603eefac99e11c89545204b8a6e'],{from: web3.eth.accounts[9], gas: 4700000})
  //   .then(result =>  alert(result.address)
  //  )
  Wallet.new(['0x922cf0b6085dcc158a29979cb27c3ab6922ba09f','0x7832ca8266160a925aaa02ae35bbd1afe8f11491','0xcea221eafc58b2dc9121c41bfcc080b8f0fc4c12'],{from: web3.eth.accounts[3], gas: 4700000})
  .then(function(instance){
    alert(instance.address);
  }).catch(function(err){
    alert("hello trong")
  });
     
    self.start();
  },



};


window.addEventListener('load', function () {
  console.warn("No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
  // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
  window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545"));
  App.start();
});
