function [] = global_set(name,value)

    global JV_gb phtd_current_gb luminance_gb EQE_gb EL_gb brightness_gb solid_angle_gb;

    switch{name}
        case 'JV'
            JV_gb = value;
        case 'phtd_current'
            phtd_current_gb = value;
        case 'luminance'
            luminance_gb = value;
        case 'EQE'
            EQE_gb = value;
        case 'EL'
            EL_gb = value;
        case 'brightness'
            brightness_gb = value;
        case 'solid_angle'
            solid_angle_gb = value;
    end
    
end