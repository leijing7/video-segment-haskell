import System.IO
import System.Cmd
import System.Directory
import System.FilePath
import System.Environment

import qualified Data.Text as T
import qualified Data.List as L
import qualified Data.List.Split as S
import qualified Data.Char as C

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
createClipDirs [] = putStrLn "No video file was found."
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
	print (show x)
writeListFile (x:xs) fpath= do 
	writeListFile [x] fpath
	writeListFile xs fpath

segmentVideo :: [(String,[Char],[Char])] -> String -> Float -> IO ()
segmentVideo [clipInfo] videopath offsetTime = do 
	let basename = takeBaseName videopath
	let syllable = tupSyllable clipInfo
	let startTime = show((read (tupStartTime clipInfo)::Float) - offsetTime)
	let duration = show((read (tupDuration clipInfo)::Float) + offsetTime*2)

	let ext = takeExtension videopath

	let avCmd = "ffmpeg\\ffmpeg -i " ++ videopath ++ " -vcodec rawvideo -acodec copy -ss " ++ startTime ++ " -t " 
				++ duration ++ " " ++ basename ++ "/" ++ syllable ++ ext
	let audioOnlyCmd = "ffmpeg\\ffmpeg -i " ++ videopath ++ " -vn -acodec copy -ss " ++ startTime ++ " -t " 
				++ duration ++ " " ++ basename ++ "_audioOnly/" ++ syllable ++ ".wav"
	let videoOnlyCmd = "ffmpeg\\ffmpeg -i " ++  videopath ++" -vcodec rawvideo -an -ss " ++ startTime ++ " -t " 
				++ duration ++ " " ++ basename ++ "_videoOnly/" ++ syllable ++ ext
	system avCmd
	system audioOnlyCmd
	system videoOnlyCmd

	print "Finished one clip."
segmentVideo (x:xs) filepath offsetTime = do
	segmentVideo [x] filepath offsetTime
	segmentVideo xs filepath offsetTime

segmentVideos :: [FilePath] -> [FilePath] -> Float -> IO ()
segmentVideos [filepath] videoPaths offsetTime = do
	clipList <- parseTextFile filepath
	let toneInfoList = suffixSyllableList (groupSyllableList (sortSyllableList clipList))
	let sortedToneInfoList = sortSyllableListByStartTime toneInfoList
	let videopath = head [ x | x<-videoPaths, L.isPrefixOf (takeBaseName filepath) x ] --need to check is the list is empty

	segmentVideo sortedToneInfoList videopath offsetTime
segmentVideos (x:xs) videoPaths offsetTime = do
	segmentVideos [x] videoPaths offsetTime
	segmentVideos xs videoPaths offsetTime

defaultOffsetTime = 0.2
setOffsetTime :: [String] -> Float
setOffsetTime [] = defaultOffsetTime
setOffsetTime (x:xs) = read x::Float

main = do
	args <- getArgs
	let offsetTime = setOffsetTime args

	currentDir <- getCurrentDirectory 
	filesInDir <- getDirectoryContents currentDir
	let videoPaths = [ x | x<-filesInDir, L.isInfixOf ".MP4" (map C.toUpper x) || L.isInfixOf ".AVI" (map C.toUpper x)]
	print "This program will process below video files: " 
	print "---------------------------------------------------------" 
	mapM_ print videoPaths
	print "---------------------------------------------------------" 
	print "#########################################################"
	print "The offset time is (in Seconds)" 
	print offsetTime
	print "#########################################################"


	let videoBaseNames = [takeBaseName x|x<-videoPaths]
	createClipDirs videoBaseNames
	let textPaths = [x++".txt"|x<-videoBaseNames]

	segmentVideos textPaths videoPaths offsetTime
	print "******"
	print "The segment was finished."
