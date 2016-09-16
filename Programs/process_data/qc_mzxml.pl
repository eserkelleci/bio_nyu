#!c:/perl/bin/perl.exe
# This program plots graphs under various 
# X and Y axes values.
#

use strict;

my $error=0;
my $XMLfilename="";
my $line="";
if ($ARGV[0]=~/\w/) { $XMLfilename=$ARGV[0];} else { $error=1; }
$XMLfilename=~s/\\/\//g;
my $XMLfilename_=$XMLfilename;
$XMLfilename_=~s/\//\\/g;
my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);

my $activation_method="";
my $mz="";
my $intensity="";
my $charge="";
my $scan="";
my $msLevel=0;
my $min_scan=10000000;
my $max_scan=0;
my %precursor_scan=();
my $precursor_scan=0;
my %activation=();
my %activation_count=();
my %mslevel=();
my %mslevel_count=();
my @time=();
my $points=0;
my @count_charge=();
my $time=0;
my $max_count_charge=0;
my $i=0;

if ($error==0)
{
	open (IN, qq!$XMLfilename!) || die "Could not open $XMLfilename\n";
	open (OUT,qq!>$XMLfilename.txt!) || die "Could not open $XMLfilename.txt\n";
	print OUT "scan\tpepmz\tcharge" ;
	print OUT "\n";
	open (OUT1,qq!>$XMLfilename..txt!) || die "Could not open $XMLfilename..txt\n";	
	open (OUT2,qq!>$XMLfilename....txt!);
	print OUT2 "time" ;
	for($i=0;$i<=10;$i++) { print OUT2 qq!\tcharge$i!; }
	print OUT2 "\n" ;
	for($i=0;$i<=10;$i++) { $count_charge[$i]=0 }
	my $time_max=-100;
	my $time_min=1000000000000000;
	
	while ($line=<IN>)
	{	
		if ($line=~/<scan num="([0-9]+)"/)
		{
			my $scan_="$1";
			if($msLevel==1 and $scan=~/\w/)
			{ 
				$precursor_scan=$scan;
				$precursor_scan{$precursor_scan}=1;	
				foreach $activation_method (keys %activation) { $activation_count{"$precursor_scan#$activation_method"}=0; }	
				foreach $msLevel (keys %mslevel) { $mslevel_count{"$precursor_scan#$msLevel"}=0; }
			}
			else
			{ 
				# $precursor_scan=$scan;							#code change : extra addition
				# $precursor_scan{$precursor_scan}=1;				#code change : extra addition
				if($msLevel=~/\w/ and $msLevel>=2)
				{ 
					$mslevel{$msLevel}=1; 
					$mslevel_count{"$precursor_scan#$msLevel"}++;
				}
				if($activation_method=~/\w/) 
				{	
					$activation{$activation_method}=1; 
					$activation_count{"$precursor_scan#$activation_method"}++;
				}
			}
			if($msLevel==2 and $scan=~/\w/)
			{  
				if ($min_scan>$scan) { $min_scan=$scan; }
				if ($max_scan<$scan) { $max_scan=$scan; }
				print OUT qq!$scan\t$mz\t$charge\n!;		
			}
			$mz="";
			$activation_method="";
			$intensity="";
			$charge="";
			$msLevel=0;
			$scan=$scan_;
		}
		
		if ($line=~/retentionTime="PT([0-9\.\-\+]+)S"/)
		{
			$time=$1/60;
		}
		if ($line=~/msLevel="([0-9]+)"/)
		{
			$msLevel=$1;
		}
		if ($line=~/<precursorMz.*>([0-9\.]+)<\/precursorMz>/)
		{
			$mz="$1";
			$intensity="";
			$charge=0;
			$activation_method="";
			if ($line=~/precursorIntensity=\"([0-9\.]+)\"/)
			{
				$intensity="$1";
			}
			if ($line=~/precursorCharge=\"([0-9\.]+)\"/)
			{
				$charge="$1";
			}
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
				print OUT2 "$time_min" ;
				for($i=0;$i<=10;$i++) 
				{ 
					if ($max_count_charge<$count_charge[$i]) { $max_count_charge=$count_charge[$i]; }
					print OUT2 qq!\t$count_charge[$i]!; 
				}
				print OUT2 "\n" ;
				print OUT2 "$time_max" ;
				for($i=0;$i<=10;$i++) 
				{ 
					if ($max_count_charge<$count_charge[$i]) { $max_count_charge=$count_charge[$i]; }
					print OUT2 qq!\t$count_charge[$i]!; 
				}
				print OUT2 "\n" ;
				@count_charge=();
				@time=();
				$time=0;
				$charge=0;
				$points=0;
				$time_max=-100;
				$time_min=1000000000000000;
				for($i=0;$i<=10;$i++) { $count_charge[$i]=0 }
			}
			if ($line=~/activationMethod=\"([A-Za-z]+)\"/)
			{
				$activation_method="$1";
			}
			else
			{
				$activation_method="undefined";
			}
		}
					
	}
			if($msLevel==2 and $scan=~/\w/)
			{  		
				if ($min_scan>$scan) { $min_scan=$scan; }
				if ($max_scan<$scan) { $max_scan=$scan; }
				print OUT qq!$scan\t$mz\t$charge\n!;		
			}
			
	print OUT1 qq!scan!;
	foreach $msLevel (sort keys %mslevel)
	{
		print OUT1 qq!\tmslevel$msLevel!;
	}
	print OUT1 qq!\n!;
	foreach $precursor_scan (sort {$a<=>$b} keys %precursor_scan)
	{	
		print OUT1 qq!$precursor_scan! ;
		foreach $msLevel (sort keys %mslevel)
		{
			if ($mslevel_count{"$precursor_scan#$msLevel"}!~/\w/) { $mslevel_count{"$precursor_scan#$msLevel"}=0; }
			print OUT1 qq!\t$mslevel_count{"$precursor_scan#$msLevel"}!;
		}
		print OUT1 "\n";
	}
			
	close(OUT);
	close(OUT1);
	close(OUT2);
	
	open (OUT,qq!>$XMLfilename...txt!) || die "Could not open $XMLfilename...txt\n";
	print OUT qq!scan!;
	foreach $activation_method (sort keys %activation)
	{
		print OUT qq!\t$activation_method!;
	}
	print OUT qq!\n!;
	foreach $precursor_scan (sort {$a<=>$b} keys %precursor_scan)
	{	
		print OUT qq!$precursor_scan! ;
		foreach $activation_method (sort keys %activation)
		{
			if ($activation_count{"$precursor_scan#$activation_method"}!~/\w/) { $activation_count{"$precursor_scan#$activation_method"}=0; }
			print OUT qq!\t$activation_count{"$precursor_scan#$activation_method"}!;
		}
		print OUT "\n";
	}
	
	close(OUT);
	
	if(open(OUT2,qq!>R-infile.txt!))
	{
		
		print OUT2 qq!windows(width=8, height=4)
					par(tcl=0.2)
					par(mfrow=c(1,1))
					par(mai=c(0.9,0.9,0.2,0.2))
					par(font=1)
					Datafile <- read.table("$XMLfilename.txt",header=TRUE, sep="\t")
					attach(Datafile)
					color <- rep("black",100000)
					color[charge==0] <-"grey"
					color[charge==1] <-"olivedrab"			
					color[charge==2] <-"red"
					color[charge==3] <- rgb(51,153,255, max=255)
					color[charge>=4] <-"black"
					
					plot(pepmz ~ scan, data=Datafile, xlim=c($min_scan,$max_scan), col=color, type="p", pch=20, cex=0.1, axes=TRUE, xlab="Scan", ylab="Precursor m/z")
					legend("topleft",c('?','1+','2+','3+','>3+'), pch=c(20,20,20,20,20), cex=0.7, pt.cex = 2, col=c('grey','olivedrab','red',rgb(51,153,255, max=255),'black'),ncol=1)
				!;
		print OUT2 qq!savePlot(filename="$XMLfilename.mz.png",type="png")!;
		close(OUT2);		
		system(qq!"$SETTINGS{'R'}" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
	}	
	if(open(OUT2,qq!>R-infile.txt!))
	{
		my @mslevel = sort keys %mslevel;
		print OUT2 qq!windows(width=8, height=8)
						par(tcl=0.2)
						par(mfrow=c(2,1))
						par(mai=c(0.9,0.9,0.2,0.2))
						par(font=1)
						Datafile1 <- read.table("$XMLfilename..txt",header=TRUE, sep="\t")
						color <- c('red','blue','violet','green','yellow','darkred')
						plot(mslevel$mslevel[0] ~ scan, data=Datafile1, xlim=c($min_scan,$max_scan), col=color[1], type="p", pch=20, cex=0.1, axes=TRUE, xlab="Scan", ylab="# of scans per MS1 scan")
						legend("bottomleft",c('mslevel$mslevel[0]'), pch=c(20), cex=0.8, pt.cex = 2, col=color[1],ncol=1)
				!;
		
		for(my $i=1;$i<@mslevel;$i++)
		{
			print OUT2 qq!line(mslevel$mslevel[$i] ~ scan, data=Datafile1, col=color[$i+1], type="p", pch=20, cex=0.1)\n!;
			print OUT2 qq!legend("bottomleft",c('mslevel$mslevel[$i]'), pch=c(20), cex=0.8, pt.cex = 2, col=c(color[$i+1]),ncol=1)!;
		}
		
		
		my @activation = sort keys %activation;									
		print OUT2 qq!Datafile <- read.table("$XMLfilename...txt",header=TRUE, sep="\t")
					  color <- c('blue','green','violet','red','yellow','darkred')
					  plot($activation[0] ~ scan, data=Datafile, xlim=c($min_scan,$max_scan), col=color[1], type="p", pch=20, cex=0.1, axes=TRUE, xlab="Scan", ylab="# of scans per MS1 scan")
					  legend("bottomleft",c('$activation[0]'), pch=c(20), cex=0.8, pt.cex = 2, col=color[1],ncol=1)
				!;
		for(my $i=1;$i<@activation;$i++)
		{
			# print OUT2 qq!line($activation[$i] ~ scan, data=Datafile, col=color[$i+1], type="p", pch=20, cex=0.1)\n!;
			print OUT2 qq!plot($activation[$i] ~ scan, data=Datafile, xlim=c($min_scan,$max_scan), col=color[$i+1], type="p", pch=20, cex=0.1, axes=TRUE, xlab="Scan", ylab="# of scans per MS1 scan")\n!;
			print OUT2 qq!legend("bottomleft",c('$activation[$i]'), pch=c(20), cex=0.8, pt.cex = 2, col=c(color[$i+1]),ncol=1)!;
		}
		
		print OUT2 qq!savePlot(filename="$XMLfilename.scan.png",type="png")!;
		close(OUT2);		
		system(qq!"$SETTINGS{'R'}" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);	
	}					
	
			
	# if(open(OUT2,qq!>R-infile.txt!))
	# {
		# print OUT2 qq!windows(width=8, height=11)
					# par(tcl=0.2)
					# par(mfrow=c(3,2))
					# par(mai=c(0.8,0.7,0.4,0.1))
					# par(font=1)
					# Datafile <- read.table("$XMLfilename....txt",header=TRUE)
		# !;
		# for($i=0;$i<=5;$i++)
		# {
			# my $legend="Charge = $i+";
			# if ($i==0) { $legend="Charge undefined"; } 
			# print OUT2 qq!
					# plot(charge$i ~ time, data=Datafile, ylim=c(0,100), type="l", axes=TRUE, main="$legend", xlab="Time", ylab="Number of spectra")
			# !;
		# }
		# print OUT2 qq!savePlot(filename="$XMLfilename.charge.png",type="png")!;
		# close(OUT2);		
		# system(qq!"$SETTINGS{'R'}" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);	
						
	# }
	if(open(OUT2,qq!>R-infile.txt!))
	{
		my @colors=();
		print OUT2 qq!windows(width=8, height=4)
					par(tcl=0.2)
					par(mfrow=c(1,1))
					par(mai=c(0.9,0.9,0.6,0.4))
					par(font=1)
					Datafile <- read.table("$XMLfilename....txt", header=TRUE)
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
		print OUT2 qq!savePlot(filename="$XMLfilename.charge.png",type="png")!;
		close(OUT2);		
		system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);
		system(qq!del R-infile.txt!);
		system(qq!del R-outfile.txt!);
	}
	
	system(qq!del R-infile.txt!);
	system(qq!del R-outfile.txt!);
	system(qq!del R-infile1.txt!);
	system(qq!del R-outfile1.txt!);
	system(qq!del "$XMLfilename_....txt"!);
	system(qq!del "$XMLfilename_...txt"!);
	system(qq!del "$XMLfilename_..txt"!);
	system(qq!del "$XMLfilename_.txt"!);
}