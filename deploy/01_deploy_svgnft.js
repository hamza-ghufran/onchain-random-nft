const fs = require('fs')

const { networkConfig } = require('../helper')

module.exports = async ({
  getNamedAccounts,
  deployments,
  getChainId
}) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = await getChainId()

  log('<--------------------------------------->')
 
  const SVGNFT = await deploy('SVGNFT', {
    from: deployer,
    log: true
  })

  log(`<<< SVG succesfully deployed to ${SVGNFT.address} >>>`)

  let filepath = './img/triangle.svg'
  let svg = fs.readFileSync(filepath, { encoding: 'utf8' })

  const svgNFTContract = await ethers.getContractFactory('SVGNFT')
  const accounts = await hre.ethers.getSigners()
  const signer = accounts[0]

  const svgNFT = new ethers.Contract(SVGNFT.address, svgNFTContract.interface, signer)
  const networkName = networkConfig[chainId]['name']

  log(`<<< Verify with: \n npx hardhat verify --network ${networkName} ${svgNFT.address} >>>`)

  const txnRes = await svgNFT.create(svg)
  const receipt = await txnRes.wait(1)

  log(`<<< You have made an NFT! >>>`)
  log(`<<< You can view the tokenURI here:: ${await svgNFT.tokenURI(0)} >>>`)
}

module.exports.tags = ['all', 'svg']