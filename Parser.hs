module Parser(
        Statement(..), 
        ArithmeticExp(..), 
        BooleanExp(..), 
        Parser.parse) where

import qualified Text.ParserCombinators.Parsec as P
import Text.ParserCombinators.Parsec.Expr
import qualified Text.ParserCombinators.Parsec.Token as T
import Text.ParserCombinators.Parsec.Language (emptyDef)

-- lexer

lexer :: T.TokenParser ()
lexer = T.makeTokenParser whileDef

whileDef = (emptyDef
              {T.reservedOpNames = ["*", "+", "-", "!", "&", "=", "<=", ":=", 
                                    ";"],
               T.reservedNames = ["true", "false", "skip", "if", "then", 
                                  "else", "while", "do", "try", "catch"],
               T.identStart = letter,
               T.commentLine = "#"
              })

identifier = T.identifier lexer
reservedOp = T.reservedOp lexer
reserved = T.reserved lexer
integer = T.integer lexer
parens = T.parens lexer
whitespace = T.whiteSpace lexer

-- parser

type Parser = P.Parser
letter = P.letter
(<|>) = (P.<|>)
try = P.try
eof = P.eof

data Statement = Skip
               | Assign String ArithmeticExp
               | If BooleanExp Statement Statement 
               | While BooleanExp Statement
               | Compound Statement Statement
               | TryCatch Statement Statement
                 deriving (Show)

data ArithmeticExp = Number Integer
                   | Variable String
                   | Add ArithmeticExp ArithmeticExp
                   | Mul ArithmeticExp ArithmeticExp
                   | Sub ArithmeticExp ArithmeticExp
                   | Div ArithmeticExp ArithmeticExp
                     deriving (Show)

data BooleanExp = Boolean Bool
                | Not BooleanExp
                | And BooleanExp BooleanExp
                | Equal ArithmeticExp ArithmeticExp
                | LessOrEqual ArithmeticExp ArithmeticExp
                  deriving (Show)

parse :: String -> Either P.ParseError Statement
parse s = P.parse parser "" s

parser :: Parser Statement
parser = do whitespace
            result <- statements
            eof
            return result


statements :: Parser Statement
statements = buildExpressionParser statementOperators statement

statement :: Parser Statement
statement =   skip
          <|> conditional 
          <|> while
          <|> assign
          <|> tryCatch
          <|> parens statements

statementOperators :: OperatorTable Char () Statement
statementOperators = [[binary ";" compound AssocLeft]]

compound :: Statement -> Statement -> Statement
compound s1 s2 = Compound s1 s2 

skip :: Parser Statement
skip = do reserved "skip"
          return (Skip)

conditional :: Parser Statement
conditional = do reserved "if"
                 condition <- booleanExpression
                 reserved "then"
                 trueStatement <- statements
                 reserved "else"
                 falseStatement <- statements
                 return (If condition trueStatement falseStatement)

while :: Parser Statement
while = do reserved "while"
           condition <- booleanExpression
           reserved "do"
           s <- statements
           return (While condition s)

assign :: Parser Statement
assign = do name <- identifier
            reservedOp ":="
            value <- arithmeticExpression
            return (Assign name value)

tryCatch :: Parser Statement
tryCatch = do reserved "try"
              s1 <- statements
              reserved "catch"
              s2 <- statements
              return (TryCatch s1 s2)

booleanExpression = buildExpressionParser booleanOperators boolean

boolean :: Parser BooleanExp
boolean =   true 
        <|> false
        <|> try (arithmeticComparison)
        <|> parens booleanExpression

booleanOperators :: OperatorTable Char () BooleanExp
booleanOperators = [[prefix "!" Parser.not],
                    [binary "&" Parser.and AssocLeft]]

arithmeticComparison :: Parser BooleanExp
arithmeticComparison = do { l <- arithmeticExpression;
                            do { reservedOp "=";
                                 equals l}
                          <|>
                            do { reservedOp "<=";
                                 lessOrEquals l}
                           }

equals :: ArithmeticExp -> Parser BooleanExp
equals l  = do r <- arithmeticExpression
               return (Equal l r)

lessOrEquals :: ArithmeticExp -> Parser BooleanExp
lessOrEquals l = do r <- arithmeticExpression
                    return (LessOrEqual l r)

not :: BooleanExp -> BooleanExp
not b = Not b

and :: BooleanExp -> BooleanExp -> BooleanExp
and l r = And l r

true :: Parser BooleanExp
true = do reserved "true"
          return (Boolean True)

false :: Parser BooleanExp
false = do reserved "false"
           return (Boolean False)

arithmeticExpression = buildExpressionParser arithmeticOperators arithmetic

arithmetic :: Parser ArithmeticExp
arithmetic =   number 
           <|> variable
           <|> parens arithmeticExpression

number :: Parser ArithmeticExp
number = do n <- integer
            return (Number n)

variable :: Parser ArithmeticExp
variable = do var <- identifier
              return (Variable var)

arithmeticOperators :: OperatorTable Char () ArithmeticExp
arithmeticOperators = [[binary "*" mul AssocLeft, binary "/" divide AssocLeft],
                       [binary "+" add AssocLeft, binary "-" sub AssocLeft]]

binary symbol operation assoc = Infix (do {reservedOp symbol; 
                                           return operation}) 
                                assoc

prefix symbol operation = Prefix (do { reservedOp symbol; 
                                       return operation })

mul :: ArithmeticExp -> ArithmeticExp -> ArithmeticExp 
mul l r = Mul l r

divide :: ArithmeticExp -> ArithmeticExp -> ArithmeticExp
divide l r = Div l r

add :: ArithmeticExp -> ArithmeticExp -> ArithmeticExp 
add l r = Add l r

sub :: ArithmeticExp -> ArithmeticExp -> ArithmeticExp 
sub l r = Sub l r
