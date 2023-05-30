pragma solidity ^0.8.0;

/**
 * @title UTXO-ERC20 interface
 */
interface IUTXO {
    /// @notice UTXO entry contains information about utxo stored in the contract state.
    /// The following information will be stored: token address and corresponding token amount,
    /// owner of the UTXO and spend flag.
    struct UTXO {
        address _token;
        uint256 _amount;
        address _owner;
        bool _spent;
    }

    /// @notice OUTPUT contains information about UTXO to be created with.
    struct OUTPUT {
        uint256 _amount;
        address _owner;
    }

    /// @notice INPUT contains information about UTXO to be spent: its identifier and corresponding signature.
    /// Signed data always contains the UTXO id.
    /// If it is the UTXO trasfer operation, the signed information hash also contains concatinated OUTPUTs data.
    /// If it is the UTXO withdraw operation, the signed information hash also contains the address of receiver.
    struct INPUT {
        uint256 _id;
        bytes _signature;
    }

    /// @notice Depositing ERC20 token to the contract. You should approve the transfer on token contract before.
    /// @param _token ERC20 token address to deposit
    /// @param _amount total amount to deposit
    /// @param _outs array of UTXO information to be created
    function deposit(
        address _token,
        uint256 _amount,
        OUTPUT[] memory _outs
    ) external;

    /// @notice Withdraw ERC20 token from the contract balance.
    /// @param _input UTXO to withdraw
    /// @param _to address withdraw tokens to
    function withdraw(INPUT memory _input, address _to) external;

    /// @notice Transfer token from one UTXO to another
    /// @param _inputs input UTXOs
    /// @param _outputs output UTXOs
    function transfer(
        INPUT[] memory _inputs,
        OUTPUT[] memory _outputs
    ) external;

    /// @notice Get UTXO by id
    /// @param _id UTXO id
    function utxo(uint256 _id) external view returns (UTXO memory);

    event UTXOCreated(uint256 indexed id, address indexed creator);

    event UTXOSpent(uint256 indexed id, address indexed spender);

    event Deposited(
        address indexed token,
        address indexed from,
        uint256 amount
    );

    event Withdrawn(address indexed token, address indexed to, uint256 amount);
}
