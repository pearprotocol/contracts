const { expect } = require("chai");

async function _createToken(tokenFactory, name, symbol) {
  const tx = await tokenFactory.createToken(name, symbol);
  const receipt = await tx.wait()
  return receipt.events.find(({ event }) => event === 'NewToken').args;
}

describe("TokenFactory", function() {
  it("Should return the new greeting once it's changed", async function() {
    const Token = await ethers.getContractFactory("Token");
    const tokenTemplate = await Token.deploy();
    await tokenTemplate.deployed()
    
    const TokenFactory = await ethers.getContractFactory("TokenFactory");
    const tokenFactory = await TokenFactory.deploy(tokenTemplate.address);
    await tokenFactory.deployed();

    expect(await tokenFactory.tokenTemplate()).to.equal(tokenTemplate.address);

    // create new test token
    const createTokenLogArgs = await _createToken(tokenFactory, "Test", "TEST");
    const testTokenAddress = createTokenLogArgs.token;
    const testToken = await Token.attach(testTokenAddress);

    // get token info
    const testTokenInfo = await tokenFactory.tokenInfos(testTokenAddress);

    expect(await testToken.owner()).to.equal(tokenFactory.address);
    expect(testTokenInfo.token).to.equal(testTokenAddress);
    expect(await testToken.decimals()).to.equal(18);
    expect(await testToken.name()).to.equal("Pear: Test");
    expect(await testToken.symbol()).to.equal("PEAR_TEST");

    //
    // Duplication check
    //

    // create new test token
    const createTokenLogArgs2 = await _createToken(tokenFactory, "Test", "TEST");
    const testTokenAddress2 = createTokenLogArgs2.token;
    expect(testTokenAddress2).not.to.equal(testTokenAddress);
  });
});
