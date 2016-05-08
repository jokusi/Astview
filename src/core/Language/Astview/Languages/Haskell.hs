module Language.Astview.Languages.Haskell (haskellExts) where
import Prelude hiding (span)

import Language.Astview.Language hiding (parse)
import Language.Astview.DataTree (dataToAstIgnoreByExample)

import Data.Generics (Data,extQ)
import Data.Generics.Zipper(toZipper,down',query)

import Control.Monad.Trans.Either (EitherT, hoistEither)

import Language.Haskell.Exts.Parser
import Language.Haskell.Exts.Annotated.Syntax
import qualified Language.Haskell.Exts.SrcLoc as HsSrcLoc

haskellExts :: Language
haskellExts = Language "Haskell" "Haskell" [".hs"] parsehs

parsehs :: String -> EitherT Error IO Ast
parsehs s = hoistEither $
  case parse s :: ParseResult (Module HsSrcLoc.SrcSpan) of
    ParseOk t  -> Right $ dataToAstIgnoreByExample getSrcLoc
                                                   (undefined::HsSrcLoc.SrcSpan)
                                                   t
    ParseFailed (HsSrcLoc.SrcLoc _ l c) m -> Left $ ErrLocation (position l c) m

getSrcLoc :: Data t => t -> Maybe SrcSpan
getSrcLoc t = down' (toZipper t) >>= query (def `extQ` atSpan) where

  def :: a -> Maybe SrcSpan
  def _ = Nothing

  atSpan :: HsSrcLoc.SrcSpan -> Maybe SrcSpan
  atSpan (HsSrcLoc.SrcSpan _ c1 c2 c3 c4) = Just $ span c1 c2 c3 c4
