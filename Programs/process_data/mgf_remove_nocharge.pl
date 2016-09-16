#!/usr/local/bin/perl
use strict;

my $error=0;
my $MGFFileName="";
if ($ARGV[0]=~/\w/) { $MGFFileName=$ARGV[0];} else { $error=1; } 
my $count_spectra=0;
my @count_charges=();
my $i=0;

if ($error==0)
{
	if(open (IN, "$MGFFileName"))
	{
		if(open (OUT,">$MGFFileName-altered.mgf"))
		{
			open (OUT_NO,">$MGFFileName-removed.mgf");
			my $pepmass=0;
			my $title="";
			my $charge="";
			my @mz=();
			my @intensity=();
			my @add=();
			my $header="";
			my $footer="";
			my $started_reading_fragments=0;
			my $done_reading_fragments=0;
			my $points=0;
			my $line="";
			while($line=<IN>)
			{
				if ($line=~/^TITLE=(.*)$/)
				{
					$title=$1;
				}
				if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)\s?([0-9\.\-\+edED]*)\s*$/)
				{
					$pepmass=$1;
				}
				if ($line=~/^CHARGE=([0-9\.\-]+)\+?\s*$/)
				{
					$charge=$1;
				}
				if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)(.*)$/)
				{
					$started_reading_fragments=1;
					$mz[$points]=$1;
					$intensity[$points]=$2;
					$add[$points]=$3;
					$points++;
				}
				else
				{
					if ($started_reading_fragments==1)
					{
						$done_reading_fragments=1;
					}
				}
				if ($started_reading_fragments==0)
				{
					$header.=$line;
				}
				else
				{
					if ($done_reading_fragments==1)
					{
						$footer.=$line;

						if ($charge=~/\w/)
						{
							$count_charges[$charge]++;
							print OUT $header;
							for(my $i=0;$i<$points;$i++)
							{
								print OUT "$mz[$i] $intensity[$i]$add[$i]\n";
							}
							print OUT $footer;
						}
						else
						{
							$count_charges[0]++;
							print OUT_NO $header;
							for(my $i=0;$i<$points;$i++)
							{
								print OUT_NO "$mz[$i] $intensity[$i]$add[$i]\n";
							}
							print OUT_NO $footer;
						}
						
						$pepmass="";
						$title="";
						$charge="";
						@mz=();
						@intensity=();
						@add=();
						$header="";
						$footer="";
						$started_reading_fragments=0;
						$done_reading_fragments=0;
						$points=0;
						$count_spectra++;
					}
				}
			}
			close(OUT);
			close(OUT_NO);
		}
		close(IN);
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

if ($error==0)
{
	print "$count_spectra spectra found in \"$MGFFileName\".\n";
	for($i=0;$i<=10;$i++)
	{
		if ($count_charges[$i]!~/\w/) { $count_charges[$i]=0; }
		print "$i\+: $count_charges[$i] spectra\n";
	}
}