pragma solidity ^0.8.0;

/**
 * @title UTXO-ETH interface
 */
interface IUTXO {

    struct ECPoint {
        uint256 _x;
        uint256 _y;
    }

    struct UTXO {
        ECPoint _c;
        bool _valuable;
    }

    struct Proof {
        uint256 _e0;
        ECPoint[] _c;
        uint256[] _s;
    }

    struct Witness {
        ECPoint _r;
        uint256 _s;
    }

    function initialize(ECPoint memory _commitment, Proof memory _proof) external returns (uint256);

    function deposit(ECPoint memory _publicKey, Witness memory _witness) payable external returns (uint256);

    function withdraw(uint256 _id, address payable _to, uint256 _amount,  Witness memory _witness) external;

    function transfer(uint256[] memory _inputs, uint256[] memory _outputs, Witness memory _witness) external;
}