%% DEMO 7:  Algorithms 02. SART
%
%
% In this demo the usage of the algorithms on the SART family among with
% their options are presented.  
% 
% 
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% This file is part of the TIGRE Toolbox
% 
% Copyright (c) 2015, University of Bath and 
%                     CERN-European Organization for Nuclear Research
%                     All rights reserved.
%
% License:            Open Source under BSD. 
%                     See the full license at
%                     https://github.com/CERN/TIGRE/license.txt
%
% Contact:            tigre.toolbox@gmail.com
% Codes:              https://github.com/CERN/TIGRE/
% Coded by:           Ander Biguri 
%--------------------------------------------------------------------------
%% Initialize
clear;
close all;

%% Define Geometry
% 
% VARIABLE                                   DESCRIPTION                    UNITS
%-------------------------------------------------------------------------------------
geo.DSD = 1536;                             % Distance Source Detector      (mm)
geo.DSO = 1000;                             % Distance Source Origin        (mm)
% Detector parameters
geo.nDetector=[512; 512];					% number of pixels              (px)
geo.dDetector=[0.8; 0.8]; 					% size of each pixel            (mm)
geo.sDetector=geo.nDetector.*geo.dDetector; % total size of the detector    (mm)
% Image parameters
geo.nVoxel=[128;128;128];                   % number of voxels              (vx)
geo.sVoxel=[256;256;256];                   % total size of the image       (mm)
geo.dVoxel=geo.sVoxel./geo.nVoxel;          % size of each voxel            (mm)
% Offsets
geo.offOrigin =[0;0;0];                     % Offset of image from origin   (mm)              
geo.offDetector=[0; 0];                     % Offset of Detector            (mm)
% Auxiliary 
geo.accuracy=0.5;                           % Accuracy of FWD proj          (vx/sample)

%% Load data and generate projections 
% see previous demo for explanation
angles=linspace(0,2*pi,100);
head=headPhantom(geo.nVoxel);
projections=Ax(head,geo,angles,'interpolated');
noise_projections=addCTnoise(projections);
%% SART family of algorithms
%
% There are 3 algorithms in this damily included in TIGRE: SART,SIRT and
% OS-SART.
%
% The main difference between them is the update process. 
%   SART: Updates the image projection by projection
%   SIRT: Updates the image using the whole set of projections at once
%   OS-SART: middle ground. Updates the image using a subset of the
%            projections
%
%  Of these algorithms, SART is generally the one reaching a better image
%  (less L2 error) for the same amount of iterations, and SIRT is the
%  worst (still relatively similar). However, SART needs increased
%  computational time per iteration, as it needs to update the image very often,
%  while SIRT only updates the emage ones for the whole sets of projections.
%  OS-SART lies in the middle, reaching similar convergence (L2 error per
%  iteration) than SART but with less computational time than SART.
%
%% Usage, with optional parameters.
% In the three algorithms, there are 4 mandatory input arguments:
% Projections, geometry, angles and number of iterations.
%
%
% Optional arguments for all of them
%==========================================================================
% 'lambda': hyperparameter. The update will be multiplied by this number
% every iteration, to make the steps bigger or smaller. Default: 1
%
lambda=1;


% 'lambdared': reduction multiplier for the hyperparameter.
% lambda=lambda*lambdared every iterations, so the steps can be smaller
% the further the update. Default=0.99
lambdared=0.999;

% 'Init' : Initialization method. Possible options are
%          'none' (default). There will be no initialization method, just
%                 the algorithm
%  
%          'FDK'  Initialize the image with the result of FDK algorithm
%
%          'multigrid' Initialize using the multigrid method. The image
%                      will be solved in a small scale, and the size of it
%                      will increase until the desired size is reached.
%
%          'image'     Initialzies with a user given image. Not recoomended
%                      unless you really know what you are doing.

initmode='none';

% 'InitImg' : related to init. The image to use for initializing the
% algorithm.

% 'verbose': boolean to make the algorithm display (or not) running state. 
%            default true.

verbose=true;
% 'QualMeas'     Asks the algorithm for a set of quality measurement
%                parameters. Input should contain a cell array of desired
%                quality measurement names. Example: {'CC','RMSE','MSSIM'}
%                These will be computed in each iteration. 
qualmeas={'RMSE'};

% SIRT and SART both have no extra input parameters.
% =========================================================================
[imgSIRT,errL2SIRT,qualitySIRT]=SIRT(projections,geo,angles,200,...
                            'lambda',lambda,'lambda_red',lambdared,'verbose',verbose,'QualMeas',qualmeas);
[imgSART,errL2SART,qualitySART]=SART(projections,geo,angles,200,...
                            'lambda',lambda,'lambda_red',lambdared,'verbose',verbose,'QualMeas',qualmeas);
% OS-SART
% ========================================================================
% Additionally OS-SART includes a couple of other parameters, related to
% the subsets.
%
%   'BlockSize':   Sets the projection block size used simultaneously. If
%                  BlockSize = 1 OS-SART becomes SART and if  BlockSize = length(angles)
%                  then OS-SART becomes SIRT. Default is 20.
blcks=8;
% 'OrderStrategy':  Chooses the subset ordering strategy. Options are
%                  'ordered' :uses them in the input order, but divided
%                  'random'  : orders them randomply
%                  'angularDistance': chooses the next subset with the 
%                                     biggest angular distance with the
%                                     ones used.  (default)
order='angularDistance';
[imgOSSART,errL2OSSART,qualityOSSART]=OS_SART(projections,geo,angles,200,...
                            'lambda',lambda,'lambda_red',lambdared,'verbose',verbose,'QualMeas',qualmeas,...
                             'BlockSize',blcks,'OrderStrategy',order);
%% Lets have a brief show of the results
% set(0,'DefaultTextInterpreter', 'latex')

subplot(211)
plot(log10([errL2SIRT;[errL2OSSART nan(1,length(errL2SART)-length(errL2OSSART))];errL2SART]'));
title('Convergence')
xlabel('Iteration')
ylabel('$ log_{10}(|Ax-b|) $')
legend('SIRT','OS-SART','SART')
subplot(212)
plot(log10([qualitySIRT;[qualityOSSART nan(1,length(qualitySART)-length(qualityOSSART))];qualitySART]'));
title('Evolution of RMSE')
legend('SIRT','OS-SART','SART')
xlabel('Iteration')
ylabel('$ log_{10}(RMSE) $')

%% plot the results

% It is clear that SART will get to better results for the same amoutn of
% iterations, however, it takes x7 more time to run.

% SART 
% OS-SART
% SIRT

plotImg([imgSIRT;  imgOSSART; imgSART;],'Dim','Z','Savegif','sarts.gif');

% plot error
plotImg(abs([head-imgSIRT; head-imgOSSART; head-imgSART; ]),'Dim','Z');



                         