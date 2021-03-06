% sim_megaspecial_shaped.m
% Jamie Near, McGill University 2014.
% 
% USAGE:
% sim_megaspecial_shaped(n,sw,Bfield,linewidth,taus,sys,editPulse,editTp,editPh1,editPh2,refPulse,refTp,Gx,dx,refPh)
% 
% DESCRIPTION:
% This function simulates the MEGA-SPECIAL sequence with a shaped
% localization pulse and shaped editing pulses.  Enables choice of the 
% timings of all of the rf pulses as well as the choice of the
% phase of both the editing pulses and the refocusing pulse.  This allows 
% phase cycling of the editing and refocusing pulses by repeating 
% simulations with different editing pulse phases, which is necessary to remove phase 
% artefacts from the editing pulses.  For the editing pulses, an eight step 
% phase cycling scheme is typically sufficient, where by the first editing pulse is cycled by 
% 0 and 90 degrees, and the second editing pulse is cycled by 0,90,180, and 270 degrees, and all
% phase cycles should be added together to remove unwanted coherences.  For
% the refocusing pulse, a two step phase cycling scheme is typically
% sufficient, where the refocusing pulses is phase cycled by 0 and 90
% degrees, and the two phase cycles are subtracted from eachother.
% 
% Note that this code only simulates one subspectrum at a time (edit-on or
% edit-off).  The difference spectrum can be obtained by simulating one of
% each, and then subtracting.
% 
% INPUTS:
% n         = number of points in fid/spectrum
% sw        = desired spectral width in [Hz]
% Bfield    = main magnetic field strength in [T]
% linewidth = linewidth in [Hz]
% taus(1)     = time in [ms] from 90 to 1st edit pulse
% taus(2)     = time in [ms] from 1st edit pulse to the 180
% taus(3)     = time in [ms] from the 180 pulse to 2nd edit pulse
% taus(4)     = time in [ms] from 2nd edit pulse to ADC
% editPulse  = Editing pulse shape structure
% editTp     = duration of editing pulse in [ms];
% sys        = Metabolite spin system definition structure;
% editPh1    = the phase of the first editing pulse in [degrees];
% editPh2    = the phase of the second editing pulse in [degrees];
% refPulse   = Refocusing pulse shape structure
% refTp      = duration of refocusing pulse in [ms]
% Gx         = gradient strength for selective refocusing pulse [G/cm]
% dx         = position offset in x-direction (corresponding to refocusing pulse) [cm]
% refPh      = the phase of the refocusing pulse in [degrees];

function out = sim_megaspecial_shaped(n,sw,Bfield,linewidth,taus,sys,editPulse,editTp,editPh1,editPh2,refPulse,refTp,Gx,dx,refPh)

%Set 3ppm GABA resonance to centre
centreFreq=3;
sys.shifts=sys.shifts-centreFreq;

%Calculate Hamiltonian matrices and starting density matrix.
[H,d]=sim_Hamiltonian(sys,Bfield);

%BEGIN PULSE SEQUENCE************
d=sim_excite(H,'x');                                     %EXCITE
d=sim_evolve(d,H,taus(1)/1000);                          %Evolve by taus(1)
d=sim_shapedRF(d,H,editPulse,editTp,180,90+editPh1);     %1st shaped editing pulse rotation
d=sim_evolve(d,H,taus(2)/1000);                          %Evolve by taus(2)
d=sim_shapedRF(d,H,refPulse,refTp,180,90+refPh,Gx,dx);   %2nd shaped 180 degree refocusing pulse
d=sim_evolve(d,H,taus(3)/1000);                          %Evolve by taus(3)
d=sim_shapedRF(d,H,editPulse,editTp,180,90+editPh2);     %2nd shaped editing pulse rotation
d=sim_evolve(d,H,taus(4)/1000);                          %Evolve by taus(4)
[out,dout]=sim_readout(d,H,n,sw,linewidth,90);           %Readout along y (90 degree phase);
%END PULSE SEQUENCE**************

%Correct the ppm scale:
out.ppm=out.ppm-(4.65-centreFreq);

%Fill in structure header fields:
out.seq='megaspecial';
out.te=sum(taus);
out.sim='shaped';

%Additional fields for compatibility with FID-A processing tools.
out.sz=size(out.specs);
out.date=date;
out.dims.t=1;
out.dims.coils=0;
out.dims.averages=0;
out.dims.subSpecs=0;
out.averages=1;
out.rawAverages=1;
out.subspecs=1;
out.rawSubspecs=1;
out.flags.writtentostruct=1;
out.flags.gotparams=1;
out.flags.leftshifted=0;
out.flags.filtered=0;
out.flags.zeropadded=0;
out.flags.freqcorrected=0;
out.flags.phasecorrected=0;
out.flags.averaged=1;
out.flags.addedrcvrs=1;
out.flags.subtracted=1;
out.flags.writtentotext=0;
out.flags.downsampled=0;
out.flags.isISIS=0;


