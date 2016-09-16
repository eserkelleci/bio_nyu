#!/usr/local/bin/perl
#-------------------------------------------------------------------------#
#   This program reads an MGF file for plotting of spectrum # against time.
#
#
#   Outline (pseudocode):
#
#	if the MGF file can be opened
#	{
#		while there are sill MS/MS spectra left to read
#		{
#			read next MS/MS spectrum
#			count spectrums with a particular charge
#			writes time into an array
#			calculates the median of time for blocks of 100
#			plot the graph, time vs spectrum # for each charge
#		}
#	}
#
#-------------------------------------------------------------------------#
use warnings;
use strict;

my $error=0;
my $MGFFileName="";
my $line="";
my	$min_scan=10000000;
my	$max_scan=0;
my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);

if ($ARGV[0]=~/\w/) { $MGFFileName=$ARGV[0];} else { $error=1; }  
$MGFFileName=~s/\\/\//g;
my $MGFFileName_=$MGFFileName;
$MGFFileName_=~s/\//\\/g;

open (OUT1,qq!>$MGFFileName..txt!);

if ($error==0)
{
	if(open (IN, qq!$MGFFileName!))
	{
		if(open (OUT,qq!>$MGFFileName.txt!))
		{
			print OUT1 "scan\tpepmass\tcharge" ;
			print OUT1 "\n" ;
			print OUT "time" ;
			my $i=0;
			for($i=0;$i<=10;$i++) { print OUT qq!\tcharge$i!; }
			print OUT "\n" ;
			my @time=();
			my $points=0;
			my @count_charge=();
			my $time="";
			my $charge=0;
			my $time_max=0;
			my $time_mid=0;
			my $time_min=1000000000000000;
			my $max_count_charge=0;
			my $scan=0;
			my $pepmass=0;
			for($i=0;$i<=10;$i++) { $count_charge[$i]=0 }
			while($line = <IN>)
			{ 
				if($line=~/Scan\s+([0-9]+)/)
				{
					$scan=$1;
					if ($min_scan>$scan) { $min_scan=$scan; }
					if ($max_scan<$scan) { $max_scan=$scan; }
					print OUT1 "$scan\t";
					
				}
				if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)\s?([0-9\.\-\+edED]*)\s*$/)
				{
					my $oldpepmass=$1;
					$pepmass=$oldpepmass-1.007825;
					print OUT1 "$pepmass\t";
				}	 
				if($line=~/Time=([0-9\.\-\+]+)/)
				{
					$time=$1/60;
				}
				if($line=~/RTINSECONDS=([0-9\.\-\+]+)/)
				{
					$time=$1/60;
				}											
				if ($line=~/^CHARGE=([0-9\.\-\+]+)\s*$/)
				{
					$charge=$1;
					$charge=~s/\+//;
					print OUT1 "$charge\n";
					$points++;
					if ($points<=100)
					{
						$count_charge[$charge]++;
						$time[$points-1]=$time;
						if ($time_min>$time) { $time_min=$time; }
						if ($time_max<$time) { $time_max=$time; }
					}
					else
					{
						print OUT "$time_min" ;
						for($i=0;$i<=10;$i++) 
						{ 
							if ($max_count_charge<$count_charge[$i]) { $max_count_charge=$count_charge[$i]; }
							print OUT qq!\t$count_charge[$i]!; 
						}
						print OUT "\n" ;
						print OUT "$time_max" ;
						for($i=0;$i<=10;$i++) 
						{ 
							if ($max_count_charge<$count_charge[$i]) { $max_count_charge=$count_charge[$i]; }
							print OUT qq!\t$count_charge[$i]!; 
						}
						print OUT "\n" ;
						@count_charge=();
						@time=();
						$time="";
						$charge=0;
						$points=0;
						for($i=0;$i<=10;$i++) { $count_charge[$i]=0 }
						$time_max=0;
						$time_min=1000000000000000;
					}
				}
				
			} 
			close(OUT);
			close(OUT1);
		if(open(OUT2,qq!>R-infile.txt!))
		{
			my @colors=();
			print OUT2 qq!windows(width=8, height=4)
						par(tcl=0.2)
						par(mfrow=c(1,1))
						par(mai=c(0.6,0.5,0.05,0.15))
						par(font=1)
						Datafile <- read.table("$MGFFileName..txt",header=TRUE, sep="\t")
			attach(Datafile)
			color <- rep("black",100000)
			color[charge==0] <-"grey"
			color[charge==1] <-"olivedrab"			
			color[charge==2] <-"red"
			color[charge==3] <- rgb(51,153,255, max=255)
			color[charge>=4] <-"black"
	
			plot(pepmass ~ scan, data=Datafile, xlim=c($min_scan,$max_scan), col=color, type="p", pch=20, cex=0.1, axes=TRUE, ylab="Precursor Mass")
			legend("topleft",c('?','1+','2+', '3+','>3+'), pch=c(20,20,20,20,20), cex=1, pt.cex = 2, col=c('grey','olivedrab','red',rgb(51,153,255, max=255),'black'),ncol=1)
			
			!;
			
			print OUT2 qq!savePlot(filename="$MGFFileName.mass.png",type="png")!;
			close(OUT2);		
			system(qq!"$SETTINGS{'R'}" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
			system(qq!del R-infile.txt!);
								
		}
			# if(open(OUT2,qq!>R-infile.txt!))
			# {
				# print OUT2 qq!windows(width=8, height=11)
							# par(tcl=0.2)
							# par(mfrow=c(3,2))
							# par(mai=c(0.8,0.7,0.4,0.1))
							# par(font=1)
							# Datafile <- read.table("$MGFFileName.txt", header=TRUE)
				# !;
				# for($i=0;$i<=5;$i++)
				# {
					# my $legend="Charge = $i+";
					# if ($i==0) { $legend="Charge undefined"; } 
					# print OUT2 qq!
							# plot(charge$i ~ time, data=Datafile, ylim=c(0,100), type="l", axes=TRUE, main="$legend", xlab="Time", ylab="\% of spectra")
					# !;
				# }
				# print OUT2 qq!savePlot(filename="$MGFFileName.charge.png",type="png")!;
				# close(OUT2);		
				# system(qq!"$SETTINGS{'R'}" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				# system(qq!del R-infile.txt!);
				# system(qq!del R-outfile.txt!);
			# }
			if(open(OUT2,qq!>R-infile.txt!))
			{
				my @colors=();
				print OUT2 qq!windows(width=8, height=4)
							par(tcl=0.2)
							par(mfrow=c(1,1))
							par(mai=c(0.9,0.9,0.6,0.4))
							par(font=1)
							Datafile <- read.table("$MGFFileName.txt", header=TRUE)
				attach(Datafile)
				color <- c('grey','orange','red','olivedrab','black','yellow')
				
				plot(charge0 ~ time, data=Datafile, ylim=c(0,100), col=color[1], type="l", pch=20, cex=0.1, axes=TRUE, xlab="Time", ylab="\% of spectra")
				legend("topleft",c('Undefined','1+','2+', '3+','4+','>4+'), pch=c(20,20,20,20,20), cex=0.6, pt.cex = 2, col=c('grey','orange','red','olivedrab','black','yellow'),ncol=1)
				!;
				for($i=1;$i<=5;$i++)
				{
					print OUT2 qq!
							lines(charge$i ~ time, data=Datafile, ylim=c(0,100), col=color[$i+1], type="l", pch=20, cex=0.1)\n
					!;
				}
				print OUT2 qq!savePlot(filename="$MGFFileName.charge.png",type="png")!;
				close(OUT2);		
				system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
				system(qq!del R-infile.txt!);
				system(qq!del R-outfile.txt!);
			}			
		}
		
	system(qq!del "$MGFFileName_.txt"!);
	system(qq!del "$MGFFileName_..txt"!);
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