pragma solidity ^0.8.0;

import "../EllipticCurve.sol";

/**
 * @title UTXO-ETH interface
 */
interface IUTXO {
    /// @notice UTXO is a base structure that stores the Pedersen commitment to the amount and _valuable flag.
    struct UTXO {
        EllipticCurve.ECPoint _c;
        bool _valuable;
    }

    /// @notice Proof contains the data to verify Back-Maxwell range proof for Pedersen commitment.
    struct Proof {
        uint256 _e0;
        EllipticCurve.ECPoint[] _c;
        uint256[] _s;
    }

    /// @notice Witness contains the aggregated Schnorr signature for transfer operation.
    struct Witness {
        EllipticCurve.ECPoint _r;
        uint256 _s;
    }

    /// @notice Initializing new UTXO (without deposit). Use to create the transfer output.
    /// No information about amount is required. The Back-Maxwell range proof should be valid.
    /// @param _commitment Pedersen commitment point.
    /// @param _proof  Back-Maxwell range proof.
    function initialize(EllipticCurve.ECPoint memory _commitment, Proof memory _proof) external returns (uint256);

    /// @notice Deposit ETH and create corresponding UTXO.
    /// @param _publicKey Public key: `prv * G`.
    /// @param _witness Schnorr signature for provided public key.
    function deposit(EllipticCurve.ECPoint memory _publicKey, Witness memory _witness) payable external returns (uint256);

    /// @notice Withdraw UTXO.
    /// @param _id UTXO index.
    /// @param _to  Receiver address
    /// @param _amount amount in wei to withdraw.
    /// @param _witness Schnorr signature for UTXO public key.
    function withdraw(uint256 _id, address payable _to, uint256 _amount,  Witness memory _witness) external;

    /// @notice Transfer ETH (anonymous)
    /// @param _inputs Input UTXO index.
    /// @param _outputs Output UTXO index.
    /// @param _witness Schnorr signature for aggregated (output - input) public key.
    function transfer(uint256[] memory _inputs, uint256[] memory _outputs, Witness memory _witness) external;
}