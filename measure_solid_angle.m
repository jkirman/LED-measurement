%% Solid angle measurement function v0.1
%   Code written by Jeffrey Kirman
%
%   changelog:
%       v0.1:   - initial revision

function [device_voltage, solid_angles, phtd_current] = measure_solid_angle(ESP, src, phtd, set_current, start_x, start_y, distances, min_distance, phtd_area, max_LED_current, stop_button_handle, graph_handle)

%   ESP, src, phtd: GPIB for the motors, device Keithley, photodetector Keithley
%   set_current: current to set the device to in mA
%   start_x: start position of the motor on the x-axis
%   start_y: start position of the motor on the y-axis
%   distances: vector of distances to do measurements at
%   phtd_area: photodetector area
%   stop_button_handle: handle for the stop button
%   graph_handle: handle for the solid angle graph

    delays = 1; % seconds
    device_voltage = zeros(size(distances));
    phtd_current = zeros(size(distances));
    solid_angles = 4 * asin(1 ./ (1 + (phtd_area ./ ( 2 * (distances+min_distance)/1000).^2 )));
 
    % Set up source Keithley to output current and measure voltage
    fprintf(src, '*RST');
    fprintf(src, ':SENS:FUNC:CONC OFF'); %Measure V and I concurrently?
    fprintf(src, ':SENS:FUNC "VOLT"'); %What do we want to sense?
    fprintf(src, ':SOUR:FUNC CURR'); %Whats the source?
    fprintf(src, ':SOUR:CURR:MODE FIXED'); %Do we want a fixed or sweep source
    fprintf(src, ':ROUT:TERM REAR'); %Use rear output
    fprintf(src, ':SENS:VOLT:RANG:AUTO ON'); %Set current range to AUTO, this defines resolution
    fprintf(src, ':SYST:BEEP:STAT OFF'); % Turn off beeping
    
    % Move to different distances and gather data
    
    move_motors(ESP, start_x + distances(1), start_y, stop_button_handle);
    fprintf(src, [':SOUR:CURR:LEV:IMM:AMPL ' num2str(-set_current/1000)]); % Set voltage to this value
    fprintf(src,':OUTP ON'); % Apply current
    
    for k=1:length(distances)
        
        drawnow()
        stop_state = get(stop_button_handle, 'Value');
        if stop_state
            break;
        end
        
        move_motors(ESP, start_x + distances(k), start_y, stop_button_handle);
    
        pause(delays); % Wait
        fprintf(src, ':READ?'); % Measure device voltage
        scan = scanstr(src, ',', '%f');
        device_voltage(k) = scan(2);

        fprintf(phtd,':OUTP ON'); % Turn on photodetector
        pause(delays); % Wait

        fprintf(phtd, ':READ?'); % Measure current in photodetector
        scan = scanstr(phtd, ',', '%f');
        phtd_current(k) = scan(2);

        fprintf(phtd,':OUTP OFF');
    end
    
    fprintf(src,':OUTP OFF');
    
    if ~stop_state
        
        % Update graphs
        set(graph_handle,'XData', fliplr(solid_angles));
        set(graph_handle,'YData', phtd_current);
        
    end
    
    fprintf(src, '*RST');
    fprintf(src, ':SENS:FUNC:CONC OFF'); %Measure V and I concurrently?
    fprintf(src, ':SENS:FUNC "CURR"'); %What do we want to sense?
    fprintf(src, ':SOUR:FUNC VOLT'); %Whats the source?
    fprintf(src, ':SOUR:VOLT:MODE FIXED'); %Do we want a fixed or sweep source
    fprintf(src, ':ROUT:TERM REAR'); %Use rear output
    fprintf(src, ':SENS:CURR:RANG:AUTO ON'); %Set current range to AUTO, this defines resolution
    fprintf(src, ':SYST:BEEP:STAT OFF'); % Turn off beeping
    fprintf(src, [':SENS:CURR:PROT:LEV ' num2str(max_LED_current)]); %Protect by setting max current limit (CURRENT COMPLIANCE)
    
end

