function varargout = oil_spill_simulator(varargin)
% OIL_SPILL_SIMULATOR MATLAB code for oil_spill_simulator.fig
%      OIL_SPILL_SIMULATOR, by itself, creates a new OIL_SPILL_SIMULATOR or raises the existing
%      singleton*.
%
%      H = OIL_SPILL_SIMULATOR returns the handle to a new OIL_SPILL_SIMULATOR or the handle to
%      the existing singleton*.
%
%      OIL_SPILL_SIMULATOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OIL_SPILL_SIMULATOR.M with the given input arguments.
%
%      OIL_SPILL_SIMULATOR('Property','Value',...) creates a new OIL_SPILL_SIMULATOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before oil_spill_simulator_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to oil_spill_simulator_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help oil_spill_simulator

% Last Modified by GUIDE v2.5 23-May-2017 21:17:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @oil_spill_simulator_OpeningFcn, ...
                   'gui_OutputFcn',  @oil_spill_simulator_OutputFcn, ...
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

% --- Executes just before oil_spill_simulator is made visible.
function oil_spill_simulator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to oil_spill_simulator (see VARARGIN)

% Choose default command line output for oil_spill_simulator
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes oil_spill_simulator wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = oil_spill_simulator_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function output_folder_Callback(hObject, eventdata, handles)
% hObject    handle to output_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of output_folder as text
%        str2double(get(hObject,'String')) returns contents of output_folder as a double

% --- Executes during object creation, after setting all properties.
function output_folder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to output_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function clases_prop_Callback(hObject, eventdata, handles)

function clases_prop_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function fin_sim_Callback(hObject, eventdata, handles)

function fin_sim_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function tiempo_derrame_Callback(hObject, eventdata, handles)

function tiempo_derrame_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function sitio_derrame_Callback(hObject, eventdata, handles)

function sitio_derrame_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function superficial_Callback(hObject, eventdata, handles)

function subsuperficial_Callback(hObject, eventdata, handles)

function profundidades_Callback(hObject, eventdata, handles)

function profundidades_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%-------------------------------------------------------------------------%
function simular_Callback(hObject, eventdata, handles)
carpeta = get(handles.output_folder,'string');
sitio_derrame = str2num(get(handles.sitio_derrame,'string'));
lat_derrame = sitio_derrame(1);
lon_derrame = sitio_derrame(2);
radio_derrame = str2double(get(handles.radio_derrame,'string'));
tiempo_derrame = str2num(get(handles.tiempo_derrame,'string'));
dia_inicio = tiempo_derrame(1);
ultimo_dia_derrame = tiempo_derrame(2);
dia_fin = str2double(get(handles.fin_sim,'string'));
caso_superficie = get(handles.superficial,'value');
viento = str2double(get(handles.wind_factor,'string'));
turb_h_sup = str2double(get(handles.dif_turb_sup,'string'));
caso_subsuperficie = get(handles.subsuperficial,'value');
profundidades = str2num(get(handles.profundidades,'string'));
turb_h_sub = str2num(get(handles.dif_turb_sub,'string'));
componentes = str2num(get(handles.clases_prop,'string'));
quema_y_recoleccion = get(handles.artificial,'value');
evaporacion = get(handles.evaporation,'value');
degradacion = get(handles.degradation,'value');
dias_degradacion = str2num(get(handles.degradation_times,'string'));

% Agrega al path la ubicación de las funciones y archivos utilizados por el modelo
addpath(genpath([pwd,'/../../campos_de_velocidad']))
addpath(genpath([pwd,'/../../archivos_comunes']))
t_degradacion = threshold(95,dias_degradacion,6);
[FechasDerrame,SurfaceOil,VBU,VE,VNW,VDB] = cantidades_por_dia;
mkdir(carpeta);
if caso_superficie == 1
    [~,~] = oilspill_superficie(dia_inicio,dia_fin,ultimo_dia_derrame,...
        lon_derrame,lat_derrame,radio_derrame,FechasDerrame,SurfaceOil,VBU,VE,VNW,...
        carpeta,t_degradacion,componentes,quema_y_recoleccion,...
        evaporacion,degradacion,viento,turb_h_sup);
end
if caso_subsuperficie == 1
    fracc_VDB   = 1/length(profundidades);
    for ciclo = 1:length(profundidades)
        Profundidad = profundidades(ciclo);
        [~,~] = oilspill_subsuperficie(Profundidad,dia_inicio,dia_fin,ultimo_dia_derrame,...
            lon_derrame,lat_derrame,radio_derrame,FechasDerrame,VDB,fracc_VDB,carpeta,...
            componentes,degradacion,t_degradacion,turb_h_sub);
    end
end
animacion3d(carpeta,dia_inicio,dia_fin,profundidades,lon_derrame,lat_derrame);
%-------------------------------------------------------------------------%
function degradation_times_Callback(hObject, eventdata, handles)

function degradation_times_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function artificial_Callback(hObject, eventdata, handles)

function evaporation_Callback(hObject, eventdata, handles)

function degradation_Callback(hObject, eventdata, handles)

function radio_derrame_Callback(hObject, eventdata, handles)

function radio_derrame_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dif_turb_sub_Callback(hObject, eventdata, handles)

function dif_turb_sub_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dif_turb_sup_Callback(hObject, eventdata, handles)

function dif_turb_sup_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function wind_factor_Callback(hObject, eventdata, handles)

function wind_factor_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function particles_per_barrel_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
