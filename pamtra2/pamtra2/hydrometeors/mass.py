# -*- coding: utf-8 -*-
import numpy as np

from .. import constants

# input names are not arbritrary and have to follow Pamtra2 defaults!

# if this is too slow think about implementing @vectorize
# https://numba.pydata.org/numba-doc/dev/user/vectorize.html

powerLawLiquidPrefactor = np.pi/6 * constants.rhoWater
powerLawIcePrefactor = np.pi/6 * constants.rhoIce

powerLawLiquidExponent = 3.
powerLawIceExponent = 3.


def waterSphere(sizeCenter):
    """mass for water spheres

    Parameters
    ----------
    sizeCenter : array_like
        particle size at center of size bin

    Returns
    -------
    mass : array_like
        particle mass
    """
    return powerLaw(
        sizeCenter, powerLawLiquidPrefactor, powerLawLiquidExponent)


def iceSphere(sizeCenter):
    """mass for ice spheres

    Parameters
    ----------
    sizeCenter : array_like
        particle size at center of size bin

    Returns
    -------
    mass : array_like
        particle mass
    """
    return powerLaw(
        sizeCenter, powerLawIcePrefactor, powerLawIceExponent)


def powerLaw(sizeCenter, massSizeA, massSizeB):
    """classical mass size relation as power law

    Parameters
    ----------
    sizeCenter : array_like
        particle size at center of size bin
    massSizeA : array_like
        mass size pre factor
    massSizeB : float or array_like
        mass size exponent

    Returns
    -------
    mass : array_like
        particle mass
    """

    m = massSizeA*sizeCenter**massSizeB

    return m


def ellipsoid(sizeCenter, aspectRatio, density):
    """mass of a fixed-density ellipsoid

    Parameters
    ----------
    sizeCenter : array_like
        particle size at center of size bin
    density : array_like
        fixed particle density
    aspectRatio : array_like
        particle aspect ratio

    Returns
    -------
    mass : array_like
        particle mass
    """

    if np.any(aspectRatio != 1):
        raise NotImplementedError(
            'aspectRatio!=1 not implemented yet. Patch this function.')

    massSizeA = np.pi/6 * density
    massSizeB = 3.

    return powerLaw(sizeCenter, massSizeA, massSizeB)
