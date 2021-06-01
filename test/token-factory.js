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

  it("Should return buy price properly", async function() {
    const Token = await ethers.getContractFactory("Token");
    const tokenTemplate = await Token.deploy();
    await tokenTemplate.deployed()

    const TokenFactory = await ethers.getContractFactory("TokenFactory");
    const tokenFactory = await TokenFactory.deploy(tokenTemplate.address);
    await tokenFactory.deployed();

    describe("Buy price scenarios", function() {
      const scenarios = [
        { supply: '0', amount: '1', cost: '0.1' },
        { supply: '0', amount: '10', cost: '1' },
        { supply: '0', amount: '45', cost: '4.5' },
        { supply: '0', amount: '450', cost: '45' },
        { supply: '0', amount: '100', cost: '10' },
        { supply: '0', amount: '1000', cost: '100' },
        { supply: '0', amount: '100000', cost: '10000' },
        { supply: '0', amount: '200000', cost: '520000' },

        { supply: '10', amount: '1', cost: '0.1' },
        { supply: '10', amount: '10', cost: '1' },
        { supply: '10', amount: '45', cost: '4.5' },
        { supply: '100', amount: '450', cost: '45' },
        { supply: '100', amount: '100', cost: '10' },

        { supply: '10000', amount: '1', cost: '0.1' },
        { supply: '10000', amount: '10', cost: '1' },
        { supply: '10000', amount: '45', cost: '4.5' },
        { supply: '10000', amount: '450', cost: '45' },
        { supply: '10000', amount: '100', cost: '10' },

        { supply: '100000', amount: '1', cost: '0.10005' },
        { supply: '100000', amount: '10', cost: '1.005' },
        { supply: '100000', amount: '45', cost: '4.60125' },
        { supply: '100000', amount: '100', cost: '10.5' },
        { supply: '100000', amount: '105', cost: '11.05125' },
        { supply: '100000', amount: '450', cost: '55.125' },
        { supply: '100000', amount: '1000', cost: '150' },

        { supply: '1000000', amount: '1', cost: '90.10005' },
        { supply: '1000000', amount: '10', cost: '901.005' },
      ];

      scenarios.forEach(function(value, i) {
        it(`Should pass scenario ${i}: supply ${value.supply}, amount ${value.amount}`, async function() {
          const scenario = value
          const cost = await tokenFactory.buyCost(
            ethers.utils.parseEther(scenario.supply).toString(),
            ethers.utils.parseEther(scenario.amount).toString()
          );
          expect(cost).to.equal(ethers.utils.parseEther(scenario.cost));
        });
      });
    })
  });

  it("Should return sell price properly", async function() {
    const Token = await ethers.getContractFactory("Token");
    const tokenTemplate = await Token.deploy();
    await tokenTemplate.deployed()

    const TokenFactory = await ethers.getContractFactory("TokenFactory");
    const tokenFactory = await TokenFactory.deploy(tokenTemplate.address);
    await tokenFactory.deployed();

    describe("Sell price scenarios", function() {
      const scenarios = [
        { supply: '10', amount: '1', cost: '0.1' },
        { supply: '10', amount: '10', cost: '1' },
        { supply: '100', amount: '100', cost: '10' },

        { supply: '10000', amount: '1', cost: '0.1' },
        { supply: '10000', amount: '10', cost: '1' },
        { supply: '10000', amount: '45', cost: '4.5' },
        { supply: '10000', amount: '450', cost: '45' },
        { supply: '10000', amount: '100', cost: '10' },

        { supply: '100000', amount: '1', cost: '0.1' },
        { supply: '100000', amount: '10', cost: '1' },
        { supply: '100000', amount: '45', cost: '4.5' },
        { supply: '100000', amount: '100', cost: '10' },
        { supply: '100000', amount: '105', cost: '10.5' },
        { supply: '100000', amount: '450', cost: '45' },
        { supply: '100000', amount: '1000', cost: '100' },
        { supply: '100000', amount: '100000', cost: '10000' },

        { supply: '1000000', amount: '1', cost: '90.10005' },
        { supply: '1000000', amount: '10', cost: '901.005' },
        { supply: '1000000', amount: '1000000', cost: '121600000' },
      ];

      scenarios.forEach(function(value, i) {
        it(`Should pass scenario ${i}: supply ${value.supply}, amount ${value.amount}`, async function() {
          const scenario = value
          const cost = await tokenFactory.sellCost(
            ethers.utils.parseEther(scenario.supply).toString(), 
            ethers.utils.parseEther(scenario.amount).toString()
          );
          expect(cost).to.equal(ethers.utils.parseEther(scenario.cost));
        });
      });
    })
  });

  it("Should return buy/sell price properly", async function() {
    const Token = await ethers.getContractFactory("Token");
    const tokenTemplate = await Token.deploy();
    await tokenTemplate.deployed()

    const TokenFactory = await ethers.getContractFactory("TokenFactory");
    const tokenFactory = await TokenFactory.deploy(tokenTemplate.address);
    await tokenFactory.deployed();

    describe("Buy/Sell price scenarios", function() {
      const scenarios = [
        { type: 'buy', supply: '0', amount: '1', cost: '0.1' },
        { type: 'buy', supply: '1', amount: '10', cost: '1' },
        { type: 'buy', supply: '10', amount: '100', cost: '10' },
        { type: 'sell', supply: '111', amount: '1', cost: '0.1' },
        { type: 'sell', supply: '110', amount: '10', cost: '1' },
        { type: 'sell', supply: '100', amount: '100', cost: '10' },

        { type: 'buy', supply: '0', amount: '1000000', cost: '40600000' },
        { type: 'buy', supply: '1000000', amount: '10', cost: '901.005' },
        { type: 'sell', supply: '1000010', amount: '10', cost: '901.015' },
        { type: 'sell', supply: '1000000', amount: '1000000', cost: '121600000' },
      ];

      scenarios.forEach(function(value, i) {
        it(`Should pass scenario ${i}: ${value.type} - supply ${value.supply}, amount ${value.amount}`, async function() {
          const scenario = value
          const cost = await tokenFactory[scenario.type === 'buy' ? 'buyCost' : 'sellCost'](
            ethers.utils.parseEther(scenario.supply).toString(),
            ethers.utils.parseEther(scenario.amount).toString()
          );
          expect(cost).to.equal(ethers.utils.parseEther(scenario.cost));
        });
      });
    })
  });
});
