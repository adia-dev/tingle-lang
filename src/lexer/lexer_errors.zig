pub const LexerError = error{
    IllegalCharacter,
    OverflowingLiteral,
    UnmatchedDelimiter,
    InvalidNumberFormat,
    UnexpectedEndOfFile,
    UnsupportedCharacterEncoding,
};
