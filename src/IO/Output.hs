{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module IO.Output
    ( output
    ) where

import ClassyPrelude

import CLI
import Http         (LinkStatus (..))
import IO.Document  (TFilePath)
import Parser.Links (Link, ParseError)

-- output
brokenOutput :: (Link, LinkStatus) -> IO ()
brokenOutput (url, Working)           = splitOut "  - OK" url
brokenOutput (url, Broken code)       = splitErr ("  -" ++ tshow code) url
brokenOutput (url, ConnectionFailure) = splitErr "  - Could not connect" url

statusError :: (Link, LinkStatus) -> Bool
statusError (_, Working) = False
statusError _            = True

countErrors :: [(Link, LinkStatus)] -> Int
countErrors statuses = length $ filter statusError statuses

outputPath :: TFilePath -> Text
outputPath path = concat ["\n", "[", path, "]"]

output :: (TFilePath, Maybe (Either ParseError [(Link, LinkStatus)])) -> IO Bool
output (path, Nothing) = do
    errorMessage $ outputPath path
    errorMessage "  - File Not found"
    return True
output (path, Just (Left err)) = do
    errorMessage $ outputPath path
    errorMessage "  - File could not be parsed"
    errorMessage err
    return True
output (path, Just (Right statuses)) = do
    let errs = countErrors statuses /= 0
    if errs
        then errorMessage $ outputPath path
        else message $ outputPath path
    sequence_ $ brokenOutput <$> statuses
    return errs