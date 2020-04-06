module Alfred (
	begin ,
	end ,
	addItem ,
	addItemBasic ,
	getAlfredDataFileContents ,
	putAlfredDataFileContents ,
	getAlfredCacheFileContents ,
	putAlfredCacheFileContents
	) where

import System.Process
import System.Directory
import System.Environment
import Text.HTML.TagSoup

cacheDirBasic :: String
cacheDirBasic = "/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/"

dataDirBasic :: String
dataDirBasic = "/Library/Application Support/Alfred 2/Workflow Data/"

begin :: String
begin = "<?xml version=\"1.0\"?><items>"

end :: String
end = "</items>"

addItem :: String -> String -> String -> String -> String -> String -> String -> String
addItem a b c d e f g = "<item uid=\"" ++ a ++ "\" arg=\""++ b ++ "\" valid=\""++ c ++ "\" autocomplete=\"" ++ d ++ "\"><title>" ++ e ++ "</title><subtitle>" ++ f ++ "</subtitle><icon>" ++ g ++ "</icon></item>"

addItemBasic ::  String -> String -> String -> String -> String
addItemBasic a b c d = addItem a b "yes" "" c d "icon.png"

getBundleID :: IO (String)
getBundleID = do
	tags <- fmap parseTags $ readFile "info.plist"
	let id = fromTagText $ dropWhile (~/= "<string>") (partitions (~== "<dict>") tags !! 0) !! 1
	return id

getAlfredDataFileContents :: String -> IO (String)
getAlfredDataFileContents fileName = do
	h <- getHomeDirectory
	id <- getBundleID
	let fPath = h ++ dataDirBasic ++ id ++ "/" ++ fileName
	fExist <- doesFileExist fPath
	if fExist
	then do
		contents <- readFile fPath
		return contents
	else
		return ""

putAlfredDataFileContents :: String -> String -> IO ()
putAlfredDataFileContents fileName dataStr = do
	h <- getHomeDirectory
	id <- getBundleID
	writeFile (h ++ dataDirBasic ++ id ++ "/" ++ fileName)  dataStr

getAlfredCacheFileContents :: String -> IO (String)
getAlfredCacheFileContents fileName = do
	h <- getHomeDirectory
	id <- getBundleID
	let fPath = h ++ cacheDirBasic ++ id ++ "/" ++ fileName
	fExist <- doesFileExist fPath
	if fExist
	then do
		contents <- readFile fPath
		return contents
	else
		return ""

putAlfredCacheFileContents :: String -> String -> IO ()
putAlfredCacheFileContents fileName dataStr = do
	h <- getHomeDirectory
	id <- getBundleID
	writeFile (h ++ cacheDirBasic ++ id ++ "/" ++ fileName)  dataStr
