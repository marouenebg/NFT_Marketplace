const network = require ("hardhat")
const {developmentChains} = require ("../helper-hardhat-config")
const {verify} = require ("../utils/verify")

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()

    //args are empty because we don't have a constructor and or the instructor is empty
    let args = []

    const NftMarketplace = await deploy("NftMarketplace", {
        from: deployer,
        args: args, 
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

log("Verifying...")
//Make sure to add etherscan you your hardhat.config to use verify
//await verify(NftMarketplace.address, args)
}

module.exports.tags = ["all", "NFTMarketplace"]