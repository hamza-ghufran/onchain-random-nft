const { networkConfig } = require('../helper')

module.exports = async ({
  getNamedAccounts,
  deployments,
  getChainId
}) => {
  const { deploy, log, get } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = await getChainId()

  let linkTokenAddress, vrfCoordinatorAddress;

  if (Number(chainId) === 31337) {
    // for local test - deploy a fake one
    const linkToken = await get('LinkToken')
    linkTokenAddress = linkToken.address
    const vrfCoordinatorMock = await get('VRFCoordinatorMock')
    vrfCoordinatorAddress = vrfCoordinatorMock.address
  }
  else {
    // for real chains use the real ones
    linkTokenAddress = networkConfig[chainId].linkToken
    vrfCoordinatorAddress = networkConfig[chainId].vrfCoordinator
  }

  const fee = networkConfig[chainId]['fee']
  const keyHash = networkConfig[chainId]['keyHash']

  const params = [vrfCoordinatorAddress, linkTokenAddress, keyHash, fee]

  log("---------------------------------------")

  const RandomSVG = await deploy('RandomSVG', {
    from: deployer,
    args: params,
    log: true
  })

  log("You have deployed your NFT contract!")
  const networkName = networkConfig[chainId]['name']

  log(`Verify with: \n npx hardhat verify --network ${networkName} ${RandomSVG.address} ${params.toString().replace(/,/g, " ")}`)

  // Signer
  const accounts = await hre.ethers.getSigners()
  const signer = accounts[0]

  // fund with Link (for vrf)
  const linkTokenContract = await ethers.getContractFactory("LinkToken")
  const linkToken = new ethers.Contract(linkTokenAddress, linkTokenContract.interface, signer)

  const fundTxn = await linkToken.transfer(RandomSVG.address, fee)
  await fundTxn.wait(1)

  // create NFT - call a random number
  const RandomSVGContract = await ethers.getContractFactory("RandomSVG")
  const randomSVG = new ethers.Contract(RandomSVG.address, RandomSVGContract.interface, signer)

  const creationTxn = await randomSVG.create({ gasLimit: 300000 })
  const receipt = await creationTxn.wait(1)

  // Token ID
  const tokenId = receipt.events[3].topics[2]

  log(`You have made your NFT! Token Number -> ${tokenId.toString()}`)
  log(`Waiting for chainlink node to respond...`)

  if (Number(chainId) === 31337) { // on local chain
    const VRFCoordinatorMock = await deployments.get("VRFCoordinatorMock")
    vrfCoordinator = await ethers.getContractAt("VRFCoordinatorMock", VRFCoordinatorMock.address, signer)

    const vrfTxn = await vrfCoordinator.callBackWithRandomness(receipt.logs[3].topics[1], 77777, randomSVG.address)
    await vrfTxn.wait(1)

    log("Mint Now")

    const finishTxn = await randomSVG.finishMint(tokenId, { gasLimit: 20000000 })
    await finishTxn.wait(1)

    log(`View token uri here: ${await randomSVG.tokenURI(tokenId)}`)
  }

}

module.exports.tags = ['all', 'rsvg']