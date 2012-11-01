{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE DeriveDataTypeable #-}

{-# LANGUAGE UndecidableInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Diagrams.TwoD.Types
-- Copyright   :  (c) 2011 diagrams-lib team (see LICENSE)
-- License     :  BSD-style (see LICENSE)
-- Maintainer  :  diagrams-discuss@googlegroups.com
--
-- Basic types for two-dimensional Euclidean space.
--
-----------------------------------------------------------------------------

module Diagrams.TwoD.Types
       ( -- * 2D Euclidean space
         R2, r2, unr2
       , P2, p2, unp2
       , D2, d2, und2
       , T2

         -- * Angles
       , Angle(..)
       , CircleFrac(..), Rad(..), Deg(..)
       , fullCircle, convertAngle
       ) where

import Diagrams.Coordinates
import Diagrams.Util (tau)
import Diagrams.Core

import Control.Newtype

import Data.Basis
import Data.NumInstances ()
import Data.VectorSpace

import Data.Typeable

------------------------------------------------------------
-- 2D Euclidean space

-- | The two-dimensional Euclidean vector space R^2.  This type is
--   intentionally abstract.
--
--   * To construct a vector, use 'r2', or '&' (from "Diagrams.Coordinates"):
--
-- > r2 (3,4) :: R2
-- > 3 & 4    :: R2
--
--   * To construct the vector from the origin to a point @p@, use
--     @p 'Data.AffineSpace..-.' 'origin'@.
--
--   * To convert a vector @v@ into the point obtained by following
--     @v@ from the origin, use @'origin' 'Data.AffineSpace..+^' v@.
--
--   * To convert a vector back into a pair of components, use 'unv2'
--     or 'coords' (from "Diagrams.Coordinates").  These are typically
--     used in conjunction with the @ViewPatterns@ extension:
--
-- > foo (unr2 -> (x,y)) = ...
-- > foo (coords -> x :& y) = ...

newtype D2 a = D2 { unD2 :: (a, a) }
  deriving (Eq, Ord, Typeable, Num, Fractional)

d2 :: (a, a) -> D2 a
d2 = D2

und2 :: D2 a -> (a, a)
und2 = unpack

type R2 = D2 Double

unR2 :: R2 -> (Double, Double)
unR2 = unD2

instance (Show a, Num a, Ord a) => Show (D2 a) where
  showsPrec p (D2 (x,y)) = showParen (p >= 7) $
    showCoord x . showString " & " . showCoord y
   where
    showCoord x | x < 0     = showParen True (shows x)
                | otherwise = shows x

instance (Read a) => Read (D2 a) where
  readsPrec d r = readParen (d > app_prec)
                  (\r -> [ (D2 (x,y), r''')
                         | (x,r')    <- readsPrec (amp_prec + 1) r
                         , ("&",r'') <- lex r'
                         , (y,r''')  <- readsPrec (amp_prec + 1) r''
                         ])
                  r
    where
      app_prec = 10
      amp_prec = 7

instance Newtype (D2 a) (a, a) where
  pack   = D2
  unpack = unD2

-- | Construct a 2D vector from a pair of components.  See also '&'.
r2 :: (Double, Double) -> R2
r2 = pack

-- | Convert a 2D vector back into a pair of components.  See also 'coords'.
unr2 :: R2 -> (Double, Double)
unr2 = unpack

type instance V R2 = R2

instance (AdditiveGroup a) => AdditiveGroup (D2 a) where
  zeroV = d2 (zeroV, zeroV)
  a ^+^ b = let (ax, ay) = und2 a
                (bx, by) = und2 b
            in d2 (ax ^+^ bx, ay ^+^ by)
  negateV a = let (ax, ay) = und2 a 
              in d2 (negateV ax, negateV ay)

instance (AdditiveGroup a, Num a) => VectorSpace (D2 a) where
  type Scalar (D2 a) = a
  s *^ v = let (vx, vy) = und2 v
           in d2 (s * vx, s * vy)

-- GHC can't deduce "a ~ Scalar a", so it has to be added here.
-- This is why "UndecidableInstances" is needed.
instance (AdditiveGroup a, Num a, HasBasis a, a ~ Scalar a) => HasBasis (D2 a) where
  type Basis (D2 a) = Basis (a,a) -- should be equal to: Either (Basis a) (Basis a)
  basisValue = d2 . basisValue
  decompose  = decompose  . und2
  decompose' = decompose' . und2

instance (AdditiveGroup a, Num a, InnerSpace a, a ~ Scalar a) => InnerSpace (D2 a) where
  (und2 -> vec1) <.> (und2 -> vec2) = vec1 <.> vec2

instance Coordinates (D2 a) where
  type FinalCoord (D2 a)     = a
  type PrevDim (D2 a)        = a
  type Decomposition (D2 a)  = a :& a

  x & y                  = d2 (x,y)
  coords (unD2 -> (x,y)) = x :& y

-- | Points in R^2.  This type is intentionally abstract.
--
--   * To construct a point, use 'p2', or '&' (see
--     "Diagrams.Coordinates"):
--
-- > p2 (3,4)  :: P2
-- > 3 & 4     :: P2
--
--   * To construct a point from a vector @v@, use @'origin' 'Data.AffineSpace..+^' v@.
--
--   * To convert a point @p@ into the vector from the origin to @p@,
--   use @p 'Data.AffineSpace..-.' 'origin'@.
--
--   * To convert a point back into a pair of coordinates, use 'unp2',
--     or 'coords' (from "Diagrams.Coordinates").  It's common to use
--     these in conjunction with the @ViewPatterns@ extension:
--
-- > foo (unp2 -> (x,y)) = ...
-- > foo (coords -> x :& y) = ...
type P2 = Point R2

-- | Construct a 2D point from a pair of coordinates.  See also '&'.
p2 :: (Double, Double) -> P2
p2 = pack . pack

-- | Convert a 2D point back into a pair of coordinates.  See also 'coords'.
unp2 :: P2 -> (Double, Double)
unp2 = unpack . unpack

-- | Transformations in R^2.
type T2 = Transformation R2

instance Transformable R2 where
  transform = apply

------------------------------------------------------------
-- Angles

-- | Newtype wrapper used to represent angles as fractions of a
--   circle.  For example, 1\/3 = tau\/3 radians = 120 degrees.
newtype CircleFrac = CircleFrac { getCircleFrac :: Double }
  deriving (Read, Show, Eq, Ord, Enum, Floating, Fractional, Num, Real, RealFloat, RealFrac)

-- | Newtype wrapper for representing angles in radians.
newtype Rad = Rad { getRad :: Double }
  deriving (Read, Show, Eq, Ord, Enum, Floating, Fractional, Num, Real, RealFloat, RealFrac)

-- | Newtype wrapper for representing angles in degrees.
newtype Deg = Deg { getDeg :: Double }
  deriving (Read, Show, Eq, Ord, Enum, Floating, Fractional, Num, Real, RealFloat, RealFrac)

-- | Type class for types that measure angles.
class Num a => Angle a where
  -- | Convert to a fraction of a circle.
  toCircleFrac   :: a -> CircleFrac

  -- | Convert from a fraction of a circle.
  fromCircleFrac :: CircleFrac -> a

instance Angle CircleFrac where
  toCircleFrac   = id
  fromCircleFrac = id

-- | tau radians = 1 full circle.
instance Angle Rad where
  toCircleFrac   = CircleFrac . (/tau) . getRad
  fromCircleFrac = Rad . (*tau) . getCircleFrac

-- | 360 degrees = 1 full circle.
instance Angle Deg where
  toCircleFrac   = CircleFrac . (/360) . getDeg
  fromCircleFrac = Deg . (*360) . getCircleFrac

-- | An angle representing a full circle.
fullCircle :: Angle a => a
fullCircle = fromCircleFrac 1

-- | Convert between two angle representations.
convertAngle :: (Angle a, Angle b) => a -> b
convertAngle = fromCircleFrac . toCircleFrac