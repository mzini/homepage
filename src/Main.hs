{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main (main) where

import           Control.Monad ((>=>), void,forM, msum, filterM)
import           Data.List (sortBy)
import qualified Data.Map as M
import           Data.Char (isAlpha, toLower)
import           Data.Maybe (fromMaybe)
import           Data.Monoid ((<>))
import           Data.Ord (comparing)
import           Data.Time.Clock (UTCTime (..), getCurrentTime)
import           Data.Time.Format (formatTime, parseTimeM, defaultTimeLocale)
import           Hakyll
import           System.FilePath (addExtension, replaceExtension, takeDirectory, takeBaseName, (</>))
import           System.Process (system)
import           Text.Read (readMaybe)
import qualified Text.Pandoc as Pandoc
import Text.Regex (subRegex, mkRegex)

config :: Configuration
config = defaultConfiguration
    { deployCommand = "rsync -avz -e ssh ~/sources/homepage/_site/ csae2496@colo1-c703.uibk.ac.at:/home/www/users/zini/" }

----------------------------------------------------------------------
-- misc

system_ :: [String] -> IO ()
system_ = void . system . unwords

getFieldUTC :: MonadMetadata m => String -> Identifier -> m UTCTime
getFieldUTC fld id' = do
    metadata <- getMetadata id'
    let tryField k fmt = lookupString k metadata >>= parseTime' fmt
    maybe empty' return $ msum [tryField fld fmt | fmt <- formats]
  where
    empty'     = fail $ "could not parse time for " ++ show id'
    parseTime' = parseTimeM True defaultTimeLocale
    formats    =
        [ "%a, %d %b %Y %H:%M:%S %Z"
        , "%Y-%m-%dT%H:%M:%S%Z"
        , "%Y-%m-%d %H:%M:%S%Z"
        , "%Y-%m-%d"
        , "%B %e, %Y %l:%M %p"
        , "%B %e, %Y"
        , "%b %d, %Y"
        , "%B, %Y"
        , "%Y"
        ]

----------------------------------------------------------------------
-- sorting

sortByItems :: (Ord b) => (Item a -> Compiler b) -> [Item a] -> Compiler [Item a]
sortByItems get items = do
  items' <- forM items $ \item -> do
    e <- get item
    return (e,item)
  return $ map snd $ sortBy (flip (comparing fst)) items'

sortByDate :: String -> [Item a] -> Compiler [Item a]
sortByDate which = sortByItems (getFieldUTC which . itemIdentifier)

----------------------------------------------------------------------
-- compiler combinators

wrapHtmlContentIn :: Identifier -> Context String -> Item String -> Compiler (Item String)
wrapHtmlContentIn template ctx =
  loadAndApplyTemplate "templates/content.html" ctx
  >=> loadAndApplyTemplate template ctx
  >=> relativizeUrls

wrapHtmlContent :: Context String -> Item String -> Compiler (Item String)
wrapHtmlContent = wrapHtmlContentIn "templates/default.html"

templateAsHtmlContent :: Context String -> Compiler (Item String)
templateAsHtmlContent ctx =
  getResourceBody
   >>= applyAsTemplate ctx
   >>= wrapHtmlContent (metadataField <> defaultContext)


----------------------------------------------------------------------
-- specific compilers

metadataCompiler :: Identifier -> Compiler (Item String)
metadataCompiler template =
    pandocCompiler
    >>= loadAndApplyTemplate template (metadataField <> defaultContext)

pandocToTex :: Item String -> Compiler (Item String)
pandocToTex str =
  fmap (Pandoc.writeLaTeX Pandoc.def {Pandoc.writerTeXLigatures = False}) <$> readPandoc str

xelatex :: Item String -> Compiler (Item TmpFile)
xelatex item = do
  TmpFile tex <- newTmpFile "tmp.tex"
  bib <- loadBody "bibliography.bib"
  unsafeCompiler $ do
    writeFile tex (itemBody item)
    writeFile (takeDirectory tex </> "bibliography.bib") bib
    latex tex >> biber tex >> latex tex >> latex tex
  makeItem $ TmpFile (replaceExtension tex "pdf")
    where
      biber tex = system_ ["biber", "--input-directory", takeDirectory tex, "--output-directory", takeDirectory tex, takeBaseName tex, "2>&1", ">/dev/zero" ]
      latex tex = system_ ["xelatex", "-halt-on-error", "-output-directory", takeDirectory tex, tex, "2>&1", ">/dev/zero" ]

gpp :: Item String -> Compiler (Item String)
gpp = withItemBody (unixFilter "gpp" ["-T"])

pdfToPng :: FilePath -> Compiler (Item TmpFile)
pdfToPng pdf = do
  TmpFile tmp <- newTmpFile "converted"
  unsafeCompiler $ system_ ["pdftoppm", "-singlefile" , "-png", pdf, tmp, "2>/dev/null"]
  makeItem $ TmpFile (addExtension tmp "png")

----------------------------------------------------------------------
-- events

loadEvents :: Compiler [Item String]
loadEvents = loadAll "events/*.md"

upcomingEvents :: Compiler [Item String]
upcomingEvents = do
  now <- unsafeCompiler getCurrentTime
  loadEvents
    >>= filterM (\ item -> (>= now) <$> getFieldUTC "start" (itemIdentifier item))

pastEvents :: Compiler [Item String]
pastEvents = do
  now <- unsafeCompiler getCurrentTime
  loadEvents
    >>= filterM (\ item -> (< now) <$> getFieldUTC "end" (itemIdentifier item))

eventContext :: Context String
eventContext =
 metadataField
 <> defaultContext
 <> field "when" (\ item -> do
       let i = itemIdentifier item
       start <- formatTime defaultTimeLocale "%d %B " <$> getFieldUTC "start" i
       end <-   formatTime defaultTimeLocale "%d %B, %Y" <$> getFieldUTC "end" i
       return (start ++ " – " ++ end))

----------------------------------------------------------------------
-- projects

loadProjects :: Compiler [Item String]
loadProjects = reverse <$> loadAll "projects/*.md"

projectContext :: Context String
projectContext = metadataField <> defaultContext

----------------------------------------------------------------------
-- software

softwareListCompiler :: Compiler (Item String)
softwareListCompiler = do
  tools <- loadAll ("software/tools/*.md" .&&. hasNoVersion)
  libs <- loadAll ("software/libraries/*.md" .&&. hasNoVersion)
  templateAsHtmlContent $
    listField "tools" (metadataField <> defaultContext) (return tools)
    <> listField "libs" (metadataField <> defaultContext) (return libs)

-----------------------------------------------------------------------
-- papers

getBibId :: Item a -> String
getBibId = takeBaseName . toFilePath . itemIdentifier

entryType :: Item a -> Compiler String
entryType item = getMetadataField' (itemIdentifier item) "type"

bibEntryType :: Item a -> Compiler String
bibEntryType item = be <$> entryType item where
  be "workshop"   = "inproceedings"
  be "conference" = "inproceedings"
  be "draft"      = "unpublished"
  be "misc"       = "unpublished"
  be et           = et

seriesTex :: String -> String
seriesTex "lncs" = "Lecture Notes in Computer Science"
seriesTex "lnai" = "Lecture Notes in Artificial Intelligence"
seriesTex "lipics" = "Leibnitz International Proceedings in Informatics"
seriesTex "pacmpl" = "Proceedings of the ACM on Programming Languages"
seriesTex s = s

copyrightTex :: String -> String
copyrightTex "cc" = "Creative Commons License - ND"
copyrightTex c = publisherTex c

publisherTex :: String -> String
publisherTex "springer" = "Springer Verlag Heidelberg"
publisherTex "elsevier" = "Elsevier"
publisherTex "acm" = "Association for Computing Machinery"
publisherTex "dagstuhl" = "Leibnitz Zentrum für Informatik"
publisherTex c = error $ "unknown publisher " ++ c

journalTex :: String -> String
journalTex "ic" = "Information and Computation"
journalTex "tcs" = "Theoretical Computer Science"
journalTex "lmcs" = "Logical Methods in Computer Science"
journalTex "pacmpl" = "Proceedings of the ACM on Programming Languages"
journalTex c = error $ "unknown journal " ++ c

proceedingsTex :: String -> String
proceedingsTex name = fromMaybe name $ do
  (s,n) <- return (span isAlpha name)
  (num :: Int) <- readMaybe n
  return ("Proceedings of the " ++ nth (read n) ++ " " ++ conferenceTex s)
  where
    nth num | num `mod` 10 == 1 && num > 20 = "\\nst{" ++ show num ++ "}"
            | num `mod` 10 == 2 && num > 20 = "\\nnd{" ++ show num ++ "}"
            | num `mod` 10 == 3 && num > 20 = "\\nrd{" ++ show num ++ "}"
            | otherwise                     = "\\nth{" ++ show num ++ "}"

conferenceTex :: String -> String
conferenceTex "rta" = "International Conference on Rewriting Techniques and Applications"
conferenceTex "aplas" = "Asian Symposium on Programming Languages and Systems"
conferenceTex "dice"  = "International Workshop on Developments in Implicit Complexity"
conferenceTex "fscd"  = "International Conference on Formal Structures for Computation and Deduction"
conferenceTex "hart"  = "Workshop on Haskell and Rewriting Techniques"
conferenceTex "icfp"  = "ACM SIGPLAN International Conference on Functional Programming"
conferenceTex "ijcar" = "International Joint Conference on Automated Reasoning"
conferenceTex "flops" = "International Symposium on Functional and Logic Programming"
conferenceTex "stacs" = "International Symposium on Theoretical Aspects of Computer Science"
conferenceTex "tacas" = "International Conference on Tools and Algorithms for the Construction and Analysis of Systems"
conferenceTex "wst"   = "Workshop on Termination"
conferenceTex p       = p

publicationContext :: Tags -> Context String
publicationContext tags =
  metadataField
  <> field "bibid"            (return . getBibId)
  <> field "entryType"        entryType
  <> field "bibEntryType"     bibEntryType
  <> longFields "series"      seriesTex
  <> longFields "copyright"   copyrightTex
  <> longFields "publisher"   publisherTex
  <> longFields "journal"     journalTex
  <> longFields "authors"     id
  <> longFields "pages"       id
  <> longFields "proceedings" proceedingsTex
  <> tagsField "theTags"      tags
  <> defaultContext
  where
    lowercase = map toLower
    longFields n f =
      field (n ++ "Tex") (\ item -> fromMaybe "???" <$> fmap f <$> getMetadataField (itemIdentifier item) n)
      <> field (n ++ "Html") (\ item -> fromMaybe "???" <$> fmap htmlize <$> fmap f <$> getMetadataField (itemIdentifier item) n)
    htmlize =       sub "(\\{|\\})" ""
      . sub "\\\\ " " "
      . sub "--" "&ndash;"
      . sub "\\\\nrd\\{([0-9]*)\\}" "\\1rd"
      . sub "\\\\nnd\\{([0-9]*)\\}" "\\1nd"
      . sub "\\\\nst\\{([0-9]*)\\}" "\\1st"
      . sub "\\\\nth\\{([0-9]*)\\}" "\\1th"
    sub pat = flip (subRegex (mkRegex pat))


loadPublications :: Compiler [Item String]
loadPublications = sortByDate "year" =<< loadAll ("papers/*.md" .&&. hasNoVersion)

publicationCompiler :: Tags -> Compiler (Item String)
publicationCompiler tags =
    pandocCompiler
     >>= loadAndApplyTemplate "templates/publication.html" ctx
     >>= wrapHtmlContent ctx
    where ctx = publicationContext tags

publicationListContext :: Tags -> [Item String] -> Context String
publicationListContext tags pubs =
    publicationField "workshop"      (== "workshop")
    <> publicationField "thesis"     (`elem` ["phdthesis", "mastersthesis"])
    <> publicationField "conference" (== "conference")
    <> publicationField "article"    (== "article")
    <> publicationField "draft"      (== "draft")
    <> publicationField "misc"       (== "misc")
    <> field "tagcloud" (const $ renderTagCloud 30 150 tags)
    <> listField "publications" pctx (return pubs)
    <> defaultContext
  where
    pctx = publicationContext tags
    publicationField n f = listField n pctx (filterType f)
    filterType f = filterM (\ item -> f <$> entryType item) pubs


publicationListCompilerForTag :: String -> Pattern -> Tags -> Compiler (Item String)
publicationListCompilerForTag string pattern tags = do
  pubs <- sortByDate "year" =<< loadAll (pattern .&&. hasNoVersion)
  let ctx = constField "title" ("List of Publications: " ++ string)
            <> publicationListContext tags pubs
  makeItem ""
   >>= loadAndApplyTemplate "templates/publications.html" ctx
   >>= wrapHtmlContent ctx

publicationListCompiler :: Tags -> Compiler (Item String)
publicationListCompiler tags = do
  pubs <- loadPublications
  templateAsHtmlContent (publicationListContext tags pubs)

publicationListPdfCompiler :: Tags -> Compiler (Item TmpFile)
publicationListPdfCompiler tags = do
  pubs <- loadPublications
  getResourceBody
   >>= applyAsTemplate (publicationListContext tags pubs)
   >>= loadAndApplyTemplate "templates/document.tex" defaultContext
   >>= xelatex

publicationListTexCompiler :: Tags -> Compiler (Item String)
publicationListTexCompiler tags = do
  pubs <- loadPublications
  getResourceBody
   >>= applyAsTemplate (publicationListContext tags pubs)
   >>= loadAndApplyTemplate "templates/document.tex" defaultContext

bibliographyCompiler :: Tags -> Compiler (Item String)
bibliographyCompiler tags = do
  pubs <- loadPublications
  getResourceBody >>= applyAsTemplate (publicationListContext tags pubs) >>= gpp


----------------------------------------------------------------------
-- CV

cvPandocCompiler :: Bool -> Compiler (Item String)
cvPandocCompiler html = do
  projects <- sortByDate "end" =<< loadProjects
  tools <- loadAll ("software/tools/*.md" .&&. hasVersion "cv")
  libs <- loadAll ("software/libraries/*.md" .&&. hasVersion "cv")
  let
   ctx = listField "projects" projectContext (return projects)
         <> listField "tools" (metadataField <> defaultContext) (return tools)
         <> listField "libs"  (metadataField <> defaultContext) (return libs)
         <> boolField "html" (const html)
         <> defaultContext
  getResourceBody >>= applyAsTemplate ctx >>= gpp

cvCompiler :: Compiler (Item String)
cvCompiler =
    cvPandocCompiler True >>= renderPandoc
     >>= return . fmap demoteHeaders
     >>= loadAndApplyTemplate "templates/cv.html" defaultContext
     >>= wrapHtmlContent defaultContext

cvTexCompiler :: Compiler (Item String)
cvTexCompiler =
    cvPandocCompiler False
     >>= pandocToTex
     >>= loadAndApplyTemplate "templates/cv.tex" defaultContext
     >>= loadAndApplyTemplate "templates/document.tex" defaultContext

cvPdfCompiler :: Compiler (Item TmpFile)
cvPdfCompiler = cvTexCompiler >>= xelatex

----------------------------------------------------------------------
-- index

indexCompiler :: Tags -> Compiler (Item String)
indexCompiler tags = do
   pubs <- take 3 <$> loadPublications
   events <- reverse <$> (sortByDate "start" =<< upcomingEvents)
   events' <- sortByDate "end" =<< pastEvents
   projects <- sortByDate "end" =<< loadProjects
   templateAsHtmlContent
         (  listField "publications"      (publicationContext tags)    (return pubs)
         <> boolField "hasUpcomingEvents" (const (not (null events)))
         <> listField "upcomingEvents"    eventContext                 (return events)
         <> listField "pastEvents"        eventContext                 (return events')
         <> listField "projects"          projectContext               (return projects)
         <> defaultContext )

----------------------------------------------------------------------
-- homepage
main :: IO ()
main = hakyllWith config $ do
    tags <- buildTags "papers/*" (fromCapture "tags/*.html")

    -- files etc
    match ("images/*.jpg" .||. "images/*.png") $ do
        route idRoute
        compile copyFileCompiler

    match "papers/*.pdf" $ do
        route   idRoute
        compile copyFileCompiler

    match "slides/*.pdf" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
      route idRoute
      compile compressCssCompiler

    match "templates/*" $ compile templateCompiler

    match "404.html" $ do
        route idRoute
        compile $ pandocCompiler >>= wrapHtmlContent defaultContext

    -- papers
    match "papers/*.pdf" $ version "preview" $ do
        route   $ setExtension "png"
        compile $ getResourceFilePath >>= pdfToPng

    match "papers/*.md" $ version "bibtex" $ do
        route   $ setExtension ".bib"
        compile $
          getResourceBody
           >>= loadAndApplyTemplate "templates/bibtex.bib" (publicationContext tags)
           >>= gpp

    match "papers/*.md" $ do
        route   $ setExtension ".html"
        compile $ publicationCompiler tags

    match "projects/*.md" $
        compile $ metadataCompiler "templates/project.html"

    match "events/*.md" $
        compile $ pandocCompiler >>= loadAndApplyTemplate "templates/event.html" eventContext

    match "software/tools/*.md" $
        compile $ metadataCompiler "templates/software.html"
    match "software/libraries/*.md" $
        compile $ metadataCompiler "templates/software.html"

    match "software/tools/*.md" $ version "cv" $
        compile $ metadataCompiler "templates/software-cv.md"
    match "software/libraries/*.md" $ version "cv" $
        compile $ metadataCompiler "templates/software-cv.md"

    -- main pages
    match "software.html" $ do
        route idRoute
        compile softwareListCompiler

    match "contact.html" $ do
        route idRoute
        compile $ templateAsHtmlContent defaultContext

    match "publications.html" $ do
        route (setExtension "html")
        compile (publicationListCompiler tags)

    match "bibliography.bib" $ do
        route idRoute
        compile (bibliographyCompiler tags)

    match "publications.tex" $ version "pdf" $ do
        route (setExtension "pdf")
        compile (publicationListPdfCompiler tags)

    match "publications.tex" $ version "tex" $ do
        route idRoute
        compile (publicationListTexCompiler tags)

    tagsRules tags $ \ tag pattern -> do
        route   idRoute
        compile (publicationListCompilerForTag tag pattern tags)

    match "cv.md" $ do
        route (setExtension "html")
        compile cvCompiler

    match "cv.md" $ version "tex" $ do
        route (setExtension "tex")
        compile cvTexCompiler


    match "cv.md" $ version "pdf" $ do
        route (setExtension ".pdf")
        compile cvPdfCompiler

    match "index.html" $ do
      route idRoute
      compile (indexCompiler tags)


    -- hosa page
    match "software/hosa/*.md" $ do
        route $ setExtension "html"
        compile $ pandocCompiler >>= wrapHtmlContent defaultContext

    -- other pages
    match "projects/J3563/*.html" $ do
        route idRoute
        let ctx = listField "publications" (publicationContext tags) loadPublications <> defaultContext
        compile $ templateAsHtmlContent ctx

    -- dice 18
    match "events/dice18/page.html" $ compile templateCompiler
    match "events/dice18/abstracts/*.pdf" $ do
        route   idRoute
        compile copyFileCompiler
    match "events/dice18/*.md" $ do
        route $ setExtension "html"
        compile $ pandocCompiler >>= wrapHtmlContentIn "events/dice18/page.html" defaultContext
