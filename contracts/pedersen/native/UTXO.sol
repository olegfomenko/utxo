pragma solidity ^0.8.0;

import "./IUTXO.sol";
import "../EllipticCurve.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract UTXO is IUTXO {
    using ECDSA for bytes32;

    uint256 public constant N = 8;
    bytes32 public constant DEPOSIT_HASH = 0x2a50cec61cf2e3d092043e80d8a7623335ebd3c95917e08b59b0126ccd01011d;

    ECPoint public H = ECPoint(0x2cb8b246dbf3d5b5d3e9f75f997cd690d205ef2372292508c806d764ee58f4db, 0x1fd7b632da9c73178503346d9ebbb60cc31104b5b8ce33782eaaecaca35c96ba);
    ECPoint public G = ECPoint(0x2f21e4931451bb6bd8032d52b90a81859fd1abba929df94621a716ebbe3456fd, 0x171c62d5d61cc08d176f2ea3fe42314a89b0196ea6c68ed1d9a4c426d47c3232);

    UTXO[] public utxos;

    function initialize(ECPoint memory _commitment, Proof memory _proof) public override returns (uint256) {
        verifyRangeProof(_commitment, _proof);
        uint256 _id = utxos.length;
        utxos.push(UTXO(_commitment, false));
        return _id;
    }

    function deposit(ECPoint memory _publicKey, Witness memory _witness) payable public override returns (uint256) {
        verifyWitness(_publicKey, _witness, DEPOSIT_HASH);

        (uint256 _x, uint256 _y) = ecScalarMul(H._x, H._y, msg.value);
        (_x, _y) = ecAdd(_x, _y, _publicKey._x, _publicKey._y);

        uint256 _id = utxos.length;
        utxos.push(UTXO(ECPoint(_x, _y), true));

        return _id;
    }

    function withdraw(uint256 _id, address payable _to, uint256 _amount, Witness memory _witness) public override{
        UTXO memory _utxo = utxos[_id];
        require(_utxo._valuable, "utxo should be valuable");

        (uint256 _x, uint256 _y) = ecScalarMul(H._x, H._y, _amount);
        (_x, _y) = ecSub(_utxo._c._x, _utxo._c._y, _x, _y);

        bytes32 _hash = hash(abi.encodePacked(_id, _to));
        verifyWitness(ECPoint(_x, _y), _witness, _hash);

        _utxo._valuable = false;
        utxos[_id] = _utxo;

        _to.transfer(_amount);
    }

    function transfer(uint256[] memory _inputs, uint256[] memory _outputs, Witness memory _witness) public override{
        uint256 _x;
        uint256 _y;

        bytes memory _data;

        for (uint _i = 0; _i < _outputs.length; _i++) {
            UTXO memory _utxo  = utxos[_outputs[_i]];
            require(!_utxo._valuable, "utxo should be unvaluable");

            _utxo._valuable = true;
            utxos[_outputs[_i]] = _utxo;

            _data = abi.encodePacked(_data, _outputs[_i]);

            if(_i == 0){
                (_x, _y) = (_utxo._c._x, _utxo._c._y);
                continue;
            }

            (_x, _y) = ecAdd(_utxo._c._x, _utxo._c._y, _x, _y);
        }

        _data = abi.encodePacked(_data, "constant string");

        for (uint _i = 0; _i < _inputs.length; _i++) {
            UTXO memory _utxo = utxos[_inputs[_i]];
            require(_utxo._valuable, "utxo should be valuable");
            _utxo._valuable = false;
            utxos[_inputs[_i]] = _utxo;

            _data = abi.encodePacked(_data, _inputs[_i]);
            (_x, _y) = ecSub(_x, _y, _utxo._c._x, _utxo._c._y);
        }

        bytes32 _hash = hash(_data);
        verifyWitness(ECPoint(_x, _y), _witness, _hash);
    }

    function getAddress(ECPoint memory _publicKey) internal pure returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked(_publicKey._x, _publicKey._y));
        return address(uint160(bytes20(_hash)));
    }

    function verifyWitness(ECPoint memory _key, Witness memory _witness, bytes32 _hash) public view {
        (uint256 _x1, uint256 _y1) = ecBaseScalarMul(_witness._s);
        _hash = hash(abi.encodePacked(_hash, _key._x, _key._y));

        (uint256 _x2, uint256 _y2) = ecScalarMul(_key._x, _key._y, uint256(_hash));
        (_x2, _y2) = ecSub(_witness._r._x, _witness._r._y, _x2, _y2);

        require(_x1 == _x2, "witness verification failed: x");
        require(_y1 == _y2, "witness verification failed: y");
    }

    function verifyRangeProof(ECPoint memory _commitment, Proof memory _proof) public view {
        require(_proof._c.length == N, "invalid _c length");
        require(_proof._s.length == N, "invalid _s length");

        ECPoint[] memory _r = new ECPoint[](N);

        for (uint256 _i = 0; _i < N; _i++) {
            (uint256 _sigX, uint256 _sigY) = ecBaseScalarMul(_proof._s[_i]);
            (uint256 _x, uint256 _y) = ecScalarMul(H._x, H._y, pow2(_i));
            (_x, _y) = ecSub(_proof._c[_i]._x, _proof._c[_i]._y, _x, _y);
            (_x, _y) = ecScalarMul(_x, _y, _proof._e0);
            (_x, _y) = ecSub(_sigX, _sigY, _x, _y);

            bytes32 _ei = hash(abi.encodePacked(_x, _y));
            (_x, _y) = ecScalarMul(_proof._c[_i]._x, _proof._c[_i]._y, uint256(_ei));
            _r[_i] = ECPoint(_x, _y);
        }

        bytes32 _e0 = hashPoints(_r);
        (uint256 _x, uint256 _y) = (_proof._c[0]._x, _proof._c[0]._y);
        for (uint _i = 1; _i < N; _i++) {
            (_x, _y) = ecAdd(_x, _y, _proof._c[_i]._x, _proof._c[_i]._y);
        }

        require(uint256(_e0) == _proof._e0, "failed to verify proof: e0");
        require(_x == _commitment._x,"failed to verify proof: x");
        require(_y == _commitment._y,"failed to verify proof: y");
    }

    function ecBaseScalarMul(uint256 _k) internal view returns (uint256, uint256) {
        return ecScalarMul(G._x, G._y, _k);
    }

    function ecScalarMul(uint256 _x, uint256 _y, uint256 _k) internal view returns (uint256, uint256) {
        uint256[2] memory _res = EllipticCurve.ecMul([_x, _y], _k);
        return (_res[0], _res[1]);
    }

    function ecAdd(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) internal view returns (uint256, uint256) {
        uint256[2] memory _res = EllipticCurve.ecAdd([_x1, _y1], [_x2, _y2]);
        return (_res[0], _res[1]);
    }

    function ecSub(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) internal view returns (uint256, uint256) {
        uint256[2] memory _negP2 = EllipticCurve.ecNeg([_x2, _y2]);
        return ecAdd(_x1, _y1, _negP2[0], _negP2[1]);
    }

    function pow2(uint256 _i) internal pure returns (uint256)  {
        return uint256(2) ** _i;
    }

    function hashPoints(ECPoint[] memory _points) internal pure returns (bytes32) {
        bytes memory _data;
        for (uint _i = 0; _i < _points.length; _i++) {
            _data = abi.encodePacked(_data, _points[_i]._x, _points[_i]._y);
        }

        return hash(_data);
    }

    function hash(bytes memory _data) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(_data)) % EllipticCurve.N);
    }
}
    