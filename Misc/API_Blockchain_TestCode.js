var Web3 = require('web3');
var web3 = new Web3(new Web3.providers.HttpProvider("https://eth-goerli.alchemyapi.io/v2/M_Nc57mA_BpcaiaaPqD8J9fprwo1Fgpm"));
// var contract = new web3.eth.Contract(HashABI, 'HashAddress')
var result = web3.eth.call({
    to: "0xE51b2f802E3dFB52522ffd3A9C839D0ac6c91E9f",
    data: "0xd0bb9508"
}).then(function (result){
console.log(result)})
