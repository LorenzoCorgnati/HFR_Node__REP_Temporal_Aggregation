# HFR_Node__REP_Temporal_Aggregataion
These applications are written in Matlab language and they are designed for High Frequency Radar (HFR) data management according to the European HFR node processing workflow. These applications aggregate historical (i.e. not processed for NRT operation, i.e. not present in the EU HFR Node NRT THREDDS catalog) HFR radial and total files in netCDF format according to the European standard data and metadata model for near real time HFR current data in order to produce temporally aggregated datasets to be pushed towards CMEMS-INSTAC for the REP products.

THIS APPLICATION IS DESIGNED FOR PROCESSING HISTORICAL DATA IN NETCDF FORMAT ACCORDING TO THE EUROPEAN STANDARD DATA AND METADATA MODEL FOR NRT HFR CURRENT DATA. 

This application supports batch processing.

Start and end dates must be specified as comma separated list at lines 43-44 of the EU_HFR_Node_TA_REP_dataset_builder.m wrapper.

HFR networks to be processed must be specified as comma separated list at line 50 of the EU_HFR_Node_TA_REP_dataset_builder.m wrapper.


THE INPUT DATA TO BE PROCESSED MUST BE PLACED IN A FOLDER NAMED WITH THE NETWORK ID OF THE HFR NETWORK AT THE SAME LEVEL OF THE FOLDER CONTAINING THE APPLICATION (I.E. A FOLDER ROOTWARD WITH RESPECT TO THE SCRIPT FILES). THE NETWORK-ID-NAMED FOLDER MUST HAVE THE FOLLOWING STRUCTURE:

HFR_network_id
      
      |__________Radials_nc (containing input .nc radial files)
            
      |               |__________station_id_1 (one per each radial station)
      
      |               |__________station_id_2
      
      |               |__________    ...
      
      |               |__________station_id_n
      
      |__________Totals_nc (containing input .nc total files)

The applications are intended to:
- list all the netCDF radial or total files to be aggregated;
- aggregated the selected files for building temporally aggregated datasets according to the European standard data and metadata model for near real time HFR current data.

All generated radial and total netCDF files are quality controlled according the the QC tests defined as standard for the European HFR node and for the data distribution on CMEMS-INSTAC and SeaDataNet platforms.

The whole workflow is intended to run automatically to aggregated historical HFR data in netCDF format according to the European standard data and metadata model for near real time HFR current data.

The wrapper EU_HFR_Node_TA_REP_dataset_builder.m sets the network ID, the starting and ending time and launches the aggregation applications.

The applications TA_REP_totals.m and TA_REP_radials.m create the folder list to be scanned for searching for the files to be aggregated.

The applications TA_REP_total_netCDF_aggregation_v212.m and TA_REP_radial_netCDF_aggregation_v212.m aggregate the files found in the selected folders and create temporally aggregated datasets in netCDF format according to the European standard data and metadata model for near real time HFR current data.


The required toolboxes are:
- Nctoolbox-1.1.3 (https://github.com/nctoolbox/nctoolbox); 
- Rdir (http://www.mathworks.com/matlabcentral/fileexchange/19550-recursive-directory-listing);


Author: Lorenzo Corgnati

Date: March 12, 2020

E-mail: lorenzo.corgnati@sp.ismar.cnr.it 

