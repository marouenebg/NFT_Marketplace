//mint an NFT and list it
const {ethers} = require ("hardhat")

const PRICE = ethers.utils.parseEther("0.1")

async function mintAndList() {
    const nftMarketplace = await ethers.getContract("NftMarketplace")
    const basicNft = await ethers.getContract("BasicNft")
    console.log("Minting...")
    const mintTx = await basicNft.mintNft()
    const mintingTxReceipt = await mintTx.wait(1)
    const tokenId = mintingTxReceipt.events[0].args.tokenId
    console.log("Approving NFT...")
    const ApproveTx = await basicNft.approve(nftMarketplace.address, tokenId)
    await ApproveTx.wait(1)
    console.log("Listing NFT...")
    const ListingTx = await nftMarketplace.listItem(basicNft.address, tokenId, PRICE)
    await ListingTx.wait(1)
    console.log("Listed")
}


mintAndList()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })