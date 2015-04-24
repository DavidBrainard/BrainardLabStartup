function startup(psychtoolboxFlavor,forceDefault,noBrainardLabToolbox)
% startup([psychtoolboxFlavor],[forceDefault],[noBrainardLabToolbox])
%
% whichPsychtoolboxFlavor:
%   'default' -- default choice [trunk]
%   'trunk' -- use the trunk version
%   'beta'/'current' -- use the current (aka beta) version.
%   'stable' -- use the stable version.
%   'none' -- no PTB!
%
% forceDefault:
%    0 -- Don't reset saved path unless Psychtoolbox is found on path (default).
%    1 -- Reset saved path to Brainard la default no matter what.
%
% noBrainarLab:
%    0 -- Add BrainardLab toolbox and some of its fellow travellers (default).
%    1 -- Don't add BLTB.
%
% This file lives in the BrainardLabStartup toolbox, and it is included
% in the path (set by hand) when MATLAB is installed.  It
% then adds the other standard toolboxes to everyone's path,
% and adds user specific toolboxes depending on who logged in.

% 9/1/11  dhb  Big simplify.
% 4/6/12  dhb  Avoid a world of hurt by not putting BrainardLabFMRIToolbox on the path.
% 6/1/12  dhb  Default for PTB is github version, then the google code svn version if the
%              github version is not there.
% 5/17/13 dhb  Protect against routine IsCluster not existing.
%         dhb  Put RenderToolbox3 on everyone's path, remove RTB2.  Remove RTB from Ana.
% 5/29/13 dhb  Added SphereRendererToolbox to path.
% 5/30/13 dhb  Add call to new RemoveSVNPaths.
% 5/31/13 dhb  Use RemoveMatchingPaths.  Clean a bit.
%         dhb  Remove dependency on RemoveTMPPaths, and printout what temp paths are being stripped.
% 6/2/13  dhb  Remove mglToolbox, which is now part of BrainardLabToolbox.
% 6/13/13 dhb  Add warnings for old PTB and Classes versions.
% 6/19/13 dhb  Java paths added here.  No need to edit classpath.txt.
% 7/12/13 dhb  Use new RemoveTMPPaths to do path removal. This now handles .svn and .git as well as others.
% 8/23/13 dhb  Add Turning point stuff to Java classpath.
% 10/17/13 dhb  Add BrainardLabToolbox to start, not end, of path.  Keeps
%              our savefig from being shadowed by Matlab 2013b's savefig.
%              Need a better long run fix.
% 10/17/13 npc Added helper function 'addToolboxPathAndWarnIfFoundAtMultipleLocations(toolboxName, newPath, oldPath, paths2add)'
%              which checks whether a toolbox exists at two locations (oldPath, newPath).
%              Applied this function to toolboxes in the toolboxesdistrib repository, which (in some computers) may be found both
%              in the 'Toolboxes' and in the 'ToolboxesDistrib' directories.
%              This function also checks if the 'toolboxName' only exists in the 'oldPath' and if so, it warns the user that
%              he/she should consider moving it to the newPath.
% 10/23/13 dhb Handle matlabPyrTools possiblity in multiple locations, but
%              without quite the same level of warning/error checking.
% 11/1/13 bsh  Default for PTB on rhino is github version
% 4/22/14 dhb  BrainardLabPrivateToolbox.
% 7/9/14  dhb  Added arg that allows one to startup without the
%              BrainardLabToobox.  This is mainly useful for testing that something in
%              the PTB works with and without our BLTB. Possible
%              that this should omit other stuff that is pretty specific to
%              us, but I didn't do that either.
% 7/31/14 dhb, ncp  Classes is no more.  Now in BLTB.
%         dhb, ncp  Put computationaleyebrain/toolbox onto path.  Slight
%                   violation of our conventions, but life is short.
% 8/1/14  dhb  Add ColorBookToolbox.
% 11/23/14 dhb Remove user jackallen.
%         dhb  Add SilentSubstitutionToolbox.
%         dhb  Remove StimulusPackages.
% 11/24/14 dhb Add RenderToolboxDevelop/VirtualScenesToolbox.
%              Remove RenderToolbox3 from Ana's special cases.
% 12/23/14 dhb Remove ConeAdaptationToolbox because it collides with isetbio.

% Don't do anything under OS 9 or if being compiled by the Matlab compiler.
if strcmp(computer, 'MAC2') || ismcc || isdeployed
    return;
end

% Check for optional org on Psychtoolbox type
if nargin < 1 || isempty(psychtoolboxFlavor)
    psychtoolboxFlavor = 'default';
end
if nargin < 2 || isempty(forceDefault)
    forceDefault = 0;
end
if nargin < 3 || isempty(noBrainardLabToolbox)
    noBrainardLabToolbox = false;
end

% Determines if this computer is some flavor of OS X.
iAmOSX = any(strcmp(computer, {'MAC', 'MACI', 'MACI64'}));

% Check whether stored path has gotten screwed up because there was a
% savepath stuck at the end of this file at some point.  Also handles case
% where Psychtoolbox install routines save the path, which is not how we
% run.  So this code should stay.
if iAmOSX
    if (any(findstr(path,'Psychtoolbox')) || forceDefault)
        fprintf('Setting stored path to Brainard lab default\n');
        if (exist('restoredefaultpath') == 2) %#ok<*EXIST>
            restoredefaultpath;
        else
            defaultPath = genpath;
            path(defaultPath);
        end
        
        [nil, host] = unix('hostname');
        switch (host(1:end-1))
            otherwise,
                addpath(genpath('/Users/Shared/Matlab/Toolboxes/BrainardLabStartup'),'-end');
        end
        savepath; %#ok<*MCSVP>
    end
end

% Only do this for OS/X, not cluster
if iAmOSX
    % Get host name, allows special casing certain computers.
    [nil, host] = unix('hostname');
    
    % BrainardLabToolbox.  Added at start so that our savefig is called
    % rather than the savefig.p added in 2013b.  Need a better long term
    % fix.
    if (~noBrainardLabToolbox)
        paths2add = addpath(genpath('/Users/Shared/Matlab/Toolboxes/BrainardLabToolbox'),'-begin');
        paths2add = addpath(genpath('/Users/Shared/Matlab/Toolboxes/BrainardLabPrivateToolbox'),'-begin');
    end
    
    % We use this variable to put all paths we need to add in one long
    % string to minimize calls to 'addpath' which seems to eat up a lot of
    % time.
    paths2add = [];
    
    % Get the computer name.  We can special case certain hosts if we want
    % to.
    switch (host(1:end-1))
        otherwise,
            fprintf('Startup: Standard Brainard lab configuration\n');
            if (noBrainardLabToolbox)
                fprintf('But without the BrainardLabToolbox.\n');
            end
            
            % Get user to allow user specific customization.  Only
            % works on OS/X.
            [nil, theUser] = unix('whoami');
            
            % Psychtoolbox.  We use the trunk.
            if ~(strcmp(psychtoolboxFlavor,'none'))
                switch (theUser(1:end-1))
                    otherwise
                        switch (psychtoolboxFlavor)
                            case {'default'}
                                if (exist('/Users/Shared/Matlab/Toolboxes/Psychtoolbox-3/Psychtoolbox','dir'))
                                    paths2add = [paths2add, ...
                                        genpath('/Users/Shared/Matlab/Toolboxes/Psychtoolbox-3/Psychtoolbox')];
                                else
                                    fprintf('WARNING: You are running an old version of Psychtoolbox.  Upgrade.  Ask David or Nicolas.\n');
                                    paths2add = [paths2add, ...
                                        genpath('/Users/Shared/Matlab/Toolboxes/Psychtoolbox-Trunk/Psychtoolbox')];
                                end
                            case {'github'}
                                paths2add = [paths2add, ...
                                    genpath('/Users/Shared/Matlab/Toolboxes/Psychtoolbox-3/Psychtoolbox')];
                            case {'trunk'}
                                fprintf('WARNING: You are running an old version of Psychtoolbox.  Upgrade.  Ask David or Nicolas.\n');
                                paths2add = [paths2add, ...
                                    genpath('/Users/Shared/Matlab/Toolboxes/Psychtoolbox-Trunk/Psychtoolbox')];
                            case {'beta', 'current'}
                                fprintf('WARNING: You are running an old version of Psychtoolbox.  Upgrade.  Ask David or Nicolas.\n');
                                paths2add = [paths2add, ...
                                    genpath('/Users/Shared/Matlab/Toolboxes/Psychtoolbox-Beta'), ...
                                    ];
                        end
                end
            end
            
            % User specific custimization. We can special case certain users if we want to.
            switch (theUser(1:end-1))
                case {'ana'}
                    paths2add = [paths2add, genpath('/Users/Shared/Matlab/Experiments/HDRExperiments/HDRCalibration'), ...
                        genpath('/Users/Shared/Matlab/toolboxes/AnaUtilities')];
                case {'radonjic'}
                    paths2add = [paths2add, genpath('/Users/Shared/Matlab/Experiments/HDRExperiments/HDRCalibration'), ...
                        genpath('/Users/Shared/Matlab/toolboxes/AnaUtilities')];
                case {'nicolas'}
                    paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/libsvm/matlab')];
                case {'spitschan', 'mspits'}
                    paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/SpikeSortToolbox') ...
                        genpath('/Users/Shared/Matlab/toolboxes/ManuelUtilities') ...
                        genpath('/Applications/freesurfer/matlab') ...
                        genpath('/Users/Shared/Matlab/Experiments/OneLight/OLFlickerMRI') ...
                        genpath('/Users/Shared/Matlab/Experiments/OneLight/OLPupilDiameter') ... 
                        genpath('/Users/Shared/Matlab/Toolboxes/AstroMatlab') ...
                        genpath('/Users/Shared/Matlab/gkaguirrelab_Toolboxes') ...
                        genpath('/Users/Shared/Matlab/gkaguirrelab_Projects') ...
                        genpath('/Users/Shared/Matlab/gkaguirrelab_Stimuli')];
                    
                    setenv('FREESURFER_HOME', '/Applications/freesurfer');
                    setenv('SUBJECTS_DIR', '/Applications/freesurfer/subjects');
                    setenv('FSFAST_HOME', '/Applications/freesurfer/fsfast');
                    setenv('FSF_OUTPUT_FORMAT', 'nii.gz');
                    setenv('FSL_DIR', '/usr/local/fsl');
                    setenv('FSLDIR', '/usr/local/fsl');
                    setenv('MNI_DIR', '/Applications/freesurfer/mni');
                    setenv('FSLOUTPUTTYPE', 'NIFTI_GZ');
                    
                    setenv('PATH', [getenv('PATH') ':/Applications/freesurfer/bin'])
                    %------------ FreeSurfer -----------------------------%
                    fshome = getenv('FREESURFER_HOME');
                    fsmatlab = sprintf('%s/matlab',fshome);
                    if (exist(fsmatlab) == 7)
                        path(path,fsmatlab);
                    end
                    clear fshome fsmatlab;
                    %-----------------------------------------------------%
                    
                    %------------ FreeSurfer FAST ------------------------%
                    fsfasthome = getenv('FSFAST_HOME');
                    fsfasttoolbox = sprintf('%s/toolbox',fsfasthome);
                    if (exist(fsfasttoolbox) == 7)
                        path(path,fsfasttoolbox);
                    end
                    clear fsfasthome fsfasttoolbox;
                    %-----------------------------------------------------%
                    
                    % Add ANTS
                    setenv('ANTSPATH', '/usr/bin');
                    setenv('PATH', [getenv('PATH') ':' getenv('ANTSPATH') ':' '/usr/local/fsl/bin']);
                    setenv('PATH', [getenv('PATH') ':/usr/local/afni']);
                    setenv('DYLD_LIBRARY_PATH', '/usr/local/bin/');
            end
            
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/ColorMemoryToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/ContrastResponseModelToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/DenoiseToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/EKColorimetryToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/EyeTrackerToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/HDRToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/ImageAlignmentToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/ImageWarpToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/LabPlotToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/MDSToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/NIToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/OneLightToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/PsychCalLocalData')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/ReceptorLearningToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/StereoHDRToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/SilentSubstitutionToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/TTClickersToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/LEDToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/OLEDToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/ColorBookToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/ContrastSplatterToolbox')];              
            
            % Toolboxes in our local toolboxesdistrib repository.
            if (exist('/Users/Shared/Matlab/ToolboxesDistrib/matlabPyrTools/','dir'))
                paths2add = [paths2add, '/Users/Shared/Matlab/ToolboxesDistrib/matlabPyrTools/MEX:', ...
                    '/Users/Shared/Matlab/ToolboxesDistrib/matlabPyrTools:'];
            elseif (exist('/Users/Shared/Matlab/Toolboxes/matlabPyrTools/','dir'))
                paths2add = [paths2add, '/Users/Shared/Matlab/Toolboxes/matlabPyrTools/MEX:', ...
                    '/Users/Shared/Matlab/Toolboxes/matlabPyrTools:'];
            end
            paths2add = addToolboxPathAndWarnIfFoundAtMultipleLocations('ComplexStatisticsToolbox', '/Users/Shared/Matlab/ToolboxesDistrib', '/Users/Shared/Matlab/Toolboxes', paths2add);
            paths2add = addToolboxPathAndWarnIfFoundAtMultipleLocations('m2html',    '/Users/Shared/Matlab/ToolboxesDistrib', '/Users/Shared/Matlab/Toolboxes', paths2add);
            paths2add = addToolboxPathAndWarnIfFoundAtMultipleLocations('Palamedes', '/Users/Shared/Matlab/ToolboxesDistrib', '/Users/Shared/Matlab/Toolboxes', paths2add);
            paths2add = addToolboxPathAndWarnIfFoundAtMultipleLocations('psignifit', '/Users/Shared/Matlab/ToolboxesDistrib', '/Users/Shared/Matlab/Toolboxes', paths2add);
            paths2add = addToolboxPathAndWarnIfFoundAtMultipleLocations('NIfTIToolbox', '/Users/Shared/Matlab/ToolboxesDistrib', '/Users/Shared/Matlab/Toolboxes', paths2add);
            
            if (exist('/Users/Shared/Matlab/Toolboxes/textureSynth/','dir'))
                paths2add = [paths2add, '/Users/Shared/Matlab/Toolboxes/textureSynth/MEX:', ...
                    '/Users/Shared/Matlab/Toolboxes/textureSynth:', ...
                    ];
            end
            
            % These are pretty obsolate, not adding at the moment.
            %paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/BrainardLabFMRIToolbox')];
            
            % Toolboxes that we used to have but moved elsewhere or got rid of
            %paths2add = [paths2add,genpath('/Users/Shared/Matlab/Toolboxes/BayesToolbox')];
            %paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/Common')];
            
            % MGL.  32 bit version is local, 64 we get from the distribution server.
            mgl64OverrideComputers = {'squid', 'clam'};  % 32 bit computers that use the new MGL.
            if strcmp(computer, 'MACI64') || any(strcmp(lower(strtok(host, '.')), mgl64OverrideComputers)) || strcmp(host(1:6), 'Baird1')
                paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/mgl64')];
            else
                paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/mgl')];
            end
            
            % Render toolbox
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/RenderToolbox3')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/SphereRendererToolbox')];
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/RenderToolboxDevelop/VirtualScenesToolbox')];

            % Simtoolbox
            paths2add = [paths2add,genpath('/Users/Shared/Matlab/Toolboxes/SimAll')];
            
            % Jacket
            paths2add = [paths2add,genpath('/Users/Shared/Matlab/Toolboxes/jacket/engine')];
            
            % Matjag
            paths2add = [paths2add,genpath('/Users/Shared/Matlab/Toolboxes/matjags')];
            
            % Add the PTB overrides toolbox before everything else if it exists.
            % This toolbox lets us write 64 bit versions of PTB functions without
            % actually touching the PTB.
            %overridesDir = '/Users/Shared/Matlab/Toolboxes/PTBOverrides';
            %if exist(overridesDir, 'dir') && strcmp(computer, 'MACI64')
            %    paths2add = [overridesDir, ':', paths2add];
            %end
            
            % If we're using a 64 bit version of Matlab we need to remove
            % the PTB's version of MOGL from the path because it's only 32
            % bit and add our local 64 bit version.  Once the PTB updates their
            % MOGL version this section can be removed.
            if strcmp(computer, 'MACI64')
                rmpath(genpath(fileparts(which('MOGL/contents'))));
                moglDir = '/Users/Shared/Matlab/Toolboxes/mogl';
                if exist(moglDir, 'dir')
                    addpath(genpath(moglDir), '-end');
                end
            end
            
            % GLCalibration.  We can't quite decide if this is a toolbox or not.
            paths2add = [paths2add, genpath('/Users/Shared/Matlab/Toolboxes/GLCalibration')];
            
            % Add the packages folder to the path if it exists.  This is where
            % people will stick any packages they want automatically on the path.
            packagesDir = '/Users/Shared/Matlab/Packages';
            if exist(packagesDir, 'dir')
                paths2add = [packagesDir, ':', paths2add];
            end
            
            % ISET at end so that conflicting names get our version.
            %paths2add = [paths2add genpath('/Users/Shared/Matlab/Toolboxes/iset-4.0')];
            %paths2add = [paths2add genpath('/Users/Shared/Matlab/Toolboxes/vset')];
            paths2add = [paths2add genpath('/Users/Shared/Matlab/Toolboxes/isetbio')];
            paths2add = [paths2add genpath('/Users/Shared/Matlab/Analysis/computationaleyebrain/toolbox')];
            paths2add = [paths2add genpath('/Users/Shared/Matlab/Analysis/BLIlluminationDiscriminationCalcs/toolbox')];
            paths2add = [paths2add genpath('/Users/Shared/Matlab/Toolboxes/UnitTestToolbox')];
            paths2add = [paths2add genpath('/Users/Shared/Matlab/Toolboxes/RemoteDataToolbox')];
            
    end % End switch (host(1:end-1))
end % End if (strcmp(computer,'MAC'))

% Cluster initialization
if (exist('IsCluster'))
    [isCluster,whichCluster] = IsCluster;
else
    isCluster = false;
end
if (isCluster)
    % We use this variable to put all paths we need to add in one long
    % string to minimize calls to 'addpath' which seems to eat up a lot of
    % time.
    paths2add = [];
    
    if (strcmp(whichCluster,'rhino'))
        % Rhino
        fprintf('Startup: Standard Brainard rhino configuration\n');
        switch (psychtoolboxFlavor)
            case 'default'
                paths2add = [paths2add, ...
                    genpath('/home2/brainard/toolboxes/Psychtoolbox-3/Psychtoolbox'), ...
                    ];
            case {'beta', 'current'}
                paths2add = [paths2add, ...
                    genpath('/home2/brainard/toolboxes/Psychtoolbox'), ...
                    ];
        end
        
        % BrainardLabToolbox
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/BrainardLabToolbox')];
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/BrainardLabPrivateToolbox')];
  
        % MDS toolbox
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/MDSToolbox')];
        
        % matlabPyrTools
        paths2add = [paths2add, '/home2/brainard/toolboxes/matlabPyrTools/MEX:', ...
            '/home2/brainard/toolboxes/matlabPyrTools:'];
        
        % Render toolbox
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/RenderToolbox3')];
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/SphereRendererToolbox')];
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/RenderToolboxDevelop/VirtualScenesToolbox')];

        % Sim toolbox.
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/SimAll')];
        
        % isetbio (includes WavefrontOpticsToolbox)
        paths2add = [paths2add, genpath('/home2/brainard/toolboxes/isetbio')];
        
        % CalLocalData
        paths2add = [paths2add, ...
            genpath('/home2/brainard/toolboxes/PsychCalLocalData'), ...
            ];
        
        % NAG
        paths2add = [paths2add, ...
            '/home2/brainard/toolboxes/NAG/mex.a64:', ...
            '/home2/brainard/toolboxes/NAG/help/NAG:', ...
            genpath('/home2/brainard/toolboxes/NAG/help/NAGToolboxDemos'), ...
            ];
    end
end

%% Now add and clean.  This applies to all platforms and machines.
addpath(paths2add, '-end');

if (exist('RemoveTMPPaths.m','file'))
    path(RemoveTMPPaths([],true));
end

% Java dynamic path.  Only on OS/X for now.  This maight
% also be fine on other machine types, but has not been
% tested and is not currently needed in the BrainardLab.
if (iAmOSX)
    if (~noBrainardLabToolbox)
        JavaAddToPath('/Users/Shared/Matlab/Toolboxes/Psychtoolbox-3/Psychtoolbox/PsychJava','Psychtoolbox/PsychJava');
        JavaAddToPath('/Users/Shared/Matlab/Toolboxes/BrainardLabToolbox/Java/jheapcl/MatlabGarbageCollector.jar','MatlabGarbageCollector.jar');
        JavaAddToPath('/Users/Shared/Matlab/Toolboxes/OneLightToolbox/OLEngine/OOI_HOME/OmniDriver.jar','OmniDriver.jar');
        JavaAddToPath('/Users/Shared/Matlab/Toolboxes/TTClickersToolbox/ResponseCardSDK-2.6.4/ResponseCardSDK-2.6.4-RELEASE.jar','ResponseCardSDK-2.6.4-RELEASE.jar');
        %JavaAddToPath('/Users/Shared/Matlab/Toolboxes/TTClickersToolbox/ResponseCardSDK-2.6.4/lib/jna.jar','jna.jar');
    end
end

% Done
fprintf('Ready to roll!\n');
end

% helper function that checks if a toolbox exists at two locations
function paths2add = addToolboxPathAndWarnIfFoundAtMultipleLocations(toolboxName, newPath, oldPath, paths2add)

if (exist(fullfile(newPath, toolboxName)))
    paths2add = [paths2add, genpath(fullfile(newPath,toolboxName))];
    % check whether we have dublicates
    if (exist(fullfile(oldPath,toolboxName), 'dir'))
        fprintf('\n');
        warning('%s found in multiple locations:\n(1)%s\n(2)%s\nRemove it from the old location (%s).\n', toolboxName, oldPath, newPath, oldPath);
    end
else
    if (exist(fullfile(oldPath,toolboxName), 'dir'))
        paths2add = [paths2add, genpath(fullfile(oldPath,toolboxName))];
        warning('%s found in the old location (%s).\nConsider moving it to the new location (%s).\n', toolboxName, oldPath, newPath);
    end
end
end
