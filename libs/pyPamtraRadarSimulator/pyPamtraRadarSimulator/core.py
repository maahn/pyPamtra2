# -*- coding: utf-8 -
# (c) M. Maahn, 2017

from __future__ import absolute_import, division, print_function

import numpy as np

from . import pyPamtraRadarSimulatorLib as rsLib

__version__ = '0.1'


def radarSimulator(
    diameterSpec,
    specWidth,
    backSpec,
    fallVelSpec,
    pathIntegratedAttenuation,
    height,
    verticalWind,
    horizontalWind,
    eddyDissipationRate,
    wavelength,
    radarMaxV=7.885,
    radarMinV=-7.885,
    radarAliasingNyquistInterv=1,
    radarNFFT=256,
    radarAirmotion=True,
    radarAirmotionModel="constant",
    radarAirmotionVmin=0,
    radarAirmotionVmax=0,
    radarAirmotionLinearSteps=30,
    radarAirmotionStepVmin=0.5,
    radarPNoise1000=-30,
    radarK2=0.93,
    radarNAve=150,
    radarBeamwidthDeg=0.2,
    radarIntegrationTime=60,
    seed=0,
    verbosity=0
):
    """Convert a spectrum of hydrometeor backscattering (per hydrometeor)
    as a function of size into a merged spectrum as a function of velocity.
    Note that the optional shapes of all input variables have to be the same.

    Parameters
    ----------
    diameterSpec :
        Hydrometeo Diameter in m. Shape (range, hydrometeor, hydrometeorBin)
    backSpec :
        Hydrometeo backscattering cross section in m2.  Shape (range,
        hydrometeor, hydrometeorBin)
    fallVelSpec :
        Fall velocity in m/s. Shape (range, hydrometeor,
        hydrometeorBin)
    pathIntegratedAttenuation :
        path integrated attenuation in dB
    height :
        altitude in m
    verticalWind :
        vertical wind in m/s
    horizontalWind :
        horizontal wind in m/s
    eddyDissipationRate :
        eddy dissipation rate in  m^(2/3) s^(-1)
    wavelength :
        wavelength in m
    radarMaxV :
        maximum radar nyquist velocity in m/s (Default value = 7.885)
    radarMinV :
        minimum radar nyquist velocity in m/s (Default value = -7.885)
    radarAliasingNyquistInterv :
        defines how often the spectrum is folded to consider aliasing
        (default 1) (Default value = 1)
    radarNFFT :
        bins of the radar spectrum (Default value = 256)
    radarAirmotion :
        consider vertical air motion (Default value = True)
    radarAirmotionModel : ["constant","linear","step"]
         (Default value = "constant")
    radarAirmotionVmin :
         (Default value = 0)
    radarAirmotionVmax :
         (Default value = 0)
    radarAirmotionLinearSteps :
         (Default value = 30)
    radarAirmotionStepVmin :
         (Default value = 0.5)
    radarPNoise1000 :
        Radar noise at 1 km range in dB (Default value = -30)
    radarK2 :
        dielectric constant |K|² (always for liquid water by convention) for
        the radar equation (Default value = 0.93)
    radarNAve :
        radar number of averages (Default value = 150)
    radarBeamwidthDeg :
        radar full beam width 2-way 6dB drop (Default value = 0.2)
    radarIntegrationTime :
        radar integration time (Default value = 60)
    seed :
        Seed of the random number generator. 0 means the seed is randomly
        generated (Default value = 0)
    verbosity :
        Fortran verbosity level (Default value = 0)

    Returns
    -------
    radar_spectrum : array_like
        Simulated radar spectrum in mm6/m3/(m/s).

    """
    nHydro = diameterSpec.shape[1]
    particleSpecs = []

    for hh in range(nHydro):
        assert not np.all(np.isnan(backSpec[:, hh, :]))

        particleSpec = createRadarSpectrum(
            diameterSpec=diameterSpec[:, hh, :],
            specWidth=specWidth[:, hh, :],
            backSpec=backSpec[:, hh, :],
            fallVelSpec=fallVelSpec[:, hh, :],
            verticalWind=verticalWind,
            wavelength=wavelength,
            radarMaxV=radarMaxV,
            radarMinV=radarMinV,
            radarAliasingNyquistInterv=radarAliasingNyquistInterv,
            radarNFFT=radarNFFT,
            verbosity=verbosity,
            radarAirmotion=radarAirmotion,
            radarAirmotionModel=radarAirmotionModel,
            radarAirmotionVmin=radarAirmotionVmin,
            radarAirmotionVmax=radarAirmotionVmax,
            radarAirmotionLinearSteps=radarAirmotionLinearSteps,
            radarAirmotionStepVmin=radarAirmotionStepVmin,
            radarK2=radarK2,
        )
        particleSpecs.append(particleSpec)
    particleSpecs = np.stack(particleSpecs, axis=0)
    # merge all the hydrometeors
    mergedParticleSpec = np.sum(particleSpecs, axis=0)

    radar_spectrum = simulateRadarSpectrum(
        height=height,
        eddyDissipationRate=eddyDissipationRate,
        horizontalWind=horizontalWind,
        mergedParticleSpec=mergedParticleSpec,
        pathIntegratedAttenuation=pathIntegratedAttenuation,
        wavelength=wavelength,
        radarMaxV=radarMaxV,
        radarMinV=radarMinV,
        radarAliasingNyquistInterv=radarAliasingNyquistInterv,
        radarNFFT=radarNFFT,
        radarPNoise1000=radarPNoise1000,
        radarK2=radarK2,
        radarNAve=radarNAve,
        radarBeamwidthDeg=radarBeamwidthDeg,
        radarIntegrationTime=radarIntegrationTime,
        seed=seed,
        verbosity=verbosity,
    )

    return radar_spectrum


# radarSimulator_ND = decorators.NDto2DtoND(
#     referenceIn=0,
#     noOfInDimsToKeep=2,
#     convertInputs=list(range(11)),
#     convertOutputs=[0],
#     verbosity=1
# )(radarSimulator)


def createRadarSpectrum(
    diameterSpec,
    specWidth,
    backSpec,
    fallVelSpec,
    verticalWind,
    wavelength,
    radarMaxV=7.885,
    radarMinV=-7.885,
    radarAliasingNyquistInterv=1,
    radarNFFT=256,
    radarAirmotion=True,
    radarAirmotionModel="constant",
    radarAirmotionVmin=0,
    radarAirmotionVmax=0,
    radarAirmotionLinearSteps=30,
    radarAirmotionStepVmin=0.5,
    radarK2=0.93,
    verbosity=0,
):
    """First step of the radar simulator which creates an idealized radar
    spectrum for each hydrometeor.

    Parameters
    ----------
    diameterSpec : array_like
        Hydrometeo Diameter in m. Shape (range, hydrometeor, hydrometeorBin)
    backSpec : array_like
        Hydrometeo backscattering cross section in m2.  Shape (range,
        hydrometeor, hydrometeorBin)
    fallVelSpec :
        Fall velocity in m/s. Shape (range, hydrometeor,
        hydrometeorBin)
    pressure : array_like
        Pressure in pa
    wavelength : array_like
        wavelength in m
    radarMaxV :
        maximum radar nyquist velocity in m/s (Default value = 7.885)
    radarMinV :
        minimum radar nyquist velocity in m/s (Default value = -7.885)
    radarAliasingNyquistInterv :
        defines how often the spectrum is folded to consider aliasing
        (default 1) (Default value = 1)
    radarNFFT :
        bins of the radar spectrum (Default value = 256)
    radarAirmotion :
        consider vertical air motion (Default value = True)
    radarAirmotionModel : ["constant","linear","step"]
         (Default value = "constant")
    radarAirmotionVmin :
         (Default value = 0)
    radarAirmotionVmax :
         (Default value = 0)
    radarAirmotionLinearSteps :
         (Default value = 30)
    radarAirmotionStepVmin :
         (Default value = 0.5)
    radarK2 :
        dielectric constant |K|² (always for liquid water by convention) for
        the radar equation (Default value = 0.93)
    verbosity :
        Fortran verbosity level (Default value = 0)

    Returns
    -------
    particleSpec : array_like
        Idealized radar spectrum in mm6/m3.
    """

    # Fortran is picky about shapes. So make sure everything is aligned
    # properly.
    assert np.ndim(diameterSpec) == 2
    assert np.shape(diameterSpec) == np.shape(backSpec)
    assert np.shape(diameterSpec) == np.shape(fallVelSpec)
    assert np.shape(diameterSpec) == np.shape(specWidth)
    assert np.shape(verticalWind)[0] == np.shape(diameterSpec)[0]
    assert np.ndim(verticalWind) == 1
    assert np.shape(verticalWind) == np.shape(wavelength)

    assert np.all(diameterSpec > 0)
    assert np.all(specWidth > 0)
    assert np.all(backSpec >= 0)
    assert np.all(np.isreal(fallVelSpec))
    assert np.all(wavelength > 0)
    assert radarMaxV >= 0
    assert radarMinV <= 0
    assert radarMaxV > radarMinV
    assert radarAliasingNyquistInterv >= 0
    assert radarNFFT > 0
    assert type(radarAirmotion) is bool
    assert radarAirmotionModel in ['constant', 'step', 'linear']
    assert np.isreal(radarAirmotionVmin)
    assert np.isreal(radarAirmotionVmax)
    assert radarAirmotionLinearSteps > 0
    assert radarAirmotionStepVmin > 0
    assert radarK2 > 0
    assert verbosity >= 0

    rsLib.report_module.verbose = verbosity

    radarNFFTAliased = radarNFFT * (1 + 2 * radarAliasingNyquistInterv)

    nHeights = verticalWind.shape[0]
    particleSpec = np.zeros((radarNFFTAliased, nHeights))

    # make sure we don't have sizes more than once.
    nUniqueSizes = np.asarray([len(np.unique(diameterSpec[ii, :]))
                               for ii in range(diameterSpec.shape[0])])
    assert np.all(diameterSpec.shape[1] == nUniqueSizes)

    # to do: expose vel_spec in case you need nothing else.

    error, particleSpec, vel_spec = rsLib.radar_spectrum.get_radar_spectrum(
        diameter_spec=diameterSpec,
        spec_width=specWidth,
        back_spec=backSpec,
        fallvel=fallVelSpec,
        atmo_wind_w=verticalWind,
        wavelength=wavelength,
        radar_max_v=radarMaxV,
        radar_min_v=radarMinV,
        radar_aliasing_nyquist_interv=radarAliasingNyquistInterv,
        radar_nfft=radarNFFT,
        radar_nfft_aliased=radarNFFTAliased,
        radar_airmotion=radarAirmotion,
        radar_airmotion_model=radarAirmotionModel,
        radar_airmotion_vmin=radarAirmotionVmin,
        radar_airmotion_vmax=radarAirmotionVmax,
        radar_airmotion_linear_steps=radarAirmotionLinearSteps,
        radar_airmotion_step_vmin=radarAirmotionStepVmin,
        radar_k2=radarK2,
    )
    if error > 0:
        raise RuntimeError('Error in Fortran routine radar_spectrum')

    return particleSpec


def simulateRadarSpectrum(
    height,
    eddyDissipationRate,
    horizontalWind,
    mergedParticleSpec,
    pathIntegratedAttenuation,
    wavelength,
    radarMaxV=7.885,
    radarMinV=-7.885,
    radarAliasingNyquistInterv=1,
    radarNFFT=256,
    radarPNoise1000=-30,
    radarK2=0.93,
    radarNAve=150,
    radarBeamwidthDeg=0.2,
    radarIntegrationTime=60,
    seed=0,
    verbosity=0
):
    """

    Parameters
    ----------
    height :
        altitude in m
    eddyDissipationRate :
        eddy dissipation rate in  m^(2/3) s^(-1)
    horizontalWind :
        horizontal wind in m/s
    mergedParticleSpec :
        idealized radar spectrum in mm6/m3. Sum for all hydrometeors.
    pathIntegratedAttenuation :
        path integrated attenuation in dB
    wavelength :
        wavelength in m
    radarMaxV :
        maximum radar nyquist velocity in m/s (Default value = 7.885)
    radarMinV :
        minimum radar nyquist velocity in m/s (Default value = -7.885)
    radarAliasingNyquistInterv :
        defines how often the spectrum is folded to consider aliasing
        (Default value = 1)
    radarNFFT :
        bins of the radar spectrum (Default value = 256)
    radarPNoise1000 :
        Radar noise at 1 km range in dB (Default value = -30)
    radarK2 :
        dielectric constant |K|² (always for liquid water by convention) for
        the radar equation (Default value = 0.93)
    radarNAve :
        radar number of averages (Default value = 150)
    radarBeamwidthDeg :
        radar full beam width 2-way 6dB drop (Default value = 0.2)
    radarIntegrationTime :
        radar integration time (Default value = 60)
    seed :
        Seed of the random number generator. 0 means the seed is randomly
        generated (Default value = 0)
    verbosity :
        Fortran verbosity level (Default value = 0)


    Returns
    -------

    """

    assert np.all(height > -420) # altitude Dead Sea
    assert np.all(eddyDissipationRate > 0)
    assert np.all(horizontalWind >= 0)
    assert np.all(mergedParticleSpec >= 0)
    assert np.all(pathIntegratedAttenuation >= 0)
    assert np.all(wavelength > 0)
    assert radarMaxV >= 0
    assert radarMinV <= 0
    assert radarMaxV > radarMinV
    assert radarAliasingNyquistInterv >= 0
    assert radarNFFT > 0
    assert np.isreal(radarPNoise1000)
    assert radarK2 > 0
    assert radarNAve >= 0
    assert radarBeamwidthDeg > 0
    assert radarIntegrationTime >= 0
    assert seed >= 0
    assert verbosity >= 0

    rsLib.report_module.verbose = verbosity

    # In case we are using a fixed seed, make sure we start the beginning
    # again.
    rsLib.random_module.counter = 0

    # estimate noise from value at 1 km:
    radarPNnoise = 10**(0.1 * radarPNoise1000) * (height / 1000.)**2

    kolmogorov = 0.5

    error, spectralBroadening = rsLib.radar_spectral_broadening(
        eddyDissipationRate,
        horizontalWind,
        height,
        radarBeamwidthDeg,
        radarIntegrationTime,
        wavelength,
        kolmogorov
    )
    if error > 0:
        raise RuntimeError(
            'Error in Fortran routine radar_spectral_broadening')

    error, radar_spectrum = rsLib.radar_simulator.simulate_radar(
        wavelength,
        mergedParticleSpec,
        pathIntegratedAttenuation,
        spectralBroadening,
        radarPNnoise,
        radarMaxV,
        radarMinV,
        radarNFFT,
        radarNAve,
        radarAliasingNyquistInterv,
        radarK2,
        seed,
    )
    if error > 0:
        raise RuntimeError('Error in Fortran routine simulate_radar')

    return radar_spectrum


def calcSpectralBroadening(
    eddyDissipationRate,
    horizontalWind,
    height,
    wavelength,
    radarBeamwidthDeg=0.2,
    radarIntegrationTime=60,
    kolmogorov=0.5,
    verbosity=0
):
    """Estimate the spectral broadening due to turbulence and horizontal wind.

    Parameters
    ----------
    eddyDissipationRate : array_like
        eddy dissipation rate in  m^(2/3) s^(-1)
    horizontalWind : array_like
        horizontal wind in m/s
    height : array_like
        heigth in m
    radarBeamwidthDeg : float
        Full width half power Beamwidth in degrees (Default value = 0.2)
    radarIntegrationTime : float
        Integration time in seconds (Default value = 60)
    wavelength : float
        wavelength in m
    kolmogorov : float, optional
        Kolmogorov constant (default 0.5)
    verbosity : integer, optional
        Define verbosity level (default 0)

    Returns
    -------
    radar_spectrum : array_like
        Simulated radar spectrum in mm6/m3/(m/s). 
    """

    rsLib.report_module.verbose = verbosity

    assert np.ndim(eddyDissipationRate) == 1, 'eddyDissipationRate must be 1D'
    assert np.ndim(horizontalWind) == 1, 'horizontalWind has to be 1D'
    assert np.ndim(height) == 1, 'height has to be 1D'

    error, specbroad = rsLib.radar_spectral_broadening(
        eddyDissipationRate,
        horizontalWind,
        height,
        radarBeamwidthDeg,
        radarIntegrationTime,
        wavelength,
        kolmogorov
    )

    if error > 0:
        raise RuntimeError(
            'Error in Fortran routine estimate_spectralbroadening')

    return specbroad
