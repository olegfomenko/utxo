// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUTXO.sol";
import "../EllipticCurve.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UTXO is IUTXO {
    using ECDSA for bytes32;
    using EllipticCurve for EllipticCurve.ECPoint;

    uint256 public constant N = 8;
    bytes32 public constant DEPOSIT_HASH =
        0x2a50cec61cf2e3d092043e80d8a7623335ebd3c95917e08b59b0126ccd01011d;

    EllipticCurve.ECPoint public H =
        EllipticCurve.ECPoint(EllipticCurve.Hx, EllipticCurve.Hy);

    UTXO[] public utxos;

    function initialize(
        EllipticCurve.ECPoint memory _commitment,
        Proof memory _proof
    ) public override returns (uint256) {
        require(
            EllipticCurve.onCurve(_commitment),
            "commitment is not on alt_bn128 curve"
        );
        verifyRangeProof(_commitment, _proof);
        uint256 _id = utxos.length;
        utxos.push(UTXO(_commitment, false));
        return _id;
    }

    function deposit(
        EllipticCurve.ECPoint memory _publicKey,
        Witness memory _witness
    ) public payable override returns (uint256) {
        require(
            EllipticCurve.onCurve(_publicKey),
            "publicKey is not on alt_bn128 curve"
        );
        verifyWitness(_publicKey, _witness, DEPOSIT_HASH);

        EllipticCurve.ECPoint memory _p = H.ecMul(msg.value);
        _p = _p.ecAdd(_publicKey);

        uint256 _id = utxos.length;
        utxos.push(UTXO(_p, true));
        return _id;
    }

    function withdraw(
        uint256 _id,
        address payable _to,
        uint256 _amount,
        Witness memory _witness
    ) public override {
        UTXO memory _utxo = utxos[_id];
        require(_utxo._valuable, "utxo should be valuable");

        EllipticCurve.ECPoint memory _p = H.ecMul(_amount);
        _p = _utxo._c.ecSub(_p);

        bytes32 _hash = hash(abi.encodePacked(_id, _to));
        verifyWitness(_p, _witness, _hash);

        _utxo._valuable = false;
        utxos[_id] = _utxo;

        _to.transfer(_amount);
    }

    function transfer(
        uint256[] memory _inputs,
        uint256[] memory _outputs,
        Witness memory _witness
    ) public override {
        EllipticCurve.ECPoint memory _p;
        bytes memory _data;

        for (uint _i = 0; _i < _outputs.length; _i++) {
            UTXO memory _utxo = utxos[_outputs[_i]];
            require(!_utxo._valuable, "utxo should be unvaluable");

            _utxo._valuable = true;
            utxos[_outputs[_i]] = _utxo;

            _data = abi.encodePacked(_data, _outputs[_i]);

            if (_i == 0) {
                _p = _utxo._c;
                continue;
            }

            _p = _p.ecAdd(_utxo._c);
        }

        _data = abi.encodePacked(_data, "constant string");

        for (uint _i = 0; _i < _inputs.length; _i++) {
            UTXO memory _utxo = utxos[_inputs[_i]];
            require(_utxo._valuable, "utxo should be valuable");
            _utxo._valuable = false;
            utxos[_inputs[_i]] = _utxo;

            _data = abi.encodePacked(_data, _inputs[_i]);
            _p = _p.ecSub(_utxo._c);
        }

        bytes32 _hash = hash(_data);
        verifyWitness(_p, _witness, _hash);
    }

    function getAddress(
        EllipticCurve.ECPoint memory _publicKey
    ) internal pure returns (address) {
        bytes32 _hash = keccak256(
            abi.encodePacked(_publicKey._x, _publicKey._y)
        );
        return address(uint160(bytes20(_hash)));
    }

    function verifyWitness(
        EllipticCurve.ECPoint memory _key,
        Witness memory _witness,
        bytes32 _hash
    ) public view {
        EllipticCurve.ECPoint memory _p1 = EllipticCurve.ecBaseMul(_witness._s);
        _hash = hash(abi.encodePacked(_hash, _key._x, _key._y));

        EllipticCurve.ECPoint memory _p2 = _key.ecMul(uint256(_hash));
        _p2 = _witness._r.ecSub(_p2);
        require(_p1._x == _p2._x, "witness verification failed: x");
        require(_p1._y == _p2._y, "witness verification failed: y");
    }

    function verifyRangeProof(
        EllipticCurve.ECPoint memory _commitment,
        Proof memory _proof
    ) public view {
        require(_proof._c.length == N, "invalid _c length");
        require(_proof._s.length == N, "invalid _s length");

        EllipticCurve.ECPoint[] memory _r = new EllipticCurve.ECPoint[](N);

        for (uint256 _i = 0; _i < N; _i++) {
            EllipticCurve.ECPoint memory _sig = EllipticCurve.ecBaseMul(
                _proof._s[_i]
            );
            EllipticCurve.ECPoint memory _p = H.ecMul(pow2(_i));
            _p = _proof._c[_i].ecSub(_p);
            _p = _p.ecMul(_proof._e0);
            _p = _sig.ecSub(_p);

            bytes32 _ei = hash(abi.encodePacked(_p._x, _p._y));
            _r[_i] = _proof._c[_i].ecMul(uint256(_ei));
        }

        bytes32 _e0 = hashPoints(_r);
        EllipticCurve.ECPoint memory _com = _proof._c[0];
        for (uint _i = 1; _i < N; _i++) {
            _com = _com.ecAdd(_proof._c[_i]);
        }

        require(uint256(_e0) == _proof._e0, "failed to verify proof: e0");
        require(_com._x == _commitment._x, "failed to verify proof: x");
        require(_com._y == _commitment._y, "failed to verify proof: y");
    }

    function pow2(uint256 _i) internal pure returns (uint256) {
        return uint256(2) ** _i;
    }

    function hashPoints(
        EllipticCurve.ECPoint[] memory _points
    ) internal pure returns (bytes32) {
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
