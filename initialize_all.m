function [ESP, src, phtd, spec] = initialize_all(SRCkeith, PHOTDETkeith, Motors, integrationTime, maxLEDcurr, maxPHOTODETcurr)

% INITIALIZE_ALL Initializes all motors, current sources/measurement and
% spectromemeter
% Returns the gpib objects

%LED Tester
instrreset; %disconnect and delete all instrument objects

%% Initialize Motor Driver (ESP 300)
ESP = gpib('ni', 0, Motors);
ESP.Timeout = 120; %in secs
fopen(ESP);
fprintf(ESP,'1MO');fprintf(ESP,'2MO'); %Turn on motors
fprintf(ESP,'1VA5');fprintf(ESP,'2VA5'); %Set velocity to 5mm/s (max is 20)
fprintf(ESP,'1OR1');fprintf(ESP,'2OR1'); % Home the motors
status = 0;
while status ~= 10000 % [power-to-motors axis4 axis3 axis2 axis1]
    fprintf(ESP,'TS');temp = scanstr(ESP,'%f');
    status_marker = dec2bin(uint8(char(temp)));
    status=str2double(status_marker(3:7));
end

fprintf('Done Motors initialization\n');

%% Initialize Keithleys
src = gpib('ni', 0, SRCkeith);
%src.InputBufferSize = 50000;
src.Timeout = 60; %in secs
fopen(src);
fprintf(src, '*RST');
fprintf(src, ':SENS:FUNC:CONC OFF'); %Measure V and I concurrently?
fprintf(src, ':SENS:FUNC "CURR"'); %What do we want to sense?
fprintf(src, ':SOUR:FUNC VOLT'); %Whats the source?
fprintf(src, ':SOUR:VOLT:MODE FIXED'); %Do we want a fixed or sweep source
fprintf(src, ':ROUT:TERM REAR'); %Use rear output
fprintf(src, ':SENS:CURR:RANG:AUTO ON'); %Set current range to AUTO, this defines resolution
fprintf(src, ':SYST:BEEP:STAT OFF'); % Turn off beeping
fprintf(src, [':SENS:CURR:PROT:LEV ' num2str(maxLEDcurr)]); %Protect by setting max current limit (CURRENT COMPLIANCE)
% fprintf(src, [':SOUR:VOLT:LEV:IMM:AMPL ' num2str(current)]); %Set voltage to this value
% fprintf(src,':OUTP ON');

phtd = gpib('ni', 0, PHOTDETkeith); %measures Voltage across a resistor connected to photodiode
%src.InputBufferSize = 50000;
phtd.Timeout = 60; %in secs
fopen(phtd);
fprintf(phtd, '*RST');
fprintf(phtd, ':SENS:FUNC:CONC OFF'); %Measure V and I concurrently?
fprintf(phtd, ':SENS:FUNC "CURR"'); %What do we want to sense?
fprintf(phtd, ':SOUR:FUNC VOLT'); %Need to set current source to zero to use as voltmeter
fprintf(phtd, ':SOUR:VOLT:LEV:IMM:AMPL 0'); %Set voltage to this value
fprintf(phtd, ':ROUT:TERM REAR'); %Use rear output
fprintf(phtd, ':SENS:CURR:RANG:AUTO ON'); %Set current range to AUTO, this defines resolution
fprintf(phtd, ':SYST:BEEP:STAT OFF'); % Turn off beeping
fprintf(phtd, [':SENS:CURR:PROT:LEV ' num2str(maxPHOTODETcurr)]); %Protect by setting max current limit (CURRENT COMPLIANCE)
%fprintf(phtd,':OUTP ON'); %Apply voltage

fprintf('Done Keithley initialization\n');

%% Initialize Spectrometer
spec = icdevice('OceanOptics_OmniDriver.mdd'); %Create object
connect(spec); %connect
spectrometerIndex = 0; channelIndex = 0; enable = 1; %if >1 Ocean Optics connected
spectrometerName = invoke(spec, 'getName', spectrometerIndex);
spectrometerSerialNumber = invoke(spec, 'getSerialNumber', spectrometerIndex);
display(['Model Name : ' spectrometerName]);
display(['Model S/N  : ' spectrometerSerialNumber]);
invoke(spec, 'setIntegrationTime', spectrometerIndex, channelIndex, integrationTime); % Set integration time.
% invoke(spectrometerObj, 'setCorrectForDetectorNonlinearity', spectrometerIndex, channelIndex, enable); % Enable correct for detector non-linearity.
% invoke(spectrometerObj, 'setCorrectForElectricalDark', spectrometerIndex, channelIndex, enable); % Enable correct for electrical dark.

fprintf('Done Spec initialization\n');

end

