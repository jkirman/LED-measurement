%% Luminance measurement function v1.0
%   Code written by Jeffrey Kirman
%
%   changelog:
%       v0.1:   - initial revision
%       v1.0:   - Fixed function to only measure EQE and calculate it properly

function [volts, I_LED, I_det, EQE, centre_wavelength, EQE_approx] = ...
    measure_luminance(src, phtd, integration_time, max_voltage, step_size, responsivity, wavelengths, EL_Spec, ...
                stop_button_handle, graph_handles, device_polarity, phtd_polarity, raw_only)
%MEASURE_INTENSITY Summary of this function goes here

%   src, phtd: GPIB for device Keithley, photodetector Keithley
%   integration_time: the amount paused at each step before photodetector measurement is taken (in ms)
%   max_voltage: the max voltage applied to the device (in V)
%   step_size: the step size in which the voltage sweep goes up by (in V)
%   responsivity: the photodetector responsivity curve
%   wavelengths: the wavelengths in the EL spectra (ELSpec)
%   EL_Spec: the EL spectra intensity values OR the wavelength to approximate at
%   lum_function: the luminosity function curve
%   solid_angle: the solid angle dependence curve on device emission (% photons/sr)
%   device_area: the area of the part of the pixel that illuminates
%   stop_button_handle: handle for the stop button
%   graph_handle: handle for the solid angle graph
%   device_polarity, phtd_polarity: set the polarity of the measurements
%   raw_only: set to true to bypass EQE measurements (for debugging)
    
    % Allocate memory for outputs
    volts = (0:step_size:max_voltage)';
    I_LED = Inf(size(volts));
    I_det = Inf(size(volts));
    EQE = Inf(size(volts));
    centre_wavelength = Inf(size(volts));
    EQE_approx = Inf(size(volts));
    
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
        I_LED(k) = scan(2)*device_polarity;
        
        fprintf(phtd,':OUTP ON'); % Turn on photodetector
        pause(delays); % Wait
        fprintf(phtd, ':READ?'); % Measure current in photodetector
        scan = scanstr(phtd, ',', '%f');
        I_det(k) = scan(2)*phtd_polarity;
        pause(delays); % Wait
        
        pause(integration_time/1000); % Pause for integration time
        
        fprintf(src,':OUTP OFF');
        fprintf(phtd,':OUTP OFF');
        
        % Update graphs
        set(graph_handles(1),'XData', volts);
        set(graph_handles(1),'YData', I_LED);
        set(graph_handles(2),'XData', volts);
        set(graph_handles(2),'YData', I_det);
        
        % Real time luminance
        if ~raw_only
            if size(EL_Spec,1) > 3
                EQE(k), centre_wavelength(k), EQE_approx(k) = calculate_EQE_2(wavelengths, EL_Spec(:,1), EL_Spec(:,k+1), I_LED, I_det, responsivity);
            else
                centre_wavelength(k) = EL_Spec;
                EQE_approx(k) = approximate_EQE(EL_Spec, responsivity, I_det, I_LED);
                EQE(k) = EQE_approx(k);
            end
        end

        % Update graphs
        set(graph_handles(3),'XData', volts);
        set(graph_handles(3),'YData', EQE);
        
    end

end

