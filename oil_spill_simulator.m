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

% Last Modified by GUIDE v2.5 03-Jun-2017 11:55:15

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

%-------------------------------------------------------------------------%
function Start_Callback(hObject, eventdata, handles)
[~,~] = addLocalPaths();
%------------------------ Read input parameters --------------------------%
modelConfig = ModelConfig;
sitio_derrame = str2num(get(handles.spill_location,'string'));
modelConfig.lat = sitio_derrame(1);
modelConfig.lon = sitio_derrame(2);
startDate = str2num(get(handles.initialSpillDay,'string'));
endDate = str2num(get(handles.finalSimDay,'string'));
modelConfig.startDate = datetime(startDate);
modelConfig.endDate = datetime(endDate);
modelConfig.timeStep = str2double(get(handles.TimeStep,'string'));
modelConfig.barrelsPerParticle = str2double(get(handles.barrels_per_particle,'string'));
modelConfig.depths = str2num(get(handles.depths,'string'));
%----------------- Assume the same proportions per depth ------------------%
classes_prop = str2num(get(handles.classes_prop,'string'));
modelConfig.components = repmat(classes_prop,[length(modelConfig.depths),1]);
%-------------------------------------------------------------------------%
modelConfig.totComponents = length(modelConfig.components(1,:));
modelConfig.visualize = true;
modelConfig.saveImages = false;
modelConfig.colorByComponent = [[1    0    0   ];
                                [0.89 0.69 0.17];
                                [1    1    0   ];
                                [0    0    1   ];
                                [0    1    0   ];
                                [0    1    1   ];
                                [0    0    1   ];
                                [1    0    1   ];
                                [0.7  0    0.70]];
modelConfig.colorByDepth = [[0 0 1];
                            [1 0 0];
                            [1 1 0];
                            [0 1 0];
                            [0 1 1]];
modelConfig.outputFolder = get(handles.output_folder,'string');
modelConfig.windcontrib = str2double(get(handles.wind_contribution,'string'));
modelConfig.turbulentDiff = str2num(get(handles.turb_diff,'string'));
modelConfig.diffusion = str2num(get(handles.spil_radius,'string'));
%---------- Assume the same subsurface oil amount at each layer ----------%
modelConfig.subSurfaceFraction = zeros(1,sum(modelConfig.depths>0))+1/sum(modelConfig.depths>0);
%-------------------------------------------------------------------------%
modelConfig.decay.evaporate = get(handles.evaporation,'value');
modelConfig.decay.exp_degradation = get(handles.exp_degradation,'value');
modelConfig.decay.burned = get(handles.burning,'value');
modelConfig.decay.burned_radius = get(handles.burning_radius,'value');
modelConfig.decay.collected = get(handles.collection,'value');
degradation_days = str2num(get(handles.degradation_times,'string'));
percentage_decay = str2double(get(handles.percentage_decay,'string'));
modelConfig.decay.exp_deg.byComponent = threshold(percentage_decay,degradation_days,modelConfig.timeStep);
modelConfig.initPartSize = 10*(24/modelConfig.timeStep);
%------------------------- Create csv file -------------------------------% 
final_spill_day = str2num(get(handles.finalSpillDay,'string'));
barrels_spilled = str2double(get(handles.barrels_spilled,'string'));
barrels_collected = str2double(get(handles.barrels_collected,'string'));
barrels_burned = str2double(get(handles.barrels_burned,'string'));
%CreateFile_csv(startDate,endDate,final_spill_day,barrels_spilled,barrels_collected,barrels_burned);
%------------------------ Call main program ------------------------------%
OilSpillModel(modelConfig);
%-------------------------------------------------------------------------%
