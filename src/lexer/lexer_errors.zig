pub const LexerError = error{
    IllegalCharacter,
    InvalidEscapedSequence,
    InvalidNumberFormat,
    InvalidCharSize,
    OverflowingLiteral,
    UnexpectedEndOfFile,
    UnmatchedDelimiter,
    UnsupportedCharacterEncoding,
};
