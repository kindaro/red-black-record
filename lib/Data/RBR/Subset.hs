{-| 
    This module contains versions of functions from "Data.RBR", generalized to
    work with a subset of the fields of a 'Record' or the branches of a
    'Variant'.

    Besides working with subsets of fields and branches, this module is useful
    for another thing. The equality of type-level trees is unfortunately too
    strict: inserting the same elements but in /different order/ can result in
    structurally different trees, which in its turn causes annoying errors when
    trying to combine 'Record's, even as they have exactly the same fields.

    To solve these kinds of problems, functions like 'projectSubset' can be
    used to transform 'Record's indexed by one map into records indexed by
    another.

    For example, consider this code:

>>> :{
    prettyShow_RecordI $
      liftA2_Record
        (\_ x -> x)
        ( id
            $ S.projectSubset @(FromList ['("bar", _), '("foo", _)]) -- rearrange
            $ insertI @"foo"
              'a'
            $ insertI @"bar"
              True
            $ unit
        )
        ( id
            $ insertI @"bar"
              True
            $ insertI @"foo"
              'a'
            $ unit
        )
:}
"{bar = True, foo = 'a'}"

    If we remove the 'projectSubset' line that rearranges the structure of the
    first record's index map, the code ceases to compile.
    
    __Note:__ There are functions of the same name in the "Data.RBR" module,
    but they are deprecated. The functions from this module should be used
    instead, preferably qualified. The changes have to do mainly with the
    required constraints.
-}
{-# LANGUAGE DataKinds,
             TypeOperators,
             ConstraintKinds,
             PolyKinds,
             TypeFamilies,
             GADTs,
             MultiParamTypeClasses,
             FunctionalDependencies,
             FlexibleInstances,
             FlexibleContexts,
             UndecidableInstances,
             UndecidableSuperClasses,
             TypeApplications,
             ScopedTypeVariables,
             AllowAmbiguousTypes,
             ExplicitForAll,
             RankNTypes, 
             DefaultSignatures,
             PartialTypeSignatures,
             LambdaCase,
             EmptyCase 
#-}
{-#  OPTIONS_GHC -Wno-partial-type-signatures  #-}
module Data.RBR.Subset (
        -- * The subset constraint
        Subset,
        -- * Record subset functions
        fieldSubset,
        projectSubset,
        getFieldSubset,
        setFieldSubset,
        modifyFieldSubset,
        -- * Variant subset functions
        branchSubset,
        injectSubset,
        matchSubset, 
        -- * Miscellany functions
        fromRecordSuperset,
        eliminateSubset
    ) where

import Data.Proxy
import Data.Kind
import Data.Monoid (Endo(..))
import GHC.TypeLits
import Data.SOP (K(..),I(..))

import Data.RBR.Internal hiding 
    ( 
       ProductlikeSubset,
       fieldSubset,
       projectSubset,
       getFieldSubset,
       setFieldSubset,
       modifyFieldSubset,
       SumlikeSubset,
       branchSubset,
       injectSubset,
       matchSubset,
       eliminateSubset
   )

{- $setup
 
>>> :set -XDataKinds -XTypeApplications -XPartialTypeSignatures -XFlexibleContexts -XTypeFamilies -XDeriveGeneric 
>>> :set -Wno-partial-type-signatures  
>>> import Data.RBR
>>> import qualified Data.RBR.Subset as S
>>> import Data.SOP
>>> import GHC.Generics

-}

{- | A type-level map is a subset of another if all of its entries are present in the other map.

-}
type Subset (subset :: Map Symbol q) (whole :: Map Symbol q) = KeysValuesAll (PresentIn whole) subset


{- | Like 'field', but targets multiple fields at the same time 

-}
fieldSubset :: forall subset whole f. (Maplike subset, Subset subset whole) 
            => Record f whole -> (Record f subset -> Record f whole, Record f subset)
fieldSubset r = 
    (,)
    (let goset :: forall left k v right color. (PresentIn whole k v, KeysValuesAll (PresentIn whole) left, 
                                                                     KeysValuesAll (PresentIn whole) right) 
               => Record (SetField f (Record f whole)) left 
               -> Record (SetField f (Record f whole)) right 
               -> Record (SetField f (Record f whole)) (N color left k v right)
         goset left right = Node left (SetField (\v w -> fst (field @k @whole w) v)) right
         setters :: Record (SetField f (Record f whole)) _ = cpara_Map (Proxy @(PresentIn whole)) unit goset
         appz (SetField func) fv = K (Endo (func fv))
      in \toset -> appEndo (collapse'_Record (liftA2_Record appz setters toset)) r)
    (let goget :: forall left k v right color. (PresentIn whole k v, KeysValuesAll (PresentIn whole) left, 
                                                                     KeysValuesAll (PresentIn whole) right) 
               => Record f left 
               -> Record f right 
               -> Record f (N color left k v right)
         goget left right = Node left (project @k @whole r) right
      in cpara_Map (Proxy @(PresentIn whole)) unit goget)




{- | Like 'project', but extracts multiple fields at the same time.

     The types in the subset tree can often be inferred and left as wildcards in type signature.
 
>>> :{ 
  prettyShow_RecordI
    $ S.projectSubset @(FromList ['("foo", _), '("bar", _)])
    $ insertI @"foo"
      'a'
    $ insertI @"bar"
      True
    $ insertI @"baz"
      (Just ())
    $ unit
:}
"{bar = True, foo = 'a'}"

     This function also be used to convert between 'Record's with structurally dissimilar
     type-level maps that nevertheless hold the same entries. 
-}
projectSubset :: forall subset whole f. (Maplike subset, Subset subset whole) 
              => Record f whole 
              -> Record f subset
projectSubset =  snd . fieldSubset

{- | Alias for 'projectSubset'.
-}
getFieldSubset :: forall subset whole f. (Maplike subset, Subset subset whole)  
               => Record f whole 
               -> Record f subset
getFieldSubset = projectSubset

{- | Like 'setField', but sets multiple fields at the same time.
 
-}
setFieldSubset :: forall subset whole f. (Maplike subset, Subset subset whole) 
               => Record f subset
               -> Record f whole 
               -> Record f whole
setFieldSubset subset whole = fst (fieldSubset whole) subset 

{- | Like 'modifyField', but modifies multiple fields at the same time.
 
-}
modifyFieldSubset :: forall subset whole f. (Maplike subset, Subset subset whole) 
                  => (Record f subset -> Record f subset)
                  -> Record f whole 
                  -> Record f whole
modifyFieldSubset f r = uncurry ($) (fmap f (fieldSubset @subset @whole r))


{- | Like 'branch', but targets multiple branches at the same time.
-}
branchSubset :: forall subset whole f. (Maplike subset, Maplike whole, Subset subset whole)
             => (Variant f whole -> Maybe (Variant f subset), Variant f subset -> Variant f whole)
branchSubset = 
    let inj2case = \adapt (Case vif) -> Case $ \fv -> adapt (vif fv) 
        -- The intuition is that getting the setter and the getter together might be faster at compile-time.
        -- The intuition might be wrong.
        subs :: forall f. Record f whole -> (Record f subset -> Record f whole, Record f subset)
        subs = fieldSubset @subset @whole
     in
     (,)
     (let injs :: Record (Case f (Maybe (Variant f subset))) subset 
          injs = liftA_Record (inj2case Just) (injections'_Variant @subset)
          -- fixme: possibly inefficient?
          wholeinjs :: Record (Case f (Maybe (Variant f subset))) whole 
          wholeinjs = pure_Record (Case (\_ -> Nothing))
          mixedinjs = fst (subs wholeinjs) injs
       in eliminate_Variant mixedinjs)
     (let wholeinjs :: Record (Case f (Variant f whole)) whole
          wholeinjs = liftA_Record (inj2case id) (injections'_Variant @whole)
          injs = snd (subs wholeinjs)
       in eliminate_Variant injs)

{- | Like 'inject', but injects one of several possible branches.
 
     Can also be used to convert between 'Variant's with structurally
     dissimilar type-level maps that nevertheless hold the same entries. 
-}
injectSubset :: forall subset whole f. (Maplike subset, Maplike whole, Subset subset whole)
             => Variant f subset -> Variant f whole
injectSubset = snd (branchSubset @subset @whole)

{- | Like 'match', but matches more than one branch.
-}
matchSubset :: forall subset whole f. (Maplike subset, Maplike whole, Subset subset whole)
            => Variant f whole -> Maybe (Variant f subset)
matchSubset = fst (branchSubset @subset @whole)

{- | 
     Like 'eliminate', but allows the eliminator 'Record' to have more fields
     than there are branches in the 'Variant'.
-}
eliminateSubset :: forall subset whole f r. (Maplike subset, Maplike whole, Subset subset whole)
                => Record (Case f r) whole -> Variant f subset -> r
eliminateSubset cases = 
    let reducedCases = getFieldSubset @subset @whole cases
     in eliminate_Variant reducedCases 

{- | 
     A common composition of 'fromRecord' and 'projectSubset'.
-}
fromRecordSuperset :: forall r t whole. (IsRecordType r t, Maplike t, Subset t whole) => Record I whole -> r 
fromRecordSuperset = fromRecord . projectSubset

