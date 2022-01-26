#!/bin/bash

####################################################################
# BACKGROUND #######################################################
####################################################################

# Create directories
mkdir -p ${data_dir_regrid}/${bump_dir}/${bkg_dir}
mkdir -p ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_background

# BACKGROUND yaml
yaml_name="regrid_c${cregrid}_${nlx}x${nly}_background.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: ${npx}
  npy: ${npy}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
states:
- input:
    filetype: gfs
    state variables: [ua,va,t,ps,sphum,liq_wat,o3mr]
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/${bkg_dir}
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
  output:
    filetype: gfs
    datapath: ${data_dir_regrid}/${bump_dir}/${bkg_dir}
    prepend files with date: false
    filename_cplr: coupler.res
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
EOF

# BACKGROUND sbatch
sbatch_name="regrid_c${cregrid}_${nlx}x${nly}_background.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regrid_c${cregrid}_${nlx}x${nly}_background
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_background/regrid_c${cregrid}_${nlx}x${nly}_background.err
#SBATCH -o ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_background/regrid_c${cregrid}_${nlx}x${nly}_background.out

source ${env_script}
export OMP_NUM_THREADS=1

cd ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_background
srun --ntasks=$((6*nlx*nly)) --cpu_bind=core --distribution=block:block ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# FIRST_MEMBER #####################################################
####################################################################

# Create directories
mkdir -p ${data_dir_regrid}/${bump_dir}/${first_member_dir}
mkdir -p ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}

# FIRST_MEMBER yaml
yaml_name="regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: ${npx}
  npy: ${npy}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
states:
- input:
    filetype: gfs
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/${first_member_dir}
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
  output:
    filetype: gfs
    datapath: ${data_dir_regrid}/${bump_dir}/${first_member_dir}
    prepend files with date: false
    filename_core: unbal.fv_core.res.nc
    filename_trcr: unbal.fv_tracer.res.nc
    filename_cplr: unbal.coupler.res
EOF

# FIRST_MEMBER sbatch
sbatch_name="regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}.out

source ${env_script}
export OMP_NUM_THREADS=1

cd ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_first_member_${yyyymmddhh_last}
srun --ntasks=$((6*nlx*nly)) --cpu_bind=core --distribution=block:block ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

exit 0
EOF


####################################################################
# PSICHITOUV #######################################################
####################################################################

# Create directories
mkdir -p ${data_dir_regrid}/${bump_dir}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}

# PSICHITOUV yaml
yaml_name="regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: ${npx}
  npy: ${npy}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
bump:
  datadir: ${data_dir_regrid}/${bump_dir}
  prefix: psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  new_wind: true
  write_wind_local: true
  wind_nlon: 400
  wind_nlat: 200
  wind_nsg: 5
  wind_inflation: 1.1
EOF

# PSICHITOUV sbatch
sbatch_name="regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
export OMP_NUM_THREADS=1

cd ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_psichitouv_${yyyymmddhh_first}-${yyyymmddhh_last}
srun --ntasks=$((6*nlx*nly)) --cpu_bind=core --distribution=block:block ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# VBAL #############################################################
####################################################################

# Create directories
mkdir -p ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}

# Link input file
ln -sf ${data_dir_c384}/${bump_dir}/vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling.nc ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling.nc
ln -sf ${data_dir_c384}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}_vbal.nc ${data_dir_regrid}/${bump_dir}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}_vbal.nc

# VBAL yaml
yaml_name="regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: ${npx}
  npy: ${npy}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [psi,chi,t,ps]
bump:
  datadir: ${data_dir_regrid}/${bump_dir}
  prefix: vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
  verbosity: main
  universe_rad: 2000.0e3
  load_vbal: true
  write_vbal: true
  fname_samp: vbal_${yyyymmddhh_last}/vbal_${yyyymmddhh_last}_sampling
  ens1_nsub: ${yyyymmddhh_size}
  load_samp_global: true
  write_samp_local: true
  vbal_block: [true, true,false, true,false,false]
EOF

# VBAL sbatch
sbatch_name="regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
export OMP_NUM_THREADS=1

cd ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_vbal_${yyyymmddhh_first}-${yyyymmddhh_last}
srun --ntasks=$((6*nlx*nly)) --cpu_bind=core --distribution=block:block ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# VAR-COR ##########################################################
####################################################################

# Create directories
mkdir -p ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
mkdir -p ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# VAR-COR yaml
yaml_name="regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
input geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: 385
  npy: 385
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
output geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: ${npx}
  npy: ${npy}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
states:
- input:
    filetype: gfs
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  output:
    filetype: gfs
    datapath: ${data_dir_regrid}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: stddev.fv_core.res.nc
    filename_trcr: stddev.fv_tracer.res.nc
    filename_cplr: stddev.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- input:
    filetype: gfs
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  output:
    filetype: gfs
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
- input:
    filetype: gfs
    state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
    psinfile: true
    datapath: ${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
  output:
    filetype: gfs
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    prepend files with date: false
    filename_core: cor_rv.fv_core.res.nc
    filename_trcr: cor_rv.fv_tracer.res.nc
    filename_cplr: cor_rv.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

# VAR-COR sbatch
sbatch_name="regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
export OMP_NUM_THREADS=1

cd ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_var-cor_${yyyymmddhh_first}-${yyyymmddhh_last}
srun --ntasks=$((6*nlx*nly)) --cpu_bind=core --distribution=block:block ${bin_dir}/fv3jedi_convertstate.x ${yaml_dir}/${yaml_name}

exit 0
EOF

####################################################################
# NICAS ############################################################
####################################################################

for var in ${vars}; do
   # Create directories
   mkdir -p ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
   mkdir -p ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}

   # Link input files
   ln -sf ${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc ${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}_nicas.nc

   # NICAS yaml
   yaml_name="regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.yaml"
cat<< EOF > ${yaml_dir}/${yaml_name}
geometry:
  fms initialization:
    namelist filename: ${fv3jedi_dir}/test/Data/fv3files/fmsmpp.nml
    field table filename: ${fv3jedi_dir}/test/Data/fv3files/field_table_gfdl
  akbk: ${fv3jedi_dir}/test/Data/fv3files/akbk127.nc4
  layout: [${nlx},${nly}]
  npx: ${npx}
  npy: ${npy}
  npz: 127
  fieldsets:
  - fieldset: ${fv3jedi_dir}/test/Data/fieldsets/dynamics.yaml
background:
  filetype: gfs
  state variables: [psi,chi,t,ps,sphum,liq_wat,o3mr]
  psinfile: true
  datapath: ${data_dir_regrid}/${bump_dir}/${first_member_dir}
  filename_core: unbal.fv_core.res.nc
  filename_trcr: unbal.fv_tracer.res.nc
  filename_cplr: unbal.coupler.res
input variables: [${var}]
bump:
  prefix: nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
  datadir: ${data_dir_regrid}/${bump_dir}
  verbosity: main
  strategy: specific_univariate
  load_nicas_global: true
  write_nicas_local: true
  min_lev:
    liq_wat: 76
  universe radius:
    filetype: gfs
    psinfile: true
    datapath: ${data_dir_regrid}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}
    filename_core: cor_rh.fv_core.res.nc
    filename_trcr: cor_rh.fv_tracer.res.nc
    filename_cplr: cor_rh.coupler.res
    date: ${yyyy_last}-${mm_last}-${dd_last}T${hh_last}:00:00Z
EOF

   # NICAS sbatch
   sbatch_name="regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=$((6*nlx*nly))
#SBATCH --cpus-per-task=2
#SBATCH --time=00:20:00
#SBATCH -e ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.err
#SBATCH -o ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}/regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}.out

source ${env_script}
export OMP_NUM_THREADS=2

cd ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${var}
srun --ntasks=$((6*nlx*nly)) --cpu_bind=core --distribution=block:block ${bin_dir}/fv3jedi_error_covariance_training.x ${yaml_dir}/${yaml_name}

exit 0
EOF
done

####################################################################
# MERGE NICAS ######################################################
####################################################################

# Create directories
mkdir -p ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Merge local NICAS files
sbatch_name="regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=40
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${env_script}
export OMP_NUM_THREADS=1
module load nco

cd ${work_dir}/regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Number of local files
nlocal=$((6*nlx*nly))

# Create scripts for local files
ntotpad=\$(printf "%.6d" "\${nlocal}")
for itot in \$(seq 1 \${nlocal}); do
   itotpad=\$(printf "%.6d" "\${itot}")
   filename_full_3D=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas_local_\${ntotpad}-\${itotpad}.nc
   filename_full_2D=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas_local_\${ntotpad}-\${itotpad}.nc
   rm -f \${filename_full_3D}
   rm -f \${filename_full_2D}
   echo "#!/bin/bash" > regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
   for var in ${vars}; do
      if test "\${var}" = "ps"; then
         filename_full=\${filename_full_2D}
      else
         filename_full=\${filename_full_3D}
      fi
      filename_var=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas_local_\${ntotpad}-\${itotpad}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}" >> regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
   done
done

# Create scripts for global files
nlocalp1=\$((nlocal+1))
itotpad=\$(printf "%.6d" "\${nlocalp1}")
filename_full_3D=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_3D_nicas.nc
filename_full_2D=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_2D_nicas.nc
rm -f \${filename_full_3D}
rm -f \${filename_full_2D}
echo "#!/bin/bash" > regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
for var in ${vars}; do
   if test "\${var}" = "ps"; then
      filename_full=\${filename_full_2D}
   else
      filename_full=\${filename_full_3D}
   fi
   filename_var=${data_dir_regrid}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas.nc
   echo -e "ncks -A \${filename_var} \${filename_full}" >> regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
done

# Run scripts in parallel
nbatch=\$((nlocalp1/40+1))
itot=0
for ibatch in \$(seq 1 \${nbatch}); do
   for i in \$(seq 1 40); do
      itot=\$((itot+1))
      if test "\${itot}" -le "\${nlocalp1}"; then
         itotpad=\$(printf "%.6d" "\${itot}")
         echo "Batch \${ibatch} - job \${i}: ./regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh"
         chmod 755 regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh
         ./regrid_c${cregrid}_${nlx}x${nly}_merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${itotpad}.sh &
      fi
   done
   wait
done

exit 0
EOF
