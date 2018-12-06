%% Solid angle measurement function v0.2
%   Code written by Jeffrey Kirman
%
%   changelog:
%       v0.2:   - added input parameter descriptions
%               - changed code to calculate % of photons per solid angle
%               - removed depricated global variables code
%               - corrected distances units for calculation
%       v0.1:   - initial revision

function [device_voltage, solid_angle, all_solid_angles, phtd_current] = measure_brightness_cone(ESP, src, phtd, set_current, start_x, start_y, distances, phtd_area, stop_button_handle, graph_handle)

%   ESP, src, phtd: GPIB for the motors, device Keithley, photodetector Keithley
%   set_current: current to set the device to in mA
%   start_x: start position of the motor on the x-axis
%   start_y: start position of the motor on the y-axis
%   distances: vector of distances to do measurements at
%   phtd_area: photodetector area
%   stop_button_handle: handle for the stop button
%   graph_handle: handle for the solid angle graph

    delays = 0.1; % seconds
    phtd_current = zeros(size(distances));

    % Move to closest distance and get light intensity
    move_motors(ESP, start_x + distances(1), start_y, stop_button_handle);
    
    fprintf(src, [':SOUR:CURR:LEV:IMM:AMPL ' num2str(-set_current/1000)]); % Set voltage to this value
    fprintf(src,':OUTP ON'); % Apply voltage
    pause(delays); % Wait
    fprintf(src, ':READ?'); % Measure device voltage
    scan = scanstr(src, ',', '%f');
    device_voltage(1) = scan(2);

    fprintf(phtd,':OUTP ON'); % Turn on photodetector
    pause(delays); % Wait

    fprintf(phtd, ':READ?'); % Measure current in photodetector
    scan = scanstr(phtd, ',', '%f');
    L_0 = scan(2);

    pause(delays); % Wait
    fprintf(src,':OUTP OFF');
    fprintf(phtd,':OUTP OFF');
    
    % Move to different distances and gather data
    for k=2:length(distances)
        
        drawnow()
        stop_state = get(stop_button_handle, 'Value');
        if stop_state
            break;
        end
        
        move_motors(ESP, start_x + distances(k), start_y, stop_button_handle);
    
        fprintf(src, [':SOUR:CURR:LEV:IMM:AMPL ' num2str(-set_current/1000)]); % Set voltage to this value
        fprintf(src,':OUTP ON'); % Apply voltage
        pause(delays); % Wait
        fprintf(src, ':READ?'); % Measure device voltage
        scan = scanstr(src, ',', '%f');
        device_voltage(k) = scan(2);

        fprintf(phtd,':OUTP ON'); % Turn on photodetector
        pause(delays); % Wait

        fprintf(phtd, ':READ?'); % Measure current in photodetector
        scan = scanstr(phtd, ',', '%f');
        L(k-1) = scan(2);

        pause(delays); % Wait
        fprintf(src,':OUTP OFF');
        fprintf(phtd,':OUTP OFF');
    end
    
    if ~stop_state
        % Calculate solid angle at each step
        r_sq = phtd_area * L_0 ./ (pi*L);
        R = sqrt(r_sq + (distances(2:end)/1000).^2);
        h = R - distances(2:end)/1000;
        solid_angles = 2*pi*R.*h ./ r_sq;

        % TODO write parsing code to decide on final solid angle
        solid_angle = solid_angles(end);
        phtd_current = [L_0 L];
        all_solid_angles = [0 solid_angles];
        
        % Update graphs
        set(graph_handle,'XData', distances(2:k));
        set(graph_handle,'YData', solid_angles);        
    end
    
end

