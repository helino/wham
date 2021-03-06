module Wham.AMDefinitions where

import Wham.ControlPoint
import Wham.SignBoolExcType

data AMExpression = PUSH Integer ControlPoint
                  | FETCH String ControlPoint
                  | STORE String ControlPoint
                  | BRANCH [AMExpression] [AMExpression] ControlPoint
                  | LOOP [AMExpression] [AMExpression] ControlPoint
                  | TRY [AMExpression] [AMExpression] ControlPoint
                  | CATCH [AMExpression] ControlPoint
                  | NOOP ControlPoint
                  | TRUE ControlPoint
                  | FALSE ControlPoint
                  | ADD ControlPoint
                  | SUB ControlPoint
                  | MULT ControlPoint
                  | DIV ControlPoint
                  | NEG ControlPoint
                  | EQUAL ControlPoint
                  | LE ControlPoint
                  | AND ControlPoint
                  | ANALYZE ControlPoint
                    deriving (Show, Ord, Eq)

data Choice = Yes | No | Maybe

class HasBottom a where
    isBottom :: a -> Choice

class (Ord a, HasBottom a, Show a) => AMNum a where
    (+) :: a -> a -> a
    (*) :: a -> a -> a
    (-) :: a -> a -> a
    (/) :: a -> a -> a
    (<=) :: (AMBoolean b) => a -> a -> b
    (==) :: (AMBoolean b) => a -> a -> b
    absInteger :: Maybe Integer -> a
    castToNonBottom :: a -> a

class (Ord a, HasBottom a, Show a) => AMBoolean a where
    (&&) :: a -> a -> a
    neg :: a -> a
    absBool :: Maybe Bool -> a
    absSignBoolExc :: SignBoolExc -> a
    cond :: a -> [AMExpression] -> [AMExpression] -> [[AMExpression]]
