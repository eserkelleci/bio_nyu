#!/usr/local/bin/perl

use strict;

my $error=0;
my $MGFFileName="";
if ($ARGV[0]=~/\w/) { $MGFFileName=$ARGV[0];} else { $error=1; } 

$MGFFileName=~s/\\/\//g;
my $MGFFileName_=$MGFFileName;
$MGFFileName_=~s/\//\\/g;
my $MGFFileName1=$MGFFileName;
$MGFFileName1=~s/\.mgf//i;
my $line="";
my @TMT_intensities_avg=();
my %TMT=();
my %QUANT=();

if ($error==0)
{
	open (OUT, qq!>$MGFFileName.combined.txt!);
	if(open (IN, qq!$MGFFileName.TMT.log!))
	{
		$error=1;
		while($line = <IN>)
		{
			chomp($line);
			if ($line=~/^INT\t[^\t]+\t([0-9\.edED\+\-]+)\t([0-9\.edED\+\-]+)\t([0-9\.edED\+\-]+)\t([0-9\.edED\+\-]+)\t([0-9\.edED\+\-]+)\t([0-9\.edED\+\-]+)/)
			{
				$error=0;
				$TMT_intensities_avg[0]=$1;
				$TMT_intensities_avg[1]=$2;
				$TMT_intensities_avg[2]=$3;
				$TMT_intensities_avg[3]=$4;
				$TMT_intensities_avg[4]=$5;
				$TMT_intensities_avg[5]=$6;
			}
		}
		close(IN);
		if($error==0)
		{
			for(my $i=0;$i<6;$i++) { print qq!$i. $TMT_intensities_avg[$i]\n!; }
			if(open (IN, qq!$MGFFileName.TMT.txt!))
			{
				$line = <IN>;
				my $count=0;
				while($line = <IN>)
				{
					chomp($line);
					if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
					{
						$count++;
						my $title=$1;
						my @int=();
						$int[0]=$2;
						$int[1]=$3;
						$int[2]=$4;
						$int[3]=$5;
						$int[4]=$6;
						$int[5]=$7;
						my $quantified=$8;
						$title=~s/^\s+//;
						$title=~s/\s+$//;
						$QUANT{$title}=$quantified;
						if ($quantified>0)
						{
							$TMT{$title}="";
							for(my $i=0;$i<6;$i++)
							{
								if ($int[$i]=~/\w/) { $int[$i]/=$TMT_intensities_avg[$i]; }
								$TMT{$title}.="$int[$i]\t";
							}
						}
					}
				}
				close(IN);
				print qq!$MGFFileName.TMT.txt $count\n!;
				if(open (IN, qq!$MGFFileName1.xml.peptide_list.0.01.out!))
				{
					my $count=0;
					my $count_not_found=0;
					my $count_zero=0;
					while($line = <IN>)
					{
						chomp($line);
						if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
						{
							$count++;
							my $title=$1;
							my $expect=$2;
							my $pep=$3;
							my $prot=$4;
							$title=~s/^\s+//;
							$title=~s/\s+$//;
							if ($TMT{$title}=~/\w/)
							{
								print OUT qq!$line\t$TMT{$title}\n!;
							}
							else
							{
								if ($QUANT{$title}!~/^0$/)
								{
									print qq!Error: $title\n!;
									$count_not_found++;
								}
								else
								{
									$count_zero++;
								}
							}
						}
					}
					close(IN);
					print qq!$MGFFileName1.xml.peptide_list.0.01.out $count (not found:$count_not_found, zero: $count_zero)\n!;
				}
				#foreach my $title (sort keys %TMT)
				#{
				#	print qq!$TMT{$title}\n!;
				#}
			}
		}
	}
}
else
{
	print "Name of MGF file is missing\n";
}
