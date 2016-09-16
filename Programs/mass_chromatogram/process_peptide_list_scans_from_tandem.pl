#!/usr/local/bin/perl
use XML::Simple;
use Data::Dumper;
#use strict;

my $error=0;
my $dir=".";
my $scan_error=1000;
my $mass_error=20;
my $del="";
my $line="";
#my %SETTINGS=(); open(IN,"../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);
#my %programs=(); if (open(IN,"../programs.txt")) { while($line=<IN>) { if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) { $programs{"$1#$2"}=$3; } } close(IN); }
my %pep=();

if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $peptides="$ARGV[1]";} else { $error=1; }
if ($ARGV[2]=~/\w/) { $scan_error="$ARGV[2]";} else { $scan_error=1000; }
if ($ARGV[3]=~/\w/) { $mass_error="$ARGV[3]";} else { $mass_error=20; }

if ($error==0)
{
	if (open(IN,"$peptides"))
	{
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([A-Z]+)/) 
			{ 
				$pep{$1}=1; 
			}
			#print "$line\n";
		}
		close(IN);
	}
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		%peptides=();
		%scans=();
		foreach $filename (@allfiles)
		{
			$filename_="";
			$expect="";
			if ($filename=~/^(.*)\.(0\.1)\.txt$/i)
			{
				$filename_=$1;
				$expect=$2;
				if (open(IN,"$dir/$filename"))
				{
					print qq!$filename_\n!;
					$line=<IN>;
					while($line=<IN>)
					{
						if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$/)
						{
							$pep=$1;
							$title=$6;
							if ($title=~/scan\s+([0-9]+)\s*/i) 
							{ 
								$scan=$1;
								if ($scan=~/\w/)
								{
									if ($pep{$pep}=~/\w/)
									{
										$peptides{"$pep"}.=1;
										$scans{"$filename#$pep"}.="#$scan#";
									}
								}
							}
						}
					}
					close(IN);
					foreach $pep (sort keys %peptides)
					{
						$min=100000000;
						$max=0;
						$temp=$scans{"$filename#$pep"};
						while($temp=~s/^#([^#]+)#//)
						{
							$scan=$1;
							if ($max<$scan) { $max=$scan; }
							if ($min>$scan) { $min=$scan; }
						}
						if ($max>0)
						{
							$scan_avg{"$filename#$pep"}=($min+$max)/2;
						}
					}
				}
			}
		}
		foreach $pep (sort keys %peptides)
		{
			$missing=0;
			foreach $filename (@allfiles)
			{
				if ($filename=~/^(.*)\.(0\.1)\.txt$/i)
				{
					if ($scan_avg{"$filename#$pep"}=~/\w/)
					{
						$scan_value{"$filename#$pep"}=$scan_avg{"$filename#$pep"};
					}
					else
					{
						@value=();
						$value_count=0;
						foreach $filename_ (@allfiles)
						{
							if ($filename_=~/^(.*)\.(0\.1)\.txt$/i)
							{
								if($scan_avg{"$filename_#$pep"}=~/\w/)
								{
									my $n=0;
									my $sumx  = 0;                                                                    
									my $sumx2 = 0;
									my $sumxy = 0;
									my $sumy  = 0;
									my $sumy2 = 0;
									foreach $pep_ (keys %peptides)
									{
										if ($scan_avg{"$filename_#$pep_"}=~/\w/ and $scan_avg{"$filename#$pep_"}=~/\w/)
										{
											$sumx  += $scan_avg{"$filename#$pep_"};                                                                    
											$sumx2 += $scan_avg{"$filename#$pep_"} * $scan_avg{"$filename#$pep_"};
											$sumxy += $scan_avg{"$filename#$pep_"} * $scan_avg{"$filename_#$pep_"};
											$sumy  += $scan_avg{"$filename_#$pep_"};
											$sumy2 += $scan_avg{"$filename_#$pep_"} * $scan_avg{"$filename_#$pep_"};
											$n++;
										}
									}
									if ($n>0 and ($n*$sumx2-$sumx*$sumx)>0 and ($n*$sumy2-$sumy*$sumy)>0)
									{
										$m = ($n * $sumxy  -  $sumx * $sumy) / ($n * $sumx2 - $sumx*$sumx);
										$b = ($sumy * $sumx2  -  $sumx * $sumxy) / ($n * $sumx2  -  $sumx*$sumx);
										$r = ($sumxy - $sumx * $sumy / $n) / sqrt(($sumx2 - $sumx*$sumx/$n) * ($sumy2 - $sumy*$sumy/$n));
										$value[$value_count]=$scan_avg{"$filename_#$pep"}/$m-$b;
										$value_count++;
									}
								}
							}
						}
						@value_sorted = sort { $a <=> $b } @value;
						if (($value_count%2)==0) { $scan_value{"$filename#$pep"}=$value_sorted[$value_count/2]; } else { $scan_value{"$filename#$pep"}=$value_sorted[($value_count+1)/2]; } 
						$count_missing++;
					} 
				}
			}
		}
		foreach $filename (@allfiles)
		{
			if ($filename=~/^(.*)\.(0\.1)\.txt$/i)
			{
				$filename_=$filename;
				$filename_=~s/^(.*)\.(0\.1)\.txt$/$1.cal/i;
				my $cal_slope=0;
				my $cal_intercept=0;
				if (open(IN,"$dir/$filename_"))
				{
					while ($line=<IN>)
					{
						if ($line=~/^Intercept=([0-9\.\-\+edED]+)\s*$/i) { $cal_intercept=$1; }
						if ($line=~/^Slope=([0-9\.\-\+edED]+)\s*$/i) { $cal_slope=$1; }
					}
					close(IN);
				}
				print qq!$filename_ $cal_slope $cal_intercept\n!;
				$filename_=$filename;
				$filename_=~s/^(.*)\.(0\.1)\.txt$/$1.pep/i;
				if (open(OUT,">$dir/$filename_"))
				{
					if (open(IN,"$peptides"))
					{
						while ($line=<IN>)
						{
							chomp($line);
							if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
							{
								$pep=$1;
								$mod=$2;
								$charge=$3;
								$mz=$4;
								$peak_num=$6;
								$scan=$scan_value{"$filename#$pep"};
								$mass_shift=$scan*$cal_slope+$cal_intercept;
								$mz*=1+$mass_shift/1e+6;
								$mz_min=$mz*(1-$mass_error/1e+6);
								$mz_max=$mz*(1+$mass_error/1e+6);
								$scan=~s/\..*$//;
								if ($scan=~/\w/)
								{
									$scan_min=$scan-$scan_error;
									$scan_max=$scan+$scan_error;
								}
								else
								{
									$scan=5000;
									$scan_min=0;
									$scan_max=10000000;
								}
								print OUT qq!$pep\t$mod\t$charge\t$mz\t$scan\t$peak_num\tP\t$scan_min\t$scan_max\t$mz_min\t$mz_max\n!;
							}
						}
						close(IN);
					}
					close(OUT);
				}
			}
		}
	}
}

