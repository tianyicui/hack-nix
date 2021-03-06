{-# OPTIONS_GHC -XNoMonomorphismRestriction #-}
module Utils where
import Data.Maybe
import Control.Monad.Reader.Class
import Distribution.ParseUtils as PU
import Distribution.Package
import Distribution.Simple.Utils (findPackageDesc)
import Control.Monad
import Control.Monad.Trans
import Distribution.Version
import System.Exit
import System.Process
import System.IO
import System.Directory
import Config
import Distribution.PackageDescription
import Distribution.PackageDescription.Parse
import Distribution.PackageDescription as PD
import Distribution.Package as D
import Distribution.Text
import Distribution.Package

-- makes sure file is fully closed after reading
readFile' :: FilePath -> IO String
readFile' f = do s <- readFile f
                 return $! (length s `seq` s)


parseResultToEither :: PU.ParseResult a -> Either String ([String],a)
parseResultToEither (PU.ParseOk warnings a) = Right (map show warnings, a)
parseResultToEither (PU.ParseFailed error) = Left (show error)

parsePkgDescToEither :: String -> Either String ([String], GenericPackageDescription)
parsePkgDescToEither = parseResultToEither . parsePackageDescription

parsePkgFormFile :: FilePath -> IO GenericPackageDescription
parsePkgFormFile file = do
  c <- readFile file
  case parsePkgDescToEither c of
    Left e -> error $ unlines [ "parsing of " ++ file ++ "failed :", e]
    Right (ws, pd) -> do
      when ((not . null) ws) $ putStrLn $ unlines $ [ "warnings while parsing " ++ file ++ ":"] ++ ws
      return pd


matchDepndencyConstraints :: Dependency -> PackageIdentifier -> Bool
matchDepndencyConstraints (Dependency name vRange) (PackageIdentifier pName pVersion) =
  pName == name && withinRange pVersion vRange

die :: String -> IO a
die msg = do
  putStrLn msg
  exitWith (ExitFailure 1)

parseCabalFileCurrentDir :: ConfigR GenericPackageDescription
parseCabalFileCurrentDir = do
  cabalFile <- liftIO $ findPackageDesc =<< getCurrentDirectory
  fileContents <- liftIO $ readFile cabalFile
  case parsePkgDescToEither fileContents of
    Left e -> liftIO $ die $ "error parsing cabal file " ++ cabalFile ++ ": " ++ show e
    Right (_, pd) -> return pd

findOneOfFiles :: [FilePath] -> IO (Maybe FilePath)
findOneOfFiles list =
  liftM (listToMaybe) $ filterM doesFileExist list

findSetup :: IO FilePath
findSetup = do
  setups <- findOneOfFiles ["setup","Setup"]
  case setups of
    Nothing -> do
      mbSource <- findOneOfFiles ["Setup.lhs", "Setup.hs"]
      source <- case mbSource of
        Just src -> return src
        Nothing -> do
          putStrLn "no setup file found. Couldn't find Setup.[l]hs either, create basic Setup.hs? [y]/.."
          c <- getChar
          if (c == 'y') then do
              writeFile "Setup.hs" $ unlines [
                    "module Main where"
                  , "import Distribution.Simple"
                  , "main = defaultMain"
                  ]
              return "Setup.hs"
            else die "dying"
      putStrLn "[Ss]etup not found, compile? y/[n]"
      c <- getChar
      if (c == 'y') then do
          run (Just 0) "ghc" ["--make", source] Nothing Nothing
          return "Setup"
        else die "can't continue"
    Just setupE -> return setupE

-- exits if command exitst with non zero exit status
run :: Maybe Int -> String -> [String] -> Maybe String -> Maybe Handle -> IO ()
run mbExpectedEC prog args mbWorkDir mbStdout = do
  let str = prog ++ " " ++ show args ++ " in " ++ show mbWorkDir
  putStrLn $ "running :" ++ str
  h <- runProcess prog args mbWorkDir  Nothing Nothing mbStdout Nothing
  ec <- waitForProcess h
  let got = case ec of
              ExitSuccess -> 0
              ExitFailure ec -> ec
  case mbExpectedEC of
    Nothing -> return ()
    (Just expectedEC) -> 
      when (expectedEC /= got) $ do
          putStrLn $ "run: " ++ str
          die $ "expected exit code: " ++ show expectedEC ++ " but got: " ++ show got
  

splitName :: String -> (String, String)
splitName fullName =
    let (versionStrR,_:nameR) = break (== '-') $ reverse fullName
    in (reverse nameR, reverse versionStrR)
