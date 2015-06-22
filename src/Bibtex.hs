-- | 

module Bibtex (
  BibEntry
  , BibFile
  , flattenBibTex
  , parseBibFile
  , keys
  , lookupById
  , entryType
  , BibTex.identifier
  , fields
  , authors
  -- , authorsList
  , title
  , booktitle  
  , journal
  , year
  , volume
  , number
  , publisher
  , institution
  , note
  , pages
  , school  
  , series
  , isInProceeding
  , isArticle
  , isTechreport
  , isPhdThesis
  , isMastersThesis  
  
  , entryToString
) where

import Data.Maybe (listToMaybe)
import qualified Text.BibTeX.Entry   as BibTex
import qualified Text.BibTeX.Format  as BibTex.Format
import qualified Text.BibTeX.Parse   as BibTex.Parse
import qualified Text.Parsec as Parsec
import           System.Process      
import Data.Char (toLower)
import Text.Regex (subRegex, mkRegex)

type BibEntry = BibTex.T
type BibFile = [BibEntry]


flattenBibTex :: [String] -> IO String
flattenBibTex fns = do
  let cmd = unwords $ ["bib2bib", "--expand", "--no-comment", "--expand-xrefs", "-w"] ++ fns
  readCreateProcess (shell cmd) "" 

parseBibFile :: [String] -> IO BibFile
parseBibFile fns = do
  str <- flattenBibTex fns
  case Parsec.parse BibTex.Parse.file "<bibfile>" str of
     Left err -> error (show err)
     Right es -> return (BibTex.lowerCaseFieldNames `map` es)

keys :: BibFile -> [String]
keys = map BibTex.identifier

lookupById :: String -> BibFile -> Maybe BibEntry
lookupById name = listToMaybe . filter (\ e -> BibTex.identifier e == name)


lower :: String -> String
lower = map toLower

isArticle :: BibEntry -> Bool
isArticle e = lower (BibTex.entryType e) == "article"

entryType :: BibEntry -> String 
entryType = lower . BibTex.entryType

isInProceeding :: BibEntry -> Bool
isInProceeding e = entryType e == "inproceedings"

isTechreport :: BibEntry -> Bool
isTechreport e = entryType e == "techreport"

isPhdThesis :: BibEntry -> Bool
isPhdThesis e = entryType e == "phdthesis"

isMastersThesis :: BibEntry -> Bool
isMastersThesis e = entryType e == "mastersthesis"

fields :: BibEntry -> [String]
fields = map fst . BibTex.fields

lookupFieldWith :: String -> (String -> Maybe a) -> BibEntry -> Maybe a
lookupFieldWith f mk e = (clean <$> lookup f (BibTex.fields e))  >>= mk  where
  clean = 
      sub "(\\{|\\})" ""    
      . sub "\\\\ " " "    
      . sub "--" "-"          
      . sub "\\\\nrd\\{([0-9]*)\\}" "\\1rd"  
      . sub "\\\\nnd\\{([0-9]*)\\}" "\\1nd"
      . sub "\\\\nst\\{([0-9]*)\\}" "\\1st"      
      . sub "\\\\nth\\{([0-9]*)\\}" "\\1th" 
  sub pat = flip (subRegex (mkRegex pat))


readMaybe :: (Read a) => String -> Maybe a
readMaybe s = 
  case reads s of
   [(x, "")] -> Just x
   _ -> Nothing

authors :: BibEntry -> Maybe String
authors = lookupFieldWith "author" Just

title :: BibEntry -> Maybe String
title = lookupFieldWith "title" Just

booktitle :: BibEntry -> Maybe String
booktitle = lookupFieldWith "booktitle" Just

publisher :: BibEntry -> Maybe String
publisher = lookupFieldWith "publisher" Just

note :: BibEntry -> Maybe String
note = lookupFieldWith "note" Just

journal :: BibEntry -> Maybe String
journal = lookupFieldWith "journal" Just

series :: BibEntry -> Maybe String
series = lookupFieldWith "series" Just

pages :: BibEntry -> Maybe String
pages = lookupFieldWith "pages" Just

year :: BibEntry -> Maybe Int
year = lookupFieldWith "year" readMaybe

volume :: BibEntry -> Maybe Int
volume = lookupFieldWith "volume" readMaybe

number :: BibEntry -> Maybe String
number = lookupFieldWith "number" Just

school :: BibEntry -> Maybe String
school = lookupFieldWith "school" Just

institution :: BibEntry -> Maybe String
institution = lookupFieldWith "institution" Just

entryToString :: BibEntry -> String
entryToString = BibTex.Format.entry
  
