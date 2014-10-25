% Harmonic Model + Phase Distortion (HMPD)
%
% Copyright (c) 2012 University of Crete - Computer Science Department
%
% License
%  This file is under the LGPL license,  you can
%  redistribute it and/or modify it under the terms of the GNU Lesser General 
%  Public License as published by the Free Software Foundation, either version 3 
%  of the License, or (at your option) any later version. This file is
%  distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
%  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
%  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
%  details.
%
% This function is part of the Covarep project: http://covarep.github.io/covarep
%
% Author
%  Gilles Degottex <degottex@csd.uoc.gr>
%



clear all;

fname = '0011.arctic_bdl1';
[wav, fs] = wavread([fname '.wav']);

% Analysis ---------------------------------------------------------------------
f0sin = []; % Can use your own here: two-column vector [time[s], f0[hz]]
            %                        if f0==0 -> unvoiced
            % If empty, estimated internally using STRAIGHT
hmpdopt = hmpd_analysis();
hmpdopt.uniform_step = 0.005; % [s] hop size for uniform features resampling
hmpdopt.f0min   = 55; % TODO If use internal f0 estimate, set it acc. to the voice
hmpdopt.f0max   = 220;% TODO If use internal f0 estimate, set it acc. to the voice

% Compression options (See the README.txt)
%  hmpdopt.amp_enc_method=2; hmpdopt.amp_log=true; hmpdopt.amp_order=39; % MFCC
%  hmpdopt.pdd_log=true; hmpdopt.pdd_order=32;% MFCC-like phase variance
%  hmpdopt.pdm_log=true; hmpdopt.pdm_order=32;

% Speed up options (See the README.txt)
%  hmpdopt.sin.use_ls=false; hmpdopt.sin.fadapted=false; % Use Peak Picking
%  hmpdopt.usemex = true; % Use mex function interp1ordered

[f0s, AE, PDM, PDD] = hmpd_analysis(wav, fs, f0sin, hmpdopt);


% Synthesis --------------------------------------------------------------------

synopt = hmpd_synthesis(hmpdopt);
synopt.usemex = hmpdopt.usemex;

syn = hmpd_synthesis(f0s, AE, [], PDD, fs, length(wav), synopt);
wavwrite(syn, fs, [fname '.hmpd-pdd.wav']);

syn = hmpd_synthesis(f0s, AE, PDM, PDD, fs, length(wav), synopt);
wavwrite(syn, fs, [fname '.hmpd-pdmpdd.wav']);



% Plot -------------------------------------------------------------------------
if 1
    figure
    fig(1) = subplot(411);
        times = (0:length(wav)-1)'/fs;
        plot(times, wav, 'k');
        hold on;
        plot((0:length(syn)-1)/fs, syn, 'b');
        plot(f0s(:,1), log2(f0s(:,2))-log2(440), 'r');
        title('Waveform');
        xlabel('Time [s]');
    fig(2) = subplot(412);
        F = fs*(0:hmpdopt.dftlen/2)/hmpdopt.dftlen;
        if ~hmpdopt.amp_log; imagesc(f0s(:,1), F, mag2db(AE)', [-120 -20]);
        else;                imagesc(f0s(:,1), (0:hmpdopt.amp_order), AE'); end
        colormap(jet);
        freezeColors;
        axis xy;
        title('Amplitude Envelope');
        xlabel('Time [s]');

    fig(3) = subplot(413);
        F = fs*(0:hmpdopt.dftlen/2)/hmpdopt.dftlen;
        imagesc(f0s(:,1), F, PDM', [-pi pi]);
        colormap(circmap);
        freezeColors;
        axis xy;
        title('Phase Distortion');
        xlabel('Time [s]');

    fig(4) = subplot(414);
        if ~hmpdopt.pdd_log; imagesc(f0s(:,1), F, PDD', [0 2]);
        else;                imagesc(f0s(:,1), (0:hmpdopt.pdd_order), PDD'); end
        colormap(jet);
        freezeColors;
        axis xy;
        title('Phase Distortion Variance');
        xlabel('Time [s]');

    linkaxes(fig, 'x');
    xlim([times(1) times(end)]);
end
