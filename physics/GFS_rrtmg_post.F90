!>\file GFS_rrtmg_post.f90
!! This file contains
       module GFS_rrtmg_post
       contains

!>\defgroup GFS_rrtmg_post GFS RRTMG Scheme Post
!! @{
!> \section arg_table_GFS_rrtmg_post_init Argument Table
!!
       subroutine GFS_rrtmg_post_init ()
       end subroutine GFS_rrtmg_post_init

!> \section arg_table_GFS_rrtmg_post_run Argument Table
!! | local_name     | standard_name                                                 | long_name                                                                     | units    | rank |  type             |   kind    | intent | optional |
!! |----------------|---------------------------------------------------------------|-------------------------------------------------------------------------------|----------|------|-------------------|-----------|--------|----------|
!! | Model          | GFS_control_type_instance                                     | Fortran DDT containing FV3-GFS model control parameters                       | DDT      |    0 | GFS_control_type  |           | in     | F        |
!! | Grid           | GFS_grid_type_instance                                        | Fortran DDT containing FV3-GFS grid and interpolation related data            | DDT      |    0 | GFS_grid_type     |           | in     | F        |
!! | Diag           | GFS_diag_type_instance                                        | Fortran DDT containing FV3-GFS diagnotics data                                | DDT      |    0 | GFS_diag_type     |           | inout  | F        |
!! | Radtend        | GFS_radtend_type_instance                                     | Fortran DDT containing FV3-GFS radiation tendencies                           | DDT      |    0 | GFS_radtend_type  |           | in     | F        |
!! | Statein        | GFS_statein_type_instance                                     | Fortran DDT containing FV3-GFS prognostic state data in from dycore           | DDT      |    0 | GFS_statein_type  |           | in     | F        |
!! | Coupling       | GFS_coupling_type_instance                                    | Fortran DDT containing FV3-GFS fields to/from coupling with other components  | DDT      |    0 | GFS_coupling_type |           | inout  | F        |
!! | scmpsw         | components_of_surface_downward_shortwave_fluxes               | derived type for special components of surface downward shortwave fluxes      | W m-2    |    1 | cmpfsw_type       |           | in     | F        |
!! | im             | horizontal_loop_extent                                        | horizontal loop extent                                                        | count    |    0 | integer           |           | in     | F        |
!! | lm             | vertical_layer_dimension_for_radiation                        | number of vertical layers for radiation calculation                           | count    |    0 | integer           |           | in     | F        |
!! | ltp            | extra_top_layer                                               | extra top layers                                                              | none     |    0 | integer           |           | in     | F        |
!! | kt             | vertical_index_difference_between_layer_and_upper_bound       | vertical index difference between layer and upper bound                       | index    |    0 | integer           |           | in     | F        |
!! | kb             | vertical_index_difference_between_layer_and_lower_bound       | vertical index difference between layer and lower bound                       | index    |    0 | integer           |           | in     | F        |
!! | kd             | vertical_index_difference_between_inout_and_local             | vertical index difference between in/out and local                            | index    |    0 | integer           |           | in     | F        |
!! | raddt          | time_step_for_radiation                                       | radiation time step                                                           | s        |    0 | real              | kind_phys | in     | F        |
!! | aerodp         | atmosphere_optical_thickness_due_to_ambient_aerosol_particles | vertical integrated optical depth for various aerosol species                 | none     |    2 | real              | kind_phys | in     | F        |
!! | cldsa          | cloud_area_fraction_for_radiation                             | fraction of clouds for low, middle, high, total and BL                        | frac     |    2 | real              | kind_phys | in     | F        |
!! | mtopa          | model_layer_number_at_cloud_top                               | vertical indices for low, middle and high cloud tops                          | index    |    2 | integer           |           | in     | F        |
!! | mbota          | model_layer_number_at_cloud_base                              | vertical indices for low, middle and high cloud bases                         | index    |    2 | integer           |           | in     | F        |
!! | clouds1        | total_cloud_fraction                                          | layer total cloud fraction                                                    | frac     |    2 | real              | kind_phys | in     | F        |
!! | cldtaulw       | cloud_optical_depth_layers_at_10mu_band                       | approx 10mu band layer cloud optical depth                                    | none     |    2 | real              | kind_phys | in     | F        |
!! | cldtausw       | cloud_optical_depth_layers_at_0.55mu_band                     | approx .55mu band layer cloud optical depth                                   | none     |    2 | real              | kind_phys | in     | F        |
!! | errmsg         | ccpp_error_message                                            | error message for error handling in CCPP                                      | none     |    0 | character         | len=*     | out    | F        |
!! | errflg         | ccpp_error_flag                                               | error flag for error handling in CCPP                                         | flag     |    0 | integer           |           | out    | F        |
!!
      subroutine GFS_rrtmg_post_run (Model, Grid, Diag, Radtend, Statein, &
              Coupling, scmpsw, im, lm, ltp, kt, kb, kd, raddt, aerodp,   &
              cldsa, mtopa, mbota, clouds1, cldtaulw, cldtausw,           &
              errmsg, errflg)

      use machine,                             only: kind_phys
      use GFS_typedefs,                        only: GFS_statein_type,   &
                                                     GFS_coupling_type,  &
                                                     GFS_control_type,   &
                                                     GFS_grid_type,      &
                                                     GFS_radtend_type,   &
                                                     GFS_diag_type
      use module_radiation_aerosols,           only: NSPC1
      use module_radsw_parameters,             only: cmpfsw_type
      use module_radlw_parameters,             only: topflw_type, sfcflw_type
      use module_radsw_parameters,             only: topfsw_type, sfcfsw_type

      implicit none

      ! Interface variables
      type(GFS_control_type),              intent(in)    :: Model
      type(GFS_grid_type),                 intent(in)    :: Grid
      type(GFS_statein_type),              intent(in)    :: Statein
      type(GFS_coupling_type),             intent(inout) :: Coupling
      type(GFS_radtend_type),              intent(in)    :: Radtend
      type(GFS_diag_type),                 intent(inout) :: Diag
      type(cmpfsw_type), dimension(size(Grid%xlon,1)), intent(in) :: scmpsw

      integer,              intent(in) :: im, lm, ltp, kt, kb, kd
      real(kind=kind_phys), intent(in) :: raddt

      real(kind=kind_phys), dimension(size(Grid%xlon,1),NSPC1),          intent(in) :: aerodp
      real(kind=kind_phys), dimension(size(Grid%xlon,1),5),              intent(in) :: cldsa
      integer,              dimension(size(Grid%xlon,1),3),              intent(in) :: mbota, mtopa
      real(kind=kind_phys), dimension(size(Grid%xlon,1),Model%levr+LTP), intent(in) :: clouds1
      real(kind=kind_phys), dimension(size(Grid%xlon,1),Model%levr+LTP), intent(in) :: cldtausw
      real(kind=kind_phys), dimension(size(Grid%xlon,1),Model%levr+LTP), intent(in) :: cldtaulw

      character(len=*), intent(out) :: errmsg
      integer, intent(out) :: errflg

      ! Local variables
      integer :: i, j, k, k1, itop, ibtc
      real(kind=kind_phys) :: tem0d, tem1, tem2

      ! Initialize CCPP error handling variables
      errmsg = ''
      errflg = 0

      if (.not. (Model%lsswr .or. Model%lslwr)) return

!>  - For time averaged output quantities (including total-sky and
!!    clear-sky SW and LW fluxes at TOA and surface; conventional
!!    3-domain cloud amount, cloud top and base pressure, and cloud top
!!    temperature; aerosols AOD, etc.), store computed results in
!!    corresponding slots of array fluxr with appropriate time weights.

!  --- ...  collect the fluxr data for wrtsfc

      if (Model%lssav) then
        if (Model%lsswr) then
          do i=1,im
            Diag%fluxr(i,34) = Diag%fluxr(i,34) + Model%fhswr*aerodp(i,1)  ! total aod at 550nm
            Diag%fluxr(i,35) = Diag%fluxr(i,35) + Model%fhswr*aerodp(i,2)  ! DU aod at 550nm
            Diag%fluxr(i,36) = Diag%fluxr(i,36) + Model%fhswr*aerodp(i,3)  ! BC aod at 550nm
            Diag%fluxr(i,37) = Diag%fluxr(i,37) + Model%fhswr*aerodp(i,4)  ! OC aod at 550nm
            Diag%fluxr(i,38) = Diag%fluxr(i,38) + Model%fhswr*aerodp(i,5)  ! SU aod at 550nm
            Diag%fluxr(i,39) = Diag%fluxr(i,39) + Model%fhswr*aerodp(i,6)  ! SS aod at 550nm
          enddo
        endif

!  ---  save lw toa and sfc fluxes
        if (Model%lslwr) then
          do i=1,im
!  ---  lw total-sky fluxes
            Diag%fluxr(i,1 ) = Diag%fluxr(i,1 ) + Model%fhlwr *    Diag%topflw(i)%upfxc   ! total sky top lw up
            Diag%fluxr(i,19) = Diag%fluxr(i,19) + Model%fhlwr * Radtend%sfcflw(i)%dnfxc   ! total sky sfc lw dn
            Diag%fluxr(i,20) = Diag%fluxr(i,20) + Model%fhlwr * Radtend%sfcflw(i)%upfxc   ! total sky sfc lw up
!  ---  lw clear-sky fluxes
            Diag%fluxr(i,28) = Diag%fluxr(i,28) + Model%fhlwr *    Diag%topflw(i)%upfx0   ! clear sky top lw up
            Diag%fluxr(i,30) = Diag%fluxr(i,30) + Model%fhlwr * Radtend%sfcflw(i)%dnfx0   ! clear sky sfc lw dn
            Diag%fluxr(i,33) = Diag%fluxr(i,33) + Model%fhlwr * Radtend%sfcflw(i)%upfx0   ! clear sky sfc lw up
          enddo
        endif

!  ---  save sw toa and sfc fluxes with proper diurnal sw wgt. coszen=mean cosz over daylight
!       part of sw calling interval, while coszdg= mean cosz over entire interval
        if (Model%lsswr) then
          do i = 1, IM
            if (Radtend%coszen(i) > 0.) then
!  ---                                  sw total-sky fluxes
!                                       -------------------
              tem0d = Model%fhswr * Radtend%coszdg(i) / Radtend%coszen(i)
              Diag%fluxr(i,2 ) = Diag%fluxr(i,2)  +    Diag%topfsw(i)%upfxc * tem0d  ! total sky top sw up
              Diag%fluxr(i,3 ) = Diag%fluxr(i,3)  + Radtend%sfcfsw(i)%upfxc * tem0d  ! total sky sfc sw up
              Diag%fluxr(i,4 ) = Diag%fluxr(i,4)  + Radtend%sfcfsw(i)%dnfxc * tem0d  ! total sky sfc sw dn
!  ---                                  sw uv-b fluxes
!                                       --------------
              Diag%fluxr(i,21) = Diag%fluxr(i,21) + scmpsw(i)%uvbfc * tem0d          ! total sky uv-b sw dn
              Diag%fluxr(i,22) = Diag%fluxr(i,22) + scmpsw(i)%uvbf0 * tem0d          ! clear sky uv-b sw dn
!  ---                                  sw toa incoming fluxes
!                                       ----------------------
              Diag%fluxr(i,23) = Diag%fluxr(i,23) + Diag%topfsw(i)%dnfxc * tem0d     ! top sw dn
!  ---                                  sw sfc flux components
!                                       ----------------------
              Diag%fluxr(i,24) = Diag%fluxr(i,24) + scmpsw(i)%visbm * tem0d          ! uv/vis beam sw dn
              Diag%fluxr(i,25) = Diag%fluxr(i,25) + scmpsw(i)%visdf * tem0d          ! uv/vis diff sw dn
              Diag%fluxr(i,26) = Diag%fluxr(i,26) + scmpsw(i)%nirbm * tem0d          ! nir beam sw dn
              Diag%fluxr(i,27) = Diag%fluxr(i,27) + scmpsw(i)%nirdf * tem0d          ! nir diff sw dn
!  ---                                  sw clear-sky fluxes
!                                       -------------------
              Diag%fluxr(i,29) = Diag%fluxr(i,29) + Diag%topfsw(i)%upfx0 * tem0d  ! clear sky top sw up
              Diag%fluxr(i,31) = Diag%fluxr(i,31) + Radtend%sfcfsw(i)%upfx0 * tem0d  ! clear sky sfc sw up
              Diag%fluxr(i,32) = Diag%fluxr(i,32) + Radtend%sfcfsw(i)%dnfx0 * tem0d  ! clear sky sfc sw dn
            endif
          enddo
        endif

!  ---  save total and boundary layer clouds

        if (Model%lsswr .or. Model%lslwr) then
          do i=1,im
            Diag%fluxr(i,17) = Diag%fluxr(i,17) + raddt * cldsa(i,4)
            Diag%fluxr(i,18) = Diag%fluxr(i,18) + raddt * cldsa(i,5)
          enddo

!  ---  save cld frac,toplyr,botlyr and top temp, note that the order
!       of h,m,l cloud is reversed for the fluxr output.
!  ---  save interface pressure (pa) of top/bot

          do j = 1, 3
            do i = 1, IM
              tem0d = raddt * cldsa(i,j)
              itop  = mtopa(i,j) - kd
              ibtc  = mbota(i,j) - kd
              Diag%fluxr(i, 8-j) = Diag%fluxr(i, 8-j) + tem0d
              Diag%fluxr(i,11-j) = Diag%fluxr(i,11-j) + tem0d * Statein%prsi(i,itop+kt)
              Diag%fluxr(i,14-j) = Diag%fluxr(i,14-j) + tem0d * Statein%prsi(i,ibtc+kb)
              Diag%fluxr(i,17-j) = Diag%fluxr(i,17-j) + tem0d * Statein%tgrs(i,itop)

!       Anning adds optical depth and emissivity output
              tem1 = 0.
              tem2 = 0.
              do k=ibtc,itop
                tem1 = tem1 + cldtausw(i,k)      ! approx .55 mu channel
                tem2 = tem2 + cldtaulw(i,k)      ! approx 10. mu channel
              enddo
              Diag%fluxr(i,43-j) = Diag%fluxr(i,43-j) + tem0d * tem1
              Diag%fluxr(i,46-j) = Diag%fluxr(i,46-j) + tem0d * (1.0-exp(-tem2))
            enddo
          enddo
        endif

!       if (.not. Model%uni_cld) then
        if (Model%lgocart .or. Model%ldiag3d) then
          do k = 1, LM
            k1 = k + kd
            Coupling%cldcovi(1:im,k) = clouds1(1:im,k1)
          enddo
        endif
      endif                                ! end_if_lssav
!
      end subroutine GFS_rrtmg_post_run

!> \section arg_table_GFS_rrtmg_post_finalize Argument Table
!!
      subroutine GFS_rrtmg_post_finalize ()
      end subroutine GFS_rrtmg_post_finalize

!! @}
      end module GFS_rrtmg_post
