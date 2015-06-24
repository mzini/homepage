{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import           Bibtex

import           Control.Monad ((>=>), void,forM, msum, filterM)
import           Data.List (sortBy)
import qualified Data.Map as M
import           Data.Maybe (fromMaybe)
import           Data.Monoid ((<>))
import           Data.Ord (comparing)
import           Data.Time.Clock (UTCTime (..), getCurrentTime)
import           Data.Time.Format (formatTime, parseTimeM, defaultTimeLocale)
import           Hakyll
import           System.FilePath (addExtension, replaceExtension, takeDirectory, takeBaseName)
import           System.Process (system)
import qualified Text.Pandoc as Pandoc

config :: Configuration
config = defaultConfiguration
    { deployCommand = "rsync -avz -e ssh ~/sources/homepage/_site/ csae2496@colo1-c703.uibk.ac.at:/home/www/users/zini/" }

----------------------------------------------------------------------
-- misc

system_ :: [String] -> IO ()
system_ = void . system . unwords

getFieldUTC :: MonadMetadata m
           => String            -- ^ Field
           -> Identifier        -- ^ Input page
           -> m UTCTime         -- ^ Parsed UTCTime
getFieldUTC fld id' = do
    metadata <- getMetadata id'
    let tryField k fmt = M.lookup k metadata >>= parseTime' fmt
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

sortByBibField :: Ord b => BibFile -> (BibEntry -> Maybe b) -> [Item a] -> Compiler [Item a]
sortByBibField biblio which = sortByItems (return . biblioField biblio which)

----------------------------------------------------------------------
-- combiler combinators

wrapHtmlContent :: Context String -> Item String -> Compiler (Item String)
wrapHtmlContent ctx = 
  loadAndApplyTemplate "templates/content.html" ctx
  >=> loadAndApplyTemplate "templates/default.html" ctx
  >=> relativizeUrls

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
  unsafeCompiler $ do
    writeFile tex (itemBody item)
    latex tex
    biber tex
    latex tex
    latex tex
  makeItem $ TmpFile (replaceExtension tex "pdf")
    where 
      biber tex = 
          system_ ["biber", "--output-directory", takeDirectory tex, takeBaseName tex, "2>&1", ">/dev/zero" ]
      latex tex = 
          system_ ["xelatex", "-halt-on-error", "-output-directory", takeDirectory tex, tex, "2>&1", ">/dev/zero" ]

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

loadSoftware :: Compiler [Item String]
loadSoftware = loadAll "software/*.md"

softwareListCompiler :: Compiler (Item String)
softwareListCompiler = do 
  software <- loadSoftware
  templateAsHtmlContent (listField "software" (metadataField <> defaultContext) (return software))

-----------------------------------------------------------------------
-- papers

getBibId :: Item a -> String
getBibId = takeBaseName . toFilePath . itemIdentifier  

biblioField :: BibFile -> (BibEntry -> Maybe b) -> Item a -> Maybe b
biblioField biblio f i = lookupById (getBibId i) biblio >>= f

publicationContext :: Tags -> BibFile -> Context String        
publicationContext tags biblio = 
  metadataField
  <> field "bibid" (return . getBibId)
  <> bibTextField "entrytype" (Just . entryType)
  -- type
  <> bibBoolField "isArticle" isArticle
  <> bibBoolField "isInProceeding" isInProceeding
  <> bibBoolField "isTechreport" isTechreport
  <> bibBoolField "isPhdThesis" isPhdThesis
  <> bibBoolField "isMastersThesis" isMastersThesis  
  -- fields
  <> bibTextField "authors" authors
  <> bibTextField "title" title
  <> bibTextField "journal" journal
  <> bibTextField "booktitle" booktitle
  <> bibTextField "school" school
  <> bibIntField "year" year
  <> bibIntField "volume" volume
  <> bibTextField "number" number
  <> bibTextField "institution" institution  
  <> bibTextField "publisher" publisher
  <> bibTextField "series" series
  <> bibTextField "note" note
  <> bibTextField "pages" pages
  <> tagsField "theTags" tags
  <> defaultContext  

  where 
    bibTextField t f = field t getField where
      getField i = 
        case biblioField biblio f i of 
         Just e -> return e
         Nothing -> fail $ unwords ["no bibtex field", t, "for entry", getBibId i]
    bibIntField t f = bibTextField t (fmap show . f)
    bibBoolField t f = boolField t getField where
      getField i = fromMaybe False (f <$> lookupById (getBibId i) biblio)


loadPublications :: Compiler [Item String]
loadPublications = loadAll ("papers/*.md" .&&. hasNoVersion)

publicationCompiler :: Tags -> BibFile -> Compiler (Item String)
publicationCompiler tags biblio = 
    pandocCompiler 
     >>= loadAndApplyTemplate "templates/publication.html" ctx
     >>= wrapHtmlContent ctx
    where ctx = publicationContext tags biblio

publicationListContext :: Tags -> BibFile -> [Item String] -> Context String
publicationListContext tags biblio pubs =
    publicationField "workshop" 
    <> publicationField "thesis"     
    <> publicationField "conference" 
    <> publicationField "article" 
    <> publicationField "misc" 
    <> publicationField "draft"     
    <> field "tagcloud" (const $ renderTagCloud 30 150 tags)
    <> listField "publications" pctx (return pubs)
    <> defaultContext
  where 
    pctx = publicationContext tags biblio
    publicationField n = listField n pctx (filterType n)
    filterType n = filterM (\ item -> (== n) <$> getMetadataField' (itemIdentifier item) "type") pubs
  


publicationListCompilerForTag :: String -> Pattern -> Tags -> BibFile -> Compiler (Item String)
publicationListCompilerForTag string pattern tags biblio = do
  pubs <- sortByBibField biblio year =<< loadAll (pattern .&&. hasNoVersion)
  let ctx = constField "title" ("List of Publications: " ++ string)
            <> publicationListContext tags biblio pubs
  makeItem ""
   >>= loadAndApplyTemplate "templates/publications.html" ctx
   >>= wrapHtmlContent ctx

publicationListCompiler :: Tags -> BibFile -> Compiler (Item String)
publicationListCompiler tags biblio = do
  pubs <- sortByBibField biblio year =<< loadPublications
  templateAsHtmlContent (publicationListContext tags biblio pubs)

publicationListPdfCompiler :: Tags -> BibFile -> Compiler (Item TmpFile)
publicationListPdfCompiler tags biblio = do
  pubs <- sortByBibField biblio year =<< loadPublications
  getResourceBody 
   >>= applyAsTemplate (publicationListContext tags biblio pubs )
   >>= loadAndApplyTemplate "templates/document.tex" defaultContext
   >>= xelatex   

bibliographyCompiler :: Tags -> BibFile -> Compiler (Item String)
bibliographyCompiler tags biblio = do
  pubs <- sortByBibField biblio year =<< loadPublications
  getResourceBody >>= applyAsTemplate (publicationListContext tags biblio pubs) >>= gpp


----------------------------------------------------------------------
-- CV

cvPandocCompiler :: Bool -> Compiler (Item String)
cvPandocCompiler html = do
  projects <- sortByDate "end" =<< loadProjects
  let 
   ctx = listField "projects" projectContext (return projects)
         <> boolField "html" (const html)
         <> defaultContext
  getResourceBody >>= applyAsTemplate ctx >>= gpp

cvCompiler :: Compiler (Item String)           
cvCompiler = 
    cvPandocCompiler True >>= renderPandoc
     >>= return . fmap demoteHeaders                    
     >>= loadAndApplyTemplate "templates/cv.html" defaultContext
     >>= wrapHtmlContent defaultContext

cvPdfCompiler :: Compiler (Item TmpFile)
cvPdfCompiler = 
    cvPandocCompiler False
     >>= pandocToTex
     >>= loadAndApplyTemplate "templates/cv.tex" defaultContext
     >>= loadAndApplyTemplate "templates/document.tex" defaultContext     
     >>= xelatex   

----------------------------------------------------------------------
-- index

indexCompiler :: Tags -> BibFile -> Compiler (Item String)
indexCompiler tags biblio = do
   pubs <- fmap (take 3) . sortByBibField biblio year =<< loadPublications
   events <- reverse <$> (sortByDate "start" =<< upcomingEvents)
   projects <- sortByDate "end" =<< loadProjects
   templateAsHtmlContent 
         (  listField "publications" (publicationContext tags biblio)  (return pubs) 
         <> listField "events"       eventContext                      (return events) 
         <> listField "projects"     projectContext                    (return projects)                     
         <> defaultContext )

----------------------------------------------------------------------
-- homepage
main :: IO ()
main = hakyllWith config $ do
    tags <- buildTags "papers/*" (fromCapture "tags/*.html")
    strings <- makePatternDependency "papers/strings.bib"
    references <- makePatternDependency "papers/references.bib"    
    biblio <- rulesExtraDependencies [strings,references] $ preprocess (parseBibFile ["papers/strings.bib", "papers/references.bib"])

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
           >>= loadAndApplyTemplate "templates/bibtex.bib" (publicationContext tags biblio)
           >>= gpp

    match "papers/*.md" $ do
        route   $ setExtension ".html"
        compile $ publicationCompiler tags biblio 
        
    match "projects/*.md" $ 
        compile $ metadataCompiler "templates/project.html"

    match "events/*.md" $ 
        compile $ 
         pandocCompiler 
          >>= loadAndApplyTemplate "templates/event.html" eventContext

    match "software/*.md" $
        compile $ metadataCompiler "templates/software.html"
   
    -- main pages
    match "software.html" $ do
        route idRoute
        compile softwareListCompiler

    match "contact.html" $ do
        route idRoute
        compile $ templateAsHtmlContent defaultContext      

    match "publications.html" $ do
        route (setExtension "html")    
        compile (publicationListCompiler tags biblio)

    match "publications.tex" $ do
        route (setExtension "pdf")
        compile (publicationListPdfCompiler tags biblio)

    match "bibliography.bib" $ do
        route idRoute
        compile (bibliographyCompiler tags biblio)

    tagsRules tags $ \ tag pattern -> do 
        route   idRoute
        compile (publicationListCompilerForTag tag pattern tags biblio)
                                        
    match "cv.md" $ do
        route (setExtension "html")
        compile cvCompiler

    match "cv.md" $ version "pdf" $ do
        route (setExtension ".pdf")
        compile cvPdfCompiler

    match "index.html" $ do
      route idRoute
      compile (indexCompiler tags biblio)









