const _TokenType = @import("../token/token_type.zig");
const TokenType = _TokenType.TokenType;
const TokenTypeTag = _TokenType.TokenTypeTag;

pub const Precedence = enum(u8) {
    lowest,
    assignment,
    range,
    logical_or,
    logical_and,
    cmp,
    eq,
    bitwise_or,
    bitwise_and,
    bitwise_shift,
    sum,
    mul,
    cast,
    colon,
    unary,
    function_call,
    field,
    method_call,
    path,

    pub fn from_token_type(token_type: TokenType) Precedence {
        return switch (@as(TokenTypeTag, token_type)) {
            .eqeq, .ne => .eq,
            .lt, .gt, .le, .ge => .cmp,
            .@"or" => .bitwise_or,
            .@"and" => .logical_and,
            .caret => .logical_and,
            .plus, .plusplus, .minus, .minusminus => .sum,
            .slash, .star, .starstar => .mul,
            else => .lowest,
        };
    }
};
