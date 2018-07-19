

var Cplayer = artifacts.require("Cplayer");
var Ctontine = artifacts.require("Ctontine");

const ETHER = 10 ** 18;
const DAY = 3600 * 24;

const { increaseTime } = require("./increaseTime");
const{ getBalance } = require("./getBalance");




contract('Cplayer', function(accounts) {
  const [firstAccount,secondAccount,thirdAccount] = accounts;
  let  Cp;
  beforeEach(async function() {
        Cp = await Cplayer.new();
    });

  it(".. should ADD three Players", async () => {

        for (let i = 0; i < 3; i++) {

await Cp.AddPlayer("player"+i,123,{ from: accounts[i] } );
const P1=await Cp.players.call(accounts[i]);
assert.equal(P1[2], accounts[i]);
}  
});

  it(".. should find a player", async () => {
//console.log("admin",accounts[0]);
await Cp.AddPlayer("player1",123,{ from: firstAccount});
const P1=await Cp.findplayer(firstAccount);
assert.equal(P1[0],"player1");

});


    it(".. should authorize Only admin can remove players", async function() {
        let Error;
await Cp.AddPlayer("player1",123,{ from: secondAccount});

try {
     await Cp.RemovePlayer(secondAccount, { from: accounts[2]  });
        } catch (error) {
            Error = error;
        }
        assert.notEqual(Error, undefined, 'Error must be thrown');
        assert.isAbove(Error.message.search('VM Exception while processing transaction: revert'), -1, 'Error: VM Exception while processing transaction: revert');

    });


});



contract('Ctontine', function(accounts) {

  const [firstAccount,secondAccount,thirdAccount] = accounts;
  let  Cp;
  let Ct;
  beforeEach(async function() {
        Cp = await Cplayer.new();
	Ct=await Ctontine.new(Cp.address);

     for (let i = 0; i < 3; i++) {
await Cp.AddPlayer("player"+i,123,{ from: accounts[i] } );
//await Ct.join({ from: accounts[i], value:1*ETHER});

}  
  
  });



    it(".. sould ebable players to join the game", async () => {

await Ct.join({ from: firstAccount, value:1*ETHER});

let P1=await Ct.active_players.call(0);
      assert.equal(P1[0], "player0", "Player active");
});


it(".. should emit 'NewActivePlayerEv' event  when a player join the game", async function() {
     let NewActivePlayerEvtListener = Ct.NewActivePlayerEv();

    await Ct.join({ from: firstAccount, value:1*ETHER});


     let proposalAddedLog = await new Promise(
         (resolve, reject) => NewActivePlayerEvtListener.get(
             (error, log) => error ? reject(error) : resolve(log)
         ));

     assert.equal(proposalAddedLog.length, 1);

     let eventArgs = proposalAddedLog[0].args;
     assert.equal(eventArgs._address, firstAccount);
let time=await Ct.ping_time.call(firstAccount);

assert.equal(eventArgs.time,time.toNumber(),"ping time");

 });

   
  it(".. should send the reward to the last active player", async () => {

// rewind forward the time
await Ct.join({ from: firstAccount, value:1*ETHER});
await Ct.join({ from: secondAccount, value:1*ETHER});
await Ct.join({ from: thirdAccount, value:1*ETHER});

await increaseTime(DAY+1);

await Ct.eliminate(secondAccount,{ from: firstAccount});
await Ct.eliminate(thirdAccount,{ from: firstAccount});

let initialBalance=web3.eth.getBalance(firstAccount).toNumber();

let Nactive=await Ct.remaining_players.call();
assert.equal(Nactive,1,"players not eliminated");

let finalBalance=web3.eth.getBalance(firstAccount).toNumber();
await Ct.claimReward({ from: firstAccount});

assert.equal(finalBalance,initialBalance+3);

});




});

