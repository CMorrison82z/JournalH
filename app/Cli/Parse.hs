module Cli.Parse where

import Cli.Commands (addNewEntry, createNewJobThing, startJobThing, stopJobThing, viewJobThing, viewJournal)
import Cli.Types (TagSetStrategy (TSSAnd, TSSOr))
import JournalH.Types
import Options.Applicative

cli :: Parser (IO ())
cli =
  subparser
    ( command
        "journal"
        (info journal_cli (progDesc "Stuff for actual journalling"))
        <> command
          "worklog"
          (info work_cli (progDesc "Stuff for recording work time stamps stuff"))
    )

journal_cli :: Parser (IO ())
journal_cli =
  subparser
    ( command "new" (info (pure addNewEntry) (progDesc "Add a new entry to the journal"))
        <> command
          "view"
          ( info
              ( (viewJournal . Tags <$> many (Tag <$> strArgument (metavar "TAGS...")))
                  <*> flag TSSOr TSSAnd (long "and" <> help "Switch search strategy to `or` mode.")
              )
              (progDesc "View journal entries")
          )
    )

work_cli :: Parser (IO ())
work_cli =
  subparser
    ( command "new" (info (createNewJobThing <$> strArgument (metavar "JOBNAME")) (progDesc "Create new work thing."))
        <> command
          "start"
          ( info
              (startJobThing <$> strArgument (metavar "JOBNAME"))
              (progDesc "Start a job session thing.")
          )
        <> command
          "stop"
          ( info
              (stopJobThing <$> strArgument (metavar "JOBNAME"))
              (progDesc "Stop a job session thing.")
          )
        <> command
          "view"
          ( info
              ( viewJobThing
                  <$> strArgument (metavar "JOBNAME")
                  <*> optional (strOption (long "from" <> short 'f' <> metavar "SINCE Y/M/D"))
                  <*> optional (strOption (long "to" <> short 't' <> metavar "UNTIL Y/M/D"))
              )
              (progDesc "View job sessions")
          )
    )
