module radar_spectrum

contains

   subroutine get_radar_spectrum( &
      errorstatus, &
      nbins, & !in
      n_heights, & !in
      diameter_spec, & !in
      spec_width, & !in
      back_spec, & !in
      fallVel, & !in
      atmo_wind_w, & !in
      wavelength, & !in
      radar_max_V, & !in
      radar_min_V, & !in
      radar_aliasing_nyquist_interv, & !in
      radar_nfft, & !in
      radar_nfft_aliased, & !in
      radar_airmotion, & !in
      radar_airmotion_model, & !in
      radar_airmotion_vmin, & !in
      radar_airmotion_vmax, & !in
      radar_airmotion_linear_steps, & !in
      radar_airmotion_step_vmin, & !in
      radar_K2, & !in
      particle_spec, & !out
      vel_spec) !out

      use kinds
      use constants
      use report_module

      implicit none

      integer, intent(in) ::  nbins

      real(kind=dbl), dimension(n_heights, nbins), intent(in):: diameter_spec
      real(kind=dbl), dimension(n_heights, nbins), intent(in):: spec_width
      real(kind=dbl), dimension(n_heights, nbins), intent(in):: back_spec
      real(kind=dbl), dimension(n_heights, nbins), intent(in):: fallVel
      real(kind=dbl), dimension(n_heights), intent(in):: wavelength
      real(kind=dbl), dimension(n_heights), intent(in):: atmo_wind_w
      integer, intent(in) :: n_heights
      real(kind=dbl), intent(in) ::  radar_max_V
      real(kind=dbl), intent(in) ::  radar_min_V
      integer, intent(in) ::  radar_aliasing_nyquist_interv
      integer, intent(in) ::  radar_nfft
      integer, intent(in):: radar_nfft_aliased
      logical, intent(in) ::  radar_airmotion ! apply vertical air motion
      character(8), intent(in) :: radar_airmotion_model
      integer(kind=long), intent(in) :: radar_airmotion_linear_steps
      real(kind=dbl), intent(in) :: radar_airmotion_vmin
      real(kind=dbl), intent(in) :: radar_airmotion_vmax
      real(kind=dbl), intent(in) :: radar_airmotion_step_vmin
      real(kind=dbl), intent(in) :: radar_K2
      real(kind=dbl), dimension(n_heights, radar_nfft_aliased), intent(out):: particle_spec
      real(kind=dbl), dimension(n_heights, nbins), intent(out):: vel_spec

      integer :: zz

      integer(kind=long), intent(out) :: errorstatus
      integer(kind=long) :: err = 0
      character(len=80) :: msg
      character(len=18) :: nameOfRoutine = 'get_radar_spectrum'

      if (verbose >= 2) call report(info, 'Start of ', nameOfRoutine)
      err = 0

      if (verbose >= 5) then
         print*, 'nbins', SHAPE(nbins), nbins
         print*, 'n_heights', SHAPE(n_heights), n_heights
         print*, '1 diameter_spec', SHAPE(diameter_spec), diameter_spec
         print*, '1a spec_width', SHAPE(spec_width), spec_width
         print*, '2 back_spec', SHAPE(back_spec), back_spec
         print*, '10 fallVel', fallVel
         print*, '8 atmo_wind_w', SHAPE(atmo_wind_w), atmo_wind_w
         print*, '9 wavelength', SHAPE(wavelength), wavelength
         print*, '11 radar_max_V', radar_max_V
         print*, '12 radar_min_V', radar_min_V
         print*, '13 radar_aliasing_nyquist_interv', radar_aliasing_nyquist_interv
         print*, '14 radar_nfft', radar_nfft
         print*, '13*14 radar_nfft_aliased', radar_nfft_aliased
         print*, '15 radar_airmotion', radar_airmotion
         print*, '16 radar_airmotion_model', radar_airmotion_model
         print*, '17 radar_airmotion_vmin', radar_airmotion_vmin
         print*, '18 radar_airmotion_vmax', radar_airmotion_vmax
         print*, '19 radar_airmotion_linear_steps', radar_airmotion_linear_steps
         print*, '20 radar_airmotion_step_vmin', radar_airmotion_step_vmin
         print*, '21 radar_K2', radar_K2
      end if



      particle_spec(:, :) = -9999.d0

      do zz = 1, n_heights

         if (ANY(ISNAN(diameter_spec(zz, :))) .or. &
             ANY(ISNAN(back_spec(zz, :))) .or. &
             ANY(ISNAN(fallVel(zz, :))) &
             ) then

            if (verbose >= 2) print *, 'skipping due to NAN', zz

            CYCLE
         end if

         call get_radar_spectrum_one( &
            errorstatus, &
            nbins, & !in
            diameter_spec(zz, :), & !in
            spec_width(zz, :), &
            back_spec(zz, :), & !in
            fallVel(zz,:), & !in
            atmo_wind_w(zz), & !in
            wavelength(zz), & !in
            radar_max_V, & !in
            radar_min_V, & !in
            radar_aliasing_nyquist_interv, & !in
            radar_nfft, & !in
            radar_nfft_aliased, & !in
            radar_airmotion, & !in
            radar_airmotion_model, & !in
            radar_airmotion_vmin, & !in
            radar_airmotion_vmax, & !in
            radar_airmotion_linear_steps, & !in
            radar_airmotion_step_vmin, & !in
            radar_K2, & !in
            particle_spec(zz, :), &
            vel_spec(zz, :)) !out
         !out

         if (err /= 0) then
            msg = 'error in get_radar_spectrum_one!'
            call report(err, msg, nameOfRoutine)
            errorstatus = err
            return
         end if

      end do
      if (verbose >= 2) call report(info, 'End of ', nameOfRoutine)

   end subroutine get_radar_spectrum

   subroutine get_radar_spectrum_one( &
      errorstatus, &
      nbins, & !in
      diameter_spec, & !in
      spec_width, & !in
      back_spec, & !in
      fallVel, & !in
      atmo_wind_w, & !in
      wavelength, & !in
      radar_max_V, & !in
      radar_min_V, & !in
      radar_aliasing_nyquist_interv, & !in
      radar_nfft, & !in
      radar_nfft_aliased, & !in
      radar_airmotion, & !in
      radar_airmotion_model, & !in
      radar_airmotion_vmin, & !in
      radar_airmotion_vmax, & !in
      radar_airmotion_linear_steps, & !in
      radar_airmotion_step_vmin, & !in
      radar_K2, & !in
      particle_spec, & !out
      vel_spec) !out

      ! this routine takes the backscattering spectrum depending on size and converts it
      ! into a spectrum depending on radar Doppler (=fall) velocity
      ! based on Spectra_simulator by P. Kollias
      !

      ! Current Code Owner: IGMK
      !
      ! History:
      !
      ! Version   Date       Comment
      ! -------   ----       -------
      ! 0.1       28/11/2012 converted from Matlab to Fortran - M. Maahn
      ! 0.2       15/04/2013 Application of European Standards for Writing and
      !                      Documenting Exchangeable Fortran 90 Code - M. Maahn
      ! 0.3       12/07/2013 adapted for new descripot files - M. Maahn
      ! 0.4       23/09/2017 moved to PamRaSim - M. Maahn
      !
      ! Code Description:
      !   Language:               Fortran 90.
      !   Software Standards: "European Standards for Writing and
      !     Documenting Exchangeable Fortran 90 Code".
      !

      !in
      !nbins: No of bins
      !diameter_spec: Diameter Spectrum (SI)
      !back_spec: backscattering cross section per volume in m²/m⁴ (includes number density)
      !atmo_wind_w: vertical wind in m/s
      !wavelength in m
      !vallVel: fall velocity of particle
      !out
      !particle_spec particle spectrum in dependence of radar Doppler velocity in m6 m-3/ms-1

      use kinds
      use constants
      use report_module
      use dia2vel
      use rescale_spec

      implicit none

      integer, intent(in) ::  nbins

      real(kind=dbl), dimension(nbins), intent(in):: diameter_spec
      real(kind=dbl), dimension(nbins), intent(in):: spec_width
      real(kind=dbl), dimension(nbins), intent(in):: back_spec
      real(kind=dbl), dimension(nbins), intent(in) :: fallVel
      real(kind=dbl), intent(in):: wavelength
      real(kind=dbl), intent(in):: atmo_wind_w
      real(kind=dbl), intent(in) ::  radar_max_V
      real(kind=dbl), intent(in) ::  radar_min_V
      integer, intent(in) ::  radar_aliasing_nyquist_interv
      integer, intent(in) ::  radar_nfft
      integer, intent(in):: radar_nfft_aliased
      logical, intent(in) ::  radar_airmotion ! apply vertical air motion
      character(8), intent(in) :: radar_airmotion_model
      integer(kind=long), intent(in) :: radar_airmotion_linear_steps
      real(kind=dbl), intent(in) :: radar_airmotion_vmin
      real(kind=dbl), intent(in) :: radar_airmotion_vmax
      real(kind=dbl), intent(in) :: radar_airmotion_step_vmin
      real(kind=dbl), intent(in) :: radar_K2
      real(kind=dbl), intent(out), dimension(radar_nfft_aliased):: particle_spec
      real(kind=dbl), intent(out), dimension(nbins):: vel_spec

      real(kind=dbl):: back
      real(kind=dbl), dimension(nbins):: dD_dU, back_vel_spec, back_spec_ref, &
                                         del_v_model, diameter_spec_cp, &
                                         diameter_spec_cp2, back_spec_cp
      real(kind=dbl), dimension(nbins) :: vel_spec_ext, back_vel_spec_ext
      real(kind=dbl), dimension(:, :), allocatable :: particle_spec_ext
      real(kind=dbl), dimension(radar_nfft_aliased):: out_radar_velo_aliased
      real(kind=dbl):: del_v_radar, K2, &
                       delta_air, rho_air, rho, viscosity, nu, Ze, K, &
                       min_V_aliased, max_V_aliased, k_factor
      integer :: ii, jj
      integer(kind=long), intent(out) :: errorstatus
      integer(kind=long) :: err = 0
      character(len=80) :: msg
      character(len=22) :: nameOfRoutine = 'get_radar_spectrum_one'

      if (verbose >= 2) then
         call report(info, 'Start of ', nameOfRoutine)
         print *, "back,nbins", back, nbins
      end if
      err = 0

      back = SUM(back_spec)

      call assert_true(err, all(diameter_spec > 0), &
                       "nan or negative diameter_spec")
      call assert_true(err, all(spec_width > 0), &
                       "nan or negative spec_width")
      call assert_true(err, all(back_spec >= 0), &
                       "nan or negative back_spec")
      call assert_true(err, nbins > 1, &
                       "nbins must be greater than 1 for the radar simulator!")
      call assert_true(err, back >= 0, &
                       "nan or negative back")
      call assert_true(err, wavelength > 0, &
                       "nan or negative wavelength")
      ! call assert_true(err, all(mass >= 0), &
      !                  "nan or negative mass")
      call assert_true(err, all(fallVel >= 0), &
                       "nan or negative fallVel")
      call assert_true(err, (radar_nfft_aliased > 0), &
                       "nan or negative radar_nfft_aliased")
      if (err > 0) then
         errorstatus = fatal
         msg = "assertation error"
         call report(errorstatus, msg, nameOfRoutine)
         return
      end if

      if (back == 0) then
         if (verbose >= 2) call report(info, 'Taking shortcut because of back==0', nameOfRoutine)
         particle_spec(:) = 0.d0
         errorstatus = err
         if (verbose >= 2) call report(info, 'End of ', nameOfRoutine)
         return
      end if

      !initialize
      back_vel_spec_ext(:) = 0.d0
      vel_spec_ext(:) = 0.d0

      !     K2 = dielec_water(0.D0,radar_K2_temp-t_abs,frequency)
      K2 = radar_K2

      diameter_spec_cp(:) = diameter_spec(:)
      diameter_spec_cp2(:) = diameter_spec(:)
      back_spec_cp(:) = back_spec(:)
      vel_spec(:) = fallVel


      ! to do: make this more efficient and sort all three arrays at once!
      call dsort(err, diameter_spec_cp, back_spec_cp, nbins, 2)
      if (err /= 0) then
         msg = 'error in dsort!'
         call report(err, msg, nameOfRoutine)
         errorstatus = err
         return
      end if
      call dsort(err, diameter_spec_cp2, vel_spec, nbins, 2)
      if (err /= 0) then
         msg = 'error in dsort!'
         call report(err, msg, nameOfRoutine)
         errorstatus = err
         return
      end if

      !if in-situ measurements are used, mass or area might be zero (since corresponding ndens=0 as well)
      ! where ((area == 0.d0) .or. (mass == 0.d0))
      ! vel_spec = 0.d0
      ! end where

      call assert_true(err, all(vel_spec >= 0) .and. (MAXVAL(vel_spec) < HUGE(vel_spec)), &
                       "nan or negative vel_spec")
      if (err /= 0) then
         msg = 'error in dia2vel_XX!'
         call report(err, msg, nameOfRoutine)
         errorstatus = err
         return
      end if

      back_spec_ref = (1d0/(K2*pi**5))*back_spec_cp*(wavelength)**4 ![m⁶/m³]
      back_spec_ref = back_spec_ref/spec_width !now  [m⁶/m³/m]

      !spetial output for testing the radar simulator
      if (verbose >= 5) then
         print *, "##########################################"
         print *, "Diameter (D)"
         print *, diameter_spec
         print *, "##########################################"
         print *, "back_spec_ref (D) [m⁶/m³/m]"
         print *, back_spec_ref
         print *, "##########################################"
      end if

      Ze = 1d18*(1d0/(K2*pi**5))*back*(wavelength)**4

      !move from dimension to velocity!
      do jj = 1, nbins - 1
         dD_dU(jj) = (diameter_spec_cp(jj + 1) - diameter_spec_cp(jj))/(vel_spec(jj + 1) - vel_spec(jj)) ![m/(m/s)]
         ! if all particles fall with the same velocity, dD_dU gets infinitive!
         if (abs(dD_dU(jj)) .ge. huge(dD_dU(jj))) then
            !             print*, jj,(diameter_spec_cp(jj+1)-diameter_spec_cp(jj)), (vel_spec(jj+1)-vel_spec(jj))
            !             errorstatus = fatal
            msg = "get_radar_spectrum_one: dD_dU is infinitive"
            call report(warning, msg, nameOfRoutine)
            !             return
            dD_dU(jj) = 0.d0
         end if

         if (verbose >= 4) print *, "jj,diameter_spec_cp(jj),vel_spec(jj), back_spec_ref(jj),dD_dU(jj)", jj, &
            diameter_spec_cp(jj), vel_spec(jj), back_spec_ref(jj), dD_dU(jj)
         del_v_model(jj) = ABS(vel_spec(jj + 1) - vel_spec(jj))
      end do
      dD_dU(nbins) = dD_dU(nbins - 1)

      call assert_false(err, any(isnan(dD_dU)), &
                        "nan  dD_dU")
      ! if (.not. radar_allow_negative_dD_dU) then
      !     call assert_false(err,any(dD_dU <= 0.d0),&
      !         "negative  dD_dU")
      ! end if
      call assert_false(err, any(vel_spec < 0) .or. any(isnan(vel_spec)), &
                        "nan or negative vel_spec")
      if (err /= 0) then
         msg = 'error in get_radar_spectrum_one!'
         call report(err, msg, nameOfRoutine)
         errorstatus = err
         return
      end if

      del_v_model(nbins) = del_v_model(nbins - 1)
      back_vel_spec = back_spec_ref*ABS(dD_dU) !non-SI: [mm⁶/m³/m * m/(m/s)]
      !get delta velocity
      del_v_radar = (radar_max_V - radar_min_V)/radar_nfft ![m/s]

      min_V_aliased = radar_min_V - radar_aliasing_nyquist_interv*(radar_max_V - radar_min_V)
      max_V_aliased = radar_max_V + radar_aliasing_nyquist_interv*(radar_max_V - radar_min_V)

      call assert_true(err, radar_min_V <= 0, &
                       "radar_min_V must be smaller equal 0")
      call assert_true(err, radar_max_V >= 0, &
                       "radar_max_V must be greater equal 0")
      call assert_true(err, min_V_aliased <= MINVAL(vel_spec), &
                       "increase radar_aliasing_nyquist_interv to the left!")
      call assert_true(err, max_V_aliased >= MAXVAL(vel_spec), &
                       "increase radar_aliasing_nyquist_interv to the right!")
      if (err /= 0) then
         print *, "min_V_aliased, MINVAL(vel_spec), max_V_aliased, MAXVAL(vel_spec)"
         print *, min_V_aliased, MINVAL(vel_spec), max_V_aliased, MAXVAL(vel_spec)
         msg = 'error in get_radar_spectrum_one!'
         call report(err, msg, nameOfRoutine)
         errorstatus = err
         return
      end if

      !create array from min_v to max_v iwth del_v_radar spacing -> velocity spectrum of radar
      out_radar_velo_aliased = (/(((ii*del_v_radar) + min_V_aliased), ii=0, radar_nfft_aliased - 1)/) ! [m/s]

      !add vertical air motion to the observations
      if (radar_airmotion) then
         if (verbose >= 3) call report(info, "Averaging spectrum and Adding vertical air motion: "// &
                                       radar_airmotion_model, nameOfRoutine)
         !constant air motion
         if (radar_airmotion_model .eq. "constant") then
            if ((atmo_wind_w /= 0.0) .and. (.not. ISNAN(atmo_wind_w))) then
               vel_spec = vel_spec + atmo_wind_w
            else
               vel_spec = vel_spec + radar_airmotion_vmin
            end if
            !interpolate OR average (depending who's bins size is greater) from N(D) bins to radar bins.
            ! particle_spec in [mm⁶/m³/m * m/(m/s)]
            call rescale_spectra(err, nbins, radar_nfft_aliased, .true., &
                                 vel_spec, back_vel_spec, out_radar_velo_aliased, particle_spec)
            !step function
         else if (radar_airmotion_model .eq. "step") then

            allocate (particle_spec_ext(2, radar_nfft_aliased))
            !for vmin
            vel_spec_ext = vel_spec + radar_airmotion_vmin
            back_vel_spec_ext = back_vel_spec*radar_airmotion_step_vmin
            !interpolate OR average (depending who's bins size is greater) from N(D) bins to radar bins.
            call rescale_spectra(err, nbins, radar_nfft_aliased, .true., vel_spec_ext, back_vel_spec_ext, out_radar_velo_aliased, &
                                 particle_spec_ext(1, :)) ! particle_spec in [mm⁶/m³/m * m/(m/s)]
            !for vmax
            vel_spec_ext = vel_spec + radar_airmotion_vmax
            back_vel_spec_ext = back_vel_spec*(1.d0 - radar_airmotion_step_vmin)
            !interpolate OR average (depending who's bins size is greater) from N(D) bins to radar bins.
            call rescale_spectra(err, nbins, radar_nfft_aliased, .true., vel_spec_ext, back_vel_spec_ext, out_radar_velo_aliased, &
                                 particle_spec_ext(2, :))
            !join results
            particle_spec = SUM(particle_spec_ext, 1)
            if (allocated(particle_spec_ext)) deallocate (particle_spec_ext)
            !
         else if (radar_airmotion_model .eq. "linear") then
            allocate (particle_spec_ext(radar_airmotion_linear_steps, radar_nfft_aliased))
            delta_air = (radar_airmotion_vmax - radar_airmotion_vmin)/REAL(radar_airmotion_linear_steps - 1)
            !     loop for linear steps
            do jj = 1, radar_airmotion_linear_steps
               vel_spec_ext = vel_spec + radar_airmotion_vmin + (jj - 1)*delta_air
               back_vel_spec_ext = back_vel_spec/REAL(radar_airmotion_linear_steps)
               !interpolate OR average (depending whos bins size is greater) from N(D) bins to radar bins.
             call rescale_spectra(err, nbins, radar_nfft_aliased, .true., vel_spec_ext, back_vel_spec_ext, out_radar_velo_aliased, &
                                    particle_spec_ext(jj, :))
            end do
            !join results
            particle_spec = SUM(particle_spec_ext, 1)
            if (allocated(particle_spec_ext)) deallocate (particle_spec_ext)
         else
            errorstatus = fatal
            msg = "unknown radar_airmotion_model: "//radar_airmotion_model
            call report(errorstatus, msg, nameOfRoutine)
            return
         end if
      else
         !no air motion, just rescale
         if (verbose >= 3) call report(info, "Averaging spectrum and Adding without vertical air motion", nameOfRoutine)
         call rescale_spectra(err, nbins, radar_nfft_aliased, .true., vel_spec,&
         back_vel_spec, out_radar_velo_aliased, particle_spec) ! particle_spec in [mm⁶/m³/m * m/(m/s)]
      end if

      if (err /= 0) then
         msg = 'error in rescale_spectra!'
         call report(err, msg, nameOfRoutine)
         errorstatus = err
         return
      end if

      K = (Ze/SUM(1d18*particle_spec*del_v_radar))
      particle_spec = K*particle_spec

      call assert_true(err, all(particle_spec >= 0), &
                       "nan or negative particle_spec")
      if (err /= 0) then
         print *, "SUM(particle_spec)", SUM(particle_spec)
         msg = 'error in transforming the spectrum to velocity space...'
         call report(err, msg, nameOfRoutine)
         errorstatus = err
         return
      end if

      if (verbose >= 4) print *, "Ze", 10*log10(Ze)
      if (verbose >= 4) print *, "K", K
      if (verbose >= 4) print *, " Ze SUM(back_vel_spec)*del_v_model", 10*log10(SUM(1d18*back_vel_spec*del_v_model))
      if (verbose >= 4) print *, " Ze SUM(back_vel_spec_ext)*del_v_model", 10*log10(SUM(1d18*back_vel_spec_ext*del_v_model)), &
         "has value only when using vertical air motion)"
      if (verbose >= 4) print *, " Ze SUM(particle_spec)*del_v_radar", 10*log10(SUM(1d18*particle_spec)*del_v_radar)

      !spetial output for testing the radar simulator
      if (verbose >= 20) then
         print *, "##########################################"
         print *, "velocity (v)"
         print *, out_radar_velo_aliased
         print *, "##########################################"
         print *, "particle_spec without turbulence (v) [mm⁶/m³/(m/s)]"
         print *, particle_spec
         print *, "##########################################"

      end if

      errorstatus = err
      if (verbose >= 2) call report(info, 'End of ', nameOfRoutine)

      return

   end subroutine get_radar_spectrum_one
end module radar_spectrum
