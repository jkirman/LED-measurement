function [volts, wavelengths, I_LED, ELSpec] = measure_EL(src, spectrometerObj, integration_time, max_voltage, step_size, stop_button_handle, device_polarity, graph_handles)
%MEASURE_EL Summary of this function goes here
%   Detailed explanation goes here

    volts = (0:step_size:max_voltage)';
    I_LED = inf(size(volts));

    delays = 0.1; % seconds
    spectrometer_delay = 1.1; % seconds
    
    % Set integration time
    spectrometerIndex = 0; channelIndex = 0;
    invoke(spectrometerObj, 'setIntegrationTime', spectrometerIndex, channelIndex, integration_time*1000); % Set integration time.
    
    % Measure dark spectrum
    wavelengths = invoke(spectrometerObj, 'getWavelengths', spectrometerIndex, channelIndex);
    DarkSpec = invoke(spectrometerObj, 'getSpectrum', spectrometerIndex);
    ELSpec = DarkSpec;

    axes(graph_handles(2));
    
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
        pause(spectrometer_delay); % Wait
        
        nextEL = invoke(spectrometerObj, 'getSpectrum', spectrometerIndex);
        ELSpec = [ELSpec, nextEL];
        fprintf(src,':OUTP OFF');
        
        % Update graphs
        set(graph_handles(1),'XData', volts);
        set(graph_handles(1),'YData', I_LED);
        
        plot(wavelengths(2:end), nextEL(2:end)-ELSpec(2:end,1))
        
    end

end