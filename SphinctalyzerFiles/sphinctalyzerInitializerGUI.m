function sphinctalyzerInitializerGUI(objarray)
    % display GUI with:
    % - cell inputs table
    % - slice options
    % - sphinctalyzer parameters
    % - roi options
    % - colormap options
    % - image queue
    % - stack previewer for the queue
    % dialogue box for exceptions?
    % - "Sphinctalyze All" and cancel buttons
    % update_parameters(1) load parameters for the first image
    

    function update_parameters(objIndex)
        % update GUI parameters wit the obj in the objIndex
        % update stack previewer with that object as well
    end

    function image_queue_callback(hObject, eventData)
        % If another image selected, update_parameter(objIndex)
    end

    function sphinctalyze_callback(hObject, eventdata)
        % for obj in objarray
        %   try running sphinctalyzeInitialize on the object
        %   if exception happens, then display that the parameters are wrong for
        %   that image
        %   if initialization goes through, add the output file into the
        %   object
        % for obj in obj array
        %   get to the parent folder path
        %   run sphincRescue
        %   run moviePlotterMulti
        % run SphinctalyzerOutput(objarray)
    end
end