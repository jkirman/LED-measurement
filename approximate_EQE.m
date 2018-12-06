function [EQE] = approximate_EQE(wavelength, responsivity, I_det, I_LED)
%approximate_EQE
%
%   wavelength: the centre wavelength of emission (nm)
%   PDcal: the photodetector calibration curve (responsivity in A/W)
%   I_det: photodetector current (A)
%   I_LED: LED current (A)

    h = 6.62607004e-34;
    c = 2.99792458e8;
    q = 1.6021766208e-19;

    % Approximate radient flux
    interpolated_wavelengths = 360:0.1:max(responsivity(:,1));
    wavelengths_rf = round(interpolated_wavelengths,1);
    PDcal_interp = interp1(responsivity(:,1), responsivity(:,2), interpolated_wavelengths);
    wavelength = round(wavelength,1);    
    
    for i = 1:size(wavelength,2)
        wv_index = wavelengths_rf == wavelength(i);
        if size(wavelength,2) == 1
            radiant_flux = I_det' ./ PDcal_interp(wv_index);
        else
            radiant_flux(i) = I_det(i) ./ PDcal_interp(wv_index);
        end
    end
    
    photons_emitted = (radiant_flux .* wavelength*1e-9)/(h*c);
    EQE = photons_emitted' ./ (I_LED / q);
    
end

