function [radient_flux] = calculate_radient_flux(PDcal, wavelengths, ELSpec, phdt_current)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    
    % Normalize EL spectrum
    k = trapz(wavelengths, ELSpec);
    ELSpec_normalized = ELSpec/k;
    
    % Calculate radient flux
    interpolated_wavelengths = 360:0.1:max(wavelengths);
    PDcal_interp = interp1(PDcal(:,1), PDcal(:,2), interpolated_wavelengths);
    ELSpec_normalized_interp = interp1(wavelengths, ELSpec_normalized, interpolated_wavelengths);
    radient_flux = (PDcal_interp .^ -1) .* ELSpec_normalized_interp * phdt_current;
    
end

