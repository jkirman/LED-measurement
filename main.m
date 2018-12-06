%% LED Measurement System GUI v0.1
%   Code written by Jeffrey Kirman
%
%   changelog:
%       v0.1: Initial setup

function varargout = main(varargin)
% MAIN MATLAB code for main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help main

% Last Modified by GUIDE v2.5 07-Nov-2018 14:25:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main (see VARARGIN)

% Choose default command line output for main
handles.output = hObject;

% Open calibration/parameters file
handles.settings = csvread('./calib.csv',0,1);
handles.PDcal = dlmread('FDS1010-cal.txt',',',14,0);
handles.luminosity_fn = csvread('luminosity_fn.csv');

% Initialize plots
handles.JV_plot = get(handles.JV, 'children');
handles.phtd_plot = get(handles.PhotodetectorCurrent, 'children');
handles.luminance_plot = get(handles.Lum, 'children');
handles.EQE_plot = get(handles.EQE, 'children');
handles.EL_plot = get(handles.EL, 'children');

% Initialize handles for variables among functions
handles.ESP = 0; % Motor GPIB
handles.src = 0; % Source Keithley GPIB
handles.phtd = 0; % Photodetector Keithley GPIB
handles.spec = 0; % Spectrometer object
handles.file_path = '';
handles.device_name = 'device_name';
handles.integration_time = handles.settings(4);
handles.max_voltage = 20;
handles.step_size = 1;
handles.device_area = 0.07065/(100^2);
handles.phtd_area = handles.settings(9);
handles.device_orientation = '8 Pin Horizontal';
handles.pixel_number = 1;
handles.pixel_number_map = [14 11 6 3 2 7 10 15];
handles.set_current = 1;
handles.solid_angles = 0;
handles.approx_wavelength = 520;
handles.ELSpec = 520e-9;
handles.use_approx = false;
handles.stop_toggle = 0;
handles.luminance_distance = handles.settings(7);
handles.distances = 44:handles.settings(8):handles.settings(7);
handles.min_dist_to_phtd = handles.settings(30);
handles.device_polarity = handles.settings(31);
handles.phtd_polarity = handles.settings(32);

handles.PD_x_dist = handles.settings(10);
handles.fibre_x_dist = handles.settings(11);

handles.PD_y_dist_h = [handles.settings(13) handles.settings(12)]; % [bottom top]
handles.fibre_y_dist_h = [handles.settings(15) handles.settings(14)]; % [bottom top]
handles.pin_dist_h = [handles.settings(16) handles.settings(17) handles.settings(18) handles.settings(19)]; % [left to right]

handles.PD_y_dist_v = [handles.settings(20) handles.settings(21) handles.settings(22) handles.settings(23)]; % [top to bottom]
handles.fibre_y_dist_v = [handles.settings(24) handles.settings(25) handles.settings(26) handles.settings(27)]; % [top to bottom]
handles.pin_dist_v = [handles.settings(28) handles.settings(29)]; % [left right]

% Set global variables for graphs
% global JV_gb phtd_current_gb luminance_gb EQE_gb EL_gb brightness_gb solid_angle_gb;

set(handles.stage_dist_text, 'String', handles.settings(16))

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% Helper functions %%

% Calculate the distances the motor should move to based on each pixel
function [x_phtd, y_phtd, x_fibre, y_fibre] = get_distances_for_pixels(handles)
    
    switch handles.device_orientation
        case '8 Pin Horizontal'
            x_phtd = repelem([handles.PD_x_dist],8);
            y_phtd = repelem(handles.PD_y_dist_h,4);
            x_fibre = repelem([handles.fibre_x_dist],8);
            y_fibre = repelem(handles.fibre_y_dist_h,4);
        case '8 Pin Vertical'
            x_phtd = repelem([handles.PD_x_dist],8);
            y_phtd = [handles.PD_y_dist_v fliplr(handles.PD_y_dist_v)];
            x_fibre = repelem([handles.fibre_x_dist],8);
            y_fibre = [handles.fibre_y_dist_v fliplr(handles.fibre_y_dist_v)];
    end
    
function [x_phtd, y_phtd, x_fibre, y_fibre] = get_distances_for_pixel(handles)
    
    [x_phtd, y_phtd, x_fibre, y_fibre] = get_distances_for_pixels(handles);
    x_phtd = x_phtd(handles.pixel_number);
    y_phtd = y_phtd(handles.pixel_number);
    x_fibre = x_fibre(handles.pixel_number);
    y_fibre = y_fibre(handles.pixel_number);

function [ELSpec, measurement_method_approx] = import_EL(device_voltage, handles)

    % Check EQE measurement method
    measurement_method_approx = handles.use_approx;
    filename = fullfile(savepath, strcat(handles.file_path,'\','*_EL.txt'));
    files = dir(filename(3:end));
 
    if ~handles.use_approx && isempty(files)
        
        measurement_method_approx = ~handles.use_approx;
        warndlg('Accurate EQE calculation selected but no EL data has been collected for this device so using approximate wavelength instead.');
        ELSpec = handles.approx_wavelength;
   
    else
        
        % Import EL data from saved file (takes most recent EL spectra
        [~,idx] = sort([files.datenum]);
        filename = fullfile(savepath, strcat(handles.file_path,'\',files(idx(end)).name));
        ELSpec_raw = dlmread(filename(3:end),'\t',1,0);
        ELSpec = ELSpec_raw(4:end,:);

        % If needed, interpolate the EL spectrum to different voltage spacing
        if ~handles.use_approx && (max(ELSpec_raw(1)) > max(device_voltage))
            measurement_method_approx = ~handles.use_approx;
            warndlg('The EL spectra provided is incompatible with the current measurment due to having a lower max voltage than specified. Using the approximate wavelength instead.');
        elseif ~handles.use_approx && ((size(ELSpec,2) - 2) ~= size(device_voltage, 2))
            warndlg('The EL spectra provided have different voltage steps than those specified for this measurement. The EL spectra will be interpolated for the measurement intervals. Results may not be perfectly accurate.');
            ELSpec_interp = [ELSpec(:,1:2) interp1(ELSpec_raw(1,3:end),ELSpec(:,3:end)',device_voltage)'];
            ELSpec = ELSpec_interp;
        end
        
    end
   
function [] = clear_figures(handles)

    % EL
    axes(handles.EL);
    delete(get(handles.EL,'children'));    

    graph_handles = [handles.JV_plot handles.phtd_plot handles.EQE_plot handles.luminance_plot];
    for i = 1:size(graph_handles,2)
        set(graph_handles(i), 'XData', 0)
        set(graph_handles(i), 'YData', 0)
    end

%% Radio buttons %%

% --- Executes on selection change in pin_orientation.
function pin_orientation_Callback(hObject, eventdata, handles)
    
    w = 8;
    h = 1.769;
    buttons = allchild(handles.pixel_choice);
    
% hObject    handle to pin_orientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pin_orientation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pin_orientation

    % Determine the selected orientation.
    str = get(hObject, 'String');
    val = get(hObject,'Value');
    handles.device_orientation = str{val};
    % Set current data to the selected data set.
    switch str{val}
    case '8 Pin Horizontal'
        y = [7.462 2.846]; % top, bot
        y = repelem(y,4);
        x = [3.6 13.4 23.2 33.4];
        x = [x fliplr(x)];
        distances = [handles.pin_dist_h fliplr(handles.pin_dist_h)];
    case '8 Pin Vertical'
        x = [25.4 11.8]; % top, bot
        x = repelem(x,4);
        y = [9 6.462 3.923 1.385];
        y = [y fliplr(y)];
        distances = [repelem(handles.pin_dist_v(1),4) repelem(handles.pin_dist_v(2),4)];
    end
    
    for i = 1:size(buttons,1)
        set( buttons(i),'Position', [x(i) y(i) w h] )
    end
    
    set(handles.stage_dist_text, 'String', distances(handles.pixel_number))
    
    % Save the handles structure.
    guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function pin_orientation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pin_orientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Push buttons

% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
% hObject    handle to browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

selpath = uigetdir;
if selpath ~= 0
    handles.file_path = strcat(selpath,'\');
    set(handles.file_path_text,'String',strcat(selpath,'\'));
end
guidata(hObject,handles);

% --- Executes on button press in initialize_button.
function initialize_button_Callback(hObject, eventdata, handles)
% hObject    handle to initialize_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Initialize and get GPIB objects
[handles.ESP, handles.src, handles.phtd, handles.spec] = ...
        initialize_all(handles.settings(1), handles.settings(2), handles.settings(3), ...
        handles.settings(4), handles.settings(5), handles.settings(6));
    
% Save the handles structure.
guidata(hObject,handles)

% --- Executes on button press in EL_button.
function EL_button_Callback(hObject, eventdata, handles)
% hObject    handle to EL_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Prepare arrays for easy indexing
    [x_phtd, y_phtd, x_fibre, y_fibre] = get_distances_for_pixel(handles);

    % Put a stop for measuring EL again for same device
    
    % Measure cone of brightness (for solid angle)
        guidata(hObject,handles);
    
%     if(handles.set_current ~= 0)
        
        % Move motors to chosen pixel and measure
%         move_motors(handles.ESP, x_phtd, y_phtd, handles.stop_button);
%     %     [device_current, handles.solid_angle, all_solid_angles, phtd_current] = measure_brightness_cone(handles.ESP, handles.src, handles.phtd, ...
%     %         handles.set_current, x_phtd(handles.pixel_number), y_phtd(handles.pixel_number), handles.distances, ...
%     %         handles.phtd_area, handles.stop_button, handles.brightness_plot);
%         [device_voltage, solid_angles, phtd_current] = measure_solid_angle(handles.ESP, handles.src, handles.phtd, ...
%             handles.set_current, x_phtd, y_phtd, handles.distances, handles.min_dist_to_phtd, ...
%             handles.phtd_area, handles.settings(5), handles.stop_button, handles.brightness_plot);
%         guidata(hObject,handles);
% 
%         handles.solid_angles = [fliplr(solid_angles)' phtd_current'];
% 
%         % Save solid angle data
%         filename = fullfile(savepath, strcat(handles.file_path,handles.device_name,'_',num2str(handles.pixel_number_map(handles.pixel_number)), ...
%                 '_solidangle.txt'));
%         fid = fopen(filename(3:end), 'wt');
%         fprintf(fid, '%s\t%s\t%s\t%s\t%s\n', 'Distance (mm)', 'Voltage (V)','Device Current (A)','Photodetector Current (A)', 'Solid Angle (sr)');  % header
%         fclose(fid);
%         dlmwrite(filename(3:end),[handles.distances' repelem(handles.set_current,length(handles.distances),1) device_voltage' phtd_current' solid_angles'], ...
%             'delimiter','\t','-append');
%     
%     end
    
    % Measure EL
    
    % Clear graphs
    clear_figures(handles);
    
    graph_handles = [handles.JV_plot handles.EL];
    
    % Move motors to chosen pixel and measure
    move_motors(handles.ESP, x_fibre, y_fibre, handles.stop_button);
    [volts, wavelengths, device_current, ELSpec] = measure_EL(handles.src, handles.spec, ...
        handles.integration_time, handles.max_voltage, handles.step_size, handles.stop_button, handles.device_polarity, graph_handles);   
    handles.ELSpec = ELSpec;
    guidata(hObject,handles);    
    
    % Save EL data
    filename = fullfile(savepath, strcat(handles.file_path,handles.device_name,'_',num2str(handles.pixel_number_map(handles.pixel_number)), ...
        '_EL.txt'));
    fid = fopen(filename(3:end), 'wt');
    fprintf(fid, '%s\t%s\t%s\n', 'Voltage (V)','Device Current (A)','Wavelengths/Counts');  % header
    fclose(fid);
    dlmwrite(filename(3:end),[[0 0 volts']; [0; 0; device_current]'; [wavelengths ELSpec]],'delimiter','\t','-append');

    set(handles.stop_button, 'Value', 0)
    guidata(hObject,handles);
    
% --- Executes on button press in EQE_button.
function EQE_button_Callback(hObject, eventdata, handles)
% hObject    handle to EQE_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Clear figures
    clear_figures(handles);
    
    % Gather all the user input data
    file_path = handles.file_path;
    device_name = handles.device_name;
    pixel_number = handles.pixel_number_map(handles.pixel_number);
    integration_time = handles.integration_time;
    max_voltage = handles.max_voltage;
    step_size = handles.step_size;
    device_polarity = handles.phtd_polarity;
    phtd_polarity = handles.phtd_polarity;
    
    graph_handles = [handles.JV_plot handles.phtd_plot handles.EQE_plot];

    % Move motors to chosen pixel
    [x_phtd, y_phtd, ~, ~] = get_distances_for_pixel(handles); % Get the motor distance to move the LED to the photodetector
    move_motors(handles.ESP, x_phtd, y_phtd, handles.stop_button);
    
    [ELSpec, measurement_method_approx] = import_EL(0:step_size:max_voltage, handles);
    
    if measurement_method_approx
        ELSpec = [0 handles.approx_wavelength];
        measurement_method_text = '_approx';
    else
        measurement_method_text = '';
        
        % Update EL graphs
        axes(handles.EL);
        delete(get(handles.EL,'children'));
        plot(ELSpec(:,1),ELSpec(:,2:end));
    end
    
    % Do measurement
    [volts, device_current, phtd_current, EQE, centre_wavelength, EQE_approx] = ...
        measure_EQE(handles.src, handles.phtd, integration_time, max_voltage, ...
        step_size, handles.PDcal, ELSpec(:,1), ELSpec(:,2:end), handles.stop_button, graph_handles, ...
        device_polarity, phtd_polarity, false);
    
    % Check if file already exists
    appended_tag = '';
    filename = fullfile(savepath, strcat(file_path,device_name,'_', ... 
        num2str(pixel_number),'_intraw.txt'));
    if ~isempty(dir(filename(3:end)))
        appended_tag = datestr(datetime('now'),'-yyyy-mm-dd-HHMMss');
    end
    
    % Save raw data
    filename = fullfile(savepath, strcat(file_path,device_name,'_', ... 
        num2str(pixel_number),'_intraw',appended_tag,'.txt'));
    fid = fopen(filename(3:end), 'wt');
    fprintf(fid, '%s\t %s\t %s\t \n', 'Voltage (V)','Device Current (A)','Photodetector Current (A)');  % header
    fclose(fid);
    dlmwrite(filename(3:end),[volts device_current phtd_current],'delimiter','\t','-append');
    
    % Save calculated data
    filename = fullfile(savepath, strcat(file_path,device_name,'_', ... 
        num2str(pixel_number),'_EQE', measurement_method_text, appended_tag ,'.txt'));
    fid = fopen(filename(3:end), 'wt');
    fprintf(fid, '%s\t %s\t %s\t %s\t %s\t %s\t \n', 'Voltage (V)','Device Current (A)','Photodetector Current (A)', ... 
        'EQE','Approximate wavelength (nm)','Approximate EQE');  % header
    fclose(fid);
    dlmwrite(filename(3:end),[volts device_current phtd_current EQE centre_wavelength EQE_approx], ...
        'delimiter','\t','-append');
    
    set(handles.stop_button, 'Value', 0)
    guidata(hObject,handles);

% --- Executes on button press in calculate_EQE_button.
function calculate_EQE_button_Callback(hObject, eventdata, handles)
% hObject    handle to calculate_EQE_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Clear figures
    clear_figures(handles)

    % Gather all the user input data
    file_path = handles.file_path;
    device_name = handles.device_name;
    pixel_number = handles.pixel_number_map(handles.pixel_number);
    
    graph_handles = [handles.JV_plot handles.phtd_plot handles.EQE_plot];
    
    % Check if raw data file exists
    filename_raw_data = fullfile(savepath, strcat(file_path,device_name,'_', ... 
        num2str(pixel_number),'_intraw.txt'));
    files = dir(filename_raw_data(3:end));
    if isempty(files)
        warndlg('There is no data on this pixel, no calculation can be made.');
    else
        [~,idx] = sort([files.datenum]);
        filename = fullfile(savepath, strcat(handles.file_path,'\',files(idx(end)).name));
        data_raw = dlmread(filename(3:end),'\t',1,0);
        appended_tag = datestr(datetime('now'),'-yyyy-mm-dd-HHMMss');
        I_det = data_raw(:,3);
        I_LED = data_raw(:,2);
        
        [ELSpec, measurement_method_approx] = import_EL(data_raw(:,1)',handles);

        if measurement_method_approx
            ELSpec = handles.approx_wavelength;
            measurement_method_text = '_approx';
        else
            measurement_method_text = '';
            
            % Update EL graphs
            axes(handles.EL);
            delete(get(handles.EL,'children'));
            plot(ELSpec(:,1),ELSpec(:,2:end));
        end

        % Update graphs
        set(graph_handles(1),'XData', data_raw(:,1));
        set(graph_handles(1),'YData', data_raw(:,2));
        set(graph_handles(2),'XData', data_raw(:,1));
        set(graph_handles(2),'YData', data_raw(:,3));

        % Real time EQE
        if size(ELSpec,1) > 3
            [EQE, centre_wavelength, EQE_approx] = calculate_EQE_2(ELSpec(:,1), ELSpec(:,2), ELSpec(:,3:end), I_LED, I_det, handles.PDcal);
        else
            centre_wavelength = ELSpec;
            EQE_approx = approximate_EQE(ELSpec, handles.PDcal, I_det, I_LED);
            EQE = EQE_approx;
            centre_wavelength = repelem(centre_wavelength,size(EQE,1))';
        end

        % Update graphs
        % Find emission starting index
        emitting_wavelengths = I_det > 1e-9;
        set(graph_handles(3),'XData', data_raw(emitting_wavelengths,1));
        set(graph_handles(3),'YData', EQE(emitting_wavelengths)*100);       

        % Save calculated data
        filename = fullfile(savepath, strcat(file_path,device_name,'_', ... 
            num2str(pixel_number),'_EQE', measurement_method_text, appended_tag ,'.txt'));
        fid = fopen(filename(3:end), 'wt');
        fprintf(fid, '%s\t %s\t %s\t %s\t %s\t %s\t \n', 'Voltage (V)','Device Current (A)','Photodetector Current (A)', ... 
            'EQE','Approximate wavelength (nm)','Approximate EQE');  % header
        fclose(fid);
        dlmwrite(filename(3:end),[data_raw(:,1) data_raw(:,2) data_raw(:,3) EQE centre_wavelength EQE_approx], ...
            'delimiter','\t','-append');

        set(handles.stop_button, 'Value', 0)
        guidata(hObject,handles);

    end
    
    
function file_path_text_Callback(hObject, eventdata, handles)
% hObject    handle to file_path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of file_path_text as text
%        str2double(get(hObject,'String')) returns contents of file_path_text as a double

% --- Executes on button press in lum_button.
function lum_button_Callback(hObject, eventdata, handles)
% hObject    handle to EQE_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Clear figures
    clear_figures(handles);
    
    % Gather all the user input data
    file_path = handles.file_path;
    device_name = handles.device_name;
    pixel_number = handles.pixel_number_map(handles.pixel_number);
    integration_time = handles.integration_time;
    max_voltage = handles.max_voltage;
    step_size = handles.step_size;
    device_polarity = handles.phtd_polarity;
    phtd_polarity = handles.phtd_polarity;
    
    graph_handles = [handles.JV_plot handles.phtd_plot handles.EQE_plot];

    % Move motors to chosen pixel
    [x_phtd, y_phtd, ~, ~] = get_distances_for_pixel(handles); % Get the motor distance to move the LED to the photodetector
    move_motors(handles.ESP, x_phtd + handles.luminance_distance, y_phtd, handles.stop_button);
    
    [ELSpec, measurement_method_approx] = import_EL(0:step_size:max_voltage, handles);
    
    if measurement_method_approx
        ELSpec = handles.approx_wavelength;
        measurement_method_text = '_approx';
    else
        measurement_method_text = '';
    end
    
    % Do measurement
    [volts, device_current, phtd_current, EQE, centre_wavelength, EQE_approx] = ...
        measure_EQE(handles.src, handles.phtd, integration_time, max_voltage, ...
        step_size, handles.PDcal, ELSpec(:,1), ELSpec(:,2:end), handles.stop_button, graph_handles, ...
        device_polarity, phtd_polarity, false);
    
    % Check if file already exists
    appended_tag = '';
    filename = fullfile(savepath, strcat(file_path,device_name,'_', ... 
        num2str(pixel_number),'_lumintraw.txt'));
    if ~isempty(dir(filename(3:end)))
        appended_tag = datestr(datetime('now'),'-yyyy-mm-dd-HHMMss');
    end
    
    % Save raw data
    filename = fullfile(savepath, strcat(file_path,device_name,'_', ... 
        num2str(pixel_number),'_lumintraw',appended_tag,'.txt'));
    fid = fopen(filename(3:end), 'wt');
    fprintf(fid, '%s\t %s\t %s\t \n', 'Voltage (V)','Device Current (A)','Photodetector Current (A)');  % header
    fclose(fid);
    dlmwrite(filename(3:end),[volts device_current phtd_current],'delimiter','\t','-append');
    
    % Save calculated data
    filename = fullfile(savepath, strcat(file_path,device_name,'_', ... 
        num2str(pixel_number),'_Luminance', measurement_method_text, appended_tag ,'.txt'));
    fid = fopen(filename(3:end), 'wt');
    fprintf(fid, '%s\t %s\t %s\t %s\t %s\t %s\t \n', 'Voltage (V)','Device Current (A)','Photodetector Current (A)', ... 
        'Luminance (cd/m^2)','Current Efficiency (cd/A)');  % header
    fclose(fid);
    dlmwrite(filename(3:end),[volts device_current phtd_current EQE centre_wavelength EQE_approx], ...
        'delimiter','\t','-append');
    
    set(handles.stop_button, 'Value', 0)
    guidata(hObject,handles);

%% Other stuff

% --- Executes during object creation, after setting all properties.
function file_path_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function device_name_text_Callback(hObject, eventdata, handles)
% hObject    handle to device_name_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of device_name_text as text
%        str2double(get(hObject,'String')) returns contents of device_name_text as a double
handles.device_name = get(hObject,'String');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function device_name_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to device_name_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function integration_time_text_Callback(hObject, eventdata, handles)
% hObject    handle to integration_time_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of integration_time_text as text
%        str2double(get(hObject,'String')) returns contents of integration_time_text as a double
str = get(hObject,'String');
num = str2double(str);
if isnan(num)
    set(hObject,'string',string(handles.settings(4)));
    num = handles.settings(4);
    warndlg('Input must be a number');
end
handles.integration_time = num;
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function integration_time_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to integration_time_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function max_voltage_text_Callback(hObject, eventdata, handles)
% hObject    handle to max_voltage_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of max_voltage_text as text
%        str2double(get(hObject,'String')) returns contents of max_voltage_text as a double
str = get(hObject,'String');
num = str2double(str);
if isnan(num)
    set(hObject,'string','20');
    num = 20;
    warndlg('Input must be a number');
end
handles.max_voltage = num;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function max_voltage_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_voltage_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function step_size_text_Callback(hObject, eventdata, handles)
% hObject    handle to step_size_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of step_size_text as text
%        str2double(get(hObject,'String')) returns contents of step_size_text as a double

str = get(hObject,'String');
num = str2double(str);
if isnan(num)
    set(hObject,'string','1');
    num = 1;
    warndlg('Input must be a number');
end
handles.step_size = num;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function step_size_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to step_size_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function device_area_text_Callback(hObject, eventdata, handles)
% hObject    handle to device_area_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of device_area_text as text
%        str2double(get(hObject,'String')) returns contents of device_area_text as a double
str = get(hObject,'String');
num = str2double(str);
if isnan(num)
    set(hObject,'string','0.07065');
    num = 0.07065;
    warndlg('Input must be a number');
end
handles.device_area = num/(100^2);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function device_area_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to device_area_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on device_name_text and none of its controls.
function device_name_text_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to device_name_text (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in pixel_choice.
function pixel_choice_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in pixel_choice 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton1'
        handles.pixel_number = 1;
    case 'radiobutton2'
        handles.pixel_number = 2;
    case 'radiobutton3'
        handles.pixel_number = 3;
    case 'radiobutton4'
        handles.pixel_number = 4;
    case 'radiobutton5'
        handles.pixel_number = 5;
    case 'radiobutton6'
        handles.pixel_number = 6;
    case 'radiobutton7'
        handles.pixel_number = 7;
    case 'radiobutton8'
        handles.pixel_number = 8;
end

switch handles.device_orientation
    case '8 Pin Horizontal'
        distances = [handles.pin_dist_h fliplr(handles.pin_dist_h)];
    case '8 Pin Vertical'
        distances = [repelem(handles.pin_dist_v(1),4) repelem(handles.pin_dist_v(2),4)];
end
set(handles.stage_dist_text, 'String', distances(handles.pixel_number))

guidata(hObject,handles);



function wavelength_text_Callback(hObject, eventdata, handles)
% hObject    handle to wavelength_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wavelength_text as text
%        str2double(get(hObject,'String')) returns contents of wavelength_text as a double
str = get(hObject,'String');
num = str2double(str);
if isnan(num) || (str2double(str) <= 0)
    set(hObject,'string','520');
    num = 520;
    warndlg('Input must be a number greater than 0.');
end
handles.approx_wavelength = num;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function wavelength_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wavelength_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in EQE_approx.
function EQE_approx_Callback(hObject, eventdata, handles)
% hObject    handle to EQE_approx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function set_voltage_text_Callback(hObject, eventdata, handles)
% hObject    handle to set_voltage_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of set_voltage_text as text
%        str2double(get(hObject,'String')) returns contents of set_voltage_text as a double

str = get(hObject,'String');
num = str2double(str);
if isnan(num)
    set(hObject,'string','1');
    num = 1;
    warndlg('Input must be a number');
end
handles.set_current = num;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function set_voltage_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to set_voltage_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in use_approx.
function use_approx_Callback(hObject, eventdata, handles)
% hObject    handle to use_approx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of use_approx
if (get(hObject,'Value') == get(hObject,'Max'))
	handles.use_approx = true;
else
	handles.use_approx = false;
end
guidata(hObject,handles);


% --- Executes on button press in stop_button.
function stop_button_Callback(hObject, eventdata, handles)
% hObject    handle to stop_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in browse_sa.
function browse_sa_Callback(hObject, eventdata, handles)
% hObject    handle to browse_sa (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function solid_angle_path_text_Callback(hObject, eventdata, handles)
% hObject    handle to solid_angle_path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of solid_angle_path_text as text
%        str2double(get(hObject,'String')) returns contents of solid_angle_path_text as a double


% --- Executes during object creation, after setting all properties.
function solid_angle_path_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to solid_angle_path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browse_el.
function browse_el_Callback(hObject, eventdata, handles)
% hObject    handle to browse_el (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function el_file_path_text_Callback(hObject, eventdata, handles)
% hObject    handle to el_file_path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of el_file_path_text as text
%        str2double(get(hObject,'String')) returns contents of el_file_path_text as a double


% --- Executes during object creation, after setting all properties.
function el_file_path_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to el_file_path_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in reload_button.
function reload_button_Callback(hObject, eventdata, handles)
% hObject    handle to reload_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
move_motors(handles.ESP, 100, 0, handles.stop_button)

% --- Executes during object creation, after setting all properties.
function JV_CreateFcn(hObject, eventdata, handles)
% hObject    handle to JV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject.Title, 'String', 'JV')
set(hObject.XLabel, 'String', 'Volts (V)')
set(hObject.YLabel, 'String', 'Current (A)')
plot(0,0)
% Hint: place code in OpeningFcn to populate JV

% --- Executes during object creation, after setting all properties.
function PhotodetectorCurrent_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PhotodetectorCurrent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject.Title, 'String', 'Photodetector Current')
set(hObject.XLabel, 'String', 'Volts (V)')
set(hObject.YLabel, 'String', 'Current (A)')
plot(0,0)
% Hint: place code in OpeningFcn to populate PhotodetectorCurrent


% --- Executes during object creation, after setting all properties.
function Lum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Lum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject.Title, 'String', 'Luminance')
set(hObject.XLabel, 'String', 'Volts (V)')
set(hObject.YLabel, 'String', 'Luminance (cd/m^2)')
plot(0,0)
% Hint: place code in OpeningFcn to populate Lum


% --- Executes during object creation, after setting all properties.
function EQE_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EQE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject.Title, 'String', 'EQE')
set(hObject.XLabel, 'String', 'Volts (V)')
set(hObject.YLabel, 'String', 'EQE (%)')
semilogy(0,0)
% Hint: place code in OpeningFcn to populate EQE


% --- Executes during object creation, after setting all properties.
function EL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject.Title, 'String', 'EL')
set(hObject.XLabel, 'String', '\lambda (nm)')
set(hObject.YLabel, 'String', 'Counts')
plot(0,0)
% Hint: place code in OpeningFcn to populate EL
