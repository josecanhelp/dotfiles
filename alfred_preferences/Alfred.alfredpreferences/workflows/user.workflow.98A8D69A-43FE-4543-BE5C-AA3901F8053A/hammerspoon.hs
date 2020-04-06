module Main where

import System.Environment
import Data.List
import Data.Char
import qualified Data.ByteString
import qualified Alfred as AL
import System.Process
import System.Directory

toWordLower :: String -> String
toWordLower a = map toLower a

addProg ::  String -> String -> IO (String)
addProg input list =  if isInfixOf (toWordLower input) (toWordLower list) && list /= ""
				   then do
				   	putStr (AL.addItemBasic ("HSP" ++ list) list  list  "HammerSpoon Workflow")
				   	return "1"
				   else return ""

runningProg :: [String] -> IO ()
runningProg [] = putStr ""
runningProg [ input ] = do
	putStr AL.begin
	progList <- readProcess "/usr/local/bin/hs" [ "-c", "appsRunning()"] ""
	result <- mapM (addProg input) ( lines progList )
	if (dropWhile isSpace $ unlines result) == ""
	then
		putStr (AL.addItem "HSP-NONE" "" "no" "" "Not Found. Try Again." "HammerSpoon Workflow" "icon.png")
	else
		putStr ""
	putStr AL.end

dispatch :: [(String, [String] -> IO ())]
dispatch =  [
		   ("running", runningProg)
		]

main = do
	(command:args) <- getArgs
	let (Just action) = lookup command dispatch
	action args
