%% EU_HFR_Node_TA_REP_dataset_builder.m
% This wrapper launches the scripts for aggregating historical (i.e. not
% processed for NRT operation, i.e. not present in the EU HFR Node NRT
% THREDDS catalog) HFR radial and total hourly files in standard format in
% order to produce temporally aggregated datasets to be pushed towards
% CMEMS-INSTAC for the REP products.

% This application works on historical data, thus the ID of the network to
% be processed and the processing time interval have to be specified in
% lines 36-47.

% Author: Lorenzo Corgnati
% Date: March 5, 2020

% E-mail: lorenzo.corgnati@sp.ismar.cnr.it
%%

warning('off', 'all');

clear all
close all
clc

% Setup netCDF toolbox
setup_nctoolbox;

EHNTA_err = 0;

disp(['[' datestr(now) '] - - ' 'EU_HFR_Node_TA_REP_dataset_builder started.']);

%%

try
    
    %% Set data format version
    vers = 'v2.2';
    
    %%
    
    %% Set HFR networks to be processed and temporal aggregation interval
    
    % START AND END DATES TO BE INSERTED IN THE FORMAT YYYY-MM-DD AS COMMA-SEPARATED LIST
    procStart = '2019-07-01'; % Start date included
    procEnd = '2019-08-01'; % End date included
    
    % Monthly aggregation flag. 0 = AGGREGATION ON THE WHOLE PERIOD -- 1 = MONTHLY AGGREGATION
    monthlyAggregation = 0;
    
    % NETWORK IDS TO BE INSERTED AS COMMA-SEPARATED LIST
    HFRnetworkID = 'HFR-Galicia';
    
    %%
    
    %% Retrieve networks IDs, start processing date and end processing date
    
    HFRPnetworks = regexp(HFRnetworkID, '[ ,;]+', 'split');
    procStartDate = regexp(procStart, '[ ,;]+', 'split');
    procEndDate = regexp(procEnd, '[ ,;]+', 'split');
    
    disp(['[' datestr(now) '] - - ' 'HFR networks succesfully listed.']);
    
    %%
    
    %% Launch the aggregators
    
    % TOTAL FILE PROCESSING
    TA_REP_totals;
    
    % RADIAL FILE PROCESSING
    TA_REP_radials;
    
    %%
    
catch err
    disp(['[' datestr(now) '] - - ERROR in ' mfilename ' -> ' err.message]);
    EHNTA_err = 1;
end

if(EHNTA_err==0)
    disp(['[' datestr(now) '] - - ' 'EU_HFR_Node_TA_REP_dataset_builder successfully executed.']);
else
    disp(['[' datestr(now) '] - - ' 'EU_HFR_Node_TA_REP_dataset_builder exited with an error.']);
end

