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
}

module.exports.tags = ['all', 'rsvg']