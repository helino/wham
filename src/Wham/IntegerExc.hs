module Wham.IntegerExc where

import Wham.AMDefinitions
import Wham.BoolExc()

data IntegerExc = Integer Integer
                | IntegerBottom

instance Show IntegerExc where
    show (Integer i) = show i
    show IntegerBottom = "Bottom"

instance HasBottom IntegerExc where
    isBottom IntegerBottom = True
    isBottom _ = False

instance AMNum IntegerExc where
    (Integer a) + (Integer b) = Integer $ (Prelude.+) a b
    _ + _ = IntegerBottom
    (Integer a) * (Integer b) = Integer $ (Prelude.*) a b
    _ * _ = IntegerBottom
    (Integer a) - (Integer b) = Integer $ (Prelude.-) a b
    _ - _ = IntegerBottom
    (Integer _) / (Integer 0) = IntegerBottom
    (Integer a) / (Integer b) = Integer $ Prelude.div a b
    _ / _ = IntegerBottom
    absInteger (Just a) = Integer a
    absInteger Nothing = IntegerBottom
    (Integer a) <= (Integer b) = absBool $ Just $ (Prelude.<=) a b
    _ <= _ = absBool Nothing
    (Integer a) == (Integer b) = absBool $ Just $ (Prelude.==) a b
    _ == _ = absBool Nothing
