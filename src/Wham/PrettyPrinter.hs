module Wham.PrettyPrinter (showAnalyze) where

import Wham.ControlPoint
import Wham.AST
import Wham.AnalyzerTypes
import Wham.InterpreterTypes
import Wham.SignBoolExcType
import Wham.SignExc
import qualified Data.Map as Map

pprintA :: ArithmeticExp -> String
pprintA (Number i) = show i
pprintA (Variable x) = x
pprintA (Add a1 a2) = (pprintA a1) ++ " + " ++ (pprintA a2)
pprintA (Mul a1 a2) = (pprintA a1) ++ " * " ++ (pprintA a2)
pprintA (Sub a1 a2) = (pprintA a1) ++ " - " ++ (pprintA a2)
pprintA (Div a1 a2) = (pprintA a1) ++ " / " ++ (pprintA a2)

pprintB :: BooleanExp -> String
pprintB (Boolean b) = show b
pprintB (Not b1) = "!" ++ (pprintB b1)
pprintB (And b1 b2) = (pprintB b1) ++ " && " ++ (pprintB b2)
pprintB (Equal a1 a2) = (pprintA a1) ++ " == " ++ (pprintA a2)
pprintB (LessOrEqual a1 a2) = (pprintA a1) ++ " <= " ++ (pprintA a2)

pprintState :: Maybe (Maybe AbstractStackElement, AbstractState, AbstractMode) 
               -> String
pprintState (Just (_,s,_)) = "{ " ++ str ++ "}"
    where 
        str = foldl (\acc (k,v) -> acc ++ k ++ " -> " ++ (show v) ++ ", ") "" $ Map.toList s
pprintState Nothing = "{ unreachable }"

printRHS :: Maybe (Maybe AbstractStackElement, AbstractState, AbstractMode) 
               -> String
printRHS (Just (Just ele, _, _)) = " rhs: " ++ (show ele) ++ 
                                    (printPossibleException ele)
printRHS (Just (Nothing, _, _)) = " rhs: CORRUPT STACK!"
printRHS Nothing = ""

printPossibleException :: AbstractStackElement -> String
printPossibleException (StackInteger AnyS) = " (Possible exception raiser!)"
printPossibleException (StackInteger ErrorS) = " Raises exception!"
printPossibleException (StackBool AnyT) = " (Possible exception raiser!)"
printPossibleException (StackBool ErrorT) = " Raises exception!"
printPossibleException _ = ""

printLast :: Maybe (Maybe AbstractStackElement, AbstractState, AbstractMode) ->
             String
printLast c@(Just (_, s, mode)) = (pprintState c) ++ str
    where
        str = case mode of
                Both -> " possible exceptional termination"
                StateMode Exception -> " exceptional termination"
                StateMode Normal -> " normal termination"
printLast Nothing = "{ unreachable }"


pprint :: StatementCP -> AnalysisMap -> String
pprint (SkipCP cp) am = (pprintState $ Map.lookup cp am) ++ "\nskip"
pprint (AssignCP x a cp) am = str2
    where 
        info = Map.lookup cp am
        str = (pprintState info) ++ (printRHS info) ++ "\n"
        str2 = str ++ x ++ " := " ++ (pprintA a)
pprint (CompoundCP s1 s2) am = str
    where
        str = (pprint s1 am) ++ ";\n" ++ (pprint s2 am)
pprint (IfCP b s1 s2 cp) am = str2
    where
        str = (pprintState $ Map.lookup cp am) ++ "\n"
        str2 = str ++ "if " ++ (pprintB b) ++ "\n" ++ (indent 1 "then") ++ "\n" 
               ++ (indent 2 $ pprint s1 am) ++ "\n" ++ 
              (indent 1 "else") ++ "\n" ++ (indent 2 $ pprint s2 am)
pprint (WhileCP b body _ cp) am = str2
    where
        str = (pprintState $ Map.lookup cp am) ++ "\n"
        str2 = str ++
              "while " ++ (pprintB b) ++ " do\n" ++ (indent 1 $ pprint body am)
pprint (TryCatchCP s1 s2 cp) am = str2
    where
        str = (pprintState $ Map.lookup cp am) ++ "\n"
        str2 = str ++ "try\n" ++ (indent 1 $ pprint s1 am) ++ 
              "\ncatch\n" ++ (indent 1 $ pprint s2 am)

showAnalyze :: StatementCP -> AnalysisMap -> String
showAnalyze stm am = str2
    where str = pprint stm am
          str2 = str ++ "\n" ++ (printLast $ Map.lookup (-1) am)

indent :: Int -> (String -> String)
indent i = 
    reverse . tail . reverse . unlines . map (replicate (2*i) ' ' ++) . lines
