pragma solidity ^0.8.0;

import "./IUTXO.sol";
import "../EllipticCurve.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UTXO is IUTXO {
    using ECDSA for bytes32;

    uint256 public constant N = 32;
    uint256 public constant SECP256K1_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    ECPoint public H = ECPoint(0x87dd0a2e880b43916d11511797fc9639fa44ebec2e36ee7f711d511745502834, 0x43f58f221b1c62788c28bf8b11bb271fb1f466d5e4ee56d1649414d1ca027bea);
    ECPoint public G = ECPoint(0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798, 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8);

    UTXO[] public utxos;

    function initialize(ECPoint memory _commitment, Proof memory _proof) public override returns (uint256) {
        verifyRangeProof(_commitment, _proof);
        uint256 _id = utxos.length;
        utxos[_id] = UTXO(_commitment, false);
        return _id;
    }

    function deposit(ECPoint memory _publicKey) payable public override returns (uint256) {
        (uint256 _x, uint256 _y) = ecScallarMul(H._x, H._y, msg.value);
        (_x, _y) = ecAdd(_x, _y, _publicKey._x, _publicKey._y);
        uint256 _id = utxos.length;
        utxos[_id] = UTXO(ECPoint(_x, _y), true);
        return _id;
    }

    function withdraw(uint256 _id, address payable _to, uint256 _amount, ECPoint memory _publicKey, bytes memory _signature) public override{
        UTXO memory _utxo = utxos[_id];
        require(_utxo._valuable, "utxo should be valuable");

        (uint256 _x, uint256 _y) = ecScallarMul(H._x, H._y, _amount);
        (_x, _y) = ecAdd(_x, _y, _publicKey._x, _publicKey._y);

        require(_x == _utxo._c._x, "invalid commitment: x does not match");
        require(_y == _utxo._c._y, "invalid commitment: y doesn not match");

        address _target = getAddress(_publicKey);
        require(_target == keccak256(abi.encodePacked(_id, _to)).recover(_signature), "invalid signature");

        _to.transfer(_amount);
    }

    function transfer(uint256[] memory _inputs, uint256[] memory _outputs, Witness memory _witness) public override{
        uint256 _x;
        uint256 _y;

        bytes memory _data;

        for (uint _i = 0; _i < _outputs.length; _i++) {
            UTXO memory _utxo  = utxos[_outputs[_i]];
            require(!_utxo._valuable, "utxo should be unvaluable");

            _data = abi.encodePacked(_data, _outputs[_i]);

            if(_i == 0){
                (_x, _y) = (_utxo._c._x, _utxo._c._y);
                continue;
            } 

            (_x, _y) = ecAdd(_utxo._c._x, _utxo._c._y, _x, _y);

            _utxo._valuable = true;
            utxos[_i] = _utxo;
        }

        _data = abi.encodePacked(_data, "constant string");

        for (uint _i = 0; _i < _inputs.length; _i++) {
            UTXO memory _utxo = utxos[_inputs[_i]];
            require(_utxo._valuable, "utxo should be valuable");

            _data = abi.encodePacked(_data, _inputs[_i]);

            (_x, _y) = ecSub(_x, _y, _utxo._c._x, _utxo._c._y);

            _utxo._valuable = false;
            utxos[_i] = _utxo;
        }

        bytes32 _hash = keccak256(_data);
        verifyWitness(ECPoint(_x, _y), _witness, _hash);
    }

    function utxo(uint256 _id) public override view returns (UTXO memory) {
        require(_id < utxos.length, "id out of bounds");
        return utxos[_id];
    }

    function getAddress(ECPoint memory _publicKey) internal pure returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked(_publicKey._x, _publicKey._y));
        return address(uint160(bytes20(_hash)));
    }


    function verifyWitness(ECPoint memory _key, Witness memory _witness, bytes32 _hash) internal view {
        (uint256 _x1, uint256 _y1) = ecBaseScallarMul(_witness._s);
        _hash = keccak256(abi.encodePacked(_hash, _key._x, _key._y));
        

        (uint256 _x2, uint256 _y2) = ecScallarMul(_key._x, _key._y, uint256(_hash));
        (_x2, _y2) = ecSub(_witness._r._x, _witness._r._y, _x2, _y2);

        require(_x1 == _x2, "witnes verification falied: x");
        require(_y1 == _y2, "witnes verification falied: y");
    }


    // function verifyWitness(ECPoint memory _commitment, Witness memory _witness, bytes32 _hash) internal view {
    //     ECPoint[] memory _data = new ECPoint[](2);
    //     _data[0] = _commitment;
    //     _data[1] = _witness._r;
        
    //     bytes32 _e  = keccak256(abi.encodePacked(hash(_data), _hash));

    //     (uint256 _x1, uint256 _y1) = ecScallarMul(_commitment._x, _commitment._y, uint256(_e));
    //     (_x1, _y1) = ecAdd(_x1, _y1, _witness._r._x, _witness._r._y);

    //     (uint256 _hvx, uint256 _hvy) = ecScallarMul(H._x, H._y, _witness._v);
    //     (uint256 _gux, uint256 _guy) = ecBaseScallarMul(_witness._u);
    //     (uint256 _x2, uint256 _y2) = ecAdd(_hvx, _hvy, _gux, _guy);

    //     require(_x1 == _x2, "witnes verification falied: x");
    //     require(_y1 == _y2, "witnes verification falied: y");
    // }

    function verifyRangeProof(ECPoint memory _commitment, Proof memory _proof) internal view{
        require(_proof._c.length == N, "invalid _c length");
        require(_proof._s.length == N, "invalid _s length");

        ECPoint[] memory _r = new ECPoint[](_proof._c.length);

        for (uint _i = 0; _i < N; _i++) {
            (uint256 _sigX, uint256 _sigY) = ecBaseScallarMul(_proof._s[_i]);

            (uint256 _x, uint256 _y) = ecScallarMul(H._x, H._y, pow2(_i));
            (_x, _y) = ecSub(_proof._c[_i]._x, _proof._c[_i]._y, _x, _y);
            (_x, _y) = ecScallarMul(_x, _y, _proof._e0);
            (_x, _y) = ecSub(_sigX, _sigY, _x, _y);

            bytes32  _ei = keccak256(abi.encodePacked(_x, _y));
            (_x, _y) = ecScallarMul(_proof._c[_i]._x, _proof._c[_i]._y, uint256(_ei));
            _r[_i] = ECPoint(_x, _y);
        }

        bytes32 _e0 = hash(_r);

        (uint256 _x, uint256 _y) = (_proof._c[0]._x, _proof._c[0]._y);
        for (uint _i = 0; _i < N; _i++) { 
            (_x, _y) = ecAdd(_x, _y, _proof._c[_i]._x, _proof._c[_i]._y);
        }

        require(uint256(_e0) == _proof._e0);
        require(_x == _commitment._x);
        require(_y == _commitment._y);
    }

    function ecBaseScallarMul(uint256 _k) internal view returns (uint256, uint256) {
        //return EllipticCurve.ecMul(_k, G._x, G._y, 0, SECP256K1_ORDER);
        return ecScallarMul(G._x, G._y, _k);
    }

    function ecScallarMul(uint256 _x, uint256 _y, uint256 _k) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecMul(_k, _x, _y, 0, SECP256K1_ORDER);
    }

    function ecAdd(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecAdd(_x1, _y1, _x2, _y2, 0, SECP256K1_ORDER);
    }

    function ecSub(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecSub(_x1, _y1, _x2, _y2, 0, SECP256K1_ORDER);
    }

    function pow2(uint256 _i) internal pure returns (uint256)  {
        return 2 ** _i;
    }

    function hash(ECPoint[] memory _points) internal pure returns (bytes32) {
        bytes memory _data;
        for (uint _i = 0; _i < _points.length; _i++) {
            _data = abi.encodePacked(_data, _points[_i]._x, _points[_i]._y);
        }

        return keccak256(_data);
    }
}
    