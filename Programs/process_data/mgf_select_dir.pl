#!/usr/local/bin/perl
use strict;

my $error=0;
my $dir="";
my $textfile="";
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; } 
if ($ARGV[1]=~/\w/) { $textfile=$ARGV[1];} else { $error=1; } 
my $count_spectra=0;
my @count_charges=();
my $i=0;

if ($error==0)
{
	my %locus=();
	my %locus_done=();
	my $line="";
	if(open (IN, "$textfile"))
	{
		while($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)$/)
			{
				$locus{"$1#$2"}=1;
				#print qq!$1#$2\n!;
			}
		}
		close(IN);
	}
	
	open (OUT, ">$dir.mgf");
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/\.mgf$/i and $filename!~/^\.\.mgf$/i)
			{
				if(open (IN, "$dir/$filename"))
				{
					print qq!$filename\n!;
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
							$line="TITLE=$filename $title\n";
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
								if ($locus{"$filename#$title"}=~/\w/)
								{
									$locus_done{"$filename#$title"}=1;
									print OUT $header;
									for(my $i=0;$i<$points;$i++)
									{
										print OUT "$mz[$i] $intensity[$i]$add[$i]\n";
									}
									print OUT $footer;
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
					close(IN);
				}
			}
		}
	}
	close(OUT);
	foreach my $locus (sort keys %locus)
	{
		if ($locus_done{$locus}!~/\w/)
		{
			print "Not found: $locus\n";
		}
	}
}
else
{
	print "Missing info\n";
}

