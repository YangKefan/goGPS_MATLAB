function [pr1, ph1, pr2, ph2, dop1, dop2, Eph, iono, snr1, snr2,...
          pr1_GLO, ph1_GLO, pr2_GLO, ph2_GLO, dop1_GLO, dop2_GLO, ...
          Eph_GLO, snr_GLO, time_GPS, week, date, pos] = ...
          load_RINEX_SA(name_F_oss, name_F_nav, wait_dlg, max_time)

% SYNTAX:
%   [pr1, ph1, pr2, ph2, dop1, dop2, Eph, iono, snr1, snr2,...
%         pr1_GLO, ph1_GLO, pr2_GLO, ph2_GLO, dop1_GLO, dop2_GLO, ...
%         Eph_GLO, snr_GLO, time_GPS, week, date, pos] = ...
%         load_RINEX_SA(name_F_oss, name_F_nav, wait_dlg, max_time);
%
% INPUT:
%   name_F_oss = RINEX observation file
%   name_F_nav = RINEX navigation file
%   wait_dlg = optional handler to waitbar figure
%   max_time = optional maximum time to stop RINEX parsing
%
% OUTPUT:
%   pr1 = code observation (L1 carrier)
%   ph1 = phase observation (L1 carrier)
%   pr2 = code observation (L2 carrier)
%   ph2 = phase observation (L2 carrier)
%   dop1 = Doppler observation (L1 carrier)
%   dop2 = Doppler observation (L2 carrier)
%   Eph = matrix containing 29 ephemerides for each satellite
%   iono = matrix containing ionosphere parameters
%   snr1 = signal-to-noise ratio (L1 carrier)
%   snr2 = signal-to-noise ratio (L2 carrier)
%   pr1_GLO = code observation (L1 carrier) (GLONASS)
%   ph1_GLO = phase observation (L1 carrier) (GLONASS)
%   pr2_GLO = code observation (L2 carrier) (GLONASS)
%   ph2_GLO = phase observation (L2 carrier) (GLONASS)
%   dop1 = Doppler observation (L1 carrier) (GLONASS)
%   dop2 = Doppler observation (L2 carrier) (GLONASS)
%   Eph_GLO = matrix containing 29 ephemerides for each satellite (GLONASS)
%   snr_GLO = signal-to-noise ratio (GLONASS)
%   time_GPS = GPS seconds-of-week
%   week = GPS week number
%   date = date (year,month,day,hour,minute,second)
%   pos = master station approximate position
%
% DESCRIPTION:
%   Parse RINEX files (both observation and navigation).

%----------------------------------------------------------------------------------------------
%                           goGPS v0.3.1 beta
%
% Copyright (C) 2009-2011 Mirko Reguzzoni, Eugenio Realini
%----------------------------------------------------------------------------------------------
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%----------------------------------------------------------------------------------------------

Eph_GLO = zeros(17,32);

if (nargin >= 3)
    waitbar(0.33,wait_dlg,'Reading navigation files...')
end

%parse RINEX navigation file
[Eph, iono] = RINEX_get_nav(name_F_nav);

if (nargin >= 3)
    waitbar(0.66,wait_dlg)
end

if (nargin >= 3)
    waitbar(1,wait_dlg)
end

%-------------------------------------------------------------------------------

%open RINEX observation file
F_oss = fopen(name_F_oss,'r');

%-------------------------------------------------------------------------------

if (nargin >= 3)
    waitbar(0.5,wait_dlg,'Parsing RINEX headers...')
end

%parse RINEX header
[obs_typ,  pos, info_base] = RINEX_parse_hdr(F_oss);

%check the availability of basic data to parse the RINEX file
if (info_base == 0)
    error('Basic data is missing in the RINEX header')
end

if (nargin >= 3)
    waitbar(1,wait_dlg)
end

%-------------------------------------------------------------------------------

if (nargin >= 3)
    waitbar(1,wait_dlg)
end

%-------------------------------------------------------------------------------

nEpochs = 86400;

%variable initialization (GPS)
time_GPS = zeros(nEpochs,1);
pr1 = zeros(32,nEpochs);
pr2 = zeros(32,nEpochs);
ph1 = zeros(32,nEpochs);
ph2 = zeros(32,nEpochs);
dop1 = zeros(32,nEpochs);
dop2 = zeros(32,nEpochs);
snr1 = zeros(32,nEpochs);
snr2 = zeros(32,nEpochs);
date = zeros(nEpochs,6);

%variable initialization (GLONASS)
pr1_GLO = zeros(32,1);
pr2_GLO = zeros(32,1);
ph1_GLO = zeros(32,1);
ph2_GLO = zeros(32,1);
dop1_GLO = zeros(32,1);
dop2_GLO = zeros(32,1);
snr_GLO = zeros(32,1);

k = 1;

if (nargin >= 3)
    waitbar(0.5,wait_dlg,'Reading RINEX observations...')
end

while (~feof(F_oss))

    if (k > nEpochs)
        
        %variable initialization (GPS)
        pr1(:,k)  = zeros(32,1);
        pr2(:,k)  = zeros(32,1);
        ph1(:,k)  = zeros(32,1);
        ph2(:,k)  = zeros(32,1);
        dop1(:,k) = zeros(32,1);
        dop2(:,k) = zeros(32,1);
        snr1(:,k) = zeros(32,1);
        snr2(:,k) = zeros(32,1);
        
        %variable initialization (GLONASS)
        % pr1_GLO(:,k) = zeros(32,1);
        % pr2_GLO(:,k) = zeros(32,1);
        % ph1_GLO(:,k) = zeros(32,1);
        % ph2_GLO(:,k) = zeros(32,1);
        % snr_GLO(:,k) = zeros(32,1);

        nEpochs = nEpochs  + 1;
    end
    
    %read data for the current epoch
    [time_GPS(k), sat, sat_types, date(k,:)] = RINEX_get_epoch(F_oss);

    %read observations
    [obs_GPS, obs_GLO, obs_SBS] = RINEX_get_obs(F_oss, sat, sat_types, obs_typ); %#ok<NASGU>
    
    %read observations (GPS)
    pr1(:,k)  = obs_GPS.C1;
    pr2(:,k)  = obs_GPS.P2;
    ph1(:,k)  = obs_GPS.L1;
    ph2(:,k)  = obs_GPS.L2;
    dop1(:,k) = obs_GPS.D1;
    dop2(:,k) = obs_GPS.D2;
    snr1(:,k)  = obs_GPS.S1;
    snr2(:,k)  = obs_GPS.S2;
    
    %read observations (GLONASS)
    % pr1_GLO(:,k) = obs_GLO.C1;
    % %pr2_GLO(:,k) = obs_GLO.P2;
    % ph1_GLO(:,k) = obs_GLO.L1;
    % %ph2_GLO(:,k) = obs_GLO.L2;
    % snr_GLO(:,k) = obs_GLO.S1;
    
    if (nargin > 3 & time_GPS(k) >= max_time)
        break
    end
    
    k = k+1;
end

%remove empty slots
time_GPS(k:nEpochs) = [];
pr1(:,k:nEpochs) = [];
pr2(:,k:nEpochs) = [];
ph1(:,k:nEpochs) = [];
ph2(:,k:nEpochs) = [];
dop1(:,k:nEpochs) = [];
dop2(:,k:nEpochs) = [];
snr1(:,k:nEpochs) = [];
snr2(:,k:nEpochs) = [];
% pr1_GLO(:,k:nEpochs) = [];
% pr2_GLO(:,k:nEpochs) = [];
% ph1_GLO(:,k:nEpochs) = [];
% ph2_GLO(:,k:nEpochs) = [];
% dop1_GLO(:,k:nEpochs) = [];
% dop2_GLO(:,k:nEpochs) = [];
% snr_GLO(:,k:nEpochs) = [];

if (nargin >= 3)
    waitbar(1,wait_dlg)
end

%-------------------------------------------------------------------------------

%close RINEX file
fclose(F_oss);

%GPS week number
week = date2gps(date);