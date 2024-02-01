pub const LexerError = error{
    IllegalCharacter,
    InvalidEscapedSequence,
    InvalidNumberFormat,
    OverflowingLiteral,
    UnexpectedEndOfFile,
    UnmatchedDelimiter,
    UnsupportedCharacterEncoding,
};
