%% EQE calculation function v0.2
%   Code written by Jeffrey Kirman
%
%   changelog:
%       v0.2:   - fixed q in EQE formula
%       v0.1:   - initial revision

function [EQE, centre_wavelength, EQE_approx] = calculate_EQE_2(wavelengths, noise_spec, EL_Spec, I_LED, I_det, responsivity)

%   wavelengths: the wavelengths covered by the radiant flux (in nm)
%   radient_flux: the radiant flux of the device (in W)
%   device_current: the current of the specific pixel in question (in A)
    
    f = 0.6; % fraction of light coupled with the detector
    h = 6.62607004e-34;
    c = 2.99792458e8;
    q = 1.6021766208e-19;
    
    % Interpolate EL responsivity curve
    interpolated_wavelengths = 360:0.1:min([max(wavelengths) max(responsivity(:,1))]);
    responsivity_interp = interp1(responsivity(:,1), responsivity(:,2), interpolated_wavelengths);

    % Fit and normalize EL spectra
    EL_Spec = abs(EL_Spec - noise_spec); % Zero noise
    for i = 1:size(EL_Spec, 2)
        EL_cfit = fit(wavelengths*1e-9, EL_Spec(:,i), 'gauss3');
        EL_fit(:,i) = feval(EL_cfit, interpolated_wavelengths*1e-9);
        EL_interp(:,i) = interp1(wavelengths, EL_Spec(:,i), interpolated_wavelengths);
        [~,index] = max(EL_fit(:,i));
        centre_wavelength(i) = interpolated_wavelengths(index);
    end
    
    I_det_total = trapz(interpolated_wavelengths*1e-9, responsivity_interp' .* EL_interp);
    k = (I_det' ./ I_det_total) / (h*c);
    EL_Spec_photons = interpolated_wavelengths'*1e-9 .* EL_fit .* k;
    photons_emitted = trapz(interpolated_wavelengths'*1e-9, EL_Spec_photons);
    
    EQE = photons_emitted' ./ (I_LED / q) / f;
    EQE_approx = approximate_EQE(centre_wavelength, responsivity, I_det, I_LED) / f;
    centre_wavelength = centre_wavelength';
    
end