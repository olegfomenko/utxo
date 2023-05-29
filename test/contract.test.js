const UTXO = artifacts.require("UTXO");
const EllipticCurve = artifacts.require("EllipticCurve");
const BigNumber = require("bignumber.js");
const {ethers} = require("hardhat");

describe("UTXO", () => {

  let lib;
  let libContract;
  let utxo;
  let utxoContract;

  // Private key: 0x13e4d2c57b16241a763047bf8f862ab630857592a18819f37b9b3c9e8567de65
  let key = {
    "_x": "15639559675625734025795989354902210429480226575270834412335467657634556514696",
    "_y": "13808122845547863717923179222109646155746415390670120415468336630118037023431"
  }
  let keyWitness = {
    "_r": {
      "_x": "4647945016766610320412477344006631128509887830145391045693063972743336143961",
      "_y": "2768426272188056247002295430844248209953159539586093251862926645074409220525"
    },
    "_s": "7560316378136231020841211442295372140678963564588656332438453137217475969138",
  };

  //Private key: 0x2d2f85864452bdbcbe53fdd5f1ee409e84b328fbaaf1e181ca6cb7e0835b143e
  let proof = {
    "_e0": "13034671058037401832908817048035336367329526989899644003788924625503626247858",
    "_c": [{
      "_x": "17979056646482512710524698864988070824432059330759501665507130089297705465596",
      "_y": "2570175629482037843771270919161459323480264688686033459905549247270508495196"
    }, {
      "_x": "20373765310172617382846396574683036124723997020141684300576751797516505478900",
      "_y": "8476829645309238698958382532845244890489137207430062590925020356662531061927"
    }, {
      "_x": "552898175239017113368370429545016982682805612863518156671751933815476816560",
      "_y": "8275004362862740693567089187920434366785936761198314527074619230183590099830"
    }, {
      "_x": "10377777729032061921433461171241956823373312114185476633923433227485584744347",
      "_y": "12322279590770885204970316853139410805031984786270674630567500786421167838326"
    }, {
      "_x": "4403698945948987415469253705475723059327754621782586012335113687178599094270",
      "_y": "18450144525122433397068400722464672577422373050867420056732908248327117418709"
    }, {
      "_x": "8707405927021329386061466631836523786052810346224857029230284296132935670905",
      "_y": "19751279196960492375490317832882253187847435821532199584429309463477774266114"
    }, {
      "_x": "3906565037867939697295024016448496717417913826884138089488564810468003003041",
      "_y": "9867792697002435669184965999570416567218989648682972928840840472947319905997"
    }, {
      "_x": "1204276084593887139760524256939190344877192909004560658658159049418486006848",
      "_y": "3890794892367546158172465598532757807254028773506685734272338847502692023181"
    }],
    "_s": ["1495522051570230179406663470859668607661691606394270219763559437377246644726", "15430260913136356499567031882443201229186498481701731928443907393512072730080", "102948425729567192232428477990740195400503376156816958671822524089449738137", "21734254507685285944872783490831975957951607912162643146463823540757050093263", "14705375676763899593124959025864186312223609658859191728502706405020142212236", "18783393756811084930089698538815852742712371375609281951483725360910131579588", "9886182767163800535576015370045939411275704575986181694726380992944718514183", "12938980618431562759209615974455279554278117472340466460361091296917947948834"]
  }
  let commitment = {
    "_x": "1611360513686692778523105541964476743471363222703219683744043542564564862020",
    "_y": "3561990449211918008297229326967605574726597344799624189917991473773328557609"
  }

  beforeEach(async () => {
    lib = await ethers.getContractFactory("EllipticCurve");
    libContract = await lib.deploy();

    utxo = await ethers.getContractFactory("UTXO",
      {
        libraries: {
          EllipticCurve: libContract.address,
        }
      }
    );

    utxoContract = await utxo.deploy()
  });

  it("Deposit 100wei", async () => {
    await utxoContract.deposit(key, keyWitness, {value: "100"});
    let utxoCreated = await utxoContract.utxos(0);
    console.log(utxoCreated);
  });

  it("Range proof", async() => {
    await utxoContract.verifyRangeProof(commitment, proof);
  });

  it("Initialize UTXO", async () => {
    await utxoContract.initialize(commitment, proof);
    let utxoCreated = await utxoContract.utxos(0);
    console.log(utxoCreated);
  });

  it("Check witness", async() => {
    await utxoContract.verifyWitness(
      {"_x": "15639559675625734025795989354902210429480226575270834412335467657634556514696", "_y": "13808122845547863717923179222109646155746415390670120415468336630118037023431"},
      {
        "_r": {"_x": "5109730908197937793186988043505009936047779970479868047734172723071291139481", "_y": "5695537219841674439580460240695926440179084672260849397819152443008669244519"},
        "_s": "17334092223146687468005548295017179129455424012029209148307492557995637382354",
      },
      "0x2bdad7e530f187ef2cb15881f641bb9020c9b9ee163a934d4b49e7d916baadf9"
    )
  });

  it("Deposit & Withdraw", async () => {
    await utxoContract.deposit(key, keyWitness, {value: "100"});
    let u = await utxoContract.utxos(0);
    assert.equal(u._valuable, true);

    await utxoContract.withdraw(
      0,
      "0xF65F3f18D9087c4E35BAC5b9746492082e186872",
      100,
      {
        "_r": {
          "_x": "16027749843855789499543341052781208687691596897196959868735514864449663931922",
          "_y": "17200311890797201156272678535458899524730867745810239045062404967632337106280"
        },
        "_s": "6588726764565379866919810050369385337140705932980820912972156497528491442968",
      },
    )

    u = await utxoContract.utxos(0);
    assert.equal(u._valuable, false);
  });


  it("Deposit & Initialize & Transfer", async () => {
    await utxoContract.deposit(key, keyWitness, {value: "100"});
    await utxoContract.initialize(commitment, proof);

    let input = await utxoContract.utxos(0);
    assert.equal(input._valuable, true);

    let output = await utxoContract.utxos(1);
    assert.equal(output._valuable, false);


    await utxoContract.transfer([0], [1],
      {
        "_r": {
          "_x": "17121664940841461257542537843583164765236574899240789196012433005513532115071",
          "_y": "6620347158522527305522704779785054649295215964477259343664434486123127475147"
        },
        "_s": "21164695856547312510960673586994436853473220592925260677258060702329315256932",
      },
    );

    input = await utxoContract.utxos(0);
    assert.equal(input._valuable, false);

    output = await utxoContract.utxos(1);
    assert.equal(output._valuable, true);
  })

});