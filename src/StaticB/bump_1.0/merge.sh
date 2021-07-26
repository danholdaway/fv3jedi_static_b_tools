#!/bin/bash

####################################################################
# VAR ##############################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}

# Merge VAR files
sbatch_name="merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh
module load nco

cd ${work_dir}/merge_var_${yyyymmddhh_first}-${yyyymmddhh_last}

# Specific file
declare -A vars_files
vars_files["psi"]="fv_core"
vars_files["chi"]="fv_core"
vars_files["t"]="fv_core"
vars_files["ps"]="fv_core"
vars_files["sphum"]="fv_tracer"
vars_files["liq_wat"]="fv_tracer"
vars_files["o3mr"]="fv_tracer"

# NetCDF files
for itile in \$(seq 1 6); do
   # Modifiy ps file axis
   filename_var=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev_ps.fv_core.res.tile\${itile}.nc
   ncrename -d zaxis_1,zaxis_2 \${filename_var}

   # Append files
   filename_core=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_core.res.tile\${itile}.nc
   filename_tracer=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.fv_tracer.res.tile\${itile}.nc
   rm -f \${filename_core} \${filename_tracer}
   for var in ${vars}; do
      filename_full=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.\${vars_files[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev_\${var}.\${vars_files[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
   done
done

# Coupler file
input_file=${data_dir}/coupler/coupler.res
output_file=${data_dir_c384}/${bump_dir}/var_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.stddev.coupler.res
echo -e "Create coupler file \${output_file}"
sed -e s/"_YYYY_"/${yyyy}/g \${input_file} > \${output_file}
if test "${m_last}" -le "9" ; then
   sed -i -e s/"_M_"/" "${m_last}/g \${output_file}
else
   sed -i -e s/"_M_"/${m_last}/g \${output_file}
fi
if test "${d_last}" -le "9" ; then
   sed -i -e s/"_D_"/" "${d_last}/g \${output_file}
else
   sed -i -e s/"_D_"/${d_last}/g \${output_file}
fi
if test "${h_last}" -le "9" ; then
   sed -i -e s/"_H_"/" "${h_last}/g \${output_file}
else
   sed -i -e s/"_H_"/${h_last}/g \${output_file}
fi

exit 0
EOF

####################################################################
# COR ##############################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# Merge COR files
sbatch_name="merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH -e ${work_dir}/merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh
module load nco

cd ${work_dir}/merge_cor_${yyyymmddhh_first}-${yyyymmddhh_last}

# Specific file
declare -A vars_files
vars_files["psi"]="fv_core"
vars_files["chi"]="fv_core"
vars_files["t"]="fv_core"
vars_files["ps"]="fv_core"
vars_files["sphum"]="fv_tracer"
vars_files["liq_wat"]="fv_tracer"
vars_files["o3mr"]="fv_tracer"

# NetCDF files
for itile in \$(seq 1 6); do
   # Modifiy ps file axis
   filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_ps.fv_core.res.tile\${itile}.nc
   ncrename -d zaxis_1,zaxis_2 \${filename_var}

   # Append files
   filename_core=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_core.res.tile\${itile}.nc
   filename_tracer=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.fv_tracer.res.tile\${itile}.nc
   rm -f \${filename_core} \${filename_tracer}
   for var in ${vars}; do
      filename_full=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.\${vars_files[\${var}]}.res.tile\${itile}.nc
      filename_var=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh_\${var}.\${vars_files[\${var}]}.res.tile\${itile}.nc
      echo -e "ncks -A \${filename_var} \${filename_full}"
      ncks -A \${filename_var} \${filename_full}
   done
done

# Coupler file
input_file=${data_dir}/coupler/coupler.res
output_file=${data_dir_c384}/${bump_dir}/cor_${yyyymmddhh_first}-${yyyymmddhh_last}/${yyyy_last}${mm_last}${dd_last}.${hh_last}0000.cor_rh.coupler.res
echo -e "Create coupler file \${output_file}"
sed -e s/"_YYYY_"/${yyyy}/g \${input_file} > \${output_file}
if test "${m_last}" -le "9" ; then
   sed -i -e s/"_M_"/" "${m_last}/g \${output_file}
else
   sed -i -e s/"_M_"/${m_last}/g \${output_file}
fi
if test "${d_last}" -le "9" ; then
   sed -i -e s/"_D_"/" "${d_last}/g \${output_file}
else
   sed -i -e s/"_D_"/${d_last}/g \${output_file}
fi
if test "${h_last}" -le "9" ; then
   sed -i -e s/"_H_"/" "${h_last}/g \${output_file}
else
   sed -i -e s/"_H_"/${h_last}/g \${output_file}
fi

exit 0
EOF

####################################################################
# NICAS ############################################################
####################################################################

# Create specific work directory
mkdir -p ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

# Loop over local files
ntotpad=$(printf "%.6d" "216")
for itot in $(seq 1 216); do
   itotpad=$(printf "%.6d" "${itot}")

   # Merge local NICAS files
   sbatch_name="merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH -e ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}.err
#SBATCH -o ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_${itotpad}.out

source ${HOME}/gnu-openmpi_env.sh
module load nco

cd ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

filename_full_3D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_3D_local_${ntotpad}-${itotpad}.nc 
filename_full_2D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_2D_local_${ntotpad}-${itotpad}.nc 
rm -f \${filename_full_3D}
rm -f \${filename_full_2D}
for var in ${vars}; do
   if test "\${var}" = "ps"; then
      filename_full=\${filename_full_2D}
   else
      filename_full=\${filename_full_3D}
   fi
   filename_var=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas_local_${ntotpad}-${itotpad}.nc 
   echo -e "ncks -A \${filename_var} \${filename_full}"
   ncks -A \${filename_var} \${filename_full}
done

exit 0
EOF
done

# Merge global NICAS files
sbatch_name="merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.sh"
cat<< EOF > ${sbatch_dir}/${sbatch_name}
#!/bin/bash
#SBATCH --job-name=merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}
#SBATCH -A da-cpu
#SBATCH -p orion
#SBATCH -q batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH -e ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.err
#SBATCH -o ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}.out

source ${HOME}/gnu-openmpi_env.sh
module load nco

cd ${work_dir}/merge_nicas_${yyyymmddhh_first}-${yyyymmddhh_last}

filename_full_3D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_3D.nc
filename_full_2D=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_nicas_2D.nc
rm -f \${filename_full_3D}
rm -f \${filename_full_2D}
for var in ${vars}; do
   if test "\${var}" = "ps"; then
      filename_full=\${filename_full_2D}
   else
      filename_full=\${filename_full_3D}
   fi
   filename_var=${data_dir_c384}/${bump_dir}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}/nicas_${yyyymmddhh_first}-${yyyymmddhh_last}_\${var}_nicas.nc 
   echo -e "ncks -A \${filename_var} \${filename_full}"
   ncks -A \${filename_var} \${filename_full}
done

exit 0
EOF
