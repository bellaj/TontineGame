pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

interface Itontine{


    function join() external payable returns(bool);
    function ping() external returns (bool);
    function eliminate(address a) external  returns(bool);
    function claimReward() external returns (bool);
    event NewActivePlayerEv(address _address ,uint time);
    event eliminatedPlayerEv(address _addrss);
}

 contract Cplayer{


address admin;
    constructor() public {
        admin=msg.sender;
    }
     struct player{
        string name;
        uint PhoneNumber;
        address Paddress;
        uint id;
     }


    mapping(address=>player) public players;

function AddPlayer(string _name, uint256 _phonenumber) public returns (bool){
 players[msg.sender].name=_name;
 players[msg.sender].Paddress=msg.sender;
 players[msg.sender].PhoneNumber=_phonenumber;
return true;
    }


      modifier onlyadmin(){
        require (msg.sender==admin);
        _;
    }
    function RemovePlayer(address _address) public onlyadmin returns (bool) {

        delete players[_address];
        return true;
    }

    function EditPlayer(string _name, uint256 _phonenumber, address _address,uint256 _id) public returns (bool){

        players[msg.sender].name=_name;
        players[msg.sender].PhoneNumber=_phonenumber;
        players[msg.sender].Paddress =_address;
        players[msg.sender].id =_id;
return true;
    }

  function EditPlayer(address _address,uint256 _id)public returns (bool){

        players[_address].id =_id;
        return true;

    }
    function findplayer(address _address) public view returns (string,uint,address){
        return ( players[_address].name, players[_address].PhoneNumber, players[_address].Paddress);
    }

    function exist(address _address) public view returns (bool){
             return  (players[_address].Paddress!=0x00);
    }

function getplayer(address _adress) public view  returns (player){
    return players[_adress];
}
 }


contract Ctontine is Itontine {

    mapping (address => uint256 ) public Tpension; // You can store structs as the values of your mapping, not as the key.
    Cplayer.player[] public active_players;
    Cplayer.player[] public eliminated_players;
    mapping(address=>uint) public ping_time;
    uint256 public Lindex; //change this to index

    Cplayer  Tplayer;

     constructor(address _CplayerAddress) public {
         Tplayer= Cplayer(_CplayerAddress);

    }


    function eliminate(address PlayerAddress) public{  

      require(now> ping_time[PlayerAddress] +1 days );
      delete Tpension[PlayerAddress]; // filled with zeros
      delete active_players[Tplayer.getplayer(PlayerAddress).id];//maybe add id to structs
      Lindex -= Tplayer.getplayer(PlayerAddress).id;
      eliminated_players.push(Tplayer.getplayer(PlayerAddress));
      Tplayer.EditPlayer(msg.sender,0);

      share_pension(PlayerAddress);
      emit eliminatedPlayerEv(PlayerAddress);

  }

  function share_pension(address user)internal returns (bool){
    uint256 remainingP=remaining_players();
    for(uint i=0; i< active_players.length;i++){
        if (active_players[i].Paddress!=0x00)
            Tpension[active_players[i].Paddress]=calcul(Tpension[user],remainingP,18);

        }
            return true;
  }
  
  function calcul(uint a, uint b, uint precision) public pure returns ( uint) {
   require (b!=0);
 
     return a*(10**(precision))/b;
 
 }




  function remaining_players() public view returns (uint256){
    return (active_players.length-eliminated_players.length);
  }

 function join() public payable returns(bool){
    require(Tplayer.exist(msg.sender),"player doesn't exist");
    require(msg.value>=1 ether && Tpension[msg.sender]==0,"send higher pension");
    Tpension[msg.sender]=msg.value;
    Tplayer.EditPlayer(msg.sender,active_players.length);

    active_players.push(Tplayer.getplayer(msg.sender));
    Lindex +=(active_players.length-1);
    ping_time[msg.sender]=now;
    emit NewActivePlayerEv(msg.sender,now);
    return true;
}

function ping() public {

ping_time[msg.sender]=now;

}
 

function claimReward() public returns (bool){
            require(remaining_players()==1);
            active_players[Lindex].Paddress.transfer(address(this).balance);
            return true;
}

}

