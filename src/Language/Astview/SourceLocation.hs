{-|
this module contains a data type for source locations in a text buffer and
a couple of useful helper functions for source locations.
-}
module Language.Astview.SourceLocation
  (select
  ,addPaths
  ,PathList(..)
  ,toList
  ,singleton
  ,ins
  )

where
import Data.Maybe(catMaybes)
import Data.Tree(Tree(..),flatten)

import Language.Astview.Language
import Language.Astview.GUIData(CursorSelection(..))

-- |transforms a CursorSelection to a SrcSpan
selectionToSpan :: CursorSelection -> SrcLocation
selectionToSpan (CursorSelection lb rb le re) = SrcSpan lb rb le re

-- |every node gains its position in the tree as additional value
addPaths :: Tree a -> Tree (a,[Int])
addPaths = f [0] where
  f :: [Int] -> Tree a -> Tree (a,[Int])
  f p (Node v cs) = Node (v,p) $ zipWith (\i c -> f (p++[i]) c) [0,1..] cs

-- |select the source location path pairs in the tree, s.t.
-- the source locations are the smallest containing given cursor selection.
-- Thus the pairs in the resulting list only differ in their paths.
select :: CursorSelection -> Ast -> PathList
select sele (Ast ast) = 
  bruteForce $ addPaths $ fmap srcloc ast where
  
    bruteForce :: Tree (Maybe SrcLocation,[Int]) -> PathList
    bruteForce tree = 
      let allSrcLocs = catMaybes $ flatten $ fmap getSrcLocPathPairs tree
      in smallest $ locsContainingSelection allSrcLocs 

    getSrcLocPathPairs :: (Maybe SrcLocation,[Int]) -> Maybe (SrcLocation,[Int])
    getSrcLocPathPairs (Nothing,_) = Nothing
    getSrcLocPathPairs (Just s ,p) = Just (s,p)

    locsContainingSelection :: [(SrcLocation,[Int])] -> [(SrcLocation,[Int])] 
    locsContainingSelection = filter (\(s,_) -> s >= selectionToSpan sele )

-- * 

-- |a pathlist stores a source location and paths to all subtrees annotated
-- with the source location
data PathList 
  = Empty -- ^ the empty list
  | PathList  SrcLocation [[Int]] -- ^ a source location and positions in the tree
                                -- where this location occurs
  deriving Eq


instance Show PathList where
  show Empty = "<>"
  show (PathList s p) = "<"++show s++" @ "++show p++">"


singleton :: (SrcLocation,[Int]) -> PathList
singleton (x,p) = PathList x [p]

ins :: (SrcLocation,[Int]) -> PathList -> PathList 
ins (s   ,p   ) Empty = PathList s [p] 
ins (sNew,pNew) (PathList s ps) 
  | s == sNew  = PathList s $ pNew:ps
  | s > sNew   = singleton (sNew,pNew)
  |otherwise   = PathList s ps 

toList :: PathList -> [(SrcLocation,[Int])]
toList Empty = []
toList (PathList s ps) = map (\p -> (s,p)) ps

-- |returns the smallest source location and all paths to operations
-- annotated with this location.
smallest :: [(SrcLocation,[Int])] -> PathList
smallest []     = Empty 
smallest (x:xs) = ins x (smallest xs)
