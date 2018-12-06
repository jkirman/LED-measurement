%% Intensity measurement function v0.1
%   Code written by Jeffrey Kirman
%
%   changelog:
%       v0.1:   - initial revision

function [volts, device_current, phtd_current, luminous_intensity, luminance, current_efficiency, EQE, wavelengths_rf, radient_flux] = ...
    measure_intensity(src, phtd, integration_time, max_voltage, step_size, PDcal, wavelengths, ELSpec, lum_function, solid_angle, device_area, stop_button_handle, graph_handles, raw_only)
%MEASURE_INTENSITY Summary of this function goes here

%   src, phtd: GPIB for device Keithley, photodetector Keithley
%   integration_time: the amount paused at each step before photodetector measurement is taken (in ms)
%   max_voltage: the max voltage applied to the device (in V)
%   step_size: the step size in which the voltage sweep goes up by (in V)
%   PDcal: the photodetector calibration curve
%   wavelengths: the wavelengths in the EL spectra (ELSpec)
%   ELSpec: the EL spectra intensity values OR the wavelength to approximate at
%   lum_function: the luminosity function curve
%   solid_angle: the solid angle dependence curve on device emission (% photons/sr)
%   device_area: the area of the part of the pixel that illuminates
%   stop_button_handle: handle for the stop button
%   graph_handle: handle for the solid angle graph
    
    % Allocate memory for outputs
    volts = (0:step_size:max_voltage)';
    device_current = zeros(size(volts));
    phtd_current = zeros(size(volts));
    luminous_intensity = zeros(size(volts));
    luminance = zeros(size(volts));
    current_efficiency = zeros(size(volts));
    EQE = zeros(size(volts));
    wavelengths_rf = zeros(size(volts));
    radient_flux = zeros(size(volts));

    delays = 0.1; % seconds

    for k=1:length(volts)
        
        drawnow()
        stop_state = get(stop_button_handle, 'Value');
        if stop_state
            break;
        end
        
        fprintf(src, [':SOUR:VOLT:LEV:IMM:AMPL ' num2str(-volts(k))]); % Set voltage to this value
        fprintf(src,':OUTP ON'); % Apply voltage
        pause(delays); % Wait
        fprintf(src, ':READ?'); % Measure device current
        scan = scanstr(src, ',', '%f');
        device_current(k) = scan(2);
        
        fprintf(phtd,':OUTP ON'); % Turn on photodetector
        pause(delays); % Wait
        fprintf(phtd, ':READ?'); % Measure current in photodetector
        scan = scanstr(phtd, ',', '%f');
        phtd_current(k) = scan(2);
        pause(delays); % Wait
        
        pause(integration_time/1000); % Pause for integration time
        
        fprintf(src,':OUTP OFF');
        fprintf(phtd,':OUTP OFF');
        
        % Update graphs
        set(graph_handles(1),'XData', volts(volts ~= 0));
        set(graph_handles(1),'YData', device_current(device_current ~= 0));
        set(graph_handles(2),'XData', volts(volts ~= 0));
        set(graph_handles(2),'YData', phtd_current(phtd_current ~= 0));
        
        % Real time EQE
        if ~raw_only
            EQE(k) = calculate_EQE(wavelengths, EL_Spec(:,k), I_LED, I_det, responsivity);     % DAEL WITH NOISE
        end
        
        % Calculate intensity and EQE
        if ~raw_only
            % Check for approx EL
            if size(ELSpec) == 1
                % Approximate luminance, current efficiency, and radient flux
                [radient_flux, luminous_intensity, luminance] = approximate_intensity(PDcal, ELSpec, phtd_current, lum_function, solid_angle, device_area);
                current_efficiency = calculate_current_efficiency(device_area, luminance, device_current);
                EQE = approximate_EQE(ELSpec, radient_flux, device_current);
            else
                % Calculate luminance, current efficiency, and radient flux
                [wavelengths_rf, radient_flux, luminous_intensity, luminance] = calculate_intensity(PDcal, wavelengths, ELSpec, phtd_current, lum_function, solid_angle, device_area);
                current_efficiency = calculate_current_efficiency(device_area, luminance, device_current);
                EQE = calculate_EQE(wavelengths_rf, radient_flux, device_current);            
            end

            % Update graphs
            set(graph_handles(3),'XData', volts(volts ~= 0));
            set(graph_handles(3),'YData', luminance(luminance ~= 0));
            set(graph_handles(4),'XData', volts(volts ~= 0));
            set(graph_handles(4),'YData', EQE(EQE ~= 0));
        end
        
    end

end

