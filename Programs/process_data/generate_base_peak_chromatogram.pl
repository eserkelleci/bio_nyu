#!/usr/local/bin/perl
#-------------------------------------------------------------------------#
#   This program reads an MGF file and plots the base peak chromatogram.
#
#-------------------------------------------------------------------------#

use strict;

my $error=0;
my $MGFFileName="";
my $line="";
my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);

if ($ARGV[0]=~/\w/) { $MGFFileName=$ARGV[0];} else { $error=1; }  
$MGFFileName=~s/\\/\//g;
my $MGFFileName_=$MGFFileName;
$MGFFileName_=~s/\//\\/g;

open (OUT1,qq!>$MGFFileName.basepeak.txt!);

if ($error==0)
{
	if(open (IN, qq!$MGFFileName!))
	{
		print OUT1 "scan\ttime\tmz\tintensity" ;
		print OUT1 "\n" ;
		my $time=0;
		my $scan=0;
		my $mz=0;
		my $intensity=0;
		my $max_intensity=-10000;
		my $basepeak_mz=0;
		my $basepeak_intensity=0;
		
		while($line = <IN>)
		{ 
			if($line=~/BEGIN IONS/)
			{
				$scan =0;
				$time =0;
				$basepeak_mz=0;
				$basepeak_intensity=0;
				$max_intensity=-10000;
			}
			elsif($line=~/Scan\s+([0-9]+), Time=([0-9\.\-\+]+)/)
			{
				$scan=$1; 
				$time=$2/60;
				print OUT1 "$scan\t$time\t";
				
			}
			elsif($line=~/([0-9\.\-\+]+)\t([0-9\.\-\+]+)/)
			{
				$mz=$1;
				$intensity=$2;
				if($max_intensity < $intensity) 
				{
					$max_intensity = $intensity;
					$basepeak_intensity = $intensity;
					$basepeak_mz = $mz;
				}
			}
			elsif($line=~/END IONS/)
			{
				print OUT1 qq!$basepeak_mz\t$basepeak_intensity\n!;
			}
			
		}
		
		if(open(OUT2,qq!>R-infile.txt!))
		{
			print OUT2 qq!windows(width=8, height=4)
						par(tcl=0.2)
						par(mfrow=c(1,1))
						par(mai=c(0.9,0.9,0.2,0.2))
						par(font=1)
						Datafile <- read.table("$MGFFileName.basepeak.txt",header=TRUE, sep="\t")
			attach(Datafile)
			plot(intensity ~ time, data=Datafile, type="l", axes=TRUE, xlab="Time", ylab="Intensity")
			!;
			print OUT2 qq!savePlot(filename="$MGFFileName.basepeak.png",type="png")!;
			close(OUT2);		
			#system(qq!"$SETTINGS{'R'}" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
			system(qq!del R-infile.txt!);
			system(qq!del R-outfile.txt!);
								
		}
	}
	else
	{
		print "Could not open \"$MGFFileName\".\n";
		$error=1;
	}
}
else
{
	print "Name of MGF file is missing\n";
}
close(IN);
close(OUT1);