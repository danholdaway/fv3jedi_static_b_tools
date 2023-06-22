#!/bin/bash

dates=("$@")
bg_date=${dates[-2]}
bgYYYY=${bg_date:0:4}
bgMM=${bg_date:4:2}
bgDD=${bg_date:6:2}
bgHH=${bg_date:8:2}

cat << EOF > new_staticb_split_vbal_gfs.yaml
geometry:
  fms initialization:
    namelist filename: Data/fv3files/fmsmpp.nml
    field table filename: Data/fv3files/field_table_gfdl
  akbk: Data/fv3files/akbk127.nc4
  npx: 13
  npy: 13
  npz: 127
  field metadata override: Data/fieldmetadata/gfs-restart.yaml
background:
  datetime: ${bgYYYY}-${bgMM}-${bgDD}T${bgHH}:00:00Z
  filetype: fms restart
  skip coupler file: true
  state variables: [stream_function,velocity_potential,air_temperature,surface_pressure]
  psinfile: true
  datapath: ${balanced_dir}/mem001/
  filename_core: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_core.res.nc
  filename_trcr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_tracer.res.nc
  filename_sfcd: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.sfc_data.nc
  filename_sfcw: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.fv_srf_wnd.res.nc
  filename_cplr: ${bgYYYY}${bgMM}${bgDD}.${bgHH}0000.coupler.res
background error:
  covariance model: SABER
  saber central block:
    saber block name: ID
  saber outer blocks:
  - saber block name: BUMP_VerticalBalance
    calibration:
      general:
        universe length-scale: 2500.0e3
      io:
        data directory: ${Data_dir}/newstaticb
        files prefix: vbal_gfs
        overriding sampling file: vbal_${dates[0]}_gfs_sampling
      drivers:
        read global sampling: true
        write local sampling: true
        read vertical balance: true
        write vertical balance: true
      vertical balance:
        vbal:
        - balanced variable: velocity_potential
          unbalanced variable: stream_function
        - balanced variable: air_temperature
          unbalanced variable: stream_function
        - balanced variable: surface_pressure
          unbalanced variable: stream_function
EOF

