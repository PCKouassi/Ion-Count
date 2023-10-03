% In the MATLAB Command Window, call the function that is defined below
% using the function name, the directory of the output CSVs from the Ion
% Count analysis, and file name for the condensed exel file.

% ConsCSV(Full Path of Ion Count Output, Desired Output CSV File Name)
% ex: 
% ****IN COMMAND WINDOW*****

% ConsCSV("/Users/peter/Documents/Research/RK Ion/Nd2 Tester/ACS Ion
% Region Count Results Output", 'ACS Low.xls')

% **Enter**

% output CSV will be saved in the directory that you entered




%function ConsCSV(input_path, output_filename)
    % Specify the folder where the files live.
    myFolder = '/Users/peter/Documents/Research/RK Ion/Nd2 Tester/ACS Ion Region Count Results Output';
    input_path= myFolder;
    output_filename = 'ACS Data.xls'; 

    %myFolder = input_path;
    % Check to make sure that folder actually exists.  Warn user if it doesn't.
    if ~isfolder(myFolder)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s\nPlease specify a new folder.', myFolder);
        uiwait(warndlg(errorMessage));
        myFolder = uigetdir(); % Ask for a new one.
        if myFolder == 0
             % User clicked Cancel
             return;
        end
    end
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(myFolder, '**/*.csv'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    for k = 1 : length(theFiles)
        baseFileName = theFiles(k).name;
        fullFileName = fullfile(theFiles(k).folder, baseFileName);
        Parsed_fullFileName=regexp(fullFileName,'\','split');
        pos_of_instance = length(Parsed_fullFileName)-1;
        [pathstr, name, ext] = fileparts(baseFileName);
        Parsed_fileName=regexp(name,'_','split');
        fprintf(1, 'Now reading %s\n', fullFileName)

        
        Parsed_Sample_Label=regexp(Parsed_fullFileName{1,pos_of_instance},'_','split');
        T = readtable(fullFileName);

        % Turning the table into a matlab data struct for easier indexing
        S = struct('Area',T.Area);

        % Creating a multipage excel file to organize data
        
        
        if k <=2 
            sheet_name_main = strcat('Segmt-',Parsed_fileName{1,2},'-',Parsed_fileName{1,3});
            writetable(T,strcat(input_path,'\',output_filename),'Sheet',strcat('Main-',sheet_name_main));
        else
            sheet_name_sub = strcat(Parsed_Sample_Label{1,1},'-',Parsed_Sample_Label{1,2},'-',Parsed_Sample_Label{1,5},'-',Parsed_fileName{1,1});

            writetable(T,strcat(input_path,'\',output_filename),'Sheet',sheet_name_sub);
        end

    end