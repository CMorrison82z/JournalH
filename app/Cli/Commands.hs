module Cli.Commands where

import Cli.Types (TagSetStrategy (TSSAnd, TSSOr))
import Control.Monad (when)
import Data.Maybe (fromJust)
import Data.Time (TimeZone, UTCTime (UTCTime), ZonedTime, defaultTimeLocale, formatTime, getCurrentTime, readPTime, utcToZonedTime)
import Share
import String.ANSI (red)
import System.Directory (XdgDirectory (XdgData), doesFileExist, getXdgDirectory)
import System.Environment (getEnv)
import System.IO (readFile')
import System.IO.Temp (emptySystemTempFile)
import System.Process (callProcess)
import Text.ParserCombinators.ReadP
import Text.ParserCombinators.ReadP (readP_to_S)
import Types

addNewEntry :: IO ()
addNewEntry = do
  je <- fromJust <$> newEntry
  app_dir <- getAppDataDirectory
  appDataContents <- readFileOrEmpty app_dir
  let updatedContents = appDataContents ++ '\n' : show je
  -- NOTE:
  -- This is deliberately written like this to force evaluation.
  -- Even `seq` did not solve the problem.
  when (length updatedContents > 0) $
    writeFile app_dir updatedContents

viewJournal :: Tags -> TagSetStrategy -> IO ()
-- viewJournal ts TSSOr = undefined
viewJournal ts TSSAnd = do
  ad <- getAppDataDirectory
  x <- readFile ad
  -- let (JEntriesDoc es) = read x
  let je = JEntriesDoc . fst . last $ readP_to_S readPJournal x
  print $ show je

showEntryInTimeZone :: TimeZone -> JournalEntry -> String
showEntryInTimeZone tz (JournalEntry {entry_time, tags, entry}) = journalEntryFormat ts (show tags) entry
  where
    ts = formatTime defaultTimeLocale preferredTimeFormatting (utcToZonedTime tz entry_time) ++ show tz

newEntry :: IO (Maybe JournalEntry)
newEntry = do
  contents <- editWithEditor
  case contents of
    "" -> pure Nothing
    _ -> do
      putStrLn "Provide a list of tags (Space separated)"
      -- TODO:
      -- Check that tag string is alphanumeric. (This is required by the parser)
      l <- Tags . fmap Tag . words <$> getLine
      t <- getCurrentTime

      pure
        . Just
        $ JournalEntry
          { entry_time = t,
            tags = l,
            -- contents always includes a new line character at the end, so I drop it.
            entry = init contents
          }
