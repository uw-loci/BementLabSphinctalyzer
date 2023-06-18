function sphinctalyzerGUI
    clear,clc, home, close all
    addpath(genpath(fullfile('./../bfmatlab')));
    
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    
    control = struct('imagePath','','imageName','','nTimepoints',0,'nChannels',0,'start',0, ...
       'end',0);
    
    %Figure for GUI
    guiCtrl = figure('Resize','on','Color',defaultBackground','Units','normalized','Position',[0.007 0.05 0.260 0.85],'Visible','on',...
        'MenuBar','none','name','sphinctalyzer','NumberTitle','off','UserData',0);
    
    imgOpen = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Open File',...
        'FontSize',12,'Enable','on','Units','normalized','Position',[0.29 .91 .405 .035],...
        'callback','ClickedCallback','Callback', {@loadImg});
    
    loadMulti = uicontrol('Parent',guiCtrl,'Style','checkbox','Enable','on','String','Load Multi-channel Image','Min',0,'Max',1,'Units',...
        'normalized','Position', [.29 .95 .8 .05], 'Value', 1);
    
    cellInputsPanel = uipanel('Parent',guiCtrl,'Title','Cell Inputs Table','FontSize',10,'Units','normalized','Position',[0 0.78 1 0.116]);
    
    cellInputs = uitable('Parent',cellInputsPanel,'ColumnName',{'Display Frame', 'Is Reference?'},'RowName', {'        ', '        ', '        '},...
        'Units','normalized','Position',[0.193 0.04 0.614 0.9],'Enable','on');
    
    slicesPanel = uipanel('Parent',guiCtrl,'visible','on','BorderType','none','FontSize',9,'Units','normalized','Position',[0 0.68 1 .0864]);
    
    hsr = uibuttongroup('parent',slicesPanel,'title','Slices Range','visible','on','Units','normalized','Position',[0 0 1 1]);
    % Create three radio buttons in the button group.
    sru1 = uicontrol('Style','radiobutton','String','Whole stack','Units','normalized',...
        'pos',[0 0.6 0.5 0.5 ],'parent',hsr,'HandleVisibility','on','FontSize',10,'Enable','off');
    sru2 = uicontrol('Style','radiobutton','String','Slices','Units','normalized',...
        'pos',[0 0.1 0.5 0.5],'parent',hsr,'HandleVisibility','on','FontSize',10,'Enable','off');
    sru3 = uicontrol('Style','edit','String','','Units','normalized',...
        'pos',[0.25 0.1 0.1 0.5],'parent',hsr,'HandleVisibility','on','Enable','off','BackgroundColor','w',...
        'Userdata',[],'Callback',{@get_textbox_sru3});
    sru4 = uicontrol('Style','text','String','To','Units','normalized',...
        'pos',[ 0.40 -0.05 0.1 0.5],'parent',hsr,'HandleVisibility','on','Enable','off','FontSize',10);
    sru5 = uicontrol('Style','edit','String','','Units','normalized',...
        'pos',[0.55 0.1 0.1 0.5],'parent',hsr,'HandleVisibility','on','Enable','off','BackgroundColor','w',...
        'Userdata',[],'Callback',{@get_textbox_sru5});
    set(hsr,'SelectionChangeFcn',@selcbk);
    
    guiPanel1 = uipanel('Parent',guiCtrl,'Title','Sphinctalyzer Parameters','Units','normalized','FontSize',10,'Position',[0 0.48 1 .186]);
    
    speedLabel = uicontrol('Parent',guiPanel1,'Style','text','String','inspeed and outspeed','FontSize',10,'Units','normalized','Position',[0 0.85 .85 .125]);
    enterSpeed = uicontrol('Parent',guiPanel1,'Style','edit','String','3','BackgroundColor','w','Min',0,'Max',1,'UserData',3,'Units','normalized','Position',[0.85 0.875 .14 .125],'Callback',{@get_textbox_speed});
    
    shapeLabel = uicontrol('Parent',guiPanel1,'Style','text','String','Scan Shape','FontSize',10,'Units','normalized','Position',[0 .65 .85 .125]);
    enterShape = uicontrol('Parent',guiPanel1,'Style','edit','String','1','BackgroundColor','w','Min',0,'Max',1,'UserData',1,'Units','normalized','Position',[0.85 .675 .14 .125],'Callback',{@get_textbox_shape});
    
    detectionLabel = uicontrol('Parent',guiPanel1,'Style','text','String','Detection Method','FontSize',10,'Units','normalized','Position',[0 .45 .85 .125]);
    enterDetection = uicontrol('Parent',guiPanel1,'Style','edit','String','3','BackgroundColor','w','Min',0,'Max',1,'UserData',3,'Units','normalized','Position',[.85 .475 .14 .125],'Callback',{@get_textbox_detection});
    
    smoothLabel = uicontrol('Parent',guiPanel1,'Style','text','String','Smooth Number','FontSize',10,'Units','normalized','Position',[0 .25 .85 .125]);
    enterSmooth = uicontrol('Parent',guiPanel1,'Style','edit','String','0','BackgroundColor','w','Min',0,'Max',1,'UserData',0,'Units','normalized','Position',[.85 .275 .14 .125],'Callback',{@get_textbox_smooth});
    
    stepLabel = uicontrol('Parent',guiPanel1,'Style','text','String','Step','FontSize',10,'Units','normalized','Position',[0 .05 .85 .125]);
    enterStep = uicontrol('Parent',guiPanel1,'Style','edit','String','8','BackgroundColor','w','Min',0,'Max',1,'UserData',8,'Units','normalized','Position',[.85 .075 .14 .125],'Callback',{@get_textbox_step});
    
    sphinctalyzeButton = uicontrol('Parent', guiCtrl, 'Style', 'pushbutton', 'String', 'Sphinctalyze', 'FontSize', 12, 'Units', 'normalized', 'Position', [0.29 0.42 0.405 0.035],'Enable','off',...
        'Callback',{@sphinctalyze});
    
    %% Import Image
    function loadImg(hObject,Img,eventdata,handles)
         [fileName, pathName] = uigetfile({'*.tif;*.tiff;'},'MultiSelect','off');
         if isequal(fileName,0)
                disp('User selected Cancel')
                return;
            else
                disp(['User selected ', fullfile(pathName,fileName)])
         end
         ff = fullfile(pathName,fileName);
         Img = imread(ff);
         r = bfGetReader(ff);
         nChannels = r.getSizeC(); 
         nTimepoints = r.getSizeT();
         control.imagePath = pathName;
         control.imageName = fileName;
         control.nTimepoints = nTimepoints;
         control.nChannels = nChannels;
         for i = 1:nChannels
             cellInputs.RowName{i, 1} = "channel" + i;
             cellInputs.Data{i, 1} = 1;
             if i ~= 1
                 cellInputs.Data{i, 2} = 0;
             else 
                 cellInputs.Data{i, 2} = 1;
             end
         end
         set(cellInputs, 'ColumnEditable',true(1,2))
         set(sru1, 'Enable', 'on')
         set(sru2, 'Enable', 'on')
         set(sphinctalyzeButton, 'Enable', 'on')
         control.start = 1;
         control.end = nTimepoints;
    end
    
    %% Selecting a specific slice range 
    function selcbk(hsr,eventdata)
        if strcmp(get(get(hsr,'SelectedObject'),'String'),'Slices')
            set([sru3 sru4 sru5],'Enable','on')
        else
            set([sru3 sru4 sru5],'Enable','off')
            control.start = 1;
            control.end = control.nTimepoints;
        end
    end
    
    function get_textbox_sru3(sru3,eventdata)
        usr_input = get(sru3,'String');
        usr_input = str2double(usr_input);
        set(sru3,'UserData',usr_input)
        control.start = usr_input;
    end
    
    function get_textbox_sru5(sru5,eventdata)  
        usr_input = get(sru5,'String');
        usr_input = str2double(usr_input);
        set(sru5,'UserData',usr_input)
        control.end = usr_input;
    end
    
    %% Update Parameters
    function get_textbox_speed(enterSpeed, eventdata)
        usr_input = get(enterSpeed, 'String');
        usr_input = str2double(usr_input);
        set(enterSpeed, 'UserData', usr_input)
    end
    
    function get_textbox_shape(enterShape, eventdata)
        usr_input = get(enterShape, 'String');
        usr_input = str2double(usr_input);
        set(enterShape, 'UserData', usr_input)
    end
    
    function get_textbox_detection(enterDetection, eventdata)
        usr_input = get(enterDetection, 'String');
        usr_input = str2double(usr_input);
        set(enterDetection, 'UserData', usr_input)
    end
    
    function get_textbox_smooth(enterSmooth, eventdata)
        usr_input = get(enterSmooth, 'String');
        usr_input = str2double(usr_input);
        set(enterSmooth, 'UserData', usr_input)
    end
    
    function get_textbox_step(enterStep, eventdata)
        usr_input = get(enterStep, 'String');
        usr_input = str2double(usr_input);
        set(enterStep, 'UserData', usr_input)
    end
    
    function sphinctalyze(hObject,eventdata)
        if control.nChannels == 1
            cellArray = {cellInputs.RowName{1}, cellInputs.Data{1, :}};
        elseif control.nChannels == 2
            cellArray = {cellInputs.RowName{1}, cellInputs.Data{1, :}; cellInputs.RowName{2}, cellInputs.Data{2, :}};
        else
            error("not supported yet")
        end
        file = SphinctalyzerInitializer(cellArray,control.start,control.end,get(enterSpeed,'UserData'),get(loadMulti, 'Value'),...
            get(enterShape,'UserData'),get(enterDetection, 'UserData'),get(enterSmooth,'UserData'),get(enterStep,'UserData'),...
            control.imagePath,control.imageName);
        
        [ParentFolderPath] = fileparts(file);
        [ParentFolderPath] = fileparts(ParentFolderPath);
        SphincRescue(ParentFolderPath)
    end
end
