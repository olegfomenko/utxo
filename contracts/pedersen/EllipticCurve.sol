pragma solidity >=0.6.0;

/**
 * Referenced from https://github.com/kendricktan/heiswap-dapp/blob/master/contracts/AltBn128.sol
*/

library EllipticCurve {
    /// @notice ECPoint stores the elliptic curve point coordinates.
    struct ECPoint {
        uint256 _x;
        uint256 _y;
    }

    /// @notice Pedersen commitment base point H
    uint256 constant public Hx = 0x2cb8b246dbf3d5b5d3e9f75f997cd690d205ef2372292508c806d764ee58f4db;
    uint256 constant public Hy = 0x1fd7b632da9c73178503346d9ebbb60cc31104b5b8ce33782eaaecaca35c96ba;

    /// @notice Pedersen commitment base point G
    uint256 constant public Gx = 0x2f21e4931451bb6bd8032d52b90a81859fd1abba929df94621a716ebbe3456fd;
    uint256 constant public Gy = 0x171c62d5d61cc08d176f2ea3fe42314a89b0196ea6c68ed1d9a4c426d47c3232;

    /// @notice Number of elements in the field (often called `q`)
    /// n = n(u) = 36u^4 + 36u^3 + 18u^2 + 6u + 1
    uint256 constant public N = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    /// @notice p = p(u) = 36u^4 + 36u^3 + 24u^2 + 6u + 1
    /// Field Order
    uint256 constant public P = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    /// @notice (p+1) / 4
    uint256 constant public A = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;

    function ecAdd(ECPoint memory _p1, ECPoint memory _p2) public view returns (ECPoint memory) {
        uint256[4] memory _i = [_p1._x, _p1._y, _p2._x, _p2._y];
        uint256[2] memory _r;

        assembly {
            // call ecadd precompile
            // inputs are: x1, y1, x2, y2
            if iszero(staticcall(not(0), 0x06, _i, 0x80, _r, 0x40)) {
                revert(0, 0)
            }
        }

        return ECPoint(_r[0], _r[1]);
    }

    function ecMul(ECPoint memory _p, uint256 s) public view returns (ECPoint memory) {
        // With a public key (x, y), this computes p = scalar * (x, y).
        uint256[3] memory _i = [_p._x, _p._y, s];
        uint256[2] memory _r;

        assembly {
            // call ecmul precompile
            // inputs are: x, y, scalar
            if iszero(staticcall(sub(gas(), 2000), 0x07, _i, 0x60, _r, 0x40)) {
                revert(0, 0)
            }
        }

        return ECPoint(_r[0], _r[1]);
    }

    function ecBaseMul(uint256 s) public view returns (ECPoint memory) {
        // With a public key (x, y), this computes p = scalar * (x, y).
        uint256[3] memory _i = [Gx, Gy, s];
        uint256[2] memory _r;

        assembly {
            // call ecmul precompile
            // inputs are: x, y, scalar
            if iszero(staticcall(sub(gas(), 2000), 0x07, _i, 0x60, _r, 0x40)) {
                revert(0, 0)
            }
        }

        return ECPoint(_r[0], _r[1]);
    }

    function ecSub(ECPoint memory _p1, ECPoint memory _p2) internal view returns (ECPoint memory) {
        _p2 = ecNeg(_p2);
        return ecAdd(_p1, _p2);
    }

    function ecNeg(ECPoint memory _p) internal pure returns (ECPoint memory) {
		if (_p._x == 0 && _p._y == 0)
			return _p;
		return ECPoint(_p._x, P - (_p._y % P));
	}

    function onCurve(uint256 x, uint256 y) public pure returns(bool) {
        uint256 beta = mulmod(x, x, P);
        beta = mulmod(beta, x, P);
        beta = addmod(beta, 3, P);

        return onCurveBeta(beta, y);
    }

    function onCurveBeta(uint256 beta, uint256 y) public pure returns(bool) {
        return beta == mulmod(y, y, P);
    }
}