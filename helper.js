const networkConfig = {
  31337: {
    name: 'localhost',
    keyHash: '0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4',
    fee: '100000000000000000' // Juels / WEI
  },
  4: {
    // https://docs.chain.link/docs/vrf-contracts/
    name: 'rinkeby',
    linkToken: '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
    vrfCoordinator: '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
    keyHash: '0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4',
    fee: '100000000000000000' // Juels / WEI
  }
}

module.exports = {
  networkConfig
}