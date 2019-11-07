# (C) Copyright 2019 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import os
import subprocess
import datetime as dt
import pathlib
import tarfile
import shutil
import time
import yaml
import json
from random import randint

import ConvertEnsemble.modules.model_utils as mu
import Config.modules.gfs_conf as modconf

# --------------------------------------------------------------------------------------------------

class GFS:

  def __init__(self):

    # Initialize

    self.myName = 'gfs'                               # Name for this model
    self.hpssRoot = '/NCEPPROD/hpssprod/runhistory/'  # Path to archived files
    self.nGrps = 8                                    # Number of ensemble groups per cycle
    self.nEns = 80                                    # Number of ensemble members
    self.stageDir = 'stageGFS'
    self.nRstFiles = 38
    self.nEnsPerGrp = int(self.nEns/self.nGrps)

    self.nProcNx = '4' # Number of processors on cube face, x direction
    self.nProcNy = '4' # Number of processors on cube face, y direction

    self.ensRes = '384' # Horizontal resolution, e.g. 384 where there are 384 by 384 per cube face.
    self.ensLev = '64'  # Number of vertical levels

    self.yamlOrJson = 'yaml'

    # String datetimes
    self.dateTime    = dt.datetime(1900,1,1)
    self.dateTimeRst = dt.datetime(1900,1,1)
    self.Y = ''
    self.m = ''
    self.d = ''
    self.H = ''
    self.YRst = ''
    self.mRst = ''
    self.dRst = ''
    self.HRst = ''
    self.YmDRst = ''
    self.YmD_HRst = ''

    # Directories
    self.homeDir = ''
    self.workDir = ''
    self.dataDir = ''
    self.fv3fDir = ''

    # Section done markers
    self.Working = ''
    self.ArchDone = 'ArchDone'
    self.ExtcDone = 'ExtcDone'
    self.ConvDone = 'ConvDone'
    self.ReArDone = 'ReArDone'
    self.AllDone = 'AllDone'
    self.HeraCopyDone = 'HeraCopyDone'
    self.HeraExtrDone = 'HeraExtrDone'

    self.convertDir = ''

  # ------------------------------------------------------------------------------------------------

  def cycleTime(self,datetime):

    # Set time information for this cycle

    self.dateTime = datetime

    six_hours = dt.timedelta(hours=6)
    self.dateTimeRst = self.dateTime + six_hours

    self.Y = self.dateTime.strftime('%Y')
    self.m = self.dateTime.strftime('%m')
    self.d = self.dateTime.strftime('%d')
    self.H = self.dateTime.strftime('%H')
    self.YRst = self.dateTimeRst.strftime('%Y')
    self.mRst = self.dateTimeRst.strftime('%m')
    self.dRst = self.dateTimeRst.strftime('%d')
    self.HRst = self.dateTimeRst.strftime('%H')

    self.YmD   = self.Y+self.m+self.d
    self.YmD_H = self.Y+self.m+self.d+"_"+self.H
    self.YmDRst   = self.YRst+self.mRst+self.dRst
    self.YmD_HRst = self.YRst+self.mRst+self.dRst+"_"+self.HRst

    print(" Cycle time: "+self.Y+self.m+self.d+' '+self.H+" \n")

  # ------------------------------------------------------------------------------------------------

  def abort(self,message):

    print('ABORT: '+message)
    os.remove(self.Working)
    raise(SystemExit)

  # ------------------------------------------------------------------------------------------------

  def setDirectories(self,work_dir,data_dir):

    # Setup the work and home directories

    self.homeDir = os.getcwd()
    self.workDir = os.path.join(work_dir,'enswork_'+self.Y+self.m+self.d+self.H)
    self.dataDir = data_dir

    self.Working = os.path.join(self.Working)

    if (os.path.exists(self.Working):
      print('ABORT: '+self.Working+' exists. Already running or previous fail ...')
      raise(SystemExit)

    # Create working directory
    if not os.path.exists(self.workDir):
      os.makedirs(self.workDir)

    # Directory for converted members
    self.convertDir = os.path.join(self.workDir,self.YRst+self.mRst+self.dRst+'_'+self.HRst)

    if not os.path.exists(self.convertDir):
      os.makedirs(self.convertDir)

    # Create working file
    pathlib.Path(self.Working).touch()

    # Path for fv3files
    self.fv3fDir = os.path.join(self.convertDir,'fv3files')

    print(" Home directory: "+self.homeDir)
    print(" Work directory: "+self.workDir,"\n")

  # ------------------------------------------------------------------------------------------------

  def allDone(self):

    # Remove the working flag

    os.remove(self.Working)

  # ------------------------------------------------------------------------------------------------

  def getEnsembleMembersFromArchive(self):

    # Method to get an ensemble member and stage it

    print(" getEnsembleMembersFromArchive \n")

    # Short cuts
    Y = self.Y
    m = self.m
    d = self.d
    H = self.H

    # Move to work directory
    os.chdir(self.workDir)

    all_done = True

    # Loop over groups of members
    for g in range(self.nGrps):

      # File name
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+Y+m+d+'_'+H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')

      # File on hpss
      remote_file = os.path.join(self.hpssRoot+'rh'+Y,Y+m,Y+m+d,file)

      print(" Acquiring "+remote_file)

      # Run hsi ls command on the current file for expected size
      tailfile = "ls_remote_member.txt"
      mu.run_bash_command("hsi ls -l "+remote_file,tailfile)

      # Search tail for line with file size
      remote_file_size = -1
      with open(tailfile, "r") as fp:
        for line in mu.lines_that_contain("rstprod", fp):
          remote_file_size = line.split()[4]
      os.remove(tailfile)

      # Fail if unable to determine remote file size
      if (remote_file_size == -1):
        call self.abort('unable to determine size of remote file')

      #  Logic to determine whether to copy member. Only copied if group
      #  - Does not exist at all
      #  - The local size does not match remote size, indicating previous copy fail

      if (not os.path.exists(file)):

        print(" No attempt to get this member group yet, copying...")
        get_member_set = True

      else:

        print(" Member group copy already attempted, checking size matches remote")

        # Git size of the local file
        proc = subprocess.Popen(['ls', '-l', file], stdout=subprocess.PIPE)
        local_file_size = proc.stdout.readline().decode('utf-8').split()[4]

        # If size matches no get required, already staged
        if (local_file_size == remote_file_size):
          print(" Local size matches remote, not copying again.")
          get_member_set = False
        else:
          print(" Remote size "+str(remote_file_size)+" does not match local size ")
          print(   str(local_file_size)+" copying again.")
          get_member_set = True


      # Copy the file to stage directory
      if (get_member_set):
        print(" Copyng member group")
        tailfile = "copy_remote_member.txt"
        mu.run_bash_command("hsi get "+remote_file, tailfile)

      # Check that the files are copied properly
      if (not os.path.exists(file)):
        mem_failed = True
      else:
        proc = subprocess.Popen(['ls', '-l', file], stdout=subprocess.PIPE)
        new_local_file_size = proc.stdout.readline().decode('utf-8').split()[4]
        if (new_local_file_size == remote_file_size):
          mem_failed = False
        else:
          mem_failed = True

      if (mem_failed):
        all_done = False

    # Create file to indicate this part is done
    if (all_done):
      pathlib.Path(self.ArchDone).touch()

    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------

  def checkGfsRestartFiles(self,path):

    # Check for expected number of restarts in path

    if os.path.exists(path):
      return len(os.listdir(path+'/')) == self.nRstFiles
    else:
      return False

  # ------------------------------------------------------------------------------------------------

  def extractEnsembleMembers(self):

    # Extract each group of ensemble members

    print(" extractEnsembleMembers \n")

    # Move to work directory
    os.chdir(self.workDir)

    all_done = True

    # Loop over groups of members
    for g in range(self.nGrps):

      # File to extract
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+self.Y+self.m+self.d+'_'+self.H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')
      print(" Extracting "+file)

      # Member range for group
      memStart = g*self.nEnsPerGrp+1
      memFinal = g*self.nEnsPerGrp+10

      # Check whether extracted files already exist
      do_untar = False
      for e in range(memStart,memFinal+1):
        path_rst = os.path.join('enkfgdas.'+self.YmDm,self.H,'mem'+str(e).zfill(3),'RESTART')
        done_mem = self.checkGfsRestartFiles(path_rst)
        if (not done_mem):
          do_untar = True

      # Extract file
      if (do_untar):
        tailfile = "untar_remote_member.txt"
        mu.run_bash_command("tar -xvf "+file, tailfile)

      # Clean up non-restart files
      for e in range(memStart,memFinal+1):
        files = [os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.abias'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.abias_air'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.abias_int'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.abias_pc'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.atminc.nc'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.cnvstat'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.gsistat'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.oznstat'),
                 os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'gdas.t06z.radstat')]
        for f in range(len(files)):
          if os.path.exists(files[f]):
            os.remove(files[f])

      # Recheck for success
      do_untar = False
      for e in range(memStart,memFinal+1):
        path_rst = os.path.join('enkfgdas.'+self.YmD,self.H,'mem'+str(e).zfill(3),'RESTART')
        done_mem = self.checkGfsRestartFiles(path_rst)
        if (not done_mem):
          do_untar = True

      if do_untar:
        all_done = False

    # Create file to indicate this part is done
    if (all_done):
      pathlib.Path(self.ExtcDone).touch()

    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------

  def removeEnsembleArchiveFiles(self):

    # Remove tar files obtained from the arhcive

    print(" removeEnsembleArchiveFiles \n")

    # Move to work directory
    os.chdir(self.workDir)

    # Loop over groups of members
    for g in range(self.nGrps):

      # File to extract
      file = ('gpfs_dell1_nco_ops_com_gfs_prod_enkfgdas'
             '.'+self.Y+self.m+self.d+'_'+self.H+'.enkfgdas_restart_grp'+str(g+1)+'.tar')

      # Remove the file
      if os.path.exists(file):
        print( " Removing "+file)
        os.remove(file)

    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------

  # Dictionary for converting a state to psi/chi

  def convertStatesDict(self,path_state_in,path_state_out,varchange='id',output_name=''):

    # Path to the fv3files, e.g. input.nml
    path_fv3files = os.path.join(self.workDir,fv3files)

    # Geometry
    inputresolution  = modconf.geometry_dict('inputresolution' ,path_fv3files)
    outputresolution = modconf.geometry_dict('outputresolution',path_fv3files)

    # Variable change
    if (varchange == 'a2c'):
      varcha = modconf.varcha_a2c_dict(path_fv3files)
    else:
      varcha = {}

    input  = {}
    output = {}

    dict_states = {}
    dict_states["states"] = []

    for e in range(1,self.nEns+1):

      path_mem_in  = 'mem'+str(e).zfill(3)+'/RESTART/'
      path_mem_out = '_mem'+str(e).zfill(3)+'/'

      # Input/output for member
      input  = modconf.state_dict('input', path_mem, self.dateTimeRst)
      output = modconf.output_dict('output', path_mem, output_name)
      inputout = {**input, **output}

      dict_states["states"].append(inputout)

    return {**inputresolution, **outputresolution, **varcha, **dict_states}

  # ------------------------------------------------------------------------------------------------

  def preparefv3Files(self):

    # First remove fv3files path if it exists
    if os.path.exists(self.fv3fDir):
      shutil.rmtree(self.fv3fDir)

    # Copy from the user provided Data directory
    shutil.copytree(os.path.join(self.dataDir,'fv3files'), self.fv3fDir)

    # Update input.nml for this run
    nml_in = open(os.path.join(self.fv3fDir,'input.nml_template')).read()
    nml_in = nml_in.replace('NPX_DIM', str(int(self.ensRes)+1))
    nml_in = nml_in.replace('NPY_DIM', str(int(self.ensRes)+1))
    nml_in = nml_in.replace('NPZ_DIM', self.ensLev)
    nml_in = nml_in.replace('NPX_PROC', self.nProcNx)
    nml_in = nml_in.replace('NPY_PROC', self.nProcNy)
    nml_out = open(os.path.join(self.fv3fDir,'input.nml'), 'w')
    nml_out.write(nml_in)
    nml_out.close()

  # ------------------------------------------------------------------------------------------------

  def prepareConvertDirsConf(self):

    # Prepare directories for the members and the configuration files

    print(" prepareConvertDirsConf \n")

    # Loop over groups of members
    for e in range(self.nEns):

      # Create member directory
      memdir = os.path.join(self.convertDir,'_mem'+str(e+1).zfill(3))
      if not os.path.exists(memdir):
        os.makedirs(memdir)

    # Create the config files
    csdict = self.convertStatesDict(varchange='id',output_name='')

    # Write dictionary to config file
    conf_file = os.path.join(memdir,'convert_state.'+self.yamlOrJson)
    with open(conf_file, 'w') as outfile:
      if self.yamlOrJson == 'yaml':
        yaml.dump(csdict, outfile, default_flow_style=False)
      elif self.yamlOrJson == 'json':
        json.dump(csdict, outfile)

  # ------------------------------------------------------------------------------------------------

  # Submit MPI job that converts the ensemble members

  def convertMembersSlurm(self,machine,nodes,taskspernode,hours,jbuild,machine):

    print(" convertMembersSlurm \n")

    # Number of processors for job
    nprocs = str(6*int(self.nProcNx)*int(self.nProcNy))

    # Filename
    fname = os.path.join(self.convertDir,'run.sh')

    # Job ID
    jobid = randint(1000000,9999999)
    jobnm = "convertstates."+str(jobid)

    # Hours
    hh = str(hours),zfill(2)

    # Bash shell script that runs through all members
    fh = open(fname, "w")
    fh.write("#!/bin/bash\n")
    fh.write("\n")

    fh.write("#SBATCH --export=NONE\n")
    fh.write("#SBATCH --job-name="+jobnm+"\n")
    fh.write("#SBATCH --output="+jobnm+".log\n")
    if machine == 'discover':
      fh.write("#SBATCH --partition=compute\n")
      fh.write("#SBATCH --account=g0613\n")
      fh.write("#SBATCH --qos=advda\n")
    elif machine == 'hera':
      fh.write("#SBATCH --account=da-cpu\n")
    fh.write("#SBATCH --nodes="+str(nodes)+"\n")
    fh.write("#SBATCH --ntasks-per-node="+str(taskspernode)+"\n")
    fh.write("#SBATCH --time="+hh+":00:00\n")

    fh.write("\n")

    fh.write("source /usr/share/modules/init/bash\n")
    fh.write("module purge\n")
    if machine == 'discover':
      fh.write("module use -a /discover/nobackup/projects/gmao/obsdev/rmahajan/opt/modulefiles\n")
      fh.write("module load apps/jedi/intel-17.0.7.259\n")
    elif machine == 'hera':
      fh.write("module use -a /scratch1/NCEPDEV/stmp4/Daniel.Holdaway/opt/modulefiles/\n")
      fh.write("module load apps/jedi/intel-17.0.5.239\n")
    fh.write("module list\n")

    fh.write("\n")
    fh.write("cd "+self.convertDir+"\n")
    fh.write("\n")
    #fh.write("export OOPS_TRACE=1\n")
    fh.write("export build="+jbuild+"\n")
    fh.write("mpirun -np "+nprocs+" $build/bin/fv3jedi_convertstate.x convert_states."+self.yamlOrJson+"\n")
    fh.write("\n")
    fh.close()

    # Submit job
    mu.run_bash_command("sbatch "+fname)

    # Wait for finish
    print(" Waiting for sbatch job to finish")

    done_convert = False
    while not done_convert:

      try:
        squeue_res = subprocess.check_output(['squeue', '-l -h -n', jobnm], shell=True)
      except subprocess.CalledProcessError
        self.abort('squeue command failed.')


      if squeue_res is '':
        done_convert = True
        break

      # If not finished wait another minute
      time.sleep(60)

    # Grep for success
    with open(jobnm+'.log', "r") as fp:
      for line in fp:
        if re.search("status = 0", line):
          pathlib.Path(sys.path.join(self.workDir,self.ConvDone).touch()
        else:
          self.abort("convertMembersSlurm failed. Job name: "+jobnm)

  # ------------------------------------------------------------------------------------------------

  def tarConvertedMembers(self):

    # Submit MPI job that converts the ensemble members

    print(" tarConvertedMembers \n")

    # Move to work directory
    os.chdir(self.workDir)
    waited = 0

    # Wait until the batch job submitted above is done
    done_convert = False
    print(" Waiting for convert job to run")
    while not done_convert:

      if os.path.exists(os.path.join(self.workDir,'ConvertDone')):
        done_convert = True
        break

      # If not finished wait another minute
      time.sleep(60)
      waited += 60

    print(' Tarring up converted ensemble members for transfer')
    tar_file_name = 'ens_'+self.YmD_HRst+'.tar'
    tailfile = "tar_converted_members.txt"

    if not os.path.exists(os.path.join(self.workDir,tar_file_name)):
      mu.run_bash_command("tar -cvf "+tar_file_name+" "+self.YmD_HRst, tailfile)
    else:
      print(" Tar file for converted members already created")

  # ------------------------------------------------------------------------------------------------

  def cleanUp(self):

    # Clean up large files

    print(" cleanUp \n")

    # Move to work directory
    os.chdir(self.workDir)

    tar_file_name = 'ens_'+self.YmD_HRst+'.tar'
    filesearch = os.path.join(self.YmD_HRst,'mem001',self.YRst+self.mRst+self.dRst+'.'+self.HRst+'0000.fv_core.res.tile1.nc')
    tailfile = "tar_check.txt"

    mu.run_bash_command("tar -tvf "+tar_file_name+" "+filesearch, tailfile)

    # Search tail for line with file size
    filesearch_found = ''
    with open(tailfile, "r") as fp:
      for line in mu.lines_that_contain('failure', fp):
        filesearch_found = line
    #os.remove(tailfile)

    # Delete all the original ensemble members and touch done file
    if filesearch_found == '':
      print(" Tar file apears to be in tact, removing all files no longer needed")

      shutil.rmtree(self.convertDir)
      shutil.rmtree(os.path.join(self.workDir,'enkfgdas.'+self.YmD))
      pathlib.Path(self.AllDone).touch()

    else:
      self.abort('tar file apears to be corrupt')

  # ------------------------------------------------------------------------------------------------

  def membersFromHera(self):

    # Copy tarred up converted members from hera

    print(" membersFromHera \n")

    # Move to work directory
    os.chdir(self.workDir)

    tar_file = 'ens_'+self.YmD_HRst+'.tar'
    hera_path = os.path.join('/scratch1','NCEPDEV','da','Daniel.Holdaway','JediScratch','StaticB','wrk','enswork_'+self.Y+self.m+self.d+self.H)
    tailfile = "ls_hera_tar.txt"
    mu.run_bash_command("ssh Daniel.Holdaway@dtn-hera.fairmont.rdhpcs.noaa.gov ls -l "+hera_path+tar_file, tailfile)

    # Search tail for line with file size
    hera_file_size = -1
    with open(tailfile, "r") as fp:
      for line in mu.lines_that_contain(tar_file, fp):
        print(line)
        hera_file_size = line.split()[4]
    os.remove(tailfile)

    # Check if copy already attempted
    disc_file_size = -1
    if (os.path.exists(os.path.join(self.workDir,tar_file))):
      proc = subprocess.Popen(['ls', '-l', os.path.join(self.workDir,tar_file)], stdout=subprocess.PIPE)
      disc_file_size = proc.stdout.readline().decode('utf-8').split()[4]

    # If not matching in file size copy
    if not hera_file_size == disc_file_size:
      print(' Copying:')
      tailfile = "scp_hera_tar.txt"
      mu.run_bash_command("scp Daniel.Holdaway@dtn-hera.fairmont.rdhpcs.noaa.gov:"+hera_path+tar_file+" ./", tailfile)
      os.remove(tailfile)

    # Check copy was successful
    disc_file_size = -1
    if (os.path.exists(os.path.join(self.workDir,tar_file))):
      proc = subprocess.Popen(['ls', '-l', os.path.join(self.workDir,tar_file)], stdout=subprocess.PIPE)
      disc_file_size = proc.stdout.readline().decode('utf-8').split()[4]

    # Tag as done
    if hera_file_size == disc_file_size:
      pathlib.Path(self.HeraCopyDone).touch()

    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------

  # Untar the converted members

  def extractConvertedMembers(self):

    print(" extractConvertedMembers \n")

    # Move to work directory
    os.chdir(self.workDir)

    tar_file = 'ens_'+self.YmD_HRst+'.tar'
    tailfile = "untar_converted_members.txt"
    mu.run_bash_command("tar -xvf ./"+tar_file, tailfile)

  # ------------------------------------------------------------------------------------------------

  # Prepare directories for the members and the configuration files

  def prepareConvertDirsConfig(self):

    print(" prepareConvertDirsConfig \n")

    # Move to work directory
    os.chdir(self.workDir)

    # Create the config dictionary
    csdict = self.convertStatesDict('a2m','bmat.')

    # Write dictionary to configuration file
    conf_file = os.path.join(self.convertDir,'convert_states.'+self.yamlOrJson)
    with open(conf_file, 'w') as outfile:
      if self.yamlOrJson == 'yaml':
        yaml.dump(csdict, outfile, default_flow_style=False)
      elif self.yamlOrJson == 'json':
        json.dump(csdict, outfile)


    os.chdir(self.homeDir)

  # ------------------------------------------------------------------------------------------------