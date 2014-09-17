import System.IO
import System.Cmd
import System.Directory
import System.FilePath
import System.Environment

import qualified Data.Text as T
import qualified Data.List as L
import qualified Data.List.Split as S

removeChar :: String -> String -> String
removeChar str ch = T.unpack( T.strip( T.replace (T.pack ch) (T.pack "") (T.pack str)))

tupSyllable :: (a, b, c) -> a
tupSyllable (x, _, _) = x
tupStartTime :: (a, b, c) -> b
tupStartTime (_, y, _) = y
tupDuration :: (a, b, c) -> c
tupDuration (_, _, z) = z

createDir :: String -> IO ()
createDir dir = do
	isDirExisting <- doesDirectoryExist dir
	if isDirExisting
		then return ()
		else createDirectory dir

createClipDirs :: [String] -> IO ()
createClipDirs [] = putStrLn "No avi file was found."
createClipDirs [dir] = do
	createDir dir
	createDir (dir++"_videoOnly")
	createDir (dir++"_audioOnly")
createClipDirs (x:xs) = do
	createClipDirs [x]
	createClipDirs xs

readLines :: FilePath -> IO [String]
readLines = fmap lines . readFile

parseTextFile :: FilePath -> IO [(String,[Char],[Char])]
parseTextFile filepath = do
	lines <- readLines filepath
	--let lineCount = length (tail lines)
	--print ("Total syllable number: " ++ show(lineCount))

	let itemInfoList = [S.splitOn "\t" x | x <- tail lines]
	let clipList = [(removeChar (x!!0) "\"", x!!1, x!! 3) | x <- itemInfoList ]
	return clipList

sortSyllableList :: [(String,String,String)] -> [(String,String,String)]
--sortSyllableList xs =  L.sortBy (\x y -> if (tupSyllable x)>(tupSyllable y) then GT else LT) xs
sortSyllableList xs =  L.sortBy (\x y -> if (tupSyllable x)>(tupSyllable y) then GT else 
							if (tupSyllable x)==(tupSyllable y) then 
								if (read (tupStartTime x) :: Float)>(read (tupStartTime y) :: Float) 
									then GT else LT else LT ) xs

sortSyllableListByStartTime :: [(String,String,String)] -> [(String,String,String)]
sortSyllableListByStartTime xs =  L.sortBy (\x y -> if (read (tupStartTime x) :: Float)> 
							(read (tupStartTime y) :: Float) then GT else LT) xs

groupSyllableList :: [(String,String,String)] -> [[(String,String,String)]]
groupSyllableList xs =  L.groupBy (\x y -> if (tupSyllable x) == (tupSyllable y) then True else False) xs

suffixSyllableList ::  [[(String,String,String)]]-> [(String,String,String)]
suffixSyllableList xs = [ ((tupSyllable (fst y)) ++"_" ++show(snd y), tupStartTime (fst y), 
							tupDuration (fst y)) | x<-xs, y<-zip x [1..]]

writeListFile :: [(String,String,String)] -> FilePath -> IO ()
writeListFile [] fpath = print "Empty string"
writeListFile [x] fpath = do 
	--appendFile "v1/1_1.txt" ("\r\n"++x)
	--inf <- openFile fpath AppendMode
	--hPutStrLn inf (show x)
	--hClose inf
	print (show x)
writeListFile (x:xs) fpath= do 
	writeListFile [x] fpath
	writeListFile xs fpath

segmentVideo :: [(String,[Char],[Char])] -> String -> Float -> IO ()
segmentVideo [clipInfo] basename offsetTime = do 
	let syllable = tupSyllable clipInfo
	let startTime = show((read (tupStartTime clipInfo)::Float) - offsetTime)
	let duration = show((read (tupDuration clipInfo)::Float) + offsetTime*2)

	let avCmd = "ffmpeg\\ffmpeg -i " ++ basename ++ ".MP4 -ss " ++ startTime ++ " -t " 
				++ duration ++ " " ++ basename ++ "/" ++syllable ++ ".MP4"
	let audioOnlyCmd = "ffmpeg\\ffmpeg -i " ++ basename ++ ".MP4 -vn -ss " ++ startTime ++ " -t " 
				++ duration ++ " " ++ basename ++ "_audioOnly/" ++syllable ++ ".wav"
	let videoOnlyCmd = "ffmpeg\\ffmpeg -i " ++ basename ++ ".MP4 -an -ss " ++ startTime ++ " -t " 
				++ duration ++ " " ++ basename ++ "_videoOnly/" ++syllable ++ ".MP4"
	system avCmd
	system audioOnlyCmd
	system videoOnlyCmd
	--print avCmd
	--print audioOnlyCmd
	--print videoOnlyCmd
	print "Finished one clip."
segmentVideo (x:xs) filepath offsetTime = do
	segmentVideo [x] filepath offsetTime
	segmentVideo xs filepath offsetTime

segmentVideos :: [FilePath] -> Float -> IO ()
segmentVideos [filepath] offsetTime = do
	clipList <- parseTextFile filepath
	let toneInfoList = suffixSyllableList (groupSyllableList (sortSyllableList clipList))
	let sortedToneInfoList = sortSyllableListByStartTime toneInfoList
	--print sortedToneInfoList
	--writeListFile sortedToneInfoList "newList.txt"
	segmentVideo sortedToneInfoList (takeBaseName filepath) offsetTime
segmentVideos (x:xs) offsetTime = do
	segmentVideos [x] offsetTime
	segmentVideos xs offsetTime

defaultOffsetTime = 0.2
setOffsetTime :: [String] -> Float
setOffsetTime [] = defaultOffsetTime
setOffsetTime (x:xs) = read x::Float

main = do
	args <- getArgs
	let offsetTime = setOffsetTime args

	currentDir <- getCurrentDirectory 
	filesInDir <- getDirectoryContents currentDir
	let videoPaths = [ x|x<-filesInDir, L.isInfixOf ".MP4" x ]
	let videoBaseNames = [takeBaseName x|x<-videoPaths]
	--let creationIoList = [createDirectory x|x<-videoBaseNames, ddd<-doesDirectoryExist x]
	createClipDirs videoBaseNames
	let textPaths = [x++".txt"|x<-videoBaseNames]

	segmentVideos textPaths offsetTime
	print "The segment was finished."
