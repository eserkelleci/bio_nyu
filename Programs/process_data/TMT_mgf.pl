#!/usr/local/bin/perl

use strict;

my $error=0;
my $MGFFileName="";
if ($ARGV[0]=~/\w/) { $MGFFileName=$ARGV[0];} else { $error=1; } 

my $mass_error=0.05;
$MGFFileName=~s/\\/\//g;
my $MGFFileName_=$MGFFileName;
$MGFFileName_=~s/\//\\/g;
my $line="";
my $title="";
my @TMT_masses=(126.127725,127.131079,128.134433,129.131468,130.141141,131.138176);
my @TMT_intensities=();
my @TMT_intensities_avg=();
my @TMT_intensities_avg_count=();
my @stat=();
my @stat_=();

if ($error==0)
{
	open (LOG,qq!>$MGFFileName.TMT.log!);
	if(open (IN, qq!$MGFFileName!))
	{
		if(open (OUT,qq!>$MGFFileName.TMT.txt!))
		{
			print OUT qq!title!;
			foreach my $mass (@TMT_masses)
			{
				print OUT qq!\tm=$mass!;
			}
			print OUT qq!\tcount\n!;
			while($line = <IN>)
			{
				chomp($line);
				if($line=~/^BEGIN IONS/)
				{
					$title="";
					@TMT_intensities=();
				}
				if($line=~/^TITLE=(.*)$/)
				{
					$title=$1;
				}
				if($line=~/^([0-9\.]+)\s([0-9\.edED\+\-]+)/)
				{
					my $mz=$1;
					my $int=$2;
					if ($TMT_masses[0]-$mass_error<$mz and $mz<$TMT_masses[-1]+$mass_error)
					{
						my $found=0;
						for(my $k=0;$k<=$#TMT_masses and $found==0;$k++)
						{
							if (abs($mz-$TMT_masses[$k])<=$mass_error) { $TMT_intensities[$k]+=$int; $found=1; }
						}
					}
				}
				if($line=~/^END IONS/)
				{
					print OUT qq!$title!;
					my $count=0;
					for(my $k=0;$k<=$#TMT_masses;$k++)
					{
						print OUT qq!\t$TMT_intensities[$k]!;
						if ($TMT_intensities[$k]=~/\w/) 
						{ 
							$count++; 
							$stat_[$k]++; 
							$TMT_intensities_avg[$k]+=$TMT_intensities[$k];
							$TMT_intensities_avg_count[$k]++;
						}
					}
					print OUT qq!\t$count\n!;
					$stat[$count]++;
				}
			}
			close(OUT);
		}
		close(IN);
	}
	else
	{
		print "Could not open \"$MGFFileName\".\n";
		$error=1;
	}
	print LOG qq!\tMGFFileName!;
	for(my $k=0;$k<=$#TMT_masses;$k++)
	{
		print LOG qq!\tcount_label_$k!;
	}
	print LOG qq!\n\t$MGFFileName!;
	for(my $k=0;$k<=$#TMT_masses;$k++)
	{
		print LOG qq!\t$stat_[$k]!;
	}
	
	print LOG qq!\n\nINT\tMGFFileName!;
	for(my $k=0;$k<=$#TMT_masses;$k++)
	{
		print LOG qq!\taverage_intensity_$k!;
	}
	print LOG qq!\nINT\t$MGFFileName!;
	for(my $k=0;$k<=$#TMT_masses;$k++)
	{
		$TMT_intensities_avg[$k]/=$TMT_intensities_avg_count[$k];
		print LOG qq!\t$TMT_intensities_avg[$k]!;
	}
	
	print LOG qq!\n\n\tMGFFileName!;
	for(my $k=0;$k<=$#TMT_masses+1;$k++)
	{
		print LOG qq!\tnumber_quantified=$k!;
	}
	print LOG qq!\n\t$MGFFileName!;
	for(my $k=0;$k<=$#TMT_masses+1;$k++)
	{
		print LOG qq!\t$stat[$k]!;
	}
	close(LOG);
}
else
{
	print "Name of MGF file is missing\n";
}
