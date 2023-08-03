// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library OptionalBool {
    enum Value {
        NULL,
        FALSE,
        TRUE
    }

    function isNull(Value v) internal pure returns (bool) {
        return v == Value.NULL;
    }

    function isFalse(Value v) internal pure returns (bool) {
        return v == Value.FALSE;
    }

    function isTrue(Value v) internal pure returns (bool) {
        return v == Value.TRUE;
    }

    function unwrap(Value v) internal pure returns (bool) {
        return isTrue(v);
    }
}
