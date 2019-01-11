module Data.RBR (
        -- * Type-level Red-Black tree
        Color (..),
        RBT (..),
        KeysValuesAll,
        demoteKeys,
        -- * Records and Variants
        Record,
        unit,
        Variant,
        impossible,
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
        -- * Subsetting
        subsetProjection,
        projectSubset,
        getFieldSubset,
        setFieldSubset,
        modifyFieldSubset,
        -- * Interfacing with Data.SOP
        Productlike (..),
        fromNP,
        toNP,
        Sumlike (..),
        fromNS,
        toNS,
        -- * Interfacing with normal records
        NominalRecord (..),
        NominalSum (..),
        -- * Data.SOP re-exports
        I(..),
        K(..),
        NP(..),
        NS(..),
    ) where

import Data.RBR.Internal
import Data.SOP (I(..),K(..),NP(..),NS(..))
