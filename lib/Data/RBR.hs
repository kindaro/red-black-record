module Data.RBR (
        -- * Type-level Red-Black tree
        Color (..),
        RBT (..),
        KeysValuesAll,
        demoteKeys,
        -- * Records and Variants
        Record,
        unit,
        prettyShowRecord,
        prettyShowRecordI,
        Variant,
        impossible,
        prettyShowVariantI,
        -- ** Inserting and widening
        Insertable (..),
        addField,
        insertI,
        addFieldI,
        InsertAll,
        FromList,
        -- ** Projecting and injecting
        Key (..),
        project,
        projectI,
        getField,
        getFieldI,
        setField,
        setFieldI,
        modifyField,
        modifyFieldI,
        inject,
        injectI,
        match,
        matchI,
        -- ** Eliminating variants
        eliminate,
        Case (..),
        addCase,
        addCaseI,
        -- ** Subsets of fields and branches
        ProjectableSubset,
        fieldSubset,
        projectSubset,
        getFieldSubset,
        setFieldSubset,
        modifyFieldSubset,
        InjectableSubset,
        branchSubset,
        injectSubset,
        matchSubset,
        eliminateSubset,
        -- * Interfacing with normal records
        FromRecord (..),
        ToRecord (..),
        -- NominalSum (..),
        -- * Interfacing with Data.SOP
        PrefixNP (..),
        fromNP,
        toNP,
        PrefixNS (..),
        fromNS,
        toNS,
        -- * Data.SOP re-exports
        I(..),
        K(..),
        NP(..),
        NS(..),
    ) where

import Data.RBR.Internal
import Data.SOP (I(..),K(..),NP(..),NS(..))
