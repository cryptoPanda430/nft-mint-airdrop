const { expect } = require("chai");
const { ethers } = require("hardhat");
const web3 = require('web3');
const helpers = require("@nomicfoundation/hardhat-network-helpers");

describe("Greeter", function () {
  const airdropAddresses = [
    '0x70997970c51812dc3a010c7d01b50e0d17dc79c8',
    '0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc',
    '0x90f79bf6eb2c4f870365e785982e1f101e93b906',
    '0x15d34aaf54267db7d7c367839aaf71a00a2c6a65',
    '0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc',
  ];
  const baseURI = 'https://gateway.pinata.cloud/ipfs/QmZzLcYPYE3unDQ7x9PFtrfoWuDo/';
  before(async function () {
    [owner, account1, account2] = await ethers.getSigners();
  });

  it("Should return the new greeting once it's changed", async function () {
    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy("My NFT", "NFT", baseURI);
    await nft.deployed();

    // await nft.airdropNfts(airdropAddresses)

    // for (let i = 0; i < airdropAddresses.length; i++) {
    //   let bal = await nft.balanceOf(airdropAddresses[i]);
    //   console.log(`${i + 1}. ${airdropAddresses[i]}: ${bal}`);
    //   expect(bal).to.equal(1);
    // }

    await nft.mint(account1.address, 1);
    await nft.mint(account2.address, 1);
    
    await nft.setBlacklist([account2.address]);

    await nft.connect(account1).approve(account2.address, 0);
    await nft.connect(account1).transferFrom(account1.address, account2.address, 0)

    let a, b, c;
    // a = await nft.walletOfOwner(account1.address);
    a = await nft.blacklisted(account2.address);
      console.log(a, '---');
    // for (i = 0; i < 100; i++) {
    //   b = await nft.TokenTypes(i);
    //   c = await nft.tokenURI(i);
    //   console.log(b, '---');
    //   console.log(c, '---');
    // }
    
  });
});
