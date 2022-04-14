#!/usr/bin/env python3
"""
@author: Benjamin Menetrier
@description: plotting facility for FV3
"""

# (C) Copyright 2021 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

import os
import argparse
import sys
import time
import subprocess


# -----------------------------------------------------------------------------

# Initial time
initial_time = time.perf_counter()

# -----------------------------------------------------------------------------

# Environment variables

# FV3_GRID_DIR: directory with FV3 grid files for each resolution ("fv3grid_cNNNN.nc")
gridfiledir = os.environ.get("FV3_GRID_DIR", os.path.dirname(os.path.realpath(__file__)) + "/fv3grid")

# -----------------------------------------------------------------------------

# Parser
parser = argparse.ArgumentParser()

# GEOS / GFS input file
parser.add_argument("--geos", dest="geos", action="store_true", help="GEOS input file")
parser.add_argument("--gfs", dest="gfs", action="store_true", help="GFS input file")

# File path
parser.add_argument("--filepath", "-f", help="File path")

# Variable
parser.add_argument("--variable", "-v", help="Variable")

# Base file path to compute a difference (optional)
parser.add_argument("--basefilepath", "-bf", help="Base file path to compute a difference (optional)")

# Base variable to compute a difference (optional)
parser.add_argument("--basevariable", "-bv", help="Base variable")

# Level
parser.add_argument("--level", "-l", type=int, help="Level")

# Color map (optional, default=jet or coolwarm)
parser.add_argument("--colormap", "-cm", type=str, nargs="?", help="Color map (optional, default=jet or coolwarm)")

# Centered color map
parser.add_argument("--centered", dest="centered", action="store_true", help="Centered color map")

# Ferret script (a lot faster)
parser.add_argument("--ferret", dest="ferret", action="store_true", help="Ferret script")

# Output file path
parser.add_argument("--output", "-o", help="Output file path")

# Lon/lat of view
lonview = -45.0
latview = 45.0

# Parse arguments
args = parser.parse_args()

# -----------------------------------------------------------------------------

# Set default string values
if args.colormap is None:
    if args.centered:
        if args.ferret:
            args.colormap = "cmocean_balance"
        else:
            args.colormap = "seismic"
    else:
        if args.ferret:
            args.colormap = "default"
        else:
            args.colormap = "viridis"
    
# Print arguments
print("Parameters:")
print(" - gridfiledir: " + gridfiledir)
for arg in vars(args):
    if not arg is None:
        print(" - " + arg + ": " + str(getattr(args, arg)))

# Check arguments
if (not (args.geos or args.gfs)):
    print("ERROR: --geos or --gfs required")
    sys.exit(1)

# -----------------------------------------------------------------------------

# Import modules
from netCDF4 import Dataset
import numpy as np
   
if args.geos:
    # Check file extension
    if not args.filepath.endswith(".nc4"):
        print("   Error: filepath extension should be .nc4")
        sys.exit(1)

    # Open data file
    fdata = Dataset(args.filepath, "r", format="NETCDF4")

    # Read field
    fld = fdata[args.variable][0,args.level-1,:,:,:]
    units = fdata[args.variable].units
    long_name = fdata[args.variable].long_name

    if not args.basefilepath is None:
        # Check base file extension
        if not args.basefilepath.endswith(".nc4"):
            print("   Error: basefilepath extension should be .nc4")
            sys.exit(1)

        # Open data file
        fdata = Dataset(args.basefilepath, "r", format="NETCDF4")

        # Variable name
        if args.basevariable is None:
            variable = args.variable
        else:
            variable = args.basevariable

        # Read field
        basefld = fdata[variable][0,args.level-1,:,:,:]

        # Compute increment
        fld = fld - basefld

    # Get shape
    shp = np.shape(fld)
    ny = shp[1]
    nx = shp[2]
elif args.gfs:
    # Check file extension
    if not args.filepath.endswith(".nc"):
        print("   Error: filepath extension should be .nc")
        sys.exit(1)

    for itile in range(0, 6):
        # Open data file
        filename = args.filepath.replace(".nc", ".tile" + str(itile+1) + ".nc")
        fdata = Dataset(filename, "r", format="NETCDF4")

        # Read field
        fld_tmp = fdata[args.variable][0,args.level-1,:,:]
        units = fdata[args.variable].units
        long_name = fdata[args.variable].long_name

        if itile == 0:
            # Get shape
            shp = np.shape(fld_tmp)
            ny = shp[0]
            nx = shp[1]

            # Initialize field
            fld = np.zeros((6, ny, nx))

        # Copy field
        fld[itile,:,:] = fld_tmp

    if not args.basefilepath is None:
        # Check base file extension
        if not args.basefilepath.endswith(".nc"):
            print("   Error: basefilepath extension should be .nc")
            sys.exit(1)

        for itile in range(0, 6):
            # Open data file
            filename = args.basefilepath.replace(".nc", ".tile" + str(itile+1) + ".nc")
            fdata = Dataset(filename, "r", format="NETCDF4")

            # Variable name
            if args.basevariable is None:
                variable = args.variable
            else:
                variable = args.basevariable

            # Read field
            fld_tmp = fdata[variable][0,args.level-1,:,:]

            # Copy field
            fld[itile,:,:] = fld[itile,:,:] - fld_tmp
 
# Open grid file
fgrid = Dataset(gridfiledir + "/fv3grid_c" + str(nx).zfill(4) + ".nc4", "r", format="NETCDF4")

# Read grid vertices lons/lats
vlons = np.degrees(fgrid["vlons"][:,:,:])
vlats = np.degrees(fgrid["vlats"][:,:,:])

# Figure title
title = args.variable + " at level " + str(args.level) + " - C" + str(nx)

if args.ferret:
    # Write field in NetCDF file
    if args.geos:
        # TODO
        print('not implemented yet')
        exit()
    elif args.gfs:
        for itile in range(0, 6):
            # Ferret file name
            ferret_file_name = "ferret_tile"

            # Open data file
            filename = ferret_file_name + str(itile+1) + ".nc"
            ncferret = Dataset(filename,mode="w",format="NETCDF4_CLASSIC")

            # Create dimensions
            nvx_dim = ncferret.createDimension('nvx', nx+1)
            nvy_dim = ncferret.createDimension('nvy', ny+1)
            ncx_dim = ncferret.createDimension('ncx', nx)
            ncy_dim = ncferret.createDimension('ncy', ny)

            # Create variables
            lat = ncferret.createVariable('lat', np.float64, ('nvy','nvx',))
            lat.units = 'degrees_north'
            lat.long_name = 'latitude'
            lon = ncferret.createVariable('lon', np.float64, ('nvy','nvx',))
            lon.units = 'degrees_east'
            lon.long_name = 'longitude'
            var = ncferret.createVariable('var', np.float64, ('ncy','ncx',))
            var.units = units
            var.long_name = long_name

            # Write variables
            lat[:,:] = vlats[itile,:,:]
            lon[:,:] = vlons[itile,:,:]
            var[:,:] = fld[itile,:,:]

            # Close file
            ncferret.close()

    # Run ferret script
    info = subprocess.getstatusoutput('ferret --help')
    if info[0] == 0:
        subprocess.run(["ferret", "-unmapped", "-gif", "-script", "raster.jnl", ferret_file_name, title, str(lonview), str(latview), args.colormap, str(args.centered), args.output],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT)
    else:
        print(info[1])

    # Remove temporary files
    if args.geos:
        # TODO
        print('not implemented yet')
        exit()
    elif args.gfs:
        for itile in range(0, 6):
            os.remove(ferret_file_name + str(itile+1) + ".nc")
else:
    # Import modules
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    import matplotlib.cm as cm
    import cartopy.crs as ccrs
    import copy
    
    # Projection
    projection = ccrs.Orthographic(lonview, latview)
   
    # Compute min/max
    if args.centered:
        vmax = np.max(np.abs(fld))
        vmin = -vmax
    else:
        vmin = np.min(fld)
        vmax = np.max(fld)
    norm = plt.Normalize(vmin=vmin, vmax=vmax)
    
    # Initialize figure
    fig,ax = plt.subplots(figsize=(8,8),subplot_kw=dict(projection=projection))
    ax.set_global()
    ax.coastlines()
    
    # Colormap
    cmap = copy.copy(cm.get_cmap(args.colormap))
    cmap.set_bad('gray', 1)
    
    # Figure title
    plt.title(title)
    
    # Loop over tiles
    for itile in range(0, 6):
        # Loop over polygons
        for iy in range(0, ny):
            for ix in range(0, nx):
                # Polygon coordinates      
                xy = [[vlons[itile,iy+0,ix+0], vlats[itile,iy+0,ix+0]],
                      [vlons[itile,iy+0,ix+1], vlats[itile,iy+0,ix+1]],
                      [vlons[itile,iy+1,ix+1], vlats[itile,iy+1,ix+1]],
                      [vlons[itile,iy+1,ix+0], vlats[itile,iy+1,ix+0]]]
    
                # Add polygon
                ax.add_patch(mpatches.Polygon(xy=xy, closed=True, facecolor=cmap(norm(fld[itile,iy,ix])),transform=ccrs.Geodetic()))
    
    # Set colorbar
    sm = cm.ScalarMappable(cmap=args.colormap, norm=plt.Normalize(vmin=vmin, vmax=vmax))
    sm.set_array([])
    plt.colorbar(sm, orientation="vertical",shrink=0.8)
    
    # Save and close figure
    plt.savefig(args.output + ".png", format="png", dpi=300)
    plt.close()

# -----------------------------------------------------------------------------

# Trim figure with mogrify if available
info = subprocess.getstatusoutput('mogrify -help')
if info[0] == 0:
    if args.ferret:
        subprocess.run(["mogrify", "-trim", "-format", "png", args.output + ".gif"])
        os.remove(args.output + ".gif")
    else:
        subprocess.run(["mogrify", "-trim", args.output + ".png"])

# -----------------------------------------------------------------------------

# Final time
final_time = time.perf_counter()

# Print timing
print(f"raster.py executed in {final_time - initial_time:0.4f} seconds")
