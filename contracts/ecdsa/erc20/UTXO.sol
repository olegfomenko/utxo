pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IUTXO.sol";

contract UTXOERC20 is IUTXO {
    using ECDSA for bytes32;

    UTXO[] public utxos;

    function deposit(
        address _token,
        uint256 _amount,
        OUTPUT[] memory _outs
    ) public override {
        require(_outs.length > 0, "empty output");
        require(getOutAmount(_outs) == _amount, "invalid amounts");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        uint256 _id = utxos.length;
        for (uint _i = 0; _i < _outs.length; _i++) {
            UTXO memory _utxo = UTXO(
                _token,
                _outs[_i]._amount,
                _outs[_i]._owner,
                false
            );
            utxos.push(_utxo);
            emit UTXOCreated(_id++, msg.sender);
        }

        emit Deposited(_token, msg.sender, _amount);
    }

    function getOutAmount(
        OUTPUT[] memory _outs
    ) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint _i = 0; _i < _outs.length; _i++) {
            result += _outs[_i]._amount;
        }
        return result;
    }

    function withdraw(INPUT memory _input, address _to) public override {
        require(_input._id < utxos.length, "UTXO id out of bound");

        UTXO memory _utxo = utxos[_input._id];
        require(!_utxo._spent, "UTXO has been spent");

        bytes memory _data = abi.encodePacked(_input._id, _to);
        require(
            _utxo._owner == keccak256(_data).recover(_input._signature),
            "invalid signature"
        );

        utxos[_input._id]._spent = true;
        IERC20(_utxo._token).transfer(_to, _utxo._amount);

        emit UTXOSpent(_input._id, msg.sender);
        emit Withdrawn(_utxo._token, _to, _utxo._amount);
    }

    function transfer(
        INPUT[] memory _inputs,
        OUTPUT[] memory _outputs
    ) public override {
        require(_outputs.length != 0, "invalid out: can not be empty");
        require(_inputs.length != 0, "invalid in: can not be empty");

        uint256 _outAmount = 0;
        bytes memory _data;
        for (uint _i = 0; _i < _outputs.length; _i++) {
            _outAmount += _outputs[_i]._amount;
            _data = abi.encodePacked(
                _data,
                _outputs[_i]._amount,
                _outputs[_i]._owner
            );
        }

        address _token = utxos[_inputs[0]._id]._token;
        uint256 _inAmount = 0;
        for (uint _i = 0; _i < _inputs.length; _i++) {
            require(_inputs[_i]._id < utxos.length, "UTXO id out of bound");
            UTXO memory _utxo = utxos[_inputs[_i]._id];
            require(
                _token == _utxo._token,
                "all UTXO should be for the same token"
            );
            require(!_utxo._spent, "UTXO has been spent");
            require(
                _utxo._owner ==
                    keccak256(abi.encodePacked(_inputs[_i]._id, _data)).recover(
                        _inputs[_i]._signature
                    ),
                "invalid signature"
            );
            _inAmount += _utxo._amount;

            utxos[_inputs[_i]._id]._spent = true;
            emit UTXOSpent(_inputs[_i]._id, msg.sender);
        }

        require(_inAmount == _outAmount, "invalid amounts");
        uint256 _id = utxos.length;
        for (uint _i = 0; _i < _outputs.length; _i++) {
            UTXO memory _newUtxo = UTXO(
                _token,
                _outputs[_i]._amount,
                _outputs[_i]._owner,
                false
            );
            utxos.push(_newUtxo);
            emit UTXOCreated(_id++, msg.sender);
        }
    }

    function utxo(uint256 _id) public view override returns (UTXO memory) {
        require(_id < utxos.length, "UTXO id out of bound");
        return utxos[_id];
    }
}
