%% Fetch Spectrum through Ocean Optics Spectrometer using MATLAB Instrument Driver
%
% This example shows how to acquire the spectrum of a fluorescent light source
% from an Ocean Optics Spectrometer.

%% Introduction
% Instrument Control Toolbox(TM) supports communication with instruments
% through high-level drivers.  In this example you can acquire spectrum
% from an Ocean Optics Spectrometer using the MATLAB Instrument Driver.
%
% Copyright 2012 The MathWorks, Inc.

%% Requirements
% This example requires the following:
% * A 64-bit Microsoft(R) Windows(R)
% * Ocean Optics spectrometer USB2000
% * Install OmniDriver downloadable from http://www.oceanoptics.com/
% * OmniDriver.mdd available from MATLAB Central

%% Create MATLAB Instrument OmniDriver object.
spectrometerObj = icdevice('OceanOptics_OmniDriver.mdd');

%% Connect to the instrument.
connect(spectrometerObj);
disp(spectrometerObj);

%% Set parameters for spectrum acquisition.

% integration time for sensor.
integrationTime = 50;
% Spectrometer index to use (first spectrometer by default).
spectrometerIndex = 0;
% Channel index to use (first channel by default).
channelIndex = 0;
% Enable flag.
enable = 1;

%% Identify the spectrometer connected.

% Get number of spectrometers connected.
numOfSpectrometers = invoke(spectrometerObj, 'getNumberOfSpectrometersFound');

display(['Found ' num2str(numOfSpectrometers) ' Ocean Optics spectrometer(s).']);

% Get spectrometer name. 
spectrometerName = invoke(spectrometerObj, 'getName', spectrometerIndex);
% Get spectrometer serial number.
spectrometerSerialNumber = invoke(spectrometerObj, 'getSerialNumber', spectrometerIndex);
display(['Model Name : ' spectrometerName])
display(['Model S/N  : ' spectrometerSerialNumber]);

%% Set the parameters for spectrum acquisition.

% Set integration time.
invoke(spectrometerObj, 'setIntegrationTime', spectrometerIndex, channelIndex, integrationTime);
% Enable correct for detector non-linearity.
invoke(spectrometerObj, 'setCorrectForDetectorNonlinearity', spectrometerIndex, channelIndex, enable);
% Enable correct for electrical dark.
invoke(spectrometerObj, 'setCorrectForElectricalDark', spectrometerIndex, channelIndex, enable);

%% Aquire the spectrum.
wavelengths = invoke(spectrometerObj, 'getWavelengths', spectrometerIndex, channelIndex);
% Get the wavelengths of the first spectrometer and save them in a double
% array.
spectralData = invoke(spectrometerObj, 'getSpectrum', spectrometerIndex);

%% Plot the waveform.
    plot(wavelengths, spectralData);
    title('Optical Spectrum');
    ylabel('Intensity (counts)');
    xlabel('\lambda (nm)');
    grid on
    axis tight

%% Clean up.
disconnect(spectrometerObj);

delete (spectrometerObj);

%%
displayEndOfDemoMessage(mfilename)
