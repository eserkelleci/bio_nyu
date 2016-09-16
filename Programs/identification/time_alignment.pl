#!c:/perl/bin/perl.exe
# This program plots graphs under various 
# X and Y axes values.
#

use warnings;
use strict;

my @filenames=();
my $threshold="";
my $error=0;
if ($ARGV[0]=~/\w/) { $filenames[0]=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $filenames[1]=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $threshold=$ARGV[2];} else { $threshold="1e-3"; }

$filenames[0]=~s/\\/\//g;
$filenames[1]=~s/\\/\//g;
my @filenames_=();
$filenames_[0]=$filenames[0];
$filenames_[0]=~s/^.*\/([^\/]+)$/$1/;
$filenames_[1]=$filenames[1];
$filenames_[1]=~s/^.*\/([^\/]+)$/$1/;

my $filename="";
my $line="";
my $min_scan=10000000;
my $max_scan=0;

if ($error==0)
{
	my %scans=();
	my %peptides=();
	foreach $filename (@filenames)
	{
		if (open(IN,"$filename"))
		{
			my %min_expect=();
			my $expect=0;
			my $seq="";
			my $modification="";
			while ($line=<IN>)
			{
				if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
				{
					$expect=$2;
					$seq=$3;
					$modification="";
					my $done=0;
					while($done==0)
					{
						if ($line=~/\<\/domain/) { $done=1; }
						else
						{
							if ($line=~/^\<aa\s+type="([A-Za-z]+)"\s+at="([0-9]+)"\s+modified="([\+\-0-9\.]+)"\s+\/>/)
							{
								$modification="$3\@$2,";
							} else { $done=1; }
						}
					}
				}
				if($line=~/<note label="Description">(.*)<\/note>/i)
				{
					my $description=$1;
					if ($description=~/scan\s+([0-9]+)/i)
					{ 
						my $scan=$1;
						if ($min_scan>$scan) { $min_scan=$scan; }
						if ($max_scan<$scan) { $max_scan=$scan; }
						if ($scan=~/\w/ and $seq=~/\w/)
						{
							if ($expect>$threshold)
							{
								if ($min_expect{"$filename#$seq-$modification"}!~/\w/ or $min_expect{"$filename#$seq-$modification"}>$expect) 
								{ 
									$min_expect{"$filename#$seq-$modification"}=$expect;
									$scans{"$filename#$seq-$modification"}=$scan;
									$peptides{"$seq-$modification"}=1;
								}
							}
						}
						$scan="";
						$seq="";
						$modification="";
					}
				}
			}
			close(IN);
		} 
		else { print "Could not open $filename\n"; }
	}
	$filename=$filenames[0];
	$filename=~s/\.mzXML.*$//;
	$filename.=".$filenames_[1]";
	$filename=~s/\.mzXML.*$//;
	if (open (OUT, qq!>$filename.align.txt!))
	{
		print OUT qq!File1Scan\tFile2Scan\n!;
		foreach my $key (keys %peptides)
		{
			if ($scans{"$filenames[0]#$key"}=~/\w/ and $scans{"$filenames[1]#$key"}=~/\w/)
			{
				print OUT qq!$scans{"$filenames[0]#$key"}\t$scans{"$filenames[1]#$key"}\n!;
			}
		}
		close(OUT);
	} else { print qq!Could not open file for writing\n!; }

	if(open(OUT2,qq!>R-infile.txt!))
	{
		print OUT2 qq!windows(width=5, height=5)
					par(tcl=0.2)
					par(mfrow=c(1,1))
					par(mai=c(0.9,0.8,0.5,0.2))
					par(font=1)
					Datafile <- read.table("$filename.align.txt",header=TRUE, sep="\t")
					attach(Datafile)
					plot(File1Scan ~ File2Scan, data=Datafile, type="p", xlim=c($min_scan,$max_scan), ylim=c($min_scan,$max_scan), pch=20, cex=0.1, axes=TRUE, ylab="Scan from $filenames_[0]", xlab="Scan from $filenames_[1]")
					x <- c($min_scan,$max_scan)
					y <- c($min_scan,$max_scan)
					lines(y ~ x, type="l")
					# smoother curve
					loess.model2 <- loess(File1Scan ~ File2Scan, span=0.75, degree=1)
					loess.model2
					predict2 <- predict(loess.model2)
					lines(File2Scan[order(File2Scan)], predict2[order(File2Scan)], col="olivedrab")
					# summary, fitted and residual values for the smoother curve
					summary(loess.model2)
					fitted.values(loess.model2)
					residuals(loess.model2)

		!;
		
		print OUT2 qq!savePlot(filename="$filename.align.png",type="png")!;
		close(OUT2);		
		system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "R-infile.txt" > "R-outfile.txt" 2>&1!);	
		my $temp="$filename.align.txt";
		$temp=~s/\//\\/g;
		system(qq!del "$temp"!);
		system(qq!del "R-infile.txt"!);
		system(qq!del "R-outfile.txt"!);
		
	}
}