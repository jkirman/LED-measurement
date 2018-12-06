%% EQE calculation function v0.2
%   Code written by Jeffrey Kirman
%
%   changelog:
%       v0.2:   - fixed q in EQE formula
%       v0.1:   - initial revision

function [EQE] = calculate_EQE(wavelengths, radiant_flux, device_current)

%   wavelengths: the wavelengths covered by the radiant flux (in nm)
%   radient_flux: the radiant flux of the device (in W)
%   device_current: the current of the specific pixel in question (in A)

    h = 6.62607004e-34;
    c = 2.99792458e8;
    q = 1.6021766208e-19;
    
    photons_emitted_per_wavelength = radiant_flux/(h*c);
    photons_emitted = trapz(wavelengths*1e-9, photons_emitted_per_wavelength);
    EQE = photons_emitted ./ (device_current / q);
    
end